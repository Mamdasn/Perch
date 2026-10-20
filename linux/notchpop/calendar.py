"""Read-only Evolution Data Server calendar access.

EDS expands recurrences, exceptions and time zones; no calendar writes are made.
All blocking calls run on a worker thread in the application.
"""

import gi

gi.require_version("ECal", "2.0")
gi.require_version("EDataServer", "1.2")
from gi.repository import ECal, EDataServer, GLib, ICalGLib

from .model import Meeting, conference_url


def to_timestamp(value):
    return value.as_timet() if hasattr(value, "as_timet") else float(value)


def from_component(component, start, end, source_id, calendar, email=""):
    dtstart = component.get_dtstart()
    if not dtstart or dtstart.is_date():
        return None
    if component.get_status() == ICalGLib.PropertyStatus.CANCELLED:
        return None
    if email:
        prop = component.get_first_property(ICalGLib.PropertyKind.ATTENDEE_PROPERTY)
        while prop:
            address = prop.get_attendee().removeprefix("mailto:").casefold()
            status = prop.get_first_parameter(ICalGLib.ParameterKind.PARTSTAT_PARAMETER)
            if address == email.casefold() and status and status.get_partstat() == ICalGLib.ParameterPartstat.DECLINED:
                return None
            prop = component.get_next_property(ICalGLib.PropertyKind.ATTENDEE_PROPERTY)
    start, end = to_timestamp(start), to_timestamp(end)
    if end <= start:
        return None
    event = ECal.Component.new_from_icalcomponent(component.clone())
    summary = event.get_summary()
    title = summary.get_value() if summary else ""
    links = [event.get_url(), event.get_location()]
    links.extend(item.get_value() for item in (event.get_descriptions() or []))
    uid = component.get_uid() or ""
    return Meeting(f"{source_id}:{uid}:{start}", title or "Untitled meeting",
                   start, end, calendar, conference_url("\n".join(x for x in links if x)),
                   source_id, uid)


def read_calendars(excluded, now, cancellable=None):
    registry = EDataServer.SourceRegistry.new_sync(cancellable)
    sources = registry.list_sources(EDataServer.SOURCE_EXTENSION_CALENDAR)
    meetings, choices, errors = {}, [], []
    for source in sources:
        if not registry.check_enabled(source):
            continue
        uid, title = source.get_uid(), source.get_display_name()
        choices.append((uid, title))
        if uid in excluded:
            continue
        try:
            client = ECal.Client.connect_sync(source, ECal.ClientSourceType.EVENTS, 5, cancellable)
            local_zone = ICalGLib.Timezone.get_builtin_timezone(GLib.TimeZone.new_local().get_identifier())
            if local_zone:
                client.set_default_timezone(local_zone)
            try:
                _, email = client.get_backend_property_sync(ECal.BACKEND_PROPERTY_CAL_EMAIL_ADDRESS, cancellable)
            except Exception:
                email = ""

            def collect(component, start, end, *args):
                try:
                    meeting = from_component(component, start, end, uid, title, email or "")
                    if meeting:
                        meetings[meeting.id] = meeting
                except Exception as exc:
                    errors.append(f"{title}: could not read an event ({exc})")
                return True

            client.generate_instances_sync(int(now - 7 * 86400), int(now + 7 * 86400),
                                           cancellable, collect, None)
        except Exception as exc:
            errors.append(f"{title}: {exc}")
    return sorted(meetings.values(), key=lambda m: (m.start, m.id)), sorted(choices, key=lambda c: c[1]), errors
