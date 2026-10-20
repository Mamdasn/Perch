#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")"
if [[ "$(uname -s)" != Linux ]]; then
    echo "Run this script on Linux." >&2
    exit 1
fi
/usr/bin/python3 -c '
import gi, cairo
gi.require_version("Gtk", "3.0")
gi.require_version("GtkLayerShell", "0.1")
gi.require_version("ECal", "2.0")
gi.require_version("EDataServer", "1.2")
from gi.repository import Gtk, GtkLayerShell, ECal, EDataServer
'
mkdir -p dist/notchpop-linux/notchpop
cp linux/notchpop/*.py dist/notchpop-linux/notchpop/
install -m 755 linux/notchpop-launcher dist/notchpop-linux/notchpop-launcher
cp LICENSE dist/notchpop-linux/
PYTHONPATH="$PWD/linux" /usr/bin/python3 -m unittest discover -s linux/tests -v
echo "Built dist/notchpop-linux"
echo "Run: dist/notchpop-linux/notchpop-launcher"
echo "Install: bash linux/install.sh"
