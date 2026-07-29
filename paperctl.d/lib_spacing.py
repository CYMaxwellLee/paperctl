#!/usr/bin/env python3
"""Measure vertical spacing in a compiled PDF and report where it was shortened.

A PDF stores no LaTeX commands, only the position of every glyph, so a \\vspace
cannot be read back out of it. Its effect can. LaTeX takes every structural gap
from the document class, which makes gaps of the same kind identical throughout
a paper: every \\subsection sits the same distance below the text above it. A
gap that falls short of others of its own kind was shortened by hand.

Two gaps are the same kind when the same kinds of line sit on either side of
them, so lines are first sorted by height. Section headings, subsection
headings, body text and bibliography entries are each set at their own size,
which the PDF records, and that is enough to tell a gap above a heading from a
gap between two paragraphs.

What this cannot do: a gap next to a float depends on which of \\textfloatsep
and the heading's own skip is larger, so two gaps of nominally the same kind
can differ for reasons that have nothing to do with \\vspace. Those buckets are
reported with their spread and left for a reader to judge. Pass --tex and the
\\vspace calls in the source are listed alongside as ground truth.
"""

import argparse
import collections
import json
import re
import statistics
import subprocess
import sys
import tempfile
from pathlib import Path

WORD_RE = re.compile(
    r'<word xMin="([\d.]+)" yMin="([\d.]+)" xMax="([\d.]+)" yMax="([\d.]+)">([^<]*)</word>'
)
PAGE_RE = re.compile(r'<page width="([\d.]+)" height="([\d.]+)">(.*?)</page>', re.S)
VSPACE_RE = re.compile(r"\\vspace\*?\s*\{\s*(-?[\d.]+)\s*(em|ex|pt|mm|cm|in|\\[a-z]+)?")

# Lines whose heights differ by less than this are set at the same size.
HEIGHT_TOL = 0.15
# A gap this far below its own kind was shortened. 2pt is 0.2em at 10pt, the
# smallest \vspace anyone writes on purpose.
MIN_DELTA_PT = 2.0
# Above this a gap is a column break, not a structural gap.
MAX_STRUCTURAL_PT = 200.0
# Buckets smaller than this have no reliable reference to compare against.
MIN_BUCKET = 3
# The class default is the value a kind of gap takes most often. It only counts
# as a reference when it holds this share of the bucket, which keeps kinds that
# the line sizes failed to separate -- body>body mixes float separation with
# bibliography and display equations -- from being measured against a value
# that belongs to only one of them.
MODE_COVERAGE = 0.35
# Width of the bins the mode is taken over, to absorb rendering jitter.
MODE_BIN_PT = 0.5

UNITS_PT = {"pt": 1.0, "mm": 2.845, "cm": 28.45, "in": 72.27}

LAYOUT_PARAMS = [
    "textheight", "textwidth", "columnsep", "columnwidth", "topmargin",
    "oddsidemargin", "evensidemargin", "headsep", "footskip", "baselinestretch",
    "parskip",
]
REDEFINE_RE = re.compile(
    r"\\(?:setlength|addtolength)\s*\{\s*\\(?:" + "|".join(LAYOUT_PARAMS) + r")\b"
    r"|\\(?:" + "|".join(LAYOUT_PARAMS) + r")\s*="
    r"|\\renewcommand\s*\{?\s*\\baselinestretch\b"
    r"|\\(?:linespread|setstretch)\s*\{"
)


def read_lines(pdf_path, columns="auto"):
    """Return [(page, column, y, height, text)] in reading order."""
    with tempfile.NamedTemporaryFile(suffix=".xml", delete=False) as tmp:
        out = tmp.name
    try:
        subprocess.run(["pdftotext", "-bbox", str(pdf_path), out],
                       check=True, capture_output=True)
        xml = Path(out).read_text(encoding="utf-8", errors="replace")
    finally:
        Path(out).unlink(missing_ok=True)

    pages = PAGE_RE.findall(xml)
    if not pages:
        raise SystemExit("no pages found -- is this a text PDF?")
    width = float(pages[0][0])

    if columns == "auto":
        left = right = 0
        for _, _, body in pages:
            for xm, *_ in WORD_RE.findall(body):
                if float(xm) < width / 2:
                    left += 1
                else:
                    right += 1
        ncol = 2 if (left + right) and min(left, right) / (left + right) > 0.2 else 1
    else:
        ncol = int(columns)

    bands = [(0, width)] if ncol == 1 else [(0, width / 2), (width / 2, width)]
    names = ["-"] if ncol == 1 else ["L", "R"]

    # One visual line does not sit at one y. Subscripts, inline math and mixed
    # sizes shift a word by a few tenths of a point, and rounding to a fixed
    # place splits such a line into several. On a page carrying much math those
    # fragments outnumber real lines and become the apparent leading. So words
    # are grouped by proximity instead, with a tolerance well under any real
    # leading and well over the shifts within a line.
    heights = [float(yM) - float(ym)
               for _, _, body in pages
               for _, ym, _, yM, _ in WORD_RE.findall(body)]
    tol = 0.5 * statistics.median(heights) if heights else 2.0

    lines = []
    for pageno, (_, _, body) in enumerate(pages, 1):
        words = WORD_RE.findall(body)
        for name, (lo, hi) in zip(names, bands):
            here = [(float(ym), float(yM) - float(ym), txt)
                    for xm, ym, _, yM, txt in words if lo <= float(xm) < hi]
            here.sort(key=lambda w: w[0])
            group = []
            for word in here:
                if group and word[0] - group[0][0] > tol:
                    lines.append((pageno, name, group[0][0],
                                  statistics.median(h for _, h, _ in group),
                                  " ".join(t for _, _, t in group)))
                    group = []
                group.append(word)
            if group:
                lines.append((pageno, name, group[0][0],
                              statistics.median(h for _, h, _ in group),
                              " ".join(t for _, _, t in group)))
    return lines, ncol


def classify_heights(lines):
    """Name each distinct line size. The commonest is the body."""
    counts = collections.Counter(h for *_, h, _ in lines)
    groups = []
    for height in sorted(counts, reverse=True):
        for g in groups:
            if abs(g["height"] - height) <= HEIGHT_TOL:
                g["count"] += counts[height]
                g["members"].add(height)
                break
        else:
            groups.append({"height": height, "count": counts[height],
                           "members": {height}})

    body = max(groups, key=lambda g: g["count"])
    names = {}
    bigger = sorted((g for g in groups if g["height"] > body["height"] + HEIGHT_TOL),
                    key=lambda g: -g["height"])
    for rank, g in enumerate(bigger, 1):
        names[id(g)] = f"head{rank}"
    names[id(body)] = "body"
    for g in groups:
        if id(g) not in names:
            names[id(g)] = f"small{g['height']:.1f}"

    lookup = {}
    for g in groups:
        for h in g["members"]:
            lookup[h] = names[id(g)]
    return lookup, {names[id(g)]: {"height": g["height"], "lines": g["count"]}
                    for g in groups}


def analyse(pdf_path, fontsize=10.0, columns="auto"):
    lines, ncol = read_lines(pdf_path, columns)
    kind_of, sizes = classify_heights(lines)

    gaps = []
    for i in range(1, len(lines)):
        p, c, y, h, _ = lines[i]
        pp, cc, yy, hh, tt = lines[i - 1]
        if (p, c) != (pp, cc):
            continue
        gaps.append({"gap": round(y - yy, 2), "page": p, "column": c,
                     "above": kind_of[hh], "below": kind_of[h],
                     "text_above": tt[:58], "text_below": lines[i][4][:40]})

    leading = collections.Counter(g["gap"] for g in gaps).most_common(1)[0][0]

    buckets = collections.defaultdict(list)
    for g in gaps:
        if leading + 1.0 < g["gap"] < MAX_STRUCTURAL_PT:
            buckets[(g["above"], g["below"])].append(g)

    report, findings = [], []
    for (above, below), members in sorted(buckets.items(),
                                          key=lambda kv: -len(kv[1])):
        values = [m["gap"] for m in members]
        name = f"{above}>{below}"

        # The reference is the value this kind of gap takes most often, not the
        # largest one. Taking the largest treats every smaller instance as
        # shortened, which is wrong whenever one bucket holds more than one
        # kind of gap.
        bins = collections.Counter(round(v / MODE_BIN_PT) for v in values)
        top_bin, top_count = bins.most_common(1)[0]
        coverage = top_count / len(values)
        in_mode = [v for v in values if round(v / MODE_BIN_PT) == top_bin]
        ref = round(statistics.median(in_mode), 2)
        # Only gaps against a heading are judged. LaTeX spaces headings from one
        # setting, so every instance is comparable, and a heading is where
        # \vspace is normally applied. A gap between two body lines carries no
        # such guarantee: float separation, display equations and bibliography
        # entries all land in that bucket and line size cannot separate them, so
        # a value low against the bucket says nothing about the class default.
        structural = above.startswith("head") or below.startswith("head")
        usable = (structural and len(members) >= MIN_BUCKET
                  and top_count >= 2 and coverage >= MODE_COVERAGE)

        hits = []
        if usable:
            for m in members:
                delta = ref - m["gap"]
                if delta >= MIN_DELTA_PT:
                    hits.append(dict(m, reference_pt=ref,
                                     delta_pt=round(delta, 2),
                                     delta_em=round(delta / fontsize, 2),
                                     bucket=name))
        report.append({"bucket": name, "instances": len(members),
                       "reference_pt": ref if usable else None,
                       "at_reference": top_count, "coverage": round(coverage, 2),
                       "min_pt": min(values), "max_pt": max(values),
                       "spread_pt": round(max(values) - min(values), 2),
                       "shortened": len(hits), "usable": usable})
        findings += hits

    findings.sort(key=lambda h: -h["delta_pt"])
    return {
        "pdf": str(pdf_path), "columns": ncol, "body_leading_pt": leading,
        "fontsize_pt": fontsize, "leading_ratio": round(leading / fontsize, 3),
        "line_sizes": sizes, "buckets": report, "findings": findings,
    }


def scan_source(tex_paths):
    """List the \\vspace calls and any redefinition of the text block."""
    vspaces, redefs = [], []
    for path in tex_paths:
        try:
            text = Path(path).read_text(encoding="utf-8", errors="replace")
        except OSError:
            continue
        for lineno, raw in enumerate(text.splitlines(), 1):
            if raw.lstrip().startswith("%"):
                continue
            code = raw.split("%")[0]
            for amount, unit in VSPACE_RE.findall(code):
                vspaces.append({"file": str(path), "line": lineno,
                                "amount": float(amount), "unit": unit or "pt"})
            if REDEFINE_RE.search(code):
                redefs.append({"file": str(path), "line": lineno,
                               "text": code.strip()[:90]})
    return vspaces, redefs


def vspace_pt(v, fontsize):
    if v["unit"] in ("em",):
        return v["amount"] * fontsize
    if v["unit"] in ("ex",):
        return v["amount"] * fontsize * 0.45
    if v["unit"].startswith("\\"):
        return None
    return v["amount"] * UNITS_PT.get(v["unit"], 1.0)


def main():
    ap = argparse.ArgumentParser(description=__doc__,
                                 formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("pdf")
    ap.add_argument("--fontsize", type=float, default=10.0,
                    help="body font size in pt, for the em column (default 10)")
    ap.add_argument("--columns", default="auto")
    ap.add_argument("--tex", action="append", default=[],
                    help="source file, for ground truth and text-block checks")
    ap.add_argument("--all-buckets", action="store_true",
                    help="show buckets too small to carry a reference")
    ap.add_argument("--json", action="store_true")
    args = ap.parse_args()

    result = analyse(args.pdf, args.fontsize, args.columns)
    vspaces, redefs = scan_source(args.tex)
    result["source_vspaces"] = vspaces
    result["layout_redefinitions"] = redefs

    if args.json:
        json.dump(result, sys.stdout, indent=2)
        print()
        return 0

    fs = result["fontsize_pt"]
    print(f"  body leading      {result['body_leading_pt']} pt   "
          f"({result['columns']}-column, ratio {result['leading_ratio']} at {fs:.0f}pt)")
    if not 1.0 <= result["leading_ratio"] <= 1.35:
        print("  ⚠️  leading/fontsize sits outside the usual 1.0-1.35 range. Either "
              "--fontsize is wrong or line spacing was altered.")
    sizes = ", ".join(f"{k} {v['height']:.2f}pt x{v['lines']}"
                      for k, v in sorted(result["line_sizes"].items(),
                                         key=lambda kv: -kv[1]["height"]))
    print(f"  line sizes        {sizes}")
    print()

    findings = result["findings"]
    if not findings:
        print("  ✅ every gap matches others of its kind. Nothing shortened unevenly.")
    else:
        print(f"  Shortened relative to its own kind ({len(findings)} places)")
        print(f"  {'PAGE':<7}{'KIND':<14}{'GAP':>8}{'OWN KIND':>10}{'SHORT BY':>11}"
              f"{'':>8}  LINE ABOVE")
        for h in findings:
            print(f"  p{h['page']}{h['column']:<5}{h['bucket']:<14}{h['gap']:>8.2f}"
                  f"{h['reference_pt']:>10.2f}{h['delta_pt']:>9.2f} pt"
                  f"{h['delta_em']:>7.2f}em  {h['text_above']}")
    print()

    print("  Every kind of gap, and whether it still sits at the class default")
    print(f"  {'KIND':<15}{'FOUND':>7}{'DEFAULT':>10}{'AT IT':>7}{'RANGE':>16}"
          f"{'SHORTENED':>11}")
    unresolved = []
    for b in result["buckets"]:
        rng = f"{b['min_pt']:.1f}-{b['max_pt']:.1f}"
        if not b["usable"]:
            unresolved.append(b)
            if not args.all_buckets:
                continue
            print(f"  {b['bucket']:<15}{b['instances']:>7}{'--':>10}{'--':>7}"
                  f"{rng:>16}{'--':>11}   no dominant value")
            continue
        note = "" if b["shortened"] else "   untouched"
        print(f"  {b['bucket']:<15}{b['instances']:>7}{b['reference_pt']:>10.2f}"
              f"{b['at_reference']:>7}{rng:>16}{b['shortened']:>11}{note}")
    if unresolved and not args.all_buckets:
        print()
        print(f"  {len(unresolved)} kind(s) were not judged, body>body among them. "
              f"Only gaps")
        print("  against a heading are comparable: line size cannot tell float "
              "separation")
        print("  from display equations from bibliography entries, so a low value "
              "there")
        print("  carries no meaning. --all-buckets lists them with their range.")
    print()

    if args.tex:
        total = 0.0
        unknown = 0
        for v in vspaces:
            pt = vspace_pt(v, fs)
            if pt is None:
                unknown += 1
            elif pt < 0:
                total += pt
        print(f"  Source: {len(vspaces)} \\vspace call(s) across {len(args.tex)} file(s)")
        for v in vspaces:
            pt = vspace_pt(v, fs)
            shown = f"{pt:+.1f} pt" if pt is not None else "unconvertible"
            print(f"     {Path(v['file']).name}:{v['line']:<6} "
                  f"\\vspace{{{v['amount']:g}{v['unit']}}}   {shown}")
        if total:
            print(f"          negative ones total {total:.1f} pt = "
                  f"{abs(total) / result['body_leading_pt']:.1f} lines of body text")
        if unknown:
            print(f"          {unknown} in units this cannot convert (\\baselineskip etc.)")
        if not redefs:
            print("  ✅ Text block: \\textheight / \\columnsep / \\baselinestretch "
                  "all left at class defaults")
        else:
            print(f"  ⛔ Text block redefined in {len(redefs)} place(s). AAAI, CVPR "
                  f"and ICML forbid this:")
            for r in redefs:
                print(f"     {Path(r['file']).name}:{r['line']}  {r['text']}")
    else:
        print("  Source not read. Pass --tex for the \\vspace calls behind these "
              "numbers and a text-block check.")

    print()
    print("  Read with care: a gap next to a float is set by whichever of "
          "\\textfloatsep and")
    print("  the heading's own skip is larger, so a wide spread in one kind need "
          "not mean")
    print("  anything was shortened. A kind shortened everywhere keeps no untouched "
          "member to")
    print("  compare against and so reads as clean.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
