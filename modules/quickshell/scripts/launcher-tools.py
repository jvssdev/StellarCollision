import html
import json
import os
import re
import subprocess
import sys
import time
import unicodedata
import urllib.parse
import urllib.request
from concurrent.futures import ThreadPoolExecutor
from datetime import datetime, timedelta, timezone
from pathlib import Path
from zoneinfo import ZoneInfo, available_timezones

QALC = os.environ.get("QALC", "qalc")
CACHE_DIR = Path(os.environ.get("XDG_CACHE_HOME") or Path.home() / ".cache") / "stellar-launcher"
RATES_STAMP = CACHE_DIR / "exchange-rates"
QALC_CONFIG_HOME = CACHE_DIR / "qalc-config"
QALC_CONFIG = "mixed_units_conversion=0\nauto_post_conversion=1\n"
RATES_MAX_AGE = 12 * 3600
RATES_RETRY_AGE = 11 * 3600
TRANSLATE_URL = "https://translate.google.com/translate_a/single"
TRANSLATE_DT = ("at", "bd", "ex", "ld", "md", "qca", "rw", "rm", "ss", "t")
USER_AGENT = "Mozilla/5.0"
REGIONS = ("Africa", "America", "Antarctica", "Arctic", "Asia", "Atlantic", "Australia", "Europe", "Indian", "Pacific")

ZONE_ALIASES = {
    "utc": "UTC",
    "gmt": "UTC",
    "z": "UTC",
    "brt": "America/Sao_Paulo",
    "brasilia": "America/Sao_Paulo",
    "brazil": "America/Sao_Paulo",
    "sp": "America/Sao_Paulo",
    "est": "America/New_York",
    "edt": "America/New_York",
    "nyc": "America/New_York",
    "cst": "America/Chicago",
    "cdt": "America/Chicago",
    "mst": "America/Denver",
    "mdt": "America/Denver",
    "pst": "America/Los_Angeles",
    "pdt": "America/Los_Angeles",
    "la": "America/Los_Angeles",
    "sf": "America/Los_Angeles",
    "california": "America/Los_Angeles",
    "bst": "Europe/London",
    "uk": "Europe/London",
    "cet": "Europe/Paris",
    "cest": "Europe/Paris",
    "portugal": "Europe/Lisbon",
    "jst": "Asia/Tokyo",
    "japan": "Asia/Tokyo",
    "ist": "Asia/Kolkata",
    "india": "Asia/Kolkata",
    "beijing": "Asia/Shanghai",
    "china": "Asia/Shanghai",
}

LANGUAGE_ALIASES = {
    "pt-br": "pt",
    "zh": "zh-CN",
    "zh-cn": "zh-CN",
    "zh-tw": "zh-TW",
    "iw": "he",
}

CORRECTION_TAGS_RE = re.compile(r"</?(?:b|i)>")
OFFSET_RE = re.compile(r"^(?:utc|gmt)?\s*([+-])\s*(\d{1,2})(?::?(\d{2}))?$")
CLOCK_RE = re.compile(r"^(\d{1,2})(?:(:|h)(\d{2})?)?\s*(am|pm)?$")
DATE_RE = re.compile(r"^(\d{4}-\d{2}-\d{2}|today|tomorrow|yesterday|hoje|amanha|ontem)\s+(.+)$")
NOW_WORDS = ("now", "time", "hora", "agora")
SPLIT_RE = re.compile(r"^(?P<left>.+?)\s+(?:in|to|->|em|para)\s+(?P<right>.+)$")
NOW_IN_RE = re.compile(r"^(?:now|time|hora|agora)\s+(?:(?:in|em|at)\s+)?(?P<zone>.+)$")
ARITHMETIC_RE = re.compile(r"[\d)]\s*[-+*/^%\u00d7\u00f7]\s*[\d(.\-]")
FUNCTION_RE = re.compile(r"\b(sqrt|cbrt|sin|cos|tan|asin|acos|atan|log|ln|exp|abs|round|floor|ceil|fact|root|gcd|lcm)\s*\(", re.I)
CONVERSION_RE = re.compile(r"\d\s*[a-z\u00b0$\u20ac\u00a3%/]*\s+(?:to|in|->|as)\s+[a-z\u00b0$\u20ac\u00a3/]+", re.I)
PERCENT_RE = re.compile(r"\d\s*%\s*(?:of|de)\s*\d", re.I)
PERCENT_OF_RE = re.compile(r"(\d+(?:[.,]\d+)?)\s*%\s*(?:of|de)\s*(.+)$", re.I)
INCH_AMBIGUITY_RE = re.compile(r"^(?P<head>.+?)\s+in\s+(?P<unit>\S+)$", re.I)
CURRENCY_RE = re.compile(r"\b[a-z]{3}\b\s+(?:to|in|->)\s+\b[a-z]{3}\b|[$\u20ac\u00a3\u00a5]", re.I)


def fold(text):
    decomposed = unicodedata.normalize("NFKD", text)
    stripped = "".join(ch for ch in decomposed if not unicodedata.combining(ch))
    return re.sub(r"\s+", " ", stripped.lower().replace("_", " ")).strip()


_zone_index = None


def zone_index():
    global _zone_index
    if _zone_index is None:
        index = {}
        for name in sorted(available_timezones()):
            if "/" not in name or name.split("/", 1)[0] not in REGIONS:
                continue
            index.setdefault(fold(name.rsplit("/", 1)[1]), name)
            index.setdefault(fold(name), name)
        _zone_index = index
    return _zone_index


def local_zone():
    candidates = []
    env_tz = os.environ.get("TZ")
    if env_tz:
        candidates.append(env_tz.lstrip(":"))
    link = os.path.realpath("/etc/localtime")
    if "zoneinfo/" in link:
        candidates.append(link.split("zoneinfo/", 1)[1])
    for name in candidates:
        try:
            return ZoneInfo(name), name.rsplit("/", 1)[-1].replace("_", " ")
        except Exception:
            continue
    return datetime.now().astimezone().tzinfo, "local"


def resolve_zone(text):
    key = fold(text)
    if key in ("local", "here", "me", "aqui"):
        return local_zone()
    match = OFFSET_RE.match(key)
    if match:
        sign = 1 if match.group(1) == "+" else -1
        hours = int(match.group(2))
        minutes = int(match.group(3) or 0)
        if hours > 14 or minutes > 59:
            return None
        delta = timedelta(hours=hours, minutes=minutes) * sign
        return timezone(delta), "UTC%s%02d:%02d" % (match.group(1), hours, minutes)
    name = ZONE_ALIASES.get(key) or zone_index().get(key)
    if not name:
        return None
    label = "UTC" if name == "UTC" else name.rsplit("/", 1)[1].replace("_", " ")
    return ZoneInfo(name), label


def parse_clock(token):
    match = CLOCK_RE.match(token.strip())
    if not match:
        return None
    hour = int(match.group(1))
    separator = match.group(2)
    minute = int(match.group(3) or 0)
    meridiem = match.group(4)
    if not separator and not meridiem:
        return None
    if meridiem:
        if hour < 1 or hour > 12:
            return None
        hour = hour % 12 + (12 if meridiem == "pm" else 0)
    if hour > 23 or minute > 59:
        return None
    return hour, minute


def split_time_and_zone(left):
    words = left.split(" ")
    for size in (2, 1):
        if len(words) < size:
            continue
        clock = parse_clock("".join(words[:size]))
        if clock:
            rest = " ".join(words[size:]).strip()
            return clock, rest
    return None


def utc_label(moment):
    offset = moment.utcoffset() or timedelta(0)
    total = int(offset.total_seconds() // 60)
    sign = "+" if total >= 0 else "-"
    hours, minutes = divmod(abs(total), 60)
    return "UTC%s%d" % (sign, hours) + (":%02d" % minutes if minutes else "")


def time_row(source_moment, destination_moment, destination_label):
    day_delta = (destination_moment.date() - source_moment.date()).days
    suffix = ""
    if day_delta:
        suffix = " (%+d day%s)" % (day_delta, "" if abs(day_delta) == 1 else "s")
    clock = destination_moment.strftime("%H:%M")
    return {
        "type": "time",
        "name": "%s%s \u00b7 %s" % (clock, suffix, destination_moment.strftime("%a %d %b")),
        "subtitle": "%s (%s)" % (destination_label, utc_label(destination_moment)),
        "copy": clock,
    }


def try_time(query):
    text = fold(query)
    now_match = NOW_IN_RE.match(text)
    if now_match:
        destination = resolve_zone(now_match.group("zone"))
        if not destination:
            return None
        source_tz, _ = local_zone()
        source_moment = datetime.now(source_tz)
        return time_row(source_moment, source_moment.astimezone(destination[0]), destination[1])
    split = SPLIT_RE.match(text)
    if not split:
        return None
    destination = resolve_zone(split.group("right"))
    if not destination:
        return None
    left = split.group("left")
    day_offset = 0
    explicit_date = None
    date_match = DATE_RE.match(left)
    if date_match:
        word = date_match.group(1)
        left = date_match.group(2)
        if word in ("tomorrow", "amanha"):
            day_offset = 1
        elif word in ("yesterday", "ontem"):
            day_offset = -1
        elif word not in ("today", "hoje"):
            try:
                explicit_date = datetime.strptime(word, "%Y-%m-%d").date()
            except ValueError:
                return None
    if left in NOW_WORDS:
        source_tz, _ = local_zone()
        source_moment = datetime.now(source_tz)
    else:
        parsed = split_time_and_zone(left)
        if not parsed:
            return None
        (hour, minute), zone_text = parsed
        source = resolve_zone(zone_text) if zone_text else local_zone()
        if not source:
            return None
        source_tz = source[0]
        base = explicit_date or (datetime.now(source_tz).date() + timedelta(days=day_offset))
        source_moment = datetime(base.year, base.month, base.day, hour, minute, tzinfo=source_tz)
    return time_row(source_moment, source_moment.astimezone(destination[0]), destination[1])


def looks_like_math(query):
    if len(query) > 200 or not re.search(r"\d", query):
        return False
    return bool(
        ARITHMETIC_RE.search(query)
        or FUNCTION_RE.search(query)
        or CONVERSION_RE.search(query)
        or PERCENT_RE.search(query)
    )


def qalc_env():
    config_file = QALC_CONFIG_HOME / "qalculate" / "qalc.cfg"
    if not config_file.exists():
        config_file.parent.mkdir(parents=True, exist_ok=True)
        config_file.write_text(QALC_CONFIG)
    return dict(os.environ, LC_ALL="C.UTF-8", XDG_CONFIG_HOME=str(QALC_CONFIG_HOME))


def normalize_expression(query):
    expression = query.replace("\u00d7", "*").replace("\u00f7", "/").strip()
    percent = PERCENT_OF_RE.search(expression)
    if percent:
        amount = percent.group(1).replace(",", ".")
        expression = "(%s/100)*(%s)" % (amount, percent.group(2))
    inch = INCH_AMBIGUITY_RE.match(expression)
    if inch:
        expression = "%s to %s" % (inch.group("head"), inch.group("unit"))
    return expression


def ensure_rates():
    try:
        age = time.time() - RATES_STAMP.stat().st_mtime
    except OSError:
        age = RATES_MAX_AGE + 1
    if age <= RATES_MAX_AGE:
        return
    CACHE_DIR.mkdir(parents=True, exist_ok=True)
    try:
        subprocess.run([QALC, "-e"], capture_output=True, timeout=10, check=True, env=qalc_env())
        RATES_STAMP.touch()
    except Exception:
        RATES_STAMP.touch()
        stale = time.time() - RATES_RETRY_AGE
        os.utime(RATES_STAMP, (stale, stale))


def try_calc(query):
    if not looks_like_math(query):
        return None
    first_word = fold(query).split(" ", 1)[0]
    if parse_clock(first_word):
        return None
    expression = normalize_expression(query)
    if CURRENCY_RE.search(expression):
        ensure_rates()
    try:
        completed = subprocess.run(
            [QALC, "-t", "-set", "precision 10", expression],
            capture_output=True,
            text=True,
            timeout=4,
            env=qalc_env(),
        )
    except Exception:
        return None
    result = completed.stdout.strip()
    stderr = completed.stderr.lower()
    if completed.returncode != 0 or not result or "error" in stderr or "\n" in result:
        return None
    if "\u211c" in result or '"' in result:
        return None
    if fold(result) == fold(expression):
        return None
    return {"type": "calc", "name": result, "subtitle": query.strip(), "copy": result}


def base_language(code):
    return code.lower().split("-")[0]


def normalize_language(code):
    key = code.strip().lower()
    return LANGUAGE_ALIASES.get(key, code.strip())


def build_request(text, source, target):
    params = [("client", "dict-chrome-ex"), ("sl", source), ("tl", target), ("hl", target)]
    params += [("dt", flag) for flag in TRANSLATE_DT]
    params += [("ie", "UTF-8"), ("oe", "UTF-8"), ("otf", "1"), ("ssel", "0"), ("tsel", "0"), ("kc", "7")]
    url = "%s?%s" % (TRANSLATE_URL, urllib.parse.urlencode(params + [("q", text)]))
    data = None
    headers = {"User-Agent": USER_AGENT}
    if len(url) > 2048:
        url = "%s?%s" % (TRANSLATE_URL, urllib.parse.urlencode(params))
        data = urllib.parse.urlencode({"q": text}).encode()
        headers["Content-Type"] = "application/x-www-form-urlencoded;charset=UTF-8"
    return urllib.request.Request(url, data=data, headers=headers)


def parse_translation(body):
    segments = body[0] or []
    translated = "".join(segment[0] for segment in segments if segment and segment[0])
    detected = ""
    if len(body) > 2 and isinstance(body[2], str):
        detected = body[2]
    pronunciation = None
    if len(segments) > 1 and isinstance(segments[1], list):
        candidate = (segments[1][2:3] or [None])[0] or (segments[1][3:4] or [None])[0]
        if isinstance(candidate, str):
            pronunciation = candidate
    return translated, detected, pronunciation


def parse_alternatives(body):
    entries = body[1] if len(body) > 1 and isinstance(body[1], list) else []
    found = []
    for entry in entries:
        if not isinstance(entry, list) or len(entry) < 2:
            continue
        pos = entry[0] if isinstance(entry[0], str) else ""
        detailed = entry[2] if len(entry) > 2 and isinstance(entry[2], list) else []
        if detailed:
            for item in detailed:
                if isinstance(item, list) and item and isinstance(item[0], str):
                    reverse = item[1] if len(item) > 1 and isinstance(item[1], list) else []
                    found.append((pos, item[0], [term for term in reverse if isinstance(term, str)]))
        elif isinstance(entry[1], list):
            found.extend((pos, term, []) for term in entry[1] if isinstance(term, str))
    return found


def parse_correction(body):
    block = body[7] if len(body) > 7 else None
    if not isinstance(block, list) or not block or not isinstance(block[0], str):
        return None, False
    corrected = html.unescape(CORRECTION_TAGS_RE.sub("", block[0])).strip()
    if not corrected:
        return None, False
    applied = len(block) > 5 and block[5] is True
    return corrected, applied


def translate_one(text, source, target):
    with urllib.request.urlopen(build_request(text, source, target), timeout=8) as response:
        body = json.loads(response.read().decode("utf-8"))
    translated, detected, pronunciation = parse_translation(body)
    correction, applied = parse_correction(body)
    return {
        "alternatives": parse_alternatives(body),
        "target": target,
        "text": translated,
        "detected": detected,
        "pronunciation": pronunciation,
        "correction": correction,
        "applied": applied,
    }


def run_translations(text, source, targets):
    with ThreadPoolExecutor(max_workers=max(1, len(targets))) as pool:
        return list(pool.map(lambda target: translate_one(text, source, target), targets))


def find_correction(text, results):
    for item in results:
        if item["correction"] and fold(item["correction"]) != fold(text):
            return item["correction"]
    return None


def alternative_rows(main_name, alternatives, limit):
    if limit <= 0:
        return []
    seen = {fold(main_name)}
    rows = []
    for pos, term, reverse in alternatives:
        key = fold(term)
        if key in seen:
            continue
        seen.add(key)
        subtitle = " \u00b7 ".join(part for part in (pos, ", ".join(reverse[:3])) if part)
        rows.append({"type": "translate", "name": term, "subtitle": subtitle, "copy": term, "alt": True})
        if len(rows) >= limit:
            break
    return rows


def translate_rows(text, source, targets, autocorrect=True, alternatives=6):
    results = run_translations(text, source, targets)
    corrected = find_correction(text, results) if autocorrect else None
    if corrected:
        return [
            {"type": "spelling", "name": 'Did you mean "%s"?' % corrected, "subtitle": "was: %s" % text, "copy": corrected},
            {"type": "keep", "name": 'Translate "%s" as typed' % text, "subtitle": "", "copy": text},
        ]
    groups = []
    for item in results:
        if not item["text"]:
            continue
        detected = item["detected"] or (source if source != "auto" else "")
        origin = detected.upper() if detected else "AUTO"
        subtitle = "%s \u2192 %s" % (origin, item["target"].upper())
        pronunciation = item["pronunciation"]
        if pronunciation and fold(pronunciation) not in (fold(item["text"]), fold(text)):
            subtitle += " \u00b7 %s" % pronunciation
        same = bool(detected) and base_language(detected) == base_language(item["target"])
        rows = [{"type": "translate", "name": item["text"], "subtitle": subtitle, "copy": item["text"], "alt": False}]
        if not same:
            rows += alternative_rows(item["text"], item["alternatives"], alternatives)
        groups.append((same, rows))
    groups.sort(key=lambda group: group[0])
    return [row for _, rows in groups for row in rows]


def command_calc(args):
    query = " ".join(args).strip()
    row = try_time(query) or try_calc(query)
    return {"rows": [row] if row else []}


def command_translate(args):
    targets_arg, source, autocorrect = args[0], args[1], args[2] != "0"
    limit = int(args[3]) if args[3].isdigit() else 6
    text = " ".join(args[4:]).strip()
    targets = [normalize_language(code) for code in targets_arg.split(",") if code.strip()]
    if not text or not targets:
        return {"rows": []}
    try:
        return {"rows": translate_rows(text, normalize_language(source), targets, autocorrect, limit)}
    except Exception as error:
        return {"rows": [], "error": "Translation failed: %s" % error}


def main():
    command = sys.argv[1] if len(sys.argv) > 1 else ""
    args = sys.argv[2:]
    if command == "calc":
        output = command_calc(args)
    elif command == "translate" and len(args) >= 5:
        output = command_translate(args)
    else:
        output = {"rows": []}
    sys.stdout.write(json.dumps(output, ensure_ascii=False))


if __name__ == "__main__":
    main()
