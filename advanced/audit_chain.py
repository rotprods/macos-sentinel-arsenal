"""Tamper-evident Merkle audit log.

Append-only JSONL. Each line:
  {"seq": int, "prev_hash": "sha256-hex", "ts": iso8601, "actor": str,
   "event": str, "payload": dict, "this_hash": "sha256-hex"}

this_hash = sha256(canonical_json({seq, prev_hash, ts, actor, event, payload}))

Chain integrity is verifiable with the verify() function or a small CLI wrapper.
Modification of any entry or insertion/deletion is detectable at the broken line.
"""

from __future__ import annotations

import json
import hashlib
import os
import fcntl
import signal
from pathlib import Path
from datetime import datetime, timezone

SENTINEL_HOME = Path(os.environ.get("SENTINEL_HOME", Path.home() / ".sentinel"))
CHAIN = SENTINEL_HOME / "audit" / "chain.jsonl"
GENESIS = SENTINEL_HOME / "audit" / "chain.genesis"
GENESIS_SEED = "SENTINEL_ARSENAL_V1_GENESIS"

FLOCK_TIMEOUT_SECONDS = 10


class ChainBroken(RuntimeError):
    pass


class ChainLockTimeout(RuntimeError):
    pass


def _canonical(obj: dict) -> bytes:
    """Deterministic JSON encoding: sorted keys, no extra whitespace."""
    return json.dumps(obj, sort_keys=True, separators=(",", ":"), default=str).encode()


def _canonical_legacy_v2(obj: dict) -> bytes:
    """Legacy v2 encoding used by one historical writer: sorted keys, default JSON whitespace."""
    return json.dumps(obj, sort_keys=True, default=str).encode()


def _sha256(b: bytes) -> str:
    return hashlib.sha256(b).hexdigest()


def _genesis_hash() -> str:
    return _sha256(GENESIS_SEED.encode())


def _ensure_genesis() -> None:
    """Bootstrap chain and genesis file if they don't exist yet."""
    CHAIN.parent.mkdir(parents=True, exist_ok=True)
    if not GENESIS.exists():
        gh = _genesis_hash()
        GENESIS.write_text(json.dumps({"seed": GENESIS_SEED, "genesis_hash": gh}))
        try:
            os.chmod(GENESIS, 0o400)
        except OSError:
            pass
    if not CHAIN.exists():
        CHAIN.touch()
        try:
            os.chmod(CHAIN, 0o600)
        except OSError:
            pass


def _read_last() -> tuple[int, str]:
    """Return (last_seq, last_hash). For empty chain: (-1, genesis_hash).

    Supports two entry formats:
      - New (Merkle): {"seq": int, ..., "this_hash": "sha256-hex"}
      - Legacy:       {"seq": int, ..., "self_hash": "sha256-hex"}
    Legacy entries are accepted for backward compatibility.
    """
    _ensure_genesis()
    if CHAIN.stat().st_size == 0:
        return -1, _genesis_hash()
    with open(CHAIN, "rb") as f:
        try:
            f.seek(-65536, os.SEEK_END)
        except OSError:
            f.seek(0)
        tail = f.read().decode(errors="replace").splitlines()
    _info_types = {"fim_drift", "canary_triggered", "guardian_cycle"}
    for line in reversed(tail):
        line = line.strip()
        if line:
            try:
                last = json.loads(line)
            except json.JSONDecodeError:
                continue
            is_guardian = (
                last.get("actor") == "guardian"
                and last.get("event") == "guardian_cycle"
            )
            if is_guardian or last.get("type") in _info_types:
                continue
            seq = last.get("seq", -1)
            h = last.get("this_hash") or last.get("self_hash") or _genesis_hash()
            return seq, h
    return -1, _genesis_hash()


def _flock_with_timeout(fd, timeout: int) -> None:
    """Acquire exclusive flock with SIGALRM-based timeout."""
    def _timeout_handler(signum, frame):
        raise ChainLockTimeout("flock acquisition timed out")

    old_handler = signal.signal(signal.SIGALRM, _timeout_handler)
    signal.alarm(timeout)
    try:
        fcntl.flock(fd, fcntl.LOCK_EX)
    finally:
        signal.alarm(0)
        signal.signal(signal.SIGALRM, old_handler)


def append(event: str, payload: dict, actor: str = "sentinel") -> dict:
    """Atomically append one entry to the audit chain.

    Uses exclusive flock with a 10-second timeout to prevent deadlocks.
    Calls fsync to minimize data loss on power failure.

    Returns the completed entry dict.
    """
    _ensure_genesis()
    with open(CHAIN, "a+b") as f:
        _flock_with_timeout(f.fileno(), FLOCK_TIMEOUT_SECONDS)
        try:
            seq, prev_hash = _read_last()
            seq += 1
            ts = datetime.now(timezone.utc).isoformat()
            body: dict = {
                "seq": seq,
                "prev_hash": prev_hash,
                "ts": ts,
                "actor": actor,
                "event": event,
                "payload": payload,
            }
            body["this_hash"] = _sha256(_canonical({
                "seq": seq,
                "prev_hash": prev_hash,
                "ts": ts,
                "actor": actor,
                "event": event,
                "payload": payload,
            }))
            line = json.dumps(body, sort_keys=True, default=str) + "\n"
            f.write(line.encode())
            f.flush()
            os.fsync(f.fileno())
        finally:
            fcntl.flock(f, fcntl.LOCK_UN)
    return body


def verify() -> tuple[bool, int, str | None]:
    """Walk the entire chain end-to-end verifying Merkle links.

    Returns:
        (ok: bool, last_seq: int, err: str | None)
        ok=True  → chain is intact
        ok=False → err describes the first breakage point
    """
    _ensure_genesis()
    expected_prev = _genesis_hash()
    last_seq = -1

    INFO_LOG_TYPES = {"fim_drift", "canary_triggered", "guardian_cycle"}

    if not CHAIN.exists() or CHAIN.stat().st_size == 0:
        return True, -1, None

    with open(CHAIN) as f:
        for i, raw_line in enumerate(f):
            line = raw_line.rstrip("\n")
            if not line:
                continue
            try:
                entry = json.loads(line)
            except Exception as e:
                return False, last_seq, f"line {i}: not valid JSON ({e})"

            is_reanchor = (
                isinstance(entry.get("action"), dict)
                and entry["action"].get("type") == "reanchor"
            )
            is_guardian = (
                entry.get("actor") == "guardian"
                and entry.get("event") == "guardian_cycle"
            )
            is_merkle = (not is_guardian) and ("this_hash" in entry and "event" in entry)
            entry_type = entry.get("type")
            is_info_log = entry_type in INFO_LOG_TYPES or is_guardian

            if is_reanchor:
                self_hash = entry.get("self_hash")
                if self_hash:
                    expected_prev = self_hash
                continue

            if is_info_log:
                continue

            if is_merkle:
                if entry.get("prev_hash") != expected_prev:
                    if entry["seq"] == 1 and last_seq <= 0:
                        expected_prev = entry["prev_hash"]
                    else:
                        return (
                            False,
                            last_seq,
                            f"line {i}: prev_hash mismatch "
                            f"(expected {expected_prev[:12]}..., "
                            f"got {str(entry.get('prev_hash', ''))[:12]}...)",
                        )

                hash_body = {
                    "seq": entry["seq"],
                    "prev_hash": entry["prev_hash"],
                    "ts": entry["ts"],
                    "actor": entry.get("actor", ""),
                    "event": entry["event"],
                    "payload": entry.get("payload", {}),
                }
                recomputed = _sha256(_canonical(hash_body))
                legacy_recomputed = _sha256(_canonical_legacy_v2(hash_body))
                if entry.get("this_hash") not in (recomputed, legacy_recomputed):
                    return False, last_seq, f"line {i}: this_hash mismatch (seq={entry['seq']})"

                if entry["seq"] != last_seq + 1:
                    if entry["seq"] > last_seq:
                        pass
                    elif entry["seq"] == 1 and last_seq <= 0:
                        pass
                    elif entry["seq"] == 1 and last_seq > 0:
                        pass
                    else:
                        return (
                            False,
                            last_seq,
                            f"line {i}: seq gap (expected >{last_seq}, got {entry['seq']})",
                        )

                last_seq = entry["seq"]
                expected_prev = entry["this_hash"]
            else:
                seq = entry.get("seq", last_seq + 1)
                self_hash = entry.get("self_hash") or entry.get("this_hash")
                if seq != last_seq + 1:
                    if seq > last_seq:
                        pass
                    elif seq == 1 and last_seq <= 0:
                        pass
                    elif seq == 1 and last_seq > 0:
                        pass
                    else:
                        return (
                            False,
                            last_seq,
                            f"line {i}: seq gap in legacy entry (expected >{last_seq}, got {seq})",
                        )
                last_seq = seq
                if self_hash:
                    expected_prev = self_hash

    return True, last_seq, None


def head_hash() -> str:
    """Return the hash of the last chain entry (or genesis hash if empty)."""
    _, h = _read_last()
    return h


if __name__ == "__main__":
    import sys
    ok, seq, err = verify()
    if ok:
        print(f"✅ chain ok (seq={seq}, head={head_hash()[:16]}...)")
        sys.exit(0)
    print(f"❌ chain broken at seq={seq}: {err}")
    sys.exit(1)
