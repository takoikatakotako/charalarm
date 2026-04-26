import json
import os
import urllib.error
import urllib.request

import boto3

_ssm = boto3.client("ssm")
_param_name = os.environ["WEBHOOK_SSM_PARAM"]
_cached_webhook = None


def _get_webhook_url() -> str:
    global _cached_webhook
    if _cached_webhook is None:
        resp = _ssm.get_parameter(Name=_param_name, WithDecryption=True)
        _cached_webhook = resp["Parameter"]["Value"]
    return _cached_webhook


def _format_alarm(alarm: dict, subject: str) -> str:
    name = alarm.get("AlarmName") or subject or "Unknown alarm"
    state = alarm.get("NewStateValue", "UNKNOWN")
    reason = alarm.get("NewStateReason", "")
    time = alarm.get("StateChangeTime", "")

    emoji = {
        "ALARM": ":rotating_light:",
        "OK": ":white_check_mark:",
        "INSUFFICIENT_DATA": ":grey_question:",
    }.get(state, ":grey_question:")

    parts = [f"{emoji} *{name}* — `{state}`"]
    if reason:
        parts.append(reason)
    if time:
        parts.append(f"_{time}_")
    return "\n".join(parts)


def lambda_handler(event, context):
    webhook_url = _get_webhook_url()

    for record in event.get("Records", []):
        sns = record.get("Sns", {})
        subject = sns.get("Subject", "")
        raw = sns.get("Message", "{}")
        try:
            alarm = json.loads(raw)
        except json.JSONDecodeError:
            alarm = {}

        text = _format_alarm(alarm, subject)
        body = json.dumps({"text": text}).encode("utf-8")
        req = urllib.request.Request(
            webhook_url,
            data=body,
            headers={"Content-Type": "application/json"},
        )
        try:
            with urllib.request.urlopen(req, timeout=5) as resp:
                resp.read()
        except urllib.error.URLError as err:
            print(f"Slack post failed: {err}")
            raise

    return {"status": "ok"}
