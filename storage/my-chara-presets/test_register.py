import unittest

from register import load_presets, register


class FakeAPI:
    def __init__(self, existing=None, fail_upload=False):
        self.existing = existing
        self.fail_upload = fail_upload
        self.operations = []

    def request(self, method, path, body=None):
        self.operations.append((method, path, body))
        if method == "GET" and path == "/chara":
            entries = [] if self.existing is None else [{"charaID": load_presets()[0]["charaID"], **self.existing}]
            return {"charas": entries}
        if method == "GET":
            return self.existing
        if method == "PUT" and not path.endswith("/assets"):
            self.existing = body

    def upload(self, path, file_name, image):
        self.operations.append(("UPLOAD", path, file_name))
        if self.fail_upload:
            raise RuntimeError("upload interrupted")


class RegistrationTests(unittest.TestCase):
    def setUp(self):
        self.character = load_presets()[0]

    def test_publishes_only_after_uploads_and_association(self):
        api = FakeAPI()
        self.assertEqual(register(api, self.character, b"image"), "registered")
        self.assertFalse(api.operations[1][2]["enable"])
        self.assertEqual([op[0] for op in api.operations], ["GET", "POST", "UPLOAD", "UPLOAD", "PUT", "PUT", "GET"])
        self.assertTrue(api.operations[-2][2]["enable"])

    def test_upload_failure_does_not_enable(self):
        api = FakeAPI(fail_upload=True)
        with self.assertRaises(RuntimeError):
            register(api, self.character, b"image")
        self.assertFalse(any(op[0] == "PUT" for op in api.operations))

    def test_existing_enabled_preset_is_not_overwritten(self):
        api = FakeAPI(existing={"preset": True, "enable": True})
        register(api, self.character, b"image")
        self.assertEqual(len(api.operations), 1)

    def test_regular_character_is_not_replaced(self):
        api = FakeAPI(existing={"preset": False})
        with self.assertRaises(ValueError):
            register(api, self.character, b"image")
        self.assertEqual(len(api.operations), 1)

    def test_interrupted_registration_can_resume(self):
        api = FakeAPI(existing={"preset": True, "enable": False})
        register(api, self.character, b"image")
        self.assertNotIn("POST", [op[0] for op in api.operations])
        self.assertTrue(api.existing["enable"])


if __name__ == "__main__":
    unittest.main()
