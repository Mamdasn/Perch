"""Native GTK popup using layer-shell on Wayland, with an X11 fallback."""

import argparse
import json
import os
from pathlib import Path
import threading
import time
from datetime import datetime
from urllib.parse import quote

import cairo
import gi

gi.require_version("Gtk", "3.0")
gi.require_version("Gdk", "3.0")
gi.require_version("GtkLayerShell", "0.1")
from gi.repository import Gdk, Gio, GLib, Gtk, GtkLayerShell

from .calendar import read_calendars
from .model import demo_meetings, featured


CSS = b"""
window#notchpop { background: transparent; }
#card { background: #17191e; color: #f4f5f8; border-radius: 0 0 24px 24px;
        border: 1px solid #343842; padding: 22px; }
#card label { color: #f4f5f8; }
#card .muted { color: #a4acbb; font-size: 12px; }
#card .heading { font-size: 21px; font-weight: bold; }
#card .eyebrow { color: #a4c8ff; font-size: 11px; font-weight: bold; }
#card button { background: #292d36; color: #f4f5f8; border: 0;
               border-radius: 10px; box-shadow: none; padding: 8px 12px; }
#card button:hover { background: #3a4250; }
#card button:disabled { opacity: 0.35; }
#card button.join { background: #bdd5ff; color: #14223a; }
#card progressbar trough { background: #303641; min-height: 3px; border: 0; }
#card progressbar progress { background: #bdd5ff; min-height: 3px; border: 0; }
"""


def label(text="", style=None):
    widget = Gtk.Label(label=text, xalign=0)
    widget.set_line_wrap(True)
    widget.set_max_width_chars(38)
    if style:
        widget.get_style_context().add_class(style)
    return widget


def button(text, callback):
    widget = Gtk.Button(label=text)
    widget.connect("clicked", lambda *_: callback())
    return widget


class Notchpop(Gtk.Application):
    def __init__(self, isolated=False):
        flags = Gio.ApplicationFlags.HANDLES_COMMAND_LINE
        if isolated:
            flags |= Gio.ApplicationFlags.NON_UNIQUE
        super().__init__(application_id="io.github.Mamdasn.Notchpop", flags=flags)
        self.window = None
        self.settings = None
        self.meetings = []
        self.choices = []
        self.errors = []
        self.demo = False
        self.loading = False
        self.reload_pending = False
        self.opened = False
        self.selected_id = None
        self.enter_timer = self.leave_timer = 0
        self.smoke_status = 0
        self.monitor_index = 0
        self.cancellable = Gio.Cancellable()
        self.config_path = Path(os.environ.get("XDG_CONFIG_HOME", Path.home() / ".config")) / "notchpop/settings.json"
        self.excluded = set()
        try:
            value = json.loads(self.config_path.read_text())
            excluded = value.get("excluded_calendars", [])
            if isinstance(excluded, list):
                self.excluded = {item for item in excluded if isinstance(item, str)}
        except FileNotFoundError:
            pass
        except (ValueError, OSError, AttributeError):
            self.errors = ["Saved settings could not be read. Calendar selections will use their defaults."]
        self.connect("shutdown", lambda *_: self.cancellable.cancel())

    def do_command_line(self, command):
        try:
            args = parser().parse_args(command.get_arguments()[1:])
        except SystemExit as exc:
            return int(exc.code)
        if args.quit:
            self.quit()
            return 0
        if args.monitor is not None:
            self.monitor_index = args.monitor
        self.activate()
        if args.monitor is not None:
            self.position()
        if args.preview_meeting or args.demo:
            self.set_demo(current=args.preview_meeting)
            self.open_card()
        if args.settings:
            self.show_settings()
        if args.toggle:
            self.close_card() if self.opened else self.open_card()
        if args.smoke_test or args.screenshot:
            GLib.timeout_add(800, self.capture, args.screenshot, args.smoke_test)
        return 0

    def do_activate(self):
        if self.window:
            return
        display = Gdk.Display.get_default()
        if display is None:
            raise RuntimeError("No graphical display is available.")
        self.layer = GtkLayerShell.is_supported()
        if not self.layer and "wayland" in display.get_name().lower():
            raise RuntimeError("This Wayland compositor does not support layer-shell.")
        provider = Gtk.CssProvider()
        provider.load_from_data(CSS)
        Gtk.StyleContext.add_provider_for_screen(Gdk.Screen.get_default(), provider,
                                                 Gtk.STYLE_PROVIDER_PRIORITY_APPLICATION)
        self.window = Gtk.ApplicationWindow(application=self, title="Notchpop")
        self.window.set_name("notchpop")
        self.window.set_decorated(False)
        self.window.set_resizable(False)
        self.window.set_app_paintable(True)
        self.window.set_default_size(400, 310)
        visual = self.window.get_screen().get_rgba_visual()
        if visual:
            self.window.set_visual(visual)
        if self.layer:
            GtkLayerShell.init_for_window(self.window)
            GtkLayerShell.set_namespace(self.window, "notchpop")
            GtkLayerShell.set_layer(self.window, GtkLayerShell.Layer.OVERLAY)
            GtkLayerShell.set_anchor(self.window, GtkLayerShell.Edge.TOP, True)
            GtkLayerShell.set_exclusive_zone(self.window, 0)
            GtkLayerShell.set_keyboard_mode(self.window, GtkLayerShell.KeyboardMode.ON_DEMAND)
        else:
            self.window.set_type_hint(Gdk.WindowTypeHint.DOCK)
            self.window.set_keep_above(True)
            self.window.set_skip_taskbar_hint(True)
            self.window.stick()
        self.position()
        display.connect("monitor-added", lambda *_: self.position())
        display.connect("monitor-removed", lambda *_: self.position())
        self.window.connect("screen-changed", lambda *_: self.position())
        self.window.add_events(Gdk.EventMask.ENTER_NOTIFY_MASK | Gdk.EventMask.LEAVE_NOTIFY_MASK |
                               Gdk.EventMask.SCROLL_MASK | Gdk.EventMask.SMOOTH_SCROLL_MASK |
                               Gdk.EventMask.POINTER_MOTION_MASK)
        self.window.connect("enter-notify-event", self.enter)
        self.window.connect("leave-notify-event", self.leave)
        self.window.connect("key-press-event", self.key)
        self.window.connect("scroll-event", self.scroll)
        self.window.connect("size-allocate", lambda *_: self.input_region())
        self.window.connect("delete-event", lambda *_: (self.quit(), True)[1])
        root = Gtk.Box(orientation=Gtk.Orientation.VERTICAL)
        self.window.add(root)
        spacer = Gtk.Box()
        spacer.set_size_request(-1, 6)
        root.pack_start(spacer, False, False, 0)
        self.revealer = Gtk.Revealer()
        self.revealer.set_transition_type(Gtk.RevealerTransitionType.CROSSFADE)
        self.revealer.set_transition_duration(180)
        self.revealer.connect("notify::child-revealed", lambda *_: self.input_region())
        root.pack_start(self.revealer, False, False, 0)
        self.card = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=12)
        self.card.set_name("card")
        self.revealer.add(self.card)
        header = Gtk.Box(spacing=6)
        self.state_label = label("UP NEXT", "eyebrow")
        header.pack_start(self.state_label, True, True, 0)
        header.pack_end(button("⚙", self.show_settings), False, False, 0)
        self.card.pack_start(header, False, False, 0)
        self.title_button = button("", self.open_event)
        self.title = label("", "heading")
        self.title_button.remove(self.title_button.get_child())
        self.title_button.add(self.title)
        self.card.pack_start(self.title_button, False, False, 0)
        self.calendar_label = label("", "muted")
        self.time_label = label()
        self.card.pack_start(self.calendar_label, False, False, 0)
        self.card.pack_start(self.time_label, False, False, 0)
        self.progress = Gtk.ProgressBar()
        self.card.pack_start(self.progress, False, False, 0)
        footer = Gtk.Box(spacing=8)
        self.previous = button("‹", lambda: self.move(-1))
        self.previous.set_tooltip_text("Earlier meeting (Down arrow or scroll down)")
        self.next = button("›", lambda: self.move(1))
        self.next.set_tooltip_text("Later meeting (Up arrow or scroll up)")
        self.counter = label("", "muted")
        self.join = button("Join meeting ↗", self.join_meeting)
        self.join.get_style_context().add_class("join")
        footer.pack_start(self.previous, False, False, 0)
        footer.pack_start(self.next, False, False, 0)
        footer.pack_start(self.counter, True, True, 0)
        footer.pack_end(self.join, False, False, 0)
        self.card.pack_start(footer, False, False, 0)
        self.window.show_all()
        self.revealer.set_reveal_child(False)
        self.render()
        self.input_region()
        self.refresh()
        GLib.timeout_add_seconds(60, self.refresh)
        GLib.timeout_add_seconds(1, self.tick)

    def position(self):
        display = Gdk.Display.get_default()
        if not display or display.get_n_monitors() == 0:
            return
        monitor = display.get_monitor(min(max(self.monitor_index, 0), display.get_n_monitors() - 1))
        if self.layer:
            GtkLayerShell.set_monitor(self.window, monitor)
        else:
            rect = monitor.get_geometry()
            self.window.move(rect.x + (rect.width - 400) // 2, rect.y)

    def input_region(self):
        native = self.window.get_window() if self.window else None
        if native:
            width = self.window.get_allocated_width()
            height = min(self.window.get_allocated_height(), self.card.get_allocated_height() + 6)
            rect = cairo.RectangleInt(0, 0, width, height) if self.opened else cairo.RectangleInt((width - 190) // 2, 0, 190, 6)
            native.input_shape_combine_region(cairo.Region(rect), 0, 0)

    def cancel_timer(self, name):
        value = getattr(self, name)
        if value:
            GLib.source_remove(value)
            setattr(self, name, 0)

    def enter(self, _window, event):
        if event.detail == Gdk.NotifyType.INFERIOR:
            return False
        self.cancel_timer("leave_timer")
        if not self.opened and not self.enter_timer:
            self.enter_timer = GLib.timeout_add(350, self.open_card)
        return False

    def leave(self, _window, event):
        if event.detail == Gdk.NotifyType.INFERIOR:
            return False
        self.cancel_timer("enter_timer")
        if self.opened and not self.leave_timer:
            self.leave_timer = GLib.timeout_add(250, self.close_card)
        return False

    def open_card(self):
        self.enter_timer = 0
        self.cancel_timer("leave_timer")
        self.opened = True
        selected = featured(self.meetings, time.time())
        self.selected_id = selected.id if selected else None
        self.render()
        self.revealer.set_reveal_child(True)
        self.input_region()
        return False

    def close_card(self):
        self.leave_timer = 0
        self.cancel_timer("enter_timer")
        self.opened = False
        self.revealer.set_reveal_child(False)
        self.input_region()
        return False

    def selected(self):
        return next((m for m in self.meetings if m.id == self.selected_id), None)

    def move(self, delta):
        if not self.meetings:
            return
        current = self.selected()
        index = self.meetings.index(current) if current else (-1 if delta > 0 else len(self.meetings))
        self.selected_id = self.meetings[min(max(index + delta, 0), len(self.meetings) - 1)].id
        self.render()

    def key(self, _window, event):
        if event.keyval == Gdk.KEY_Escape:
            self.close_card()
        elif event.keyval == Gdk.KEY_Up:
            self.move(1)
        elif event.keyval == Gdk.KEY_Down:
            self.move(-1)
        else:
            return False
        return True

    def scroll(self, _window, event):
        now = time.monotonic()
        if now - getattr(self, "last_scroll", 0) < 0.18:
            return True
        delta = 0
        if event.direction == Gdk.ScrollDirection.UP:
            delta = 1
        elif event.direction == Gdk.ScrollDirection.DOWN:
            delta = -1
        elif event.direction == Gdk.ScrollDirection.SMOOTH:
            _, _, dy = event.get_scroll_deltas()
            self.scroll_amount = getattr(self, "scroll_amount", 0) + dy
            if abs(self.scroll_amount) >= 1:
                delta = -1 if self.scroll_amount > 0 else 1
                self.scroll_amount = 0
        if delta:
            self.last_scroll = now
            self.move(delta)
        return True

    def render(self):
        meeting = self.selected()
        if not meeting:
            meeting = featured(self.meetings, time.time())
            self.selected_id = meeting.id if meeting else None
        now = time.time()
        if meeting:
            self.state_label.set_text("DEMO · " + ("IN PROGRESS" if meeting.current(now) else "UP NEXT") if self.demo
                                      else "IN PROGRESS" if meeting.current(now) else "EARLIER" if meeting.end <= now else "UP NEXT")
            self.title.set_text(meeting.title)
            self.calendar_label.set_text(meeting.calendar)
            start, end = datetime.fromtimestamp(meeting.start), datetime.fromtimestamp(meeting.end)
            when = start.strftime("%a, %d %b · %H:%M") + " – " + end.strftime("%H:%M")
            remaining = max(1, int((meeting.start - now + 59) // 60))
            self.time_label.set_text(when + (f"\nStarts in {remaining} min" if 0 < meeting.start - now < 3600 else ""))
            self.progress.set_fraction(meeting.progress(now))
            self.progress.set_visible(meeting.current(now))
            index = self.meetings.index(meeting)
            self.previous.set_sensitive(index > 0)
            self.next.set_sensitive(index + 1 < len(self.meetings))
            self.counter.set_text(f"{index + 1} / {len(self.meetings)}")
            self.join.set_visible(bool(meeting.join_url))
            self.title_button.set_sensitive(True)
            self.title_button.set_tooltip_text("Open in your calendar" if meeting.uid else "Demo meeting")
        else:
            self.state_label.set_text("NOTCHPOP")
            self.title.set_text("Your day, at a glance")
            self.title_button.set_sensitive(False)
            self.calendar_label.set_text("Checking calendars…" if self.loading else
                                         "Calendar unavailable — open settings" if self.errors else
                                         "No upcoming meetings")
            self.time_label.set_text("Hover here whenever you need a quick look.")
            self.progress.hide()
            self.join.hide()
            self.previous.set_sensitive(bool(self.meetings))
            self.next.set_sensitive(False)
            self.counter.set_text("")

    def tick(self):
        if self.opened:
            self.render()
        return True

    def set_demo(self, current=False):
        self.demo = True
        self.meetings = sorted(demo_meetings(time.time(), current), key=lambda m: (m.start, m.id))
        self.selected_id = None
        self.render()
        self.update_settings()

    def use_calendars(self):
        self.demo = False
        self.meetings = []
        self.selected_id = None
        self.refresh()
        self.update_settings()

    def refresh(self):
        if self.demo:
            return True
        if self.loading:
            self.reload_pending = True
            return True
        self.loading = True
        self.cancellable = Gio.Cancellable()
        # Some providers can stall while offline. Cancellation bounds the wait
        # without blocking GTK or starting overlapping reader threads.
        cancellation = self.cancellable
        deadline = threading.Timer(20, cancellation.cancel)
        deadline.daemon = True
        deadline.start()
        excluded = self.excluded.copy()

        def work():
            try:
                result = read_calendars(excluded, time.time(), cancellation)
                if cancellation.is_cancelled():
                    result = (result[0], result[1], result[2] + ["Calendar refresh timed out. Check your calendar accounts and try again."])
            except Exception as exc:
                result = ([], [], ["Calendar refresh timed out. Check your calendar accounts and try again."
                                  if cancellation.is_cancelled() else f"Calendar service unavailable: {exc}"])
            finally:
                deadline.cancel()
            GLib.idle_add(self.loaded, result)

        threading.Thread(target=work, name="calendar-reader", daemon=True).start()
        self.render()
        return True

    def loaded(self, result):
        self.loading = False
        if not self.demo:
            self.meetings, self.choices, self.errors = result
            self.render()
        self.update_settings()
        if self.reload_pending:
            self.reload_pending = False
            self.refresh()
        return False

    def launch(self, uri):
        try:
            Gio.AppInfo.launch_default_for_uri(uri, None)
        except GLib.Error as exc:
            self.errors = [f"Could not open the link: {exc.message}"]
            self.show_settings()

    def open_event(self):
        meeting = self.selected()
        if meeting and meeting.uid:
            self.launch(f"calendar:///?source-uid={quote(meeting.source_id, safe='')}&comp-uid={quote(meeting.uid, safe='')}")

    def join_meeting(self):
        meeting = self.selected()
        if meeting and meeting.join_url:
            self.launch(meeting.join_url)

    def show_settings(self):
        self.close_card()
        if self.settings:
            self.settings.present()
            return
        self.settings = Gtk.ApplicationWindow(application=self, title="Notchpop settings")
        self.settings.set_default_size(460, 460)
        self.settings.connect("destroy", lambda *_: setattr(self, "settings", None))
        box = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=14, margin=24)
        self.settings.add(box)
        box.pack_start(label("Notchpop", "heading"), False, False, 0)
        box.pack_start(label("Hover at the top center of your screen to see meetings.\n"
                             "Scroll up for later events, down for earlier ones. Click the card to use arrow keys."), False, False, 0)
        box.pack_start(label("Calendars are read from Evolution Data Server. Add accounts in "
                             "GNOME Calendar or Evolution; Notchpop never edits your events."), False, False, 0)
        self.status = label()
        self.status.set_selectable(True)
        box.pack_start(self.status, False, False, 0)
        scroller = Gtk.ScrolledWindow()
        scroller.set_policy(Gtk.PolicyType.NEVER, Gtk.PolicyType.AUTOMATIC)
        self.calendar_box = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=6)
        scroller.add(self.calendar_box)
        box.pack_start(scroller, True, True, 0)
        row = Gtk.Box(spacing=8)
        row.pack_start(button("Load demo meeting", lambda: (self.set_demo(), self.open_card())), True, True, 0)
        row.pack_start(button("Use my calendars", self.use_calendars), True, True, 0)
        box.pack_start(row, False, False, 0)
        box.pack_start(button("Refresh calendars", self.refresh), False, False, 0)
        box.pack_start(button("Quit Notchpop", self.quit), False, False, 0)
        self.settings.show_all()
        self.update_settings()
        self.settings.present()

    def update_settings(self):
        if not self.settings:
            return
        self.status.set_text("Demo meetings are active." if self.demo else
                             "\n".join(self.errors[:3]) if self.errors else
                             "Reading calendars…" if self.loading else
                             f"{len(self.choices)} calendars · {len(self.meetings)} meetings in the last/next 7 days")
        for child in self.calendar_box.get_children():
            self.calendar_box.remove(child)
        for uid, title in self.choices:
            check = Gtk.CheckButton(label=title)
            check.set_active(uid not in self.excluded)
            check.connect("toggled", self.calendar_toggled, uid)
            self.calendar_box.pack_start(check, False, False, 0)
        self.calendar_box.show_all()

    def calendar_toggled(self, check, uid):
        if check.get_active():
            self.excluded.discard(uid)
        else:
            self.excluded.add(uid)
        try:
            self.config_path.parent.mkdir(parents=True, exist_ok=True)
            temp = self.config_path.with_suffix(".tmp")
            temp.write_text(json.dumps({"excluded_calendars": sorted(self.excluded)}, indent=2) + "\n")
            temp.replace(self.config_path)
        except OSError as exc:
            self.errors = [f"Could not save calendar selections: {exc}"]
            self.update_settings()
        self.refresh()

    def capture(self, path, smoke):
        try:
            if not self.window.get_realized():
                raise RuntimeError("Window was not realized")
            if path:
                width, height = self.window.get_size()
                surface = cairo.ImageSurface(cairo.FORMAT_ARGB32, width, height)
                self.window.draw(cairo.Context(surface))
                surface.write_to_png(path)
            print(f"Notchpop: window ready; layer-shell={self.layer}; demo={self.demo}", flush=True)
        except Exception as exc:
            print(f"Notchpop smoke test failed: {exc}", flush=True)
            self.smoke_status = 1
        if smoke:
            self.quit()
        return False


def parser():
    result = argparse.ArgumentParser(description="A quiet, native Linux meeting companion.")
    result.add_argument("--preview-meeting", action="store_true", help="show a current demo meeting")
    result.add_argument("--demo", action="store_true", help="show an upcoming demo meeting")
    result.add_argument("--settings", action="store_true", help="open calendar settings")
    result.add_argument("--toggle", action="store_true", help="toggle the popup (also useful for compositor key bindings)")
    result.add_argument("--quit", action="store_true", help="quit the running instance")
    result.add_argument("--monitor", type=int, help="monitor index, starting at zero")
    result.add_argument("--smoke-test", action="store_true", help="test an isolated window and exit")
    result.add_argument("--screenshot", metavar="PATH", help="save an image of this app's window")
    return result


def run():
    import sys
    args = parser().parse_args()
    app = Notchpop(isolated=args.smoke_test)
    result = app.run(sys.argv)
    return app.smoke_status or result
