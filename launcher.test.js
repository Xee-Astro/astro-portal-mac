const assert = require('assert');
const fs = require('fs');
const vm = require('vm');
const files = new Map();
let permissions;
function dollar(value) {
  return {
    value,
    writeToFileAtomicallyEncodingError(path) { files.set(path.value, value); return true; }
  };
}
dollar.NSHomeDirectory = () => '/test-user';
dollar.NSFileManager = { defaultManager: {
  setAttributesOfItemAtPathError(attrs) { permissions = attrs.value.NSFilePosixPermissions; }
}};
dollar.NSString = { stringWithContentsOfFileEncodingError(path) {
  return {value:files.get(path.value), isNil() {return !files.has(path.value);}};
}};
dollar.NSUTF8StringEncoding = 4;
dollar.CLLocationManager = {locationServicesEnabled: true};
const context = vm.createContext({$:dollar, ObjC:{import(){}, registerSubclass(){}, unwrap(x){return x && x.value !== undefined ? x.value : x;}}, Ref:()=>({}), console});
vm.runInContext(fs.readFileSync(require('path').join(__dirname,'Launcher.js'),'utf8'),context);
vm.runInContext(`
var alerts=[], actions=[];
alert=function(message){alerts.push(message);};
start=function(action){actions.push(action);};
fillCoordinates=function(){};
setBusy=function(){};
ui={fullscreen:{state:1},lat:{stringValue:'-30.25'},lon:{stringValue:'151.5'},alt:{stringValue:'800'},status:{stringValue:''}};
manager={stopUpdatingLocation:undefined,authorizationStatus:2};
load(); manual();
`,context);
assert.equal(context.config.locationMode,'manual');
assert.equal(context.config.latitude,-30.25);
assert.equal(context.config.longitude,151.5);
assert.equal(context.config.altitude,800);
assert.equal(context.actions.at(-1),'sync');
assert.equal(permissions,0o600);
vm.runInContext('config={}; load();',context);
assert.equal(context.config.latitude,-30.25,'coordinates survive reload');
assert.equal(context.config.fullscreen,true,'fullscreen survives reload');
const saved = [...files.values()][0];
vm.runInContext("ui.lat.stringValue='91';manual();",context);
assert.equal([...files.values()][0],saved,'invalid coordinates do not overwrite saved settings');
assert.equal(context.alerts.length,1);
vm.runInContext("ui.lat.stringValue='0';ui.lon.stringValue='0';ui.alt.stringValue='0';manual();",context);
assert.equal(context.config.latitude,0,'equator is valid');
assert.equal(context.config.longitude,0,'prime meridian is valid');
vm.runInContext("requestMac('launch');",context);
assert.match(context.ui.status.stringValue.value,/denied|restricted/,'permission failure is shown');
assert.equal(context.config.locationMode,'manual','denied permission preserves manual settings');
vm.runInContext(`
pending='location';pendingPurpose='launch';
gotLocation({lastObject:{isNil:()=>false,horizontalAccuracy:20,verticalAccuracy:5,altitude:42,timestamp:{timeIntervalSinceNow:-1000},coordinate:{latitude:12,longitude:34}}});
`,context);
assert.equal(context.pending,'location','stale OS fix is ignored');
vm.runInContext(`
gotLocation({lastObject:{isNil:()=>false,horizontalAccuracy:20,verticalAccuracy:5,altitude:42,timestamp:{timeIntervalSinceNow:-1},coordinate:{latitude:12,longitude:34}}});
`,context);
assert.equal(context.pending,null);
assert.equal(context.config.locationMode,'mac');
assert.equal(context.config.latitude,12);
assert.equal(context.config.longitude,34);
assert.equal(context.config.altitude,42);
assert.equal(context.config.accuracy,20);
assert.equal(context.actions.at(-1),'launch');
assert.ok(Number.isInteger(context.config.fixEpoch));
vm.runInContext('config={};load();',context);
assert.equal(context.config.locationMode,'mac','Mac selection survives reload');
assert.equal(context.config.longitude,34);
console.log('Settings persistence, private file mode, coordinate validation, zero coordinates, denied permission, stale-fix rejection, and fresh-fix forwarding logic passed with mocked macOS APIs.');
