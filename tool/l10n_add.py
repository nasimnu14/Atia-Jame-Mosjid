#!/usr/bin/env python3
"""Adds keys to BOTH lib/l10n/app_en.arb and lib/l10n/app_bn.arb so they never
drift apart (GEN-2). Usage from another script:

    from l10n_add import add
    add({"save": ("Save", "সংরক্ষণ করুন")})

`{name}` in a text becomes a String placeholder; function arguments follow the
order of first appearance in the English text.
Then run: flutter gen-l10n
"""
import json
import os
import re
import sys

ROOT = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "lib", "l10n")


def _load(name):
    path = os.path.join(ROOT, name)
    if os.path.exists(path):
        with open(path, encoding="utf-8") as f:
            return json.load(f)
    return {}


def _save(name, data):
    with open(os.path.join(ROOT, name), "w", encoding="utf-8") as f:
        json.dump(data, f, ensure_ascii=False, indent=2)
        f.write("\n")


def add(entries):
    en = _load("app_en.arb")
    bn = _load("app_bn.arb")
    en.setdefault("@@locale", "en")
    bn.setdefault("@@locale", "bn")
    for key, (en_text, bn_text) in entries.items():
        en[key] = en_text
        bn[key] = bn_text
        names = list(dict.fromkeys(re.findall(r"\{(\w+)\}", en_text)))  # order of appearance
        if names:
            en["@" + key] = {"placeholders": {n: {"type": "String"} for n in names}}
        if sorted(set(re.findall(r"\{(\w+)\}", bn_text))) != sorted(names):
            sys.exit(f"placeholder mismatch in {key}")
    _save("app_en.arb", en)
    _save("app_bn.arb", bn)


if __name__ == "__main__":
    print(__doc__)
