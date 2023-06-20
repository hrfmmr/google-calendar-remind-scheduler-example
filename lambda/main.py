import datetime
import json
import logging
import os
import re
from collections import defaultdict
from dataclasses import dataclass
from enum import Enum
from typing import Optional

import boto3
import slack_sdk
import slack_sdk.errors
from google.oauth2 import service_account
from googleapiclient.discovery import build as build_google_service


logging.basicConfig()
logger = logging.getLogger()


SCOPES = ["https://www.googleapis.com/auth/calendar.readonly"]
GOOGLE_CALENDAR_ID = os.environ["GOOGLE_CALENDAR_ID"]
PARAM_KEY_SERVICE_ACCOUNT_JSON = os.environ["PARAM_KEY_SERVICE_ACCOUNT_JSON"]
PARAM_KEY_SLACK_API_TOKEN = os.environ["PARAM_KEY_SLACK_API_TOKEN"]
SLACK_CHANNEL_ID = os.environ["SLACK_CHANNEL_ID"]

REX_EVENT_DESCRIPTION_LINK = re.compile(r'href="([^"]*)"')


class ISO8601Formatter(logging.Formatter):
    def formatTime(self, record, datefmt=None):
        tz_jst = datetime.timezone(datetime.timedelta(hours=+9), 'JST')
        dt = datetime.datetime.fromtimestamp(record.created, tz_jst)
        return dt.isoformat()


@dataclass
class CalendarEvent:
    date: str
    summary: str
    description: str

    @property
    def link_url(self) -> Optional[str]:
        match = REX_EVENT_DESCRIPTION_LINK.search(self.description)
        if match:
            return match.group(1)
        return None


class RemainingDays(Enum):
    ONE_DAY = 1
    THREE_DAYS = 3
    ONE_WEEK = 7

    @property
    def date(self):
        target_date = datetime.datetime.now() + datetime.timedelta(days=self.value)
        return target_date.strftime("%Y-%m-%d")


class GoogleCalendarClient:
    def __init__(self):
        service_account_json = get_ssm_param(PARAM_KEY_SERVICE_ACCOUNT_JSON)
        service_account_info = json.loads(service_account_json)
        creds = service_account.Credentials.from_service_account_info(
            service_account_info, scopes=SCOPES
        )
        self.service = build_google_service("calendar", "v3", credentials=creds)

    def get_events(self):
        now = datetime.datetime.utcnow().isoformat() + "Z"  # 'Z' indicates UTC time
        events_result = (
            self.service.events()
            .list(
                calendarId=GOOGLE_CALENDAR_ID,
                timeMin=now,
                maxResults=10,
                singleEvents=True,
                orderBy="startTime",
            )
            .execute()
        )
        events = events_result.get("items", [])

        if not events:
            logger.info("No upcoming events found.")
        for event in events:
            date = event["start"].get("dateTime", event["start"].get("date"))
            summary = event.get("summary", "")
            description = event.get("description", "")
            yield CalendarEvent(date, summary, description)


class SlackClient:
    def __init__(self):
        api_token = get_ssm_param(PARAM_KEY_SLACK_API_TOKEN)
        self.client = slack_sdk.WebClient(token=api_token)

    def post_schedules(self, channel_id: str, events: list[CalendarEvent]):
        try:
            message = self._build_schedule_reminder_message(events)
            logger.info(f"✉️  Posting message:{message}")
            self.client.chat_postMessage(channel=channel_id, text=message)
        except slack_sdk.errors.SlackApiError as e:
            err = e.response.get("error", "")
            logger.error(f"❗error:{err}")

    def _build_schedule_reminder_message(self, events: list[CalendarEvent]) -> str:
        d = {d_r.date: d_r for d_r in RemainingDays}
        remaining_days_event_map = defaultdict(list)
        for event in events:
            if event.date in d:
                d_r = d[event.date]
                remaining_days_event_map[d_r.value].append(event)
        lines: list[str] = []
        lines.append(self._build_schedule_reminder_title_text())
        for k in sorted(remaining_days_event_map.keys()):
            events = remaining_days_event_map[k]
            lines.append(self._build_schedule_reminder_section_text(k))
            for event in events:
                lines.append(
                    self._build_list_item_text(
                        self._build_schedule_reminder_event_text(event)
                    )
                )
            lines.append("\n")
        return "\n".join(lines)

    def _build_schedule_reminder_title_text(self) -> str:
        return "Hey <!channel>, here is the upcoming schedules🗓️"

    def _build_schedule_reminder_section_text(self, days_remaining: int) -> str:
        match days_remaining:
            case 1:
                title = "tomorrow"
            case 7:
                title = "in a week"
            case _:
                title = f"in {days_remaining} days"
        padding = "=" * 20
        return self._build_bold_text(padding + f"{title}" + padding)

    def _build_schedule_reminder_event_text(self, event: CalendarEvent) -> str:
        date_text = f"{event.date}({get_weekday(event.date)}):"
        if event.link_url:
            return (
                f"{date_text}" f"{self._build_link_text(event.summary, event.link_url)}"
            )
        else:
            return f"{date_text}" f"{event.summary} {event.description}"

    def _build_link_text(self, text: str, url: str) -> str:
        return f"<{url}|{text}>"

    def _build_bold_text(self, text) -> str:
        return f"*{text}*"

    def _build_list_item_text(self, text) -> str:
        return f"• {text}"


def get_ssm_param(param_key):
    ssm = boto3.client("ssm")
    response = ssm.get_parameters(
        Names=[
            param_key,
        ],
        WithDecryption=True,
    )
    return response["Parameters"][0]["Value"]


def get_weekday(date_string: str):
    date = datetime.datetime.strptime(date_string, "%Y-%m-%d")
    weekdays = ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"]
    return weekdays[date.weekday()]


def init_logging():
    logformatter = ISO8601Formatter(
        (
            "[%(levelname)s] @%(asctime)s "
            "- %(name)s.%(filename)s#%(funcName)s():L%(lineno)s "
            "- %(message)s"
        ),
        "%Y-%m-%dT%H:%M:%S%z",
    )

    for handler in logger.handlers:
        handler.setFormatter(logformatter)
        handler.setLevel(os.environ.get("LOG_LEVEL", "INFO"))
        logger.setLevel(os.environ.get("LOG_LEVEL", "INFO"))
        logger.addHandler(handler)


def main():
    init_logging()
    calendar_client = GoogleCalendarClient()

    events = list(calendar_client.get_events())
    for event in events:
        logger.info(event)
    slack_client = SlackClient()
    slack_client.post_schedules(channel_id=SLACK_CHANNEL_ID, events=events)


def lambda_handler(event, context):
    main()
