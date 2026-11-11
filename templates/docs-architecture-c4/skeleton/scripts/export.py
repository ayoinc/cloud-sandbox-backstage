#!/usr/bin/env -S uv run
# /// script
# requires-python = ">=3.11"
# dependencies = ["pyyaml>=6", "python-docx>=1.1"]
# ///
"""Exports each design document to a branded PDF and Word file in out/.

    uv run scripts/export.py                every document
    uv run scripts/export.py --sync-brand   also write the primary colour into
                                            docs/diagrams/c4.d2

Needs pandoc, typst, d2 and rsvg-convert on the PATH. The organisation name,
logo and primary colour come from brand.yaml, or from the portal named there.
"""
from __future__ import annotations

import argparse
import datetime
import json
import re
import shutil
import subprocess
import sys
import urllib.parse
import urllib.request
from pathlib import Path

import yaml
from docx import Document
from docx.enum.text import WD_ALIGN_PARAGRAPH, WD_BREAK
from docx.oxml import OxmlElement
from docx.oxml.ns import qn
from docx.shared import Mm, Pt, RGBColor

ROOT = Path(__file__).resolve().parent.parent
DOCS = ROOT / "docs"
OUT = ROOT / "out"
BUILD = OUT / ".build"
C4 = DOCS / "diagrams" / "c4.d2"
HEX = re.compile(r"^#[0-9a-fA-F]{6}$")
DEFAULT_COLOUR = "#3f4a5a"
# The primary colour of each of the portal's theme presets, for an
# organisation whose owner chose a preset and no colour of their own.
PRESET_COLOURS = {
    "neutral": "#3f4a5a",
    "harbour": "#005399",
    "forest": "#1f6b45",
    "plum": "#6a2c91",
    "ember": "#a8401c",
    "civic": "#1d70b8",
    "baseline": "#6750a4",
}
LOGO_TYPES = {"image/png": ".png", "image/jpeg": ".jpg", "image/svg+xml": ".svg"}


def note(message: str) -> None:
    print(message, file=sys.stderr)


def run(*command: str | Path) -> None:
    """Runs a tool, and stops with its own words if it fails."""
    tool = str(command[0])
    if shutil.which(tool) is None:
        sys.exit(f"{tool} is not on the PATH. See README.md, 'Export it'.")
    result = subprocess.run([str(part) for part in command], capture_output=True, text=True)
    if result.returncode != 0:
        sys.exit(f"{tool} failed:\n{result.stderr.strip() or result.stdout.strip()}")


def fetch(url: str) -> tuple[bytes, str]:
    request = urllib.request.Request(url, headers={"user-agent": "design-export"})
    with urllib.request.urlopen(request, timeout=15) as response:
        return response.read(), response.headers.get_content_type()


def portal_brand(portal_url: str) -> dict:
    """What the organisation's owner set: name, colour and logo, if any.

    `portal_url` is the organisation's address in the portal, such as
    https://portal.example.com/o/acme.
    """
    address = urllib.parse.urlsplit(portal_url)
    match = re.match(r"/o/([a-z0-9][a-z0-9-]*)/?$", address.path)
    if not match:
        raise ValueError("portal_url must be an organisation's address, ending /o/<name>")
    settings_url = f"{address.scheme}://{address.netloc}/api/organisations/{match[1]}"
    body, _ = fetch(settings_url)
    settings = json.loads(body)
    brand: dict = {}
    if settings.get("name"):
        brand["organisation"] = settings["name"]
    colour = settings.get("primaryColor") or PRESET_COLOURS.get(settings.get("themePreset") or "")
    if colour:
        brand["primary_colour"] = colour
    if settings.get("logoFullUrl"):
        data, content_type = fetch(urllib.parse.urljoin(settings_url, settings["logoFullUrl"]))
        extension = LOGO_TYPES.get(content_type)
        if extension:
            logo = BUILD / f"portal-logo{extension}"
            logo.write_bytes(data)
            brand["logo"] = logo
        else:
            note(f"The portal's logo is {content_type}, which the exports cannot place. Skipping it.")
    return brand


def load_brand() -> dict:
    stored = yaml.safe_load((ROOT / "brand.yaml").read_text(encoding="utf-8")) or {}
    brand = {
        "organisation": str(stored.get("organisation") or ""),
        "primary_colour": str(stored.get("primary_colour") or DEFAULT_COLOUR),
        "classification": str(stored.get("classification") or ""),
        "logo": (ROOT / stored["logo"]) if stored.get("logo") else None,
    }
    portal_url = str(stored.get("portal_url") or "").strip()
    if portal_url:
        try:
            brand.update(portal_brand(portal_url))
            note(f"Branding read from {portal_url}")
        except (OSError, ValueError) as error:
            # A portal that is down must not stop a document being exported.
            note(f"Could not read branding from {portal_url} ({error}). Using brand.yaml.")
    if not HEX.match(brand["primary_colour"]):
        sys.exit(f"primary_colour must be a six-digit hex colour, not {brand['primary_colour']!r}.")
    if brand["logo"] and not Path(brand["logo"]).is_file():
        sys.exit(f"The logo {brand['logo']} does not exist.")
    if brand["logo"] and Path(brand["logo"]).suffix.lower() == ".svg":
        # Word cannot place an SVG reliably, so both formats get a PNG.
        png = BUILD / "logo.png"
        run("rsvg-convert", "--height", "240", brand["logo"], "--output", png)
        brand["logo"] = png
    return brand


def sync_brand(colour: str) -> None:
    source = C4.read_text(encoding="utf-8")
    updated, count = re.subn(r'(?m)^(\s*brand:\s*)"#[0-9a-fA-F]{6}"', rf'\g<1>"{colour}"', source, count=1)
    if count != 1:
        sys.exit(f"{C4.relative_to(ROOT)} has no `brand: \"#rrggbb\"` line to update.")
    if updated != source:
        C4.write_text(updated, encoding="utf-8")
        note(f"Primary colour {colour} written to {C4.relative_to(ROOT)}")


def documents() -> list[Path]:
    """The pages listed in mkdocs.yml, apart from the overview."""
    config = yaml.safe_load((ROOT / "mkdocs.yml").read_text(encoding="utf-8"))
    pages = [next(iter(entry.values())) for entry in config["nav"]]
    return [DOCS / page for page in pages if page != "index.md"]


def render_diagrams(markdown: str, page: Path, colour: str) -> str:
    """Replaces each `![..](x.d2)` with a PNG drawn in the brand colour."""

    def render(match: re.Match) -> str:
        source = (page.parent / match.group(2)).resolve()
        work = BUILD / "diagrams"
        work.mkdir(parents=True, exist_ok=True)
        # Drawn from a copy, so the colour applies without touching the repository.
        for file in source.parent.glob("*.d2"):
            text = file.read_text(encoding="utf-8")
            if file.name == C4.name:
                text = re.sub(r'(?m)^(\s*brand:\s*)"#[0-9a-fA-F]{6}"', rf'\g<1>"{colour}"', text, count=1)
            (work / file.name).write_text(text, encoding="utf-8")
        svg = work / f"{source.stem}.svg"
        png = work / f"{source.stem}.png"
        run("d2", work / source.name, svg)
        run("rsvg-convert", "--zoom", "2", svg, "--output", png)
        return f"![{match.group(1)}]({png})"

    return re.sub(r"!\[([^\]]*)\]\(([^)\s]+\.d2)\)", render, markdown)


def prepare(page: Path, colour: str) -> tuple[str, Path]:
    """The page's title, and its Markdown ready for pandoc."""
    markdown = page.read_text(encoding="utf-8")
    heading = re.match(r"#\s+(.+)\n", markdown)
    if not heading:
        sys.exit(f"{page.relative_to(ROOT)} must start with a `# Title` line.")
    markdown = markdown[heading.end():]
    markdown = render_diagrams(markdown, page, colour)
    # Links to the other pages mean nothing in a standalone document.
    markdown = re.sub(r"\[([^\]]+)\]\((?!https?:|#|/)[^)#]*\.md(#[^)]*)?\)", r"\1", markdown)
    prepared = BUILD / f"{page.stem}.md"
    prepared.write_text(markdown, encoding="utf-8")
    return heading.group(1).strip(), prepared


def typst_string(text: str) -> str:
    return '"' + text.replace("\\", "\\\\").replace('"', '\\"') + '"'


def export_pdf(title: str, system: str, prepared: Path, brand: dict, target: Path) -> None:
    colour = brand["primary_colour"]
    footer = " · ".join(part for part in (brand["organisation"], brand["classification"]) if part)
    header = BUILD / f"{prepared.stem}-header.typ"
    header.write_text(
        f"""
#let brand = rgb({typst_string(colour)})
#set page(
  header: context {{ if counter(page).get().first() > 1 [
    #set text(size: 9pt, fill: luma(90))
    #{typst_string(system)} #h(1fr) #{typst_string(title)}
    #v(-6pt) #line(length: 100%, stroke: 0.6pt + brand)
  ] }},
  footer: context {{ if counter(page).get().first() > 1 [
    #set text(size: 9pt, fill: luma(90))
    #{typst_string(footer)} #h(1fr) #counter(page).display()
  ] }},
)
#set text(font: ("Liberation Sans", "Helvetica Neue", "Arial"), size: 10.5pt)
#set par(justify: false, leading: 0.7em)
#show heading: set text(fill: brand)
#show heading.where(level: 1): it => {{ v(8pt); it; v(-4pt); line(length: 100%, stroke: 1pt + brand); v(4pt) }}
#show link: set text(fill: brand)
#show image: set align(center)
#set table(stroke: (x, y) => (bottom: 0.5pt + luma(190)), inset: 6pt)
#show table.cell.where(y: 0): set text(weight: "bold", fill: brand)
#show table.cell: set align(left)
#show table.cell: set par(justify: false)
#show raw.where(block: false): box.with(fill: luma(240), inset: (x: 3pt), outset: (y: 3pt), radius: 2pt)
""",
        encoding="utf-8",
    )
    logo = (
        f"#image({typst_string(str(Path(brand['logo']).resolve()))}, height: 22mm)"
        if brand["logo"]
        else ""
    )
    cover = BUILD / f"{prepared.stem}-cover.typ"
    cover.write_text(
        f"""
#page(header: none, footer: none)[
  #v(18mm)
  {logo}
  #v(1fr)
  #rect(width: 28mm, height: 2.5mm, fill: brand)
  #v(4mm)
  #text(size: 30pt, weight: "bold", fill: brand)[#{typst_string(system)}]
  #v(2mm)
  #text(size: 20pt)[#{typst_string(title)}]
  #v(2fr)
  #set text(size: 11pt, fill: luma(60))
  #{typst_string(brand["organisation"])} \\
  #{typst_string(datetime.date.today().strftime("%-d %B %Y"))} \\
  #{typst_string(brand["classification"])}
]
#outline(title: [Contents], depth: 2)
#pagebreak()
""",
        encoding="utf-8",
    )
    layout = BUILD / "layout.yaml"
    layout.write_text(
        "papersize: a4\nsection-numbering: '1.1'\n"
        "margin:\n  x: 22mm\n  top: 26mm\n  bottom: 22mm\n",
        encoding="utf-8",
    )
    run(
        "pandoc", prepared,
        "--from", "markdown+pipe_tables-implicit_figures",
        # The page title is on the cover, so its sections become chapters.
        "--shift-heading-level-by=-1",
        "--to", "pdf", "--pdf-engine", "typst",
        # Typst reads only below its root, and the diagrams and logo are absolute.
        "--pdf-engine-opt=--root=/",
        "--include-in-header", header,
        "--include-before-body", cover,
        "--metadata-file", layout,
        "--output", target,
    )


def reference_docx(colour: str) -> Path:
    """Pandoc's own Word styles, with headings in the brand colour."""
    reference = BUILD / "reference.docx"
    data = subprocess.run(
        ["pandoc", "--print-default-data-file", "reference.docx"], capture_output=True, check=True
    ).stdout
    reference.write_bytes(data)
    document = Document(str(reference))
    rgb = RGBColor.from_string(colour.lstrip("#").upper())
    for name in ("Title", "Heading 1", "Heading 2", "Heading 3", "Heading 4"):
        style = document.styles[name]
        style.font.color.rgb = rgb
        style.font.name = "Arial"
        style.font.bold = True
    for name in ("Normal", "Body Text", "First Paragraph", "Compact"):
        if name in [style.name for style in document.styles]:
            document.styles[name].font.name = "Arial"
            document.styles[name].font.size = Pt(10.5)
    for section in document.sections:
        section.page_width, section.page_height = Mm(210), Mm(297)
        section.left_margin = section.right_margin = Mm(22)
        section.top_margin = section.bottom_margin = Mm(24)
    document.save(str(reference))
    return reference


def page_number(paragraph) -> None:
    """A PAGE field, which Word fills in."""
    for kind, text in (("begin", None), (None, "PAGE"), ("end", None)):
        run_element = paragraph.add_run()._r
        if kind:
            mark = OxmlElement("w:fldChar")
            mark.set(qn("w:fldCharType"), kind)
        else:
            mark = OxmlElement("w:instrText")
            mark.set(qn("xml:space"), "preserve")
            mark.text = text
        run_element.append(mark)


def export_docx(title: str, system: str, prepared: Path, brand: dict, target: Path) -> None:
    run(
        "pandoc", prepared,
        "--from", "markdown+pipe_tables-implicit_figures",
        # The page title is on the cover, so its sections become chapters.
        "--shift-heading-level-by=-1",
        "--to", "docx",
        "--reference-doc", reference_docx(brand["primary_colour"]),
        "--table-of-contents", "--toc-depth", "2",
        "--number-sections",
        "--output", target,
    )
    document = Document(str(target))
    rgb = RGBColor.from_string(brand["primary_colour"].lstrip("#").upper())
    first = document.paragraphs[0]

    cover = []

    def before(text: str = "", size: float = 11, bold: bool = False, coloured: bool = False):
        paragraph = first.insert_paragraph_before()
        cover.append(paragraph._p)
        if text:
            piece = paragraph.add_run(text)
            piece.font.size, piece.font.bold = Pt(size), bold
            if coloured:
                piece.font.color.rgb = rgb
        return paragraph

    if brand["logo"]:
        before().add_run().add_picture(str(brand["logo"]), height=Mm(22))
    for _ in range(6):
        before()
    before(system, size=30, bold=True, coloured=True)
    before(title, size=20)
    for _ in range(8):
        before()
    for line in (brand["organisation"], datetime.date.today().strftime("%-d %B %Y"), brand["classification"]):
        if line:
            before(line)
    before().add_run().add_break(WD_BREAK.PAGE)
    # The contents list pandoc wrote sits above the first paragraph: the cover
    # goes above that.
    body = document.element.body
    for index, element in enumerate(cover):
        body.remove(element)
        body.insert(index, element)

    footer_text = " · ".join(part for part in (brand["organisation"], brand["classification"]) if part)
    for section in document.sections:
        header = section.header.paragraphs[0]
        header.text = f"{system}  |  {title}"
        header.runs[0].font.size = Pt(9)
        footer = section.footer.paragraphs[0]
        footer.text = (footer_text + "    ") if footer_text else ""
        footer.alignment = WD_ALIGN_PARAGRAPH.RIGHT
        page_number(footer)
        for piece in footer.runs:
            piece.font.size = Pt(9)
    # Diagrams as wide as the text, not as wide as their pixels.
    width = document.sections[0].page_width - document.sections[0].left_margin - document.sections[0].right_margin
    for shape in list(document.inline_shapes)[1 if brand["logo"] else 0 :]:
        if shape.width > width:
            shape.height = int(shape.height * width / shape.width)
            shape.width = width
    document.save(str(target))


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    parser.add_argument("--sync-brand", action="store_true", help="write the primary colour into docs/diagrams/c4.d2")
    arguments = parser.parse_args()

    shutil.rmtree(BUILD, ignore_errors=True)
    BUILD.mkdir(parents=True)
    brand = load_brand()
    if arguments.sync_brand:
        sync_brand(brand["primary_colour"])

    config = yaml.safe_load((ROOT / "mkdocs.yml").read_text(encoding="utf-8"))
    system = re.sub(r"\s+design$", "", str(config["site_name"]))
    for page in documents():
        title, prepared = prepare(page, brand["primary_colour"])
        name = page.stem.upper()
        export_pdf(title, system, prepared, brand, OUT / f"{name}.pdf")
        export_docx(title, system, prepared, brand, OUT / f"{name}.docx")
        print(f"out/{name}.pdf  out/{name}.docx")
    shutil.rmtree(BUILD)


if __name__ == "__main__":
    main()
