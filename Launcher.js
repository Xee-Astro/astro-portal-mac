ObjC.import('Cocoa');
ObjC.import('CoreLocation');

// Compiled by the Mac's built-in osacompile into a stay-open application.
var root = ObjC.unwrap($.NSHomeDirectory()) + '/Library/Application Support/Astro-DWARFLAB-Test';
var resources, win, delegate, manager, pending = null, pendingPurpose = '', requestedAt = 0;
var task = null, handle = null, lastAction = '', lastSync = 0, startedSession = false;
var buttons = [], ui = {}, config;
var fm = $.NSFileManager.defaultManager;
var settingsPath = root + '/settings.json';

function string(value) { return ObjC.unwrap(value); }
function text(path) {
    var value = $.NSString.stringWithContentsOfFileEncodingError($(path), $.NSUTF8StringEncoding, null);
    return value.isNil() ? '' : string(value);
}
function status(message) { if (ui.status) ui.status.stringValue = $(message); }
function alert(message) {
    var dialog = $.NSAlert.alloc.init;
    dialog.messageText = $('Astro Portal'); dialog.informativeText = $(message);
    dialog.addButtonWithTitle($('OK')); dialog.runModal;
}
function load() {
    try { config = JSON.parse(text(settingsPath)); } catch (_) { config = {}; }
    if (!['none', 'manual', 'mac'].includes(config.locationMode)) config.locationMode = 'none';
    if (typeof config.fullscreen !== 'boolean') config.fullscreen = true;
}
function save() {
    var error = Ref();
    var ok = $(JSON.stringify(config, null, 2)).writeToFileAtomicallyEncodingError($(settingsPath), true, $.NSUTF8StringEncoding, error);
    if (!ok) throw Error('Could not save launcher settings. Check free disk space and folder permissions.');
    fm.setAttributesOfItemAtPathError($({NSFilePosixPermissions: 384}), $(settingsPath), null);
}
function field(label, x, y, width, initial) {
    var caption = $.NSTextField.labelWithString($(label));
    caption.frame = $.NSMakeRect(x, y + 32, width, 20); win.contentView.addSubview(caption);
    var entry = $.NSTextField.alloc.initWithFrame($.NSMakeRect(x, y, width, 28));
    entry.stringValue = $(initial === undefined ? '' : String(initial));
    win.contentView.addSubview(entry); return entry;
}
function label(value, x, y, width, height, size) {
    var view = $.NSTextField.wrappingLabelWithString($(value));
    view.frame = $.NSMakeRect(x, y, width, height);
    view.font = $.NSFont.systemFontOfSize(size || 13);
    win.contentView.addSubview(view); return view;
}
function button(title, action, x, y, width) {
    var b = $.NSButton.buttonWithTitleTargetAction($(title), delegate, $.NSSelectorFromString($(action + ':')));
    b.frame = $.NSMakeRect(x, y, width, 34); win.contentView.addSubview(b);
    buttons.push(b); return b;
}
function setBusy(value) { buttons.forEach(function(b) { b.enabled = !value; }); ui.fullscreen.enabled = !value; }
function fillCoordinates() {
    ui.lat.stringValue = $(config.latitude === undefined ? '' : String(config.latitude));
    ui.lon.stringValue = $(config.longitude === undefined ? '' : String(config.longitude));
    ui.alt.stringValue = $(config.altitude === undefined ? '0' : String(config.altitude));
    var summary = config.locationMode === 'none' ? 'No observing location selected.' :
        (config.locationMode === 'mac' ? 'Mac location' : 'Manual location') + ': ' + config.latitude + ', ' + config.longitude + ' · ' + config.altitude + ' m';
    if (config.locationMode === 'mac') summary += '\nLast fix: ' + (config.fixDate || 'unknown') + ' · accuracy ±' + config.accuracy + ' m';
    ui.location.stringValue = $(summary);
}
function currentDisplayChoice() { config.fullscreen = Number(ui.fullscreen.state) === 1; }
function start(action) {
    if (task || pending) return;
    try {
        currentDisplayChoice(); save();
        var log = root + '/logs/last-action.log';
        fm.createFileAtPathContentsAttributes($(log), $.NSData.data, null);
        handle = $.NSFileHandle.fileHandleForWritingAtPath($(log));
        task = $.NSTask.alloc.init;
        task.launchPath = $('/bin/bash');
        task.arguments = $([resources + '/worker.sh', action]);
        task.standardOutput = handle; task.standardError = handle;
        lastAction = action; setBusy(true); status('Working… ' + (action === 'update' ? 'downloading and updating DWARFLAB' : action));
        task.launch;
    } catch (e) { task = null; setBusy(false); status(String(e)); }
}
function manual() {
    try {
        var latText = string(ui.lat.stringValue).trim(), lonText = string(ui.lon.stringValue).trim(), altText = string(ui.alt.stringValue).trim();
        var number = /^-?\d+(\.\d+)?$/;
        if (![latText, lonText, altText].every(function(x) { return number.test(x); })) throw Error('Enter decimal coordinates and altitude. Use a minus sign for south/west.');
        var lat = Number(latText), lon = Number(lonText), alt = Number(altText);
        if (lat < -90 || lat > 90 || lon < -180 || lon > 180 || alt < -1000 || alt > 100000) throw Error('Latitude must be −90 to 90, longitude −180 to 180, and altitude −1000 to 100000 metres.');
        config.locationMode = 'manual'; config.latitude = lat; config.longitude = lon; config.altitude = alt;
        delete config.accuracy; delete config.fixDate;
        currentDisplayChoice(); save(); fillCoordinates(); start('sync');
    } catch (e) { alert(String(e)); }
}
function requestMac(purpose) {
    if (task || pending) return;
    if (!$.CLLocationManager.locationServicesEnabled) { pendingPurpose = purpose; locationFailure('Enable Location Services in macOS System Settings, or enter manual coordinates.'); return; }
    pending = 'location'; pendingPurpose = purpose; requestedAt = Date.now(); setBusy(true);
    status('Requesting a fresh Mac location… allow Astro Portal in the macOS location prompt.');
    try {
        var auth = Number(manager.authorizationStatus);
        if (auth === 2 || auth === 1) { locationFailure('Location permission is denied or restricted. Enable Astro Portal in macOS Location Services, or use manual coordinates.'); return; }
        if (auth === 0) manager.requestWhenInUseAuthorization;
        else manager.requestLocation;
    } catch (e) { locationFailure(String(e)); }
}
function locationFailure(message) {
    pending = null; manager.stopUpdatingLocation; setBusy(false); status(message);
    if (pendingPurpose === 'sync' && startedSession) start('sync');
}
function gotLocation(locations) {
    if (!pending) return;
    var fix = locations.lastObject;
    if (fix.isNil() || Number(fix.horizontalAccuracy) < 0) return;
    if (Math.abs(Number(fix.timestamp.timeIntervalSinceNow)) > 120) return;
    var coord = fix.coordinate, purpose = pendingPurpose;
    config.latitude = Number(coord.latitude); config.longitude = Number(coord.longitude);
    config.altitude = Number(fix.verticalAccuracy) >= 0 ? Number(fix.altitude) : 0;
    config.locationMode = 'mac'; config.accuracy = Math.round(Number(fix.horizontalAccuracy));
    config.fixDate = new Date().toISOString();
    config.fixEpoch = Math.floor(Date.now() / 1000);
    pending = null; manager.stopUpdatingLocation; setBusy(false);
    try { currentDisplayChoice(); save(); fillCoordinates(); start(purpose); } catch (e) { status(String(e)); }
}
function launch() {
    if (config.locationMode === 'mac') requestMac('launch'); else start('launch');
}
function update() {
    var dialog = $.NSAlert.alloc.init;
    dialog.messageText = $('Update DWARFLAB?');
    dialog.informativeText = $('Downloads the vendor APK and updates the installed app while preserving its data. DWARFLAB will close and reopen. Finish any capture first.');
    dialog.addButtonWithTitle($('Update')); dialog.addButtonWithTitle($('Cancel'));
    if (Number(dialog.runModal) === 1000) {
        if (config.locationMode === 'mac') requestMac('update'); else start('update');
    }
}
function changeDisplay() {
    try { currentDisplayChoice(); save(); if (startedSession) start('apply'); else status('Display preference saved for the next launch.'); } catch(e) { alert(String(e)); }
}
ObjC.registerSubclass({
    name: 'AstroPortalDelegate', superclass: 'NSObject', protocols: ['CLLocationManagerDelegate'],
    methods: {
        'launch:': {types:['void',['id']], implementation:function() {launch();}},
        'manual:': {types:['void',['id']], implementation:function() {manual();}},
        'mac:': {types:['void',['id']], implementation:function() {requestMac('sync');}},
        'update:': {types:['void',['id']], implementation:function() {update();}},
        'stop:': {types:['void',['id']], implementation:function() {start('stop');}},
        'display:': {types:['void',['id']], implementation:function() {changeDisplay();}},
        'logs:': {types:['void',['id']], implementation:function() {$.NSWorkspace.sharedWorkspace.openURL($.NSURL.fileURLWithPath($(root + '/logs')));}},
        'locationManager:didUpdateLocations:': {types:['void',['id','id']], implementation:function(_, locations) {gotLocation(locations);}},
        'locationManager:didFailWithError:': {types:['void',['id','id']], implementation:function(_, error) {if(pending) locationFailure('Mac location unavailable: ' + string(error.localizedDescription) + '. You can use manual coordinates.');}},
        'locationManagerDidChangeAuthorization:': {types:['void',['id']], implementation:function(m) {
            if (!pending) return;
            var auth = Number(m.authorizationStatus);
            if (auth === 3 || auth === 4) m.requestLocation;
            else if (auth === 1 || auth === 2) locationFailure('Mac location permission was not granted. Use manual coordinates or enable Location Services.');
        }}
    }
});
function run() {
    resources = string($.NSBundle.mainBundle.resourcePath);
    fm.createDirectoryAtPathWithIntermediateDirectoriesAttributesError($(root + '/logs'), true, null, null);
    load(); delegate = $.AstroPortalDelegate.alloc.init;
    manager = $.CLLocationManager.alloc.init; manager.delegate = delegate; manager.desiredAccuracy = 100;
    win = $.NSWindow.alloc.initWithContentRectStyleMaskBackingDefer($.NSMakeRect(0,0,740,650), 15, $.NSBackingStoreBuffered, false);
    win.title = $('Astro Portal — Mac Edition 1.1'); win.releasedWhenClosed = false;
    var icon = $.NSImage.alloc.initWithContentsOfFile($(resources + '/AstroPortal.icns'));
    $.NSApplication.sharedApplication.applicationIconImage = icon;
    var picture = $.NSImageView.alloc.initWithFrame($.NSMakeRect(28,550,72,72)); picture.image = icon; win.contentView.addSubview(picture);
    label('ASTRO PORTAL',118,582,570,32,26);
    label('Mac edition 1.1 · original DWARFLAB Android app',118,553,570,25,14);
    button('Open DWARFLAB', 'launch',28,494,214);
    button('Update DWARFLAB app', 'update',256,494,228);
    button('Stop Android', 'stop',498,494,214);
    ui.fullscreen = $.NSButton.checkboxWithTitleTargetAction($('Open DWARFLAB fullscreen'),delegate,$.NSSelectorFromString($('display:')));
    ui.fullscreen.frame = $.NSMakeRect(30,452,650,28); ui.fullscreen.state = config.fullscreen ? 1 : 0; win.contentView.addSubview(ui.fullscreen);
    label('Observing location',30,411,650,26,18);
    ui.lat=field('Latitude (−90 to 90)',30,336,210,config.latitude);
    ui.lon=field('Longitude (−180 to 180)',264,336,210,config.longitude);
    ui.alt=field('Altitude (metres)',498,336,210,config.altitude === undefined ? 0 : config.altitude);
    button('Save & use manual coordinates','manual',28,282,330);
    button('Use Mac location','mac',378,282,334);
    ui.location=label('',30,211,680,60,13); fillCoordinates();
    label('Date, time & timezone · from this Mac',30,174,680,25,17);
    ui.clock=label('',30,143,680,26,13);
    label('Saved settings apply at launch. Mac location and clock refresh every minute while this launcher is open. Mac location may be approximate.',30,89,680,48,12);
    ui.status=label('Ready. Select an observing location, then open DWARFLAB.',30,24,550,58,12);
    button('View logs','logs',588,34,124);
    win.center; win.makeKeyAndOrderFront(null); $.NSApplication.sharedApplication.activateIgnoringOtherApps(true);
}
function reopen() { if (win) { win.makeKeyAndOrderFront(null); $.NSApplication.sharedApplication.activateIgnoringOtherApps(true); } }
function idle() {
    if (!win) return 1;
    ui.clock.stringValue = $(new Date().toLocaleString() + ' · ' + string($.NSTimeZone.localTimeZone.name));
    if (pending && Date.now() - requestedAt > 30000) locationFailure('Mac did not provide a fresh location within 30 seconds. Check Location Services or use manual coordinates.');
    if (task && !task.running) {
        var exit = Number(task.terminationStatus); task = null;
        if (handle) { handle.closeFile; handle = null; }
        setBusy(false); lastSync = Date.now();
        if (exit !== 0) { status('Operation failed. View logs → last-action.log for the exact error.'); }
        else {
            if (['launch','apply','update'].includes(lastAction)) startedSession = true;
            if (lastAction === 'stop') startedSession = false;
            var lines = text(root + '/logs/last-action.log').trim().split('\n');
            status(lines.slice(-2).join('\n'));
        }
    }
    if (startedSession && !task && !pending && Date.now() - lastSync > 60000) {
        lastSync = Date.now();
        if (config.locationMode === 'mac') requestMac('sync'); else start('sync');
    }
    return 1;
}
