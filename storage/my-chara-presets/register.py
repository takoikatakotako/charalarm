#!/usr/bin/env python3
"""Register the ten appearance presets through the existing development admin API.

Default: validate local assets only. --apply requires an authenticated AWS SSO session.
Existing enabled characters are skipped; interrupted disabled registrations can resume.
"""

import argparse
import base64
import hashlib
import json
from pathlib import Path
import struct
import subprocess
import urllib.error
import urllib.request

ROOT = Path(__file__).resolve().parent
ORIGIN = "https://admin.charalarm-development.swiswiswift.com"
PROFILE = "charalarm-development-sso"
PUBLIC_API = "https://api.charalarm-development.swiswiswift.com"


def load_presets():
    characters = json.loads((ROOT / "presets.json").read_text())["characters"]
    if len(characters) != 10 or sum(c["gender"] == "male" for c in characters) != 3:
        raise ValueError("Expected 10 characters, including 3 male characters")
    if len({c["charaID"] for c in characters}) != 10:
        raise ValueError("Character IDs must be unique")
    for character in characters:
        image = (ROOT / character["image"]).read_bytes()
        if image[:8] != b"\x89PNG\r\n\x1a\n" or len(image) < 33:
            raise ValueError(f"Invalid PNG: {character['id']}")
        width, height, depth, color = struct.unpack(">IIBB", image[16:26])
        if width != 1024 or height != 1536 or depth != 8 or color != 6:
            raise ValueError(f"Expected 1024x1536 RGBA PNG: {character['id']}")
        if hashlib.sha256(image).hexdigest() != character["sha256"]:
            raise ValueError(f"Image checksum differs: {character['id']}")
    return characters


def settings(character, enabled=False):
    return {
        "enable": enabled,
        "name": character["name"],
        "description": character["description"],
        "profiles": [],
        "displayOrder": character["displayOrder"],
        "preset": True,
        "appearanceType": "illustration",
        "vrmFileName": "",
        "conversationType": "gemini",
        "conversationPrompt": "ユーザーの朝を応援する、親しみやすく思いやりのあるキャラクターです。",
        "voicevoxStyleID": 0,
        "conversationLanguages": ["ja", "en", "zh-Hans", "zh-Hant", "ko", "es", "fr", "de"],
        "geminiVoice": "Zephyr",
        "geminiVoiceStyle": "",
        "callOpeningPrompt": "",
        "callEndingPrompt": "",
        "callNoInputEndingPrompt": "",
    }


class AdminAPI:
    def __init__(self, authorization):
        self.authorization = authorization

    def request(self, method, path, body=None):
        data = None if body is None else json.dumps(body, ensure_ascii=False).encode()
        request = urllib.request.Request(
            ORIGIN + "/api" + path, data=data, method=method,
            headers={"Authorization": self.authorization, "Content-Type": "application/json"},
        )
        try:
            with urllib.request.urlopen(request, timeout=60) as response:
                if response.status == 204:
                    return None
                if response.headers.get_content_type() != "application/json":
                    raise RuntimeError(f"Admin API {method} {path}: expected JSON response")
                return json.load(response)
        except urllib.error.HTTPError as error:
            if method == "GET" and error.code == 404:
                return None
            # Do not print response bodies, signed URLs, or credentials.
            raise RuntimeError(f"Admin API {method} {path}: HTTP {error.code}") from None

    def upload(self, path, file_name, image):
        signed = self.request("POST", path + "/files/upload-url", {"fileName": file_name})
        request = urllib.request.Request(
            signed["uploadURL"], data=image, method="PUT",
            headers={"Content-Type": signed["contentType"]},
        )
        try:
            with urllib.request.urlopen(request, timeout=120) as response:
                if response.status != 200:
                    raise RuntimeError("Image upload failed")
        except urllib.error.URLError:
            raise RuntimeError("Image upload failed; registration is disabled and can be resumed") from None


def register(api, character, image):
    path = "/chara/" + character["charaID"]
    # CloudFront turns an origin 404 into the frontend's HTML with status 200.
    # Determine absence from the list instead of requesting a missing item.
    characters = api.request("GET", "/chara")["charas"]
    existing = next((item for item in characters if item["charaID"] == character["charaID"]), None)
    if existing is not None:
        if not existing.get("preset"):
            raise ValueError(f"Refusing to replace a regular character: {character['charaID']}")
        if existing.get("enable"):
            return "already enabled; skipped"
    else:
        api.request("POST", "/chara", {"charaID": character["charaID"], **settings(character)})

    # Enable only after both uploads and the assets association have succeeded.
    api.upload(path, "normal.png", image)
    api.upload(path, "thumbnail.png", image)
    api.request("PUT", path + "/assets", {
        "expressions": {"normal": {"imageFileNames": ["normal.png"], "voiceFileNames": []}},
        "calls": [],
    })
    api.request("PUT", path, settings(character, enabled=True))
    verified = api.request("GET", path)
    if not verified or not verified.get("enable") or not verified.get("preset"):
        raise RuntimeError(f"Registration verification failed: {character['charaID']}")
    return "registered"


def authorization():
    result = subprocess.run([
        "aws", "ssm", "get-parameters", "--profile", PROFILE, "--region", "ap-northeast-1",
        "--with-decryption", "--names", "/charalarm/dev/admin/basic-auth-user",
        "/charalarm/dev/admin/basic-auth-password", "--output", "json",
    ], capture_output=True, text=True)
    if result.returncode:
        raise RuntimeError(f"AWS authentication failed. Run: aws sso login --profile {PROFILE}")
    values = {p["Name"].rsplit("/", 1)[-1]: p["Value"] for p in json.loads(result.stdout)["Parameters"]}
    credentials = values["basic-auth-user"] + ":" + values["basic-auth-password"]
    return "Basic " + base64.b64encode(credentials.encode()).decode()


def verify(api, characters):
    registered = {c["charaID"]: c for c in api.request("GET", "/chara")["charas"]}
    with urllib.request.urlopen(PUBLIC_API + "/chara/presets", timeout=30) as response:
        presets = {c["charaID"]: c for c in json.load(response)}
    with urllib.request.urlopen(PUBLIC_API + "/chara/list", timeout=30) as response:
        regular_ids = {c["charaID"] for c in json.load(response)}
    for character in characters:
        chara_id = character["charaID"]
        entry = registered.get(chara_id, {})
        public = presets.get(chara_id, {})
        if not entry.get("enable") or not entry.get("preset") or public.get("name") != character["name"]:
            raise RuntimeError(f"Preset registration differs: {chara_id}")
        if chara_id in regular_ids:
            raise RuntimeError(f"Preset leaked into the regular character list: {chara_id}")
        normal_url = public["expressions"]["normal"]["imageFileURLs"][0]
        base_url = normal_url.rsplit("/", 1)[0]
        for file_name in ["normal.png", "thumbnail.png"]:
            with urllib.request.urlopen(base_url + "/" + file_name, timeout=60) as response:
                digest = hashlib.sha256(response.read()).hexdigest()
            if digest != character["sha256"]:
                raise RuntimeError(f"Published image checksum differs: {chara_id}/{file_name}")
        print(f"Verified: {chara_id} (enabled, preset-only, both published images match)", flush=True)


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    mode = parser.add_mutually_exclusive_group()
    mode.add_argument("--apply", action="store_true", help="Register in development (no production writes)")
    mode.add_argument("--verify", action="store_true", help="Read-only verification of development records and public images")
    args = parser.parse_args()
    characters = load_presets()
    if not args.apply and not args.verify:
        for character in characters:
            print(f"Validated: {character['charaID']} ({character['name']})")
        print("No remote changes. Use --apply to register in development.")
        return
    api = AdminAPI(authorization())
    if args.verify:
        verify(api, characters)
        return
    for character in characters:
        result = register(api, character, (ROOT / character["image"]).read_bytes())
        print(f"{character['charaID']}: {result}")


if __name__ == "__main__":
    main()
