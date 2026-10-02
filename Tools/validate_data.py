#!/usr/bin/env python3
"""Offline integrity checks for the bundled official pool and study aids."""

from __future__ import annotations

import json
import re
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
pool = json.loads((ROOT / "Resources/questions.json").read_text(encoding="utf-8"))
questions = pool["questions"]

assert pool["meta"]["questionCount"] == 409 == len(questions)
assert pool["meta"]["groupCount"] == 35 == len({q["group"] for q in questions})
assert pool["meta"]["passScore"] == 26
assert len({q["id"] for q in questions}) == 409
assert {Path(q["figure"]).stem for q in questions if q["figure"]} == {"t-1", "t-2", "t-3"}

letters = "ABCD"
for q in questions:
    assert len(q["answers"]) == 4, q["id"]
    assert 0 <= q["correct"] < 4, q["id"]
    assert q["correct_letter"] == letters[q["correct"]], q["id"]
    assert re.fullmatch(r"T[0-9][A-Z][0-9]{2}", q["id"]), q["id"]

ids = {q["id"] for q in questions}
for code in ("en", "zh-Hans", "ko", "vi", "es"):
    path = ROOT / f"Resources/Translations/{code}.json"
    data = json.loads(path.read_text(encoding="utf-8"))
    assert set(data) == ids, f"{code}: missing/extra IDs"
    for qid, item in data.items():
        assert item["question"].strip(), f"{code}/{qid}: blank question"
        assert len(item["answers"]) == 4, f"{code}/{qid}: answer count"
        assert all(str(answer).strip() for answer in item["answers"]), f"{code}/{qid}: blank answer"
        assert len(item["explanation"].strip()) >= 15, f"{code}/{qid}: thin explanation"
        assert not re.search(r"\bplaceholder\b|translation unavailable|\bTODO\s*:", item["explanation"], re.I), f"{code}/{qid}: placeholder"
        if code == "en":
            source = next(question for question in questions if question["id"] == qid)
            assert item["question"] == source["question"], f"en/{qid}: question diverged from official English"
            assert item["answers"] == source["answers"], f"en/{qid}: answers diverged from official English"
    print(f"{code}: {len(data)} complete records")

print("Official pool: 409 questions · 35 groups · 3 diagrams · mappings valid")
