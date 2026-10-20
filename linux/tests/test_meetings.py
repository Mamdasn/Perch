import unittest

from notchpop.model import Meeting, conference_url, featured
from notchpop.calendar import from_component, ECal, ICalGLib


class SelectionTests(unittest.TestCase):
    def test_latest_started_meeting_wins_overlap(self):
        older = Meeting("a", "Earlier", 10, 100, "Work")
        newer = Meeting("b", "Latest", 20, 80, "Work")
        self.assertEqual(featured([older, newer], 30), newer)
        self.assertEqual(featured([older, newer], 80), older)
        self.assertIsNone(featured([older, newer], 100))

    def test_upcoming_and_invalid_duration(self):
        upcoming = Meeting("a", "Next", 50, 80, "Work")
        invalid = Meeting("b", "Invalid", 40, 30, "Work")
        self.assertEqual(featured([invalid, upcoming], 20), upcoming)
        self.assertEqual(upcoming.progress(100), 1)
        self.assertEqual(upcoming.progress(0), 0)

    def test_conference_links_require_exact_host_boundary(self):
        for value in ("http://zoom.us/a", "https://zoom.us.evil.example/a",
                      "https://zoom.us@evil.example/a", "https://evilzoom.us/a",
                      "https://user@zoom.us/a"):
            self.assertIsNone(conference_url(value))
        self.assertEqual(conference_url("Join (https://meet.google.com/abc-defg-hij)."),
                         "https://meet.google.com/abc-defg-hij")
        self.assertEqual(conference_url("https://company.zoom.us/j/123"),
                         "https://company.zoom.us/j/123")


class CalendarTests(unittest.TestCase):
    def component(self, extra="", start="DTSTART:20261020T090000Z"):
        return ICalGLib.Component.new_from_string(
            "BEGIN:VEVENT\r\nUID:test-event\r\n" + start +
            "\r\nDTEND:20261020T100000Z\r\nSUMMARY:Planning\r\n"
            "DESCRIPTION:Join https://meet.google.com/abc-defg-hij\r\n"
            + extra + "\r\nEND:VEVENT\r\n")

    def test_event_and_occurrence_identity(self):
        component = self.component()
        meeting = from_component(component, 100, 200, "work", "Work")
        next_occurrence = from_component(component, 300, 400, "work", "Work")
        self.assertEqual(meeting.title, "Planning")
        self.assertEqual(meeting.join_url, "https://meet.google.com/abc-defg-hij")
        self.assertNotEqual(meeting.id, next_occurrence.id)
        self.assertEqual(next_occurrence.start, 300)

    def test_cancelled_all_day_and_declined_are_excluded(self):
        self.assertIsNone(from_component(self.component("STATUS:CANCELLED"), 100, 200, "w", "W"))
        self.assertIsNone(from_component(self.component(start="DTSTART;VALUE=DATE:20261020"), 100, 200, "w", "W"))
        declined = self.component("ATTENDEE;PARTSTAT=DECLINED:mailto:me@example.com")
        self.assertIsNone(from_component(declined, 100, 200, "w", "W", "me@example.com"))
        self.assertIsNotNone(from_component(declined, 100, 200, "w", "W", "other@example.com"))

    def test_recurring_event_respects_excluded_occurrence(self):
        component = self.component("RRULE:FREQ=DAILY;COUNT=3\r\nEXDATE:20261021T090000Z")
        meetings = []

        def collect(event, start, end, *args):
            meetings.append(from_component(event, start, end, "work", "Work"))
            return True

        ECal.recur_generate_instances_sync(
            component, ICalGLib.Time.new_from_string("20261020T000000Z"),
            ICalGLib.Time.new_from_string("20261024T000000Z"), collect, None,
            lambda *_: ICalGLib.Timezone.get_utc_timezone(), None,
            ICalGLib.Timezone.get_utc_timezone(), None)
        self.assertEqual(len(meetings), 2)
        self.assertEqual(meetings[1].start - meetings[0].start, 2 * 86400)
        self.assertEqual(meetings[0].end - meetings[0].start, 3600)


if __name__ == "__main__":
    unittest.main()
