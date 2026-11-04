"""Screenshot slide 1 of a rendered preview deck and warn if the figure runs
outside the frame body. Exit 10 = rendered but overflowing (warning printed)."""
import sys

from playwright.sync_api import Error, sync_playwright

html, png = sys.argv[1], sys.argv[2]
with sync_playwright() as pw:
    try:
        browser = pw.chromium.launch()
    except Error as e:
        sys.exit(f"preview.py: cannot start Chromium ({e.message.splitlines()[0]}).\n"
                 "  Install it with: uv run --no-project --with playwright playwright install chromium\n"
                 "  or set PLAYWRIGHT_VERSION to match a browser you already have.")
    page = browser.new_page(viewport={"width": 1280, "height": 720}, device_scale_factor=1)
    page.goto("file://" + html, wait_until="networkidle")
    page.wait_for_timeout(500)
    m = page.evaluate("""() => {
        const s = document.querySelector('.reveal .slides section.present');
        const img = s.querySelector('img');
        const sr = s.getBoundingClientRect(), ir = img.getBoundingClientRect();
        const pad = parseFloat(getComputedStyle(s).paddingBottom);
        const padX = parseFloat(getComputedStyle(s).paddingLeft);
        return {w: ir.width, h: ir.height, nw: img.naturalWidth, nh: img.naturalHeight,
                bottom: ir.bottom, limit: sr.bottom - pad, maxw: sr.width - 2 * padX};
    }""")
    page.screenshot(path=png)
    browser.close()

print(f"figure: {m['w']:.0f} x {m['h']:.0f} px on the slide "
      f"(frame body {m['maxw']:.0f} px wide, ends at y={m['limit']:.0f})")
warn = []
if m["bottom"] > m["limit"] + 1:
    warn.append(f"runs {m['bottom'] - m['limit']:.0f}px into the footline")
if m["w"] + 1 < m["nw"]:
    warn.append(f"was scaled down from {m['nw']}px wide, so its text shrank too")
if warn:
    print("WARNING: figure overflows the frame body: " + "; ".join(warn) + ". Shrink figsize.", file=sys.stderr)
    sys.exit(10)
