#!/usr/bin/env python3
"""Merge the 1.3 game-layer strings (badges, ranks, celebrations, recap,
share cards) into CalmAnchor/Localizable.xcstrings with de/fr/ja.
Translations live in localize_v13_data.py (dict T: en -> (de, fr, ja)).
"Panic SOS" is normalised to the names the catalog already uses."""
import json, os, runpy

HERE = os.path.dirname(__file__)
CAT = os.path.join(HERE, "..", "CalmAnchor", "Localizable.xcstrings")
T = runpy.run_path(os.path.join(HERE, "localize_v13_data.py"))["T"]

SOS = {"de": [("Panic-SOS", "Panik-SOS"), ("Panic SOS", "Panik-SOS")],
       "fr": [("Panic SOS", "SOS panique")],
       "ja": [("Panic SOS", "パニックSOS")]}

def unit(val):
    return {"stringUnit": {"state": "translated", "value": val}}

def main():
    cat = json.load(open(CAT, encoding="utf-8"))
    strings = cat["strings"]
    added = updated = 0
    for en, (de, fr, ja) in T.items():
        vals = {"de": de, "fr": fr, "ja": ja}
        for lang, pairs in SOS.items():
            for a, b in pairs:
                vals[lang] = vals[lang].replace(a, b)
        entry = strings.get(en)
        if entry is None:
            entry = {"extractionState": "manual", "localizations": {}}
            strings[en] = entry
            added += 1
        else:
            updated += 1
        locs = entry.setdefault("localizations", {})
        for lang, v in vals.items():
            locs[lang] = unit(v)
    with open(CAT, "w", encoding="utf-8") as f:
        json.dump(cat, f, ensure_ascii=False, indent=2, separators=(",", ": "))
    print(f"added {added}, updated {updated}, total keys {len(strings)}")

if __name__ == "__main__":
    main()
