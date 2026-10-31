"""Verify every platform file against its recorded import or adaptation hash."""
import hashlib
import json
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]


def main():
    manifest = json.loads((ROOT / "research/upstream/platform-import.json").read_text())
    inventory = json.loads((ROOT / manifest["tree_inventory"]).read_text())
    upstream = {row["path"]: row["sha"] for row in inventory["tree"] if row["type"] == "blob"}
    failures = []
    expected_paths = set()
    for row in manifest["files"] + manifest["added"]:
        path = ROOT / row["path"]
        expected_paths.add(row["path"])
        if not path.is_file():
            failures.append(f"Missing {row['path']}")
            continue
        data = path.read_bytes()
        expected = row.get("adapted_sha256", row["sha256"])
        if hashlib.sha256(data).hexdigest() != expected:
            failures.append(f"Changed {row['path']}")
        if "upstream" in row:
            if upstream.get(row["upstream"]) != row["git_blob_sha1"]:
                failures.append(f"Upstream inventory mismatch {row['path']}")
            if row["status"] == "unchanged":
                blob = hashlib.sha1(f"blob {len(data)}\0".encode() + data).hexdigest()
                if blob != row["git_blob_sha1"]:
                    failures.append(f"Original bytes changed {row['path']}")
    actual = {p.relative_to(ROOT).as_posix() for p in (ROOT / "src/platform").rglob("*") if p.is_file()}
    for path in sorted(actual - expected_paths):
        failures.append(f"Unrecorded {path}")
    if failures:
        raise SystemExit("\n".join(failures))
    print(f"Verified {len(actual)} platform files, including unchanged upstream blob hashes.")


if __name__ == "__main__":
    main()
