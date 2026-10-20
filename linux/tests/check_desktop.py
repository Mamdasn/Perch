"""Run explicitly in a graphical session: PYTHONPATH=linux python3 linux/tests/check_desktop.py."""

from types import SimpleNamespace

from notchpop.app import Notchpop, GLib, Gdk

app = Notchpop(isolated=True)
failed = []


def check():
    try:
        assert app.layer, "The current Wayland desktop must support layer-shell"
        assert app.window.get_realized()
        app.set_demo(current=True)
        app.open_card()
        assert app.selected().id == "demo"
        app.key(None, SimpleNamespace(keyval=Gdk.KEY_Up))
        assert app.selected().id == "demo-next"
        app.key(None, SimpleNamespace(keyval=Gdk.KEY_Down))
        assert app.selected().id == "demo"
        app.move(-1)
        assert app.selected().id == "demo-before"
        app.move(-1)
        assert app.selected().id == "demo-before", "Navigation must stop at the first event"
        app.key(None, SimpleNamespace(keyval=Gdk.KEY_Escape))
        assert not app.opened
        app.open_card()
        assert app.selected().id == "demo", "Reopening must reset to the featured event"
        app.show_settings()
        assert app.settings.get_visible()
        assert not app.opened
        app.settings.destroy()
        assert app.settings is None
        app.open_card()
        print("Desktop checks passed: layer-shell, navigation, bounds, Escape, settings, reopening.", flush=True)
    except Exception as exc:
        failed.append(str(exc))
        print(f"Desktop checks failed: {exc}", flush=True)
    finally:
        app.quit()
    return False


GLib.timeout_add(1000, check)
app.run(["notchpop-desktop-check", "--preview-meeting"])
raise SystemExit(bool(failed))
