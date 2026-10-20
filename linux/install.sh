#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
bash build-linux.sh
app_dir="${XDG_DATA_HOME:-$HOME/.local/share}/notchpop"
desktop_dir="${XDG_DATA_HOME:-$HOME/.local/share}/applications"
mkdir -p "$app_dir/notchpop" "$desktop_dir" "$HOME/.local/bin"
cp dist/notchpop-linux/notchpop/*.py "$app_dir/notchpop/"
cp LICENSE "$app_dir/"
install -m 755 linux/notchpop-launcher "$app_dir/notchpop-launcher"
# Use a wrapper rather than a symlink: the launcher resolves its own directory.
/usr/bin/python3 - "$app_dir" "$HOME/.local/bin/notchpop" "$desktop_dir/notchpop.desktop" <<'PY'
from pathlib import Path
import shlex
import sys
root, wrapper, desktop = map(Path, sys.argv[1:])
launcher = str(root / "notchpop-launcher")
wrapper.write_text("#!/bin/sh\nexec " + shlex.quote(launcher) + ' "$@"\n')
wrapper.chmod(0o755)
escaped = launcher.replace("\\", "\\\\").replace('"', '\\"').replace("`", "\\`").replace("$", "\\$").replace("%", "%%")
desktop.write_text('[Desktop Entry]\nType=Application\nName=Notchpop\n'
                   'Comment=Your current and upcoming meetings at a glance\n'
                   f'Exec="{escaped}" --settings\nIcon=appointment-soon\n'
                   'Terminal=false\nCategories=Office;Calendar;\nStartupNotify=false\n')
PY
echo "Installed $HOME/.local/bin/notchpop"
echo "Launch from your application menu or run: $HOME/.local/bin/notchpop"
