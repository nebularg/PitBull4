"""Verify vendor bytes and reject library files in application-only overlays."""

import argparse
import hashlib
import json
from pathlib import Path, PurePosixPath
from zipfile import ZipFile


def is_library(path):
    """Return whether a file is beneath a lib/libs directory."""
    normalized = str(path).replace("\\", "/")
    return any(part.lower() in ("lib", "libs") for part in PurePosixPath(normalized).parts[:-1])


def sha256(data):
    return hashlib.sha256(data).hexdigest()


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--root", type=Path, default=Path(__file__).resolve().parents[2])
    parser.add_argument("--patch", type=Path)
    parser.add_argument("--baseline-archive", type=Path)
    args = parser.parse_args()
    manifest = json.loads(Path(__file__).with_name("library_baseline_hashes.json").read_text())
    expected = manifest["files"]
    actual = {}
    for addon in ("PitBull4", "PitBull4_DogTagTexts"):
        for path in (args.root / addon).rglob("*"):
            if path.is_file():
                name = path.relative_to(args.root).as_posix()
                if is_library(name):
                    actual[name] = sha256(path.read_bytes())
    failures = []
    for name in sorted(set(expected) | set(actual)):
        if expected.get(name) != actual.get(name):
            failures.append(name)
    if args.baseline_archive:
        if sha256(args.baseline_archive.read_bytes()) != manifest["archive_sha256"]:
            failures.append("baseline archive digest")
        with ZipFile(args.baseline_archive) as archive:
            original = {
                name: sha256(archive.read(name))
                for name in archive.namelist()
                if not name.endswith("/") and is_library(name)
            }
        if original != expected:
            failures.append("baseline archive library inventory/content")
    if args.patch:
        with ZipFile(args.patch) as patch:
            failures.extend(name for name in patch.namelist()
                            if not name.endswith("/") and is_library(name))
    if failures:
        raise SystemExit("Library boundary failed:\n" + "\n".join(failures))
    print(f"PASS: {len(expected)} library files match the supplied baseline byte for byte.")
    if args.patch:
        print("PASS: changed-only archive contains no library files.")


if __name__ == "__main__":
    main()
