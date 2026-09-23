#!/bin/bash
# Fix Flutter + App Extension build cycle (Cycle inside Runner)
# Run from the repo root:  bash ios/fix_build_cycle.sh
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
PBX="$ROOT/ios/Runner.xcodeproj/project.pbxproj"

if [[ ! -f "$PBX" ]]; then
  echo "Cannot find $PBX"
  exit 1
fi

cp "$PBX" "$PBX.bak.$(date +%s)"
echo "Backup created"

python3 - "$PBX" <<'PY'
import re
import sys
from pathlib import Path

p = Path(sys.argv[1])
t = p.read_text()

# 1) CodeSignOnCopy on embedded appex
t = t.replace(
    "settings = {ATTRIBUTES = (RemoveHeadersOnCopy, ); };",
    "settings = {ATTRIBUTES = (CodeSignOnCopy, RemoveHeadersOnCopy, ); };",
)

# 2) Reorder Runner buildPhases:
# Embed Foundation Extensions BEFORE CocoaPods + Thin Binary last
old = """\t\t\tbuildPhases = (
\t\t\t\t836A93DCADAC044299B79791 /* [CP] Check Pods Manifest.lock */,
\t\t\t\t9740EEB61CF901F6004384FC /* Run Script */,
\t\t\t\t97C146EA1CF9000F007C117D /* Sources */,
\t\t\t\t97C146EB1CF9000F007C117D /* Frameworks */,
\t\t\t\t97C146EC1CF9000F007C117D /* Resources */,
\t\t\t\t9705A1C41CF9048500538489 /* Embed Frameworks */,
\t\t\t\t3B06AD1E1E4923F5004D2608 /* Thin Binary */,
\t\t\t\t8ABA70C739BAD1469E21D88B /* [CP] Embed Pods Frameworks */,
\t\t\t\t5C13F898A750B18203785DC4 /* [CP] Copy Pods Resources */,
\t\t\t\tFD3196FF3063F55D003EC577 /* Embed Foundation Extensions */,
\t\t\t);"""

new = """\t\t\tbuildPhases = (
\t\t\t\t836A93DCADAC044299B79791 /* [CP] Check Pods Manifest.lock */,
\t\t\t\t9740EEB61CF901F6004384FC /* Run Script */,
\t\t\t\t97C146EA1CF9000F007C117D /* Sources */,
\t\t\t\t97C146EB1CF9000F007C117D /* Frameworks */,
\t\t\t\t97C146EC1CF9000F007C117D /* Resources */,
\t\t\t\t9705A1C41CF9048500538489 /* Embed Frameworks */,
\t\t\t\tFD3196FF3063F55D003EC577 /* Embed Foundation Extensions */,
\t\t\t\t8ABA70C739BAD1469E21D88B /* [CP] Embed Pods Frameworks */,
\t\t\t\t5C13F898A750B18203785DC4 /* [CP] Copy Pods Resources */,
\t\t\t\t3B06AD1E1E4923F5004D2608 /* Thin Binary */,
\t\t\t);"""

if old in t:
    t = t.replace(old, new)
    print("Reordered build phases")
else:
    # Already reordered or different — force by regex on Runner phases block
    print("Exact phase block not found; applying flexible reorder")
    def reorder(m):
        body = m.group(0)
        # Remove embed + thin from list then append correct order at end of known set
        return new
    t2, n = re.subn(
        r"\t\t\tbuildPhases = \(\n(?:\t\t\t\t[^\n]+\n)+\t\t\t\);",
        lambda m: new if "97C146EA1CF9000F007C117D" in m.group(0) and "FD3196FF" in m.group(0) else m.group(0),
        t,
        count=1,
    )
    if n:
        t = t2
        print("Flexible reorder applied")
    else:
        print("WARNING: could not reorder phases automatically")

# 3) Remove Thin Binary inputPaths (breaks cycle with PlugIns)
old_in = """\t\t\tinputPaths = (\n\t\t\t\t\"${TARGET_BUILD_DIR}/${INFOPLIST_PATH}\",\n\t\t\t);\n\t\t\tname = \"Thin Binary\";"""
new_in = """\t\t\tinputPaths = (\n\t\t\t);\n\t\t\tname = \"Thin Binary\";"""
if old_in in t:
    t = t.replace(old_in, new_in)
    print("Cleared Thin Binary inputPaths")
else:
    t = re.sub(
        r'(name = "Thin Binary";\n\t\t\toutputPaths = \()',
        r'inputPaths = (\n\t\t\t);\n\t\t\t\1',
        t,
        count=1,
    )
    # simpler: empty inputPaths near Thin Binary
    t = re.sub(
        r'(3B06AD1E1E4923F5004D2608 /\* Thin Binary \*/ = \{[^}]*?)inputPaths = \(\n\t\t\t\t"\$\{TARGET_BUILD_DIR\}/\$\{INFOPLIST_PATH\}",\n\t\t\t\);',
        r'\1inputPaths = (\n\t\t\t);',
        t,
        count=1,
        flags=re.S,
    )
    print("Attempted Thin Binary inputPaths clear")

# 4) alwaysOutOfDate on CocoaPods script phases
for uid, name in [
    ("8ABA70C739BAD1469E21D88B", "[CP] Embed Pods Frameworks"),
    ("5C13F898A750B18203785DC4", "[CP] Copy Pods Resources"),
]:
    marker = f"{uid} /* {name} */ = {{\n\t\t\tisa = PBXShellScriptBuildPhase;\n"
    insert = f"{uid} /* {name} */ = {{\n\t\t\tisa = PBXShellScriptBuildPhase;\n\t\t\talwaysOutOfDate = 1;\n"
    pos = t.find(f"{uid} /* {name} */")
    if pos >= 0 and "alwaysOutOfDate" not in t[pos:pos + 350]:
        if marker in t:
            t = t.replace(marker, insert, 1)
            print(f"alwaysOutOfDate -> {name}")

p.write_text(t)
print("Patched", p)
PY

echo ""
echo "Next:"
echo "  flutter clean"
echo "  cd ios && pod install && cd .."
echo "  rm -rf ~/Library/Developer/Xcode/DerivedData/Runner-*"
echo "  flutter run"
