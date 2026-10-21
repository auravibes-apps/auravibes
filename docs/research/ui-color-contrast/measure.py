"""Reproduce screenshot measurements. Requires Pillow; no network requests.

python3 docs/research/ui-color-contrast/measure.py build/color_research/2026-10-08
Matrices: https://bottosson.github.io/posts/oklab/ (2021-01-25 update).
"""

import csv
import hashlib
import json
import math
import sys
from collections import Counter
from pathlib import Path

from PIL import Image, ImageDraw, ImageFont

HERE = Path(__file__).resolve().parent


def linearize(u):
    return u / 12.92 if u <= 0.04045 else ((u + 0.055) / 1.055) ** 2.4


def rgb_lab(rgb):
    r, g, b = (linearize(v / 255) for v in rgb)
    l = (0.4122214708 * r + 0.5363325363 * g + 0.0514459929 * b) ** (1 / 3)
    m = (0.2119034982 * r + 0.6806995451 * g + 0.1073969566 * b) ** (1 / 3)
    s = (0.0883024619 * r + 0.2817188376 * g + 0.6299787005 * b) ** (1 / 3)
    return (
        0.2104542553 * l + 0.7936177850 * m - 0.0040720468 * s,
        1.9779984951 * l - 2.4285922050 * m + 0.4505937099 * s,
        0.0259040371 * l + 0.7827717662 * m - 0.8086757660 * s,
    )


def lab_linear(l, a, b):
    x = (l + 0.3963377774 * a + 0.2158037573 * b) ** 3
    y = (l - 0.1055613458 * a - 0.0638541728 * b) ** 3
    z = (l - 0.0894841775 * a - 1.2914855480 * b) ** 3
    return (
        4.0767416621 * x - 3.3077115913 * y + 0.2309699292 * z,
        -1.2684380046 * x + 2.6097574011 * y - 0.3413193965 * z,
        -0.0041960863 * x - 0.7034186147 * y + 1.7076147010 * z,
    )


def lch_linear(l, c, h):
    return lab_linear(l, c * math.cos(math.radians(h)), c * math.sin(math.radians(h)))


def luminance(rgb):
    return sum(w * linearize(v / 255) for w, v in zip((0.2126, 0.7152, 0.0722), rgb))


def contrast(a, b):
    lo, hi = sorted((luminance(a), luminance(b)))
    return (hi + 0.05) / (lo + 0.05)


def cmax(l, h):
    lo, hi = 0.0, 0.5
    for _ in range(60):
        mid = (lo + hi) / 2
        if all(0 <= x <= 1 for x in lch_linear(l, mid, h)):
            lo = mid
        else:
            hi = mid
    return lo


def color_record(rgb):
    l, a, b = rgb_lab(rgb)
    c = math.hypot(a, b)
    return dict(rgb=list(rgb), hex="#" + "".join(f"{x:02X}" for x in rgb),
                L=l, C=c, h=None if c < 0.001 else math.degrees(math.atan2(b, a)) % 360,
                a=a, b=b, Y=luminance(rgb))


def selected(pixel, method):
    if method == "all":
        return True
    if method == "dark":
        return max(pixel) < 140
    if method == "light":
        return min(pixel) >= 150
    if method == "mid":
        return min(pixel) >= 70 and max(pixel) < 220
    raise ValueError(method)


def measure(root):
    source = json.loads((HERE / "samples-input.json").read_text())
    source["method"] = "Mode of opaque RGB pixels in recorded ROI, filtered for glyph core where specified. Untagged source assumed sRGB."
    rows, pairs = [], []
    for shot in source["shots"]:
        path = root / shot["file"]
        shot["sha256"] = hashlib.sha256(path.read_bytes()).hexdigest()
        assert shot["sha256"] == shot["expected_sha256"], "Source bytes differ from recorded observation"
        with Image.open(path) as im:
            assert not im.info.get("icc_profile"), "ICC source requires explicit conversion"
            shot["dimensions"] = list(im.size)
            assert shot["dimensions"] == shot["expected_dimensions"]
            for patch in shot["patches"]:
                pixels = list(im.convert("RGBA").crop(patch["roi"]).get_flattened_data())
                assert all(p[3] == 255 for p in pixels), "ROI must be opaque"
                candidates = [p[:3] for p in pixels if selected(p[:3], patch["selection"])]
                assert candidates, (shot["key"], patch["id"], "empty foreground filter")
                counts = Counter(candidates)
                rgb, count = counts.most_common(1)[0]
                patch.update(color_record(rgb))
                ls = [rgb_lab(p)[0] for p in candidates]
                patch.update(pixel_count=len(pixels), selected_count=len(candidates),
                             mode_fraction=count / len(candidates), L_range=[min(ls), max(ls)],
                             top_rgb=[dict(rgb=list(p), count=n) for p, n in counts.most_common(3)])
                rows.append(dict(shot=shot["key"], role=patch["id"], **patch))
        lookup = {p["id"]: p for p in shot["patches"]}
        for pair in shot["pairs"]:
            fg, bg = lookup[pair["foreground"]], lookup[pair["background"]]
            pair.update(ratio=contrast(fg["rgb"], bg["rgb"]),
                        delta_L=fg["L"] - bg["L"], delta_C=fg["C"] - bg["C"],
                        delta_E=math.sqrt(sum((fg[k] - bg[k]) ** 2 for k in ("L", "a", "b"))))
            pairs.append(dict(shot=shot["key"], **pair))
    (HERE / "measurements.json").write_text(json.dumps(source, indent=2) + "\n")
    fields = ["shot", "role", "theme", "hex", "L", "C", "h", "Y", "roi", "mode_fraction", "L_range", "notes"]
    with (HERE / "samples.csv").open("w", newline="") as out:
        writer = csv.DictWriter(out, fields, extrasaction="ignore", lineterminator="\n")
        writer.writeheader()
        writer.writerows(rows)
    with (HERE / "pairs.csv").open("w", newline="") as out:
        writer = csv.DictWriter(out, ["shot", "foreground", "background", "kind", "ratio", "delta_L", "delta_C", "delta_E"], lineterminator="\n")
        writer.writeheader()
        writer.writerows(pairs)
    tables = []
    for shot in source["shots"]:
        tables += [f"## {shot['title']}", "", "| Role | Theme | RGB | L | C | h |", "| --- | --- | --- | ---: | ---: | ---: |"]
        for p in shot["patches"]:
            hue = "—" if p["h"] is None else f"{p['h']:.1f}"
            tables.append(f"| {p['id']} | {p['theme']} | `{p['hex']}` | {p['L']:.4f} | {p['C']:.4f} | {hue} |")
        tables += ["", "| Pair: first relative to second | Kind | WCAG ratio | ΔL | ΔC | ΔEOK |", "| --- | --- | ---: | ---: | ---: | ---: |"]
        for p in shot["pairs"]:
            tables.append(f"| {p['foreground']} / {p['background']} | {p['kind']} | {p['ratio']:.2f} | {p['delta_L']:+.4f} | {p['delta_C']:+.4f} | {p['delta_E']:.4f} |")
        tables.append("")
    (HERE / "measurement-tables.md").write_text("\n".join(tables))
    swatches(source)
    return rows, pairs


def swatches(source):
    canvas = Image.new("RGB", (1260, 1390), "#fafafa")
    draw = ImageDraw.Draw(canvas)
    title_font = ImageFont.load_default(size=24)
    heading_font = ImageFont.load_default(size=17)
    label_font = ImageFont.load_default(size=12)
    draw.text((36, 20), "Popular UI palettes: measured screenshot interiors", fill="#202530", font=title_font)
    draw.text((36, 56), "OKLCH L/C. Role samples; likes do not establish preference. Observed 2026-10-08.", fill="#202530", font=label_font)
    for i, shot in enumerate(source["shots"]):
        x, y = 36 + (i % 2) * 620, 100 + (i // 2) * 250
        popularity = "same shot" if shot["kind"] == "alternate" else shot["displayed_likes"] + " likes"
        draw.text((x, y-18), f"{shot['key']} / {popularity} / {shot['kind']}", fill="#202530", font=heading_font)
        patches = [p for p in shot["patches"] if p["selection"] == "all"][:8]
        for j, p in enumerate(patches):
            sx, sy = x + (j % 4) * 145, y + 15 + (j // 4) * 100
            draw.rounded_rectangle((sx, sy, sx+132, sy+46), radius=6, fill=p["hex"], outline="#aaaaaa")
            draw.text((sx, sy+53), p["id"], fill="#202530", font=label_font)
            draw.text((sx, sy+71), f"L {p['L']:.3f} / C {p['C']:.3f}", fill="#202530", font=label_font)
    canvas.save(HERE / "palette-swatches.png")


def math_checks():
    assert contrast((0, 0, 0), (255, 255, 255)) == 21
    assert abs(rgb_lab((255, 0, 0))[0] - 0.627955) < 0.000001
    for rgb in [(0, 0, 0), (255, 255, 255), (128, 128, 128), (255, 0, 0), (0, 255, 0), (0, 0, 255)]:
        recovered = lab_linear(*rgb_lab(rgb))
        assert max(abs(a - linearize(b / 255)) for a, b in zip(recovered, rgb)) < 0.000001
    counterexamples = []
    for h in [30, 90, 140, 200, 270, 330]:
        rgb = lch_linear(0.57, 0.08, h)
        assert all(0 <= x <= 1 for x in rgb)
        y = sum(w * x for w, x in zip((0.2126, 0.7152, 0.0722), rgb))
        counterexamples.append(dict(h=h, Y=y, contrast_white=1.05 / (y + 0.05), Cmax_at_L_065=cmax(0.65, h)))
    ceilings = []
    for l in [0.4, 0.5, 0.6, 0.65, 0.78, 0.85, 0.9, 0.95]:
        c, h = min((cmax(l, h), h) for h in range(360))
        ceilings.append(dict(L=l, minimum_Cmax=c, limiting_hue_sample=h))
    data = dict(equal_LC_counterexamples=counterexamples, hue_grid_step_degrees=1,
                sampled_srgb_chroma_ceilings=ceilings)
    (HERE / "computed-examples.json").write_text(json.dumps(data, indent=2) + "\n")


if __name__ == "__main__":
    math_checks()
    rows, pairs = measure(Path(sys.argv[1]))
    print(f"Math identities checked; measured {len(rows)} patches and {len(pairs)} pairs.")
    for p in rows:
        print(f"{p['shot']:8} {p['role']:24} {p['hex']} L={p['L']:.4f} C={p['C']:.4f} mode={p['mode_fraction']:.2f}")
