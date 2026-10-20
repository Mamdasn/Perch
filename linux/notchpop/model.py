"""Meeting selection shared by the native Linux interface and its tests."""

from dataclasses import dataclass
import re
from urllib.parse import urlsplit


@dataclass(frozen=True)
class Meeting:
    id: str
    title: str
    start: float
    end: float
    calendar: str
    join_url: str | None = None
    source_id: str = ""
    uid: str = ""

    def current(self, now):
        return self.start <= now < self.end

    def progress(self, now):
        return min(1, max(0, (now - self.start) / max(1, self.end - self.start)))


def featured(meetings, now):
    valid = [m for m in meetings if m.end > now and m.end > m.start]
    current = sorted((m for m in valid if m.current(now)), key=lambda m: (-m.start, m.id))
    upcoming = sorted((m for m in valid if m.start > now), key=lambda m: (m.start, m.id))
    return next(iter(current or upcoming), None)


def conference_url(text):
    hosts = ("meet.google.com", "zoom.us", "teams.microsoft.com", "teams.live.com", "webex.com")
    for match in re.findall(r"https://[^\s<>\"']+", text, re.IGNORECASE):
        url = match.rstrip(".,;:!?)]}")
        try:
            parts = urlsplit(url)
            host = (parts.hostname or "").lower()
            if parts.username or parts.password:
                continue
            if any(host == allowed or host.endswith("." + allowed) for allowed in hosts):
                return url
        except ValueError:
            continue
    return None


def demo_meetings(now, current=False):
    return [
        Meeting("demo-before", "Morning catch-up", now - 7200, now - 5400, "Work · Demo calendar"),
        Meeting("demo", "Design review", now - 600 if current else now + 180,
                now + 1200 if current else now + 1980, "Work · Demo calendar"),
        Meeting("demo-next", "Product direction", now + 3600, now + 5400, "Work · Demo calendar"),
        Meeting("demo-later", "Team sync", now + 7200, now + 9000, "Work · Demo calendar"),
    ]
