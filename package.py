"""Validate source and build release archives. Requires requirements-dev.txt and Node."""
from pathlib import Path
import hashlib
import json
import re
import subprocess
import zipfile

from PIL import Image
from tree_sitter import Language, Parser
import tree_sitter_bash

ROOT = Path(__file__).resolve().parent
VERSION = (ROOT / 'VERSION').read_text().strip()
DIST = ROOT / 'dist'
DIST.mkdir(exist_ok=True)
checks = {}
parser = Parser(Language(tree_sitter_bash.language()))

for path in sorted(ROOT.iterdir()):
    if path.suffix in ('.command', '.sh'):
        data = path.read_bytes().replace(b'\r\n', b'\n')
        if parser.parse(data).root_node.has_error:
            raise SystemExit(f'Bash grammar error: {path.name}')
        checks[path.name] = 'Bash grammar passed'
subprocess.run(['node', '--check', str(ROOT / 'Launcher.js')], check=True)
subprocess.run(['node', str(ROOT / 'launcher.test.js')], check=True)
checks['JavaScript'] = 'Syntax passed'
checks['settings_and_location'] = 'Mocked macOS API tests passed: persistence, private file mode, coordinate validation, zero coordinates, denial, stale/fresh fixes'
with Image.open(ROOT / 'AstroPortal.icns') as icon:
    assert icon.format == 'ICNS'
    icon.load()
checks['icon'] = 'ICNS decoded successfully; user-provided artwork retained at owner request'
build = (ROOT / 'build-launcher.sh').read_text()
assert f'CFBundleShortVersionString string {VERSION}' in build
assert 'NSLocationUsageDescription' in build
assert 'NSLocationWhenInUseUsageDescription' in build
assert 'codesign --verify' in build
checks['bundle_configuration'] = 'Version, location purpose strings, compilation/signature commands present; native execution unverified'
for path in ROOT.glob('*.md'):
    for target in re.findall(r'\]\(([^)]+)\)', path.read_text(encoding='utf-8')):
        if not (':' in target or target.startswith('#')):
            assert (ROOT / target.split('#')[0]).exists(), (path.name, target)
checks['local_document_links'] = 'All relative Markdown links resolve'

report = {
    'version': VERSION,
    'checks': checks,
    'execution_host': 'Source/package checks; no native Mac execution claimed',
    'not_verified': ['Native macOS Cocoa/JXA interface and bundle execution',
        'Android provisioning and emulator boot on a Mac', 'Real macOS location permissions',
        'DWARFLAB reading forwarded GPS coordinates', 'Android time/timezone sync on Mac',
        'Fullscreen display/input', 'APK update and data retention on Mac',
        'Physical telescope discovery, pairing, capture, guiding, movement and firmware'],
    'upstream_checks': {
        'scrcpy': '5.0.1 Mac archive layout and published SHA-256 checked for aarch64 and x86_64',
        'DWARFLAB': 'Vendor APK index inspected 2026-11-02: arm64-v8a, armeabi-v7a, x86, x86_64'
    },
    'rights_review': 'See THIRD-PARTY.md and RIGHTS.md. User-provided artwork retained at owner request; no legal clearance claimed.'
}
(ROOT / 'Verification.json').write_text(json.dumps(report, indent=2) + '\n', encoding='utf-8')
(DIST / 'Verification.json').write_bytes((ROOT / 'Verification.json').read_bytes())

def archive(name, files):
    target = DIST / (name + '.zip')
    with zipfile.ZipFile(target, 'w', zipfile.ZIP_DEFLATED) as z:
        for path in sorted(files):
            relative = path.relative_to(ROOT).as_posix()
            info = zipfile.ZipInfo(name + '/' + relative)
            info.create_system = 3
            info.external_attr = (0o100755 if path.suffix in ('.command', '.sh') else 0o100644) << 16
            info.compress_type = zipfile.ZIP_DEFLATED
            data = path.read_bytes()
            if path.suffix not in ('.icns', '.png'):
                data = data.replace(b'\r\n', b'\n')
            z.writestr(info, data)
    with zipfile.ZipFile(target) as z:
        assert z.testzip() is None
        for info in z.infolist():
            if info.filename.endswith('.command'):
                assert (info.external_attr >> 16) & 0o111
    return target

source_files = [p for p in ROOT.rglob('*') if p.is_file()
    and not any(part in ('dist', '.git', '.venv', '__pycache__') for part in p.relative_to(ROOT).parts)]
installer_files = [p for p in source_files if p.parent == ROOT
    and p.name not in ('package.py', 'launcher.test.js', 'requirements-dev.txt', '.gitignore', '.gitattributes')]
assets = [archive(f'Astro-Portal-{VERSION}-macOS', installer_files),
          archive(f'Astro-Portal-Source-{VERSION}', source_files), DIST / 'Verification.json']
checksums = ''.join(hashlib.sha256(p.read_bytes()).hexdigest() + '  ' + p.name + '\n' for p in assets)
(DIST / 'SHA256SUMS.txt').write_text(checksums)
print(f'Version {VERSION}: checks and ZIP integrity/executable metadata passed')
print(checksums)
