"""Exercise release metadata through the same CLI used by GitHub Actions."""

from pathlib import Path
import subprocess
import sys
import tempfile
import unittest


SCRIPT = Path(__file__).with_name("android_release.py")


class ReleaseMetadataTest(unittest.TestCase):
    def run_metadata(self, tag="v1.0.1", run="7", offset="1", version="1.0.0+1"):
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            (root / "pubspec.yaml").write_text(f"name: example\nversion: {version}\n")
            output = root / "output"
            result = subprocess.run(
                [sys.executable, str(SCRIPT), "metadata"],
                cwd=root,
                env={
                    "RELEASE_TAG": tag,
                    "GITHUB_RUN_NUMBER": run,
                    "BUILD_OFFSET": offset,
                    "GITHUB_OUTPUT": str(output),
                },
                capture_output=True,
                text=True,
            )
            return result, output.read_text() if output.exists() else ""

    def test_tag_overrides_local_version(self):
        result, output = self.run_metadata()
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(output, "version=1.0.1\nbuild_number=8\n")

    def test_first_run_and_rerun_have_same_build(self):
        for _ in range(2):
            result, output = self.run_metadata(run="1")
            self.assertEqual(result.returncode, 0, result.stderr)
            self.assertEqual(output, "version=1.0.1\nbuild_number=2\n")

    def test_invalid_tag_is_rejected(self):
        result, output = self.run_metadata(tag="v1.0.1-beta")
        self.assertNotEqual(result.returncode, 0)
        self.assertIn("Release tag must be", result.stderr)
        self.assertEqual(output, "")

    def test_invalid_build_numbers_are_rejected(self):
        for run, offset in [("0", "1"), ("1", "-1"), ("1", "0"),
                            ("2100000000", "1"), ("abc", "1")]:
            with self.subTest(run=run, offset=offset):
                result, output = self.run_metadata(run=run, offset=offset)
                self.assertNotEqual(result.returncode, 0)
                self.assertEqual(output, "")

    def test_malformed_local_version_is_rejected(self):
        result, output = self.run_metadata(version="1.0.0")
        self.assertNotEqual(result.returncode, 0)
        self.assertIn("pubspec.yaml version must be", result.stderr)
        self.assertEqual(output, "")


if __name__ == "__main__":
    unittest.main()
