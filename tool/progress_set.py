#!/usr/bin/env python3
"""Updates rows of the requirement tracker in docs/progress/accounts-app.md.

    tool/progress_set.py done "GEN-3,GEN-4" "lib/app/app_state.dart" "test/widget/sign_in_flow_test.dart"
    tool/progress_set.py --init      # (re)build the table from the requirements doc

Status: todo | partial | done | blocked. Files/tests columns are replaced when given.
"""
import os
import re
import sys

ROOT = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..")
PROGRESS = os.path.join(ROOT, "docs", "progress", "accounts-app.md")
REQ = os.path.join(ROOT, "docs", "atia-jame-masjid-accounts-requirement.md")
START, END = "<!-- REQ-TABLE-START -->", "<!-- REQ-TABLE-END -->"


def must_ids():
    text = open(REQ, encoding="utf-8").read()
    text = text.split("### Nice-to-have")[0]
    ids = []
    for m in re.finditer(r"^- \*\*([A-Z]+-\d+)\*\*", text, re.M):
        ids.append(m.group(1))
    return ids


def read_rows(doc):
    a, b = doc.index(START) + len(START), doc.index(END)
    rows = {}
    for line in doc[a:b].strip().splitlines():
        if line.startswith("| ") and not line.startswith("| ID") and not line.startswith("|---"):
            cells = [c.strip() for c in line.strip("|").split("|")]
            rows[cells[0]] = cells[1:]
    return rows


def write_rows(doc, rows):
    a, b = doc.index(START) + len(START), doc.index(END)
    head = "\n| ID | Status | Implemented in | Covered by |\n|---|---|---|---|\n"
    body = "\n".join(f"| {k} | {v[0]} | {v[1]} | {v[2]} |" for k, v in rows.items())
    return doc[:a] + head + body + "\n" + doc[b:]


def main():
    doc = open(PROGRESS, encoding="utf-8").read()
    if sys.argv[1] == "--init":
        old = read_rows(doc) if START in doc and END in doc else {}
        rows = {i: old.get(i, ["todo", "", ""]) for i in must_ids()}
        open(PROGRESS, "w", encoding="utf-8").write(write_rows(doc, rows))
        return
    status, ids = sys.argv[1], sys.argv[2].split(",")
    files = sys.argv[3] if len(sys.argv) > 3 else None
    tests = sys.argv[4] if len(sys.argv) > 4 else None
    rows = read_rows(doc)
    for i in ids:
        i = i.strip()
        if i not in rows:
            sys.exit(f"unknown id {i}")
        rows[i][0] = status
        if files is not None:
            rows[i][1] = files
        if tests is not None:
            rows[i][2] = tests
    open(PROGRESS, "w", encoding="utf-8").write(write_rows(doc, rows))


main()
