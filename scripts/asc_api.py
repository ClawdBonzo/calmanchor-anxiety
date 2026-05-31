#!/usr/bin/env python3
"""
App Store Connect API client for CalmAnchor.
Pushes localized metadata and uploads screenshots (no browser needed).

Auth (set env vars, or pass --key/--key-id/--issuer):
  ASC_KEY_PATH   path to AuthKey_XXXXXXXXXX.p8   (App Store Connect API key, App Manager)
  ASC_KEY_ID     the Key ID (e.g. 2X9R4HXF34)
  ASC_ISSUER_ID  the Issuer ID (UUID from Users and Access > Integrations)

Usage:
  python3 scripts/asc_api.py whoami                 # verify auth + show app/version
  python3 scripts/asc_api.py metadata               # push appstore_metadata/<locale>/*
  python3 scripts/asc_api.py screenshots            # upload screenshots/final[/<locale>]
  python3 scripts/asc_api.py all                    # metadata + screenshots
  add --dry-run to preview without writing.
"""
import os, sys, time, json, hashlib, argparse, urllib.request, urllib.error
import jwt  # PyJWT

ROOT = os.path.join(os.path.dirname(__file__), "..")
APP_ID = "6761788508"
BASE = "https://api.appstoreconnect.apple.com"
# locale -> screenshot source dir (None = use the shared English screenshots/final/*.png)
SCREENSHOT_DIRS = {
    "en-US": None, "en-GB": None, "en-AU": None,
    "de-DE": "de", "fr-FR": "fr", "ja": "ja",
}
DISPLAY_TYPE = "APP_IPHONE_67"  # accepts 1290x2796 and 1320x2868 (6.9")


def token():
    kid = os.environ.get("ASC_KEY_ID")
    iss = os.environ.get("ASC_ISSUER_ID")
    kp = os.environ.get("ASC_KEY_PATH")
    if not (kid and iss and kp and os.path.exists(kp)):
        sys.exit("Missing ASC_KEY_ID / ASC_ISSUER_ID / ASC_KEY_PATH (readable .p8). See header.")
    key = open(kp).read()
    payload = {"iss": iss, "iat": int(time.time()), "exp": int(time.time()) + 1100,
               "aud": "appstoreconnect-v1"}
    return jwt.encode(payload, key, algorithm="ES256", headers={"kid": kid, "typ": "JWT"})


def req(method, path, tok, body=None, raw=None, ctype="application/json", base=None):
    url = (base or BASE) + path if path.startswith("/") else path
    data = raw if raw is not None else (json.dumps(body).encode() if body is not None else None)
    r = urllib.request.Request(url, data=data, method=method)
    r.add_header("Authorization", f"Bearer {tok}")
    if data is not None:
        r.add_header("Content-Type", ctype)
    try:
        with urllib.request.urlopen(r) as resp:
            b = resp.read()
            return json.loads(b) if b and ctype == "application/json" and method != "PUT" else (b or {})
    except urllib.error.HTTPError as e:
        print(f"  ! {method} {path} -> {e.code}\n    {e.read().decode()[:600]}")
        raise


def get_all(path, tok):
    out, url = [], path
    while url:
        d = req("GET", url, tok)
        out += d.get("data", [])
        url = (d.get("links") or {}).get("next")
        if url:
            url = url.replace(BASE, "")
    return out


def editable_version(tok):
    vers = get_all(f"/v1/apps/{APP_ID}/appStoreVersions?limit=50", tok)
    edit_states = {"PREPARE_FOR_SUBMISSION", "DEVELOPER_REJECTED", "REJECTED",
                   "METADATA_REJECTED", "INVALID_BINARY", "WAITING_FOR_REVIEW"}
    for v in vers:
        if v["attributes"]["appStoreState"] in edit_states:
            return v
    return vers[0] if vers else None


def app_info(tok):
    infos = get_all(f"/v1/apps/{APP_ID}/appInfos", tok)
    # the editable appInfo (state PREPARE_FOR_SUBMISSION) holds name/subtitle
    for i in infos:
        st = i["attributes"].get("appStoreState") or i["attributes"].get("state")
        if st in (None, "PREPARE_FOR_SUBMISSION"):
            return i
    return infos[0]


def read_meta(loc):
    d = os.path.join(ROOT, "appstore_metadata", loc)
    if not os.path.isdir(d):
        return None
    def r(f):
        p = os.path.join(d, f)
        return open(p, encoding="utf-8").read().strip() if os.path.exists(p) else None
    return {"name": r("name.txt"), "subtitle": r("subtitle.txt"),
            "description": r("description.txt"), "keywords": r("keywords.txt"),
            "promotionalText": r("promotional_text.txt")}


def push_metadata(tok, dry):
    ver = editable_version(tok); vid = ver["id"]
    print(f"editable version {ver['attributes']['versionString']} ({ver['attributes']['appStoreState']})")
    info = app_info(tok); iid = info["id"]
    for loc in SCREENSHOT_DIRS:
        m = read_meta(loc)
        if not m:
            continue
        print(f"[{loc}] {m['name']!r} / {m['subtitle']!r}")
        if dry:
            continue
        # refetch per-locale: creating an appInfoLocalization auto-creates the
        # matching appStoreVersionLocalization, so cached maps go stale.
        ver_locs = {l["attributes"]["locale"]: l["id"]
                    for l in get_all(f"/v1/appStoreVersions/{vid}/appStoreVersionLocalizations", tok)}
        info_locs = {l["attributes"]["locale"]: l["id"]
                     for l in get_all(f"/v1/appInfos/{iid}/appInfoLocalizations", tok)}
        # --- app info localization (name + subtitle) ---
        ia = {"name": m["name"], "subtitle": m["subtitle"]}
        if loc in info_locs:
            req("PATCH", f"/v1/appInfoLocalizations/{info_locs[loc]}", tok,
                {"data": {"type": "appInfoLocalizations", "id": info_locs[loc], "attributes": ia}})
        else:
            req("POST", "/v1/appInfoLocalizations", tok, {"data": {
                "type": "appInfoLocalizations", "attributes": {**ia, "locale": loc},
                "relationships": {"appInfo": {"data": {"type": "appInfos", "id": iid}}}}})
        # --- version localization (description, keywords, promo) ---
        # refetch: the appInfo create above may have auto-created this locale
        ver_locs = {l["attributes"]["locale"]: l["id"]
                    for l in get_all(f"/v1/appStoreVersions/{vid}/appStoreVersionLocalizations", tok)}
        va = {"description": m["description"], "keywords": m["keywords"],
              "promotionalText": m["promotionalText"]}
        if loc in ver_locs:
            req("PATCH", f"/v1/appStoreVersionLocalizations/{ver_locs[loc]}", tok,
                {"data": {"type": "appStoreVersionLocalizations", "id": ver_locs[loc], "attributes": va}})
        else:
            req("POST", "/v1/appStoreVersionLocalizations", tok, {"data": {
                "type": "appStoreVersionLocalizations", "attributes": {**va, "locale": loc},
                "relationships": {"appStoreVersion": {"data": {"type": "appStoreVersions", "id": vid}}}}})
        print(f"  ✓ metadata pushed")


def loc_shots(loc):
    sub = SCREENSHOT_DIRS[loc]
    base = os.path.join(ROOT, "screenshots", "final", sub or "")
    return sorted(f for f in (os.path.join(base, x) for x in os.listdir(base))
                  if f.endswith(".png")) if os.path.isdir(base) else []


def upload_screenshots(tok, dry):
    ver = editable_version(tok); vid = ver["id"]
    ver_locs = {l["attributes"]["locale"]: l["id"]
                for l in get_all(f"/v1/appStoreVersions/{vid}/appStoreVersionLocalizations", tok)}
    for loc, sub in SCREENSHOT_DIRS.items():
        shots = loc_shots(loc)
        if not shots:
            continue
        print(f"[{loc}] {len(shots)} screenshots")
        if dry:
            continue
        if loc not in ver_locs:
            print(f"  ! no version localization for {loc} (run metadata first)"); continue
        lid = ver_locs[loc]
        # find or create screenshot set for the display type
        sets = get_all(f"/v1/appStoreVersionLocalizations/{lid}/appScreenshotSets", tok)
        sset = next((s for s in sets if s["attributes"]["screenshotDisplayType"] == DISPLAY_TYPE), None)
        if not sset:
            sset = req("POST", "/v1/appScreenshotSets", tok, {"data": {
                "type": "appScreenshotSets",
                "attributes": {"screenshotDisplayType": DISPLAY_TYPE},
                "relationships": {"appStoreVersionLocalization": {"data": {
                    "type": "appStoreVersionLocalizations", "id": lid}}}}})["data"]
        sid = sset["id"]
        for path in shots:
            blob = open(path, "rb").read()
            fn = os.path.basename(path)
            # 1) reserve
            res = req("POST", "/v1/appScreenshots", tok, {"data": {
                "type": "appScreenshots",
                "attributes": {"fileSize": len(blob), "fileName": fn},
                "relationships": {"appScreenshotSet": {"data": {"type": "appScreenshotSets", "id": sid}}}}})["data"]
            shot_id = res["id"]
            # 2) upload via the returned operations
            for op in res["attributes"]["uploadOperations"]:
                chunk = blob[op["offset"]: op["offset"] + op["length"]]
                rr = urllib.request.Request(op["url"], data=chunk, method=op["method"])
                for h in op.get("requestHeaders", []):
                    rr.add_header(h["name"], h["value"])
                urllib.request.urlopen(rr).read()
            # 3) commit with md5 checksum
            req("PATCH", f"/v1/appScreenshots/{shot_id}", tok, {"data": {
                "type": "appScreenshots", "id": shot_id,
                "attributes": {"uploaded": True, "sourceFileChecksum": hashlib.md5(blob).hexdigest()}}})
            print(f"  ✓ {fn}")


def whoami(tok):
    app = req("GET", f"/v1/apps/{APP_ID}", tok)["data"]
    print("app:", app["attributes"]["name"], "/", app["attributes"]["bundleId"])
    ver = editable_version(tok)
    print("editable version:", ver["attributes"]["versionString"], ver["attributes"]["appStoreState"])
    info = app_info(tok)
    locs = [l["attributes"]["locale"] for l in get_all(f"/v1/appInfos/{info['id']}/appInfoLocalizations", tok)]
    print("existing locales:", ", ".join(locs))


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("cmd", choices=["whoami", "metadata", "screenshots", "all"])
    ap.add_argument("--dry-run", action="store_true")
    a = ap.parse_args()
    tok = token()
    if a.cmd == "whoami":
        whoami(tok)
    if a.cmd in ("metadata", "all"):
        push_metadata(tok, a.dry_run)
    if a.cmd in ("screenshots", "all"):
        upload_screenshots(tok, a.dry_run)


if __name__ == "__main__":
    main()
