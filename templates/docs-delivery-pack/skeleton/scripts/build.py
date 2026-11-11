#!/usr/bin/env -S uv run
# /// script
# requires-python = ">=3.11"
# dependencies = ["pyyaml>=6", "openpyxl>=3.1", "python-docx>=1.1"]
# ///
"""Checks the delivery data and builds the pack from it.

    uv run scripts/build.py

Rewrites docs/status.md, plan.md, raid.md and raci.md, and writes
out/delivery-workbook.xlsx, out/status-report.docx and, when typst is on the
PATH, out/status-report.pdf. Stops, listing every problem, if the data is
inconsistent.
"""
from __future__ import annotations

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
from docx.enum.text import WD_ALIGN_PARAGRAPH
from docx.oxml import OxmlElement
from docx.oxml.ns import qn
from docx.shared import Mm, Pt, RGBColor
from openpyxl import Workbook
from openpyxl.styles import Alignment, Border, Font, PatternFill, Side
from openpyxl.utils import get_column_letter

ROOT = Path(__file__).resolve().parent.parent
DATA = ROOT / "delivery"
DOCS = ROOT / "docs"
OUT = ROOT / "out"
HEX = re.compile(r"^#[0-9a-fA-F]{6}$")
WEEK = re.compile(r"^week (\d+)$", re.IGNORECASE)
DEFAULT_COLOUR = "#3f4a5a"
PRESET_COLOURS = {
    "neutral": "#3f4a5a",
    "harbour": "#005399",
    "forest": "#1f6b45",
    "plum": "#6a2c91",
    "ember": "#a8401c",
    "civic": "#1d70b8",
    "baseline": "#6750a4",
}
MILESTONE_STATUS = {
    "not started": "D9DEE5",
    "in progress": "9CC3F5",
    "done": "9AD6AE",
    "at risk": "F7C873",
    "blocked": "F29B9B",
}
RAG = {"green": "9AD6AE", "amber": "F7C873", "red": "F29B9B"}
RACI = {"R": "9CC3F5", "A": "F7C873", "C": "D9DEE5", "I": "EEF1F5"}
OPEN_CLOSED = ("open", "closed")


def note(message: str) -> None:
    print(message, file=sys.stderr)


def load(name: str) -> dict:
    return yaml.safe_load((DATA / name).read_text(encoding="utf-8")) or {}


# --- Brand -----------------------------------------------------------------


def fetch(url: str) -> tuple[bytes, str]:
    request = urllib.request.Request(url, headers={"user-agent": "delivery-pack"})
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
    settings = json.loads(fetch(settings_url)[0])
    brand: dict = {}
    if settings.get("name"):
        brand["organisation"] = settings["name"]
    colour = settings.get("primaryColor") or PRESET_COLOURS.get(settings.get("themePreset") or "")
    if colour:
        brand["primary_colour"] = colour
    if settings.get("logoFullUrl"):
        data, content_type = fetch(urllib.parse.urljoin(settings_url, settings["logoFullUrl"]))
        extension = {"image/png": ".png", "image/jpeg": ".jpg"}.get(content_type)
        if extension:
            logo = OUT / f"portal-logo{extension}"
            logo.write_bytes(data)
            brand["logo"] = logo
        else:
            note(f"The portal's logo is {content_type}; the pack places PNG or JPEG. Skipping it.")
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
            # A portal that is down must not stop the pack being built.
            note(f"Could not read branding from {portal_url} ({error}). Using brand.yaml.")
    if not HEX.match(brand["primary_colour"]):
        sys.exit(f"primary_colour must be a six-digit hex colour, not {brand['primary_colour']!r}.")
    if brand["logo"] and not Path(brand["logo"]).is_file():
        sys.exit(f"The logo {brand['logo']} does not exist.")
    return brand


# --- Data ------------------------------------------------------------------


def as_date(value, start: datetime.date, end_of_week: bool) -> datetime.date | None:
    """A date, from a date or from "week N" of the project."""
    if isinstance(value, datetime.date):
        return value
    text = str(value or "").strip()
    week = WEEK.match(text)
    if week and int(week.group(1)) >= 1:
        monday = start - datetime.timedelta(days=start.weekday())
        monday += datetime.timedelta(weeks=int(week.group(1)) - 1)
        return monday + datetime.timedelta(days=4) if end_of_week else monday
    try:
        return datetime.date.fromisoformat(text)
    except ValueError:
        return None


def read_pack() -> tuple[dict, list[str]]:
    """Everything in delivery/, with dates resolved, and what is wrong with it."""
    problems: list[str] = []
    plan, raid, raci, status = (load(f"{name}.yaml") for name in ("plan", "raid", "raci", "status"))

    start = as_date(plan.get("start"), datetime.date.today(), False)
    if not isinstance(start, datetime.date) or WEEK.match(str(plan.get("start") or "")):
        problems.append("plan.yaml: `start` must be a date such as 2027-03-01.")
        start = datetime.date.today()

    milestones = []
    for phase in plan.get("phases") or []:
        for milestone in phase.get("milestones") or []:
            where = f"plan.yaml: milestone {milestone.get('id', '?')}"
            begin = as_date(milestone.get("start"), start, False)
            end = as_date(milestone.get("end"), start, True)
            if not begin or not end:
                problems.append(f'{where}: `start` and `end` must each be a date or "week N".')
                begin = end = start
            elif end < begin:
                problems.append(f"{where}: ends before it starts.")
            if milestone.get("status") not in MILESTONE_STATUS:
                problems.append(f"{where}: `status` must be one of {', '.join(MILESTONE_STATUS)}.")
            for field in ("id", "name", "owner"):
                if not milestone.get(field):
                    problems.append(f"{where}: `{field}` is missing.")
            milestones.append(
                {
                    **milestone,
                    "phase": phase.get("name", ""),
                    "start": begin,
                    "end": end,
                    "depends_on": list(milestone.get("depends_on") or []),
                }
            )
    ids = [milestone.get("id") for milestone in milestones]
    for milestone in milestones:
        for dependency in milestone["depends_on"]:
            if dependency not in ids:
                problems.append(f"plan.yaml: milestone {milestone.get('id')} depends on {dependency}, which does not exist.")
    if not milestones:
        problems.append("plan.yaml: there are no milestones.")

    for kind in ("risks", "assumptions", "issues", "dependencies"):
        for entry in raid.get(kind) or []:
            where = f"raid.yaml: {kind[:-1] if kind != 'dependencies' else 'dependency'} {entry.get('id', '?')}"
            ids.append(entry.get("id"))
            for field in ("id", "description", "owner"):
                if not entry.get(field):
                    problems.append(f"{where}: `{field}` is missing.")
            if entry.get("status") not in OPEN_CLOSED:
                problems.append(f"{where}: `status` must be open or closed.")
            if kind == "risks":
                for field in ("probability", "impact"):
                    if not isinstance(entry.get(field), int) or not 1 <= entry[field] <= 5:
                        problems.append(f"{where}: `{field}` must be a whole number from 1 to 5.")
                        entry[field] = 1
            if kind == "dependencies":
                needed = as_date(entry.get("needed_by"), start, True)
                if not needed:
                    problems.append(f'{where}: `needed_by` must be a date or "week N".')
                entry["needed_by"] = needed or start
    for duplicate in sorted({i for i in ids if i and ids.count(i) > 1}):
        problems.append(f"The id {duplicate} is used more than once.")

    roles = list(raci.get("roles") or [])
    for activity in raci.get("activities") or []:
        where = f"raci.yaml: activity {activity.get('name', '?')!r}"
        assigned = {role: letter for role, letter in activity.items() if role != "name"}
        for role, letter in assigned.items():
            if role not in roles:
                problems.append(f"{where}: {role!r} is not in `roles`.")
            if letter not in RACI:
                problems.append(f"{where}: {role} has {letter!r}; use R, A, C or I.")
        if list(assigned.values()).count("A") != 1:
            problems.append(f"{where}: needs exactly one accountable role (A).")

    rag = status.get("rag") or {}
    for measure in ("overall", "schedule", "scope", "budget", "quality"):
        if rag.get(measure) not in RAG:
            problems.append(f"status.yaml: rag.{measure} must be green, amber or red.")

    return {"plan": plan, "start": start, "milestones": milestones, "raid": raid, "raci": raci, "status": status}, problems


def day(value: datetime.date) -> str:
    return value.strftime("%-d %b %Y")


# --- Pages -----------------------------------------------------------------


def cell(value) -> str:
    return str(value if value is not None else "").replace("|", "\\|").replace("\n", " ")


def table(headers: list[str], rows: list[list]) -> str:
    if not rows:
        return "None recorded.\n"
    lines = ["| " + " | ".join(headers) + " |", "| " + " | ".join("---" for _ in headers) + " |"]
    lines += ["| " + " | ".join(cell(value) for value in row) + " |" for row in rows]
    return "\n".join(lines) + "\n"


def bullets(items: list) -> str:
    return "\n".join(f"- {item}" for item in items) + "\n" if items else "None.\n"


def status_markdown(pack: dict) -> str:
    status, plan = pack["status"], pack["plan"]
    rag = status["rag"]
    return "\n".join(
        [
            f"# Status: {status.get('period', '')}",
            "",
            f"**Overall: {str(rag['overall']).capitalize()}**",
            "",
            table(["Schedule", "Scope", "Budget", "Quality"], [[str(rag[m]).capitalize() for m in ("schedule", "scope", "budget", "quality")]]),
            "## Summary",
            "",
            str(status.get("summary") or "").strip(),
            "",
            "## Achieved this period",
            "",
            bullets(status.get("achievements") or []),
            "## Next period",
            "",
            bullets(status.get("next") or []),
            "## Decisions needed",
            "",
            bullets(status.get("decisions_needed") or []),
            "## Milestones",
            "",
            table(
                ["ID", "Milestone", "Owner", "Due", "Status"],
                [[m["id"], m["name"], m["owner"], day(m["end"]), str(m["status"]).capitalize()] for m in pack["milestones"]],
            ),
            f"Sponsor: {plan.get('sponsor') or 'not named'}. Manager: {plan.get('manager') or 'not named'}.",
            "",
        ]
    )


def plan_markdown(pack: dict) -> str:
    parts = ["# Plan", "", f"The project starts on {day(pack['start'])}.", ""]
    for phase in pack["plan"].get("phases") or []:
        rows = [
            [m["id"], m["name"], m["owner"], day(m["start"]), day(m["end"]), str(m["status"]).capitalize(), ", ".join(m["depends_on"])]
            for m in pack["milestones"]
            if m["phase"] == phase.get("name")
        ]
        parts += [f"## {phase.get('name')}", "", table(["ID", "Milestone", "Owner", "Start", "End", "Status", "Depends on"], rows)]
    return "\n".join(parts)


def raid_markdown(pack: dict) -> str:
    raid = pack["raid"]
    risks = sorted(raid.get("risks") or [], key=lambda r: -(r["probability"] * r["impact"]))
    return "\n".join(
        [
            "# RAID log",
            "",
            "## Risks",
            "",
            "Scored as probability times impact, each from 1 to 5. Highest first.",
            "",
            table(
                ["ID", "Risk", "Probability", "Impact", "Score", "Response", "Owner", "Status"],
                [[r["id"], r["description"], r["probability"], r["impact"], r["probability"] * r["impact"], r.get("response"), r["owner"], r["status"]] for r in risks],
            ),
            "## Assumptions",
            "",
            table(["ID", "Assumption", "Owner", "Status"], [[a["id"], a["description"], a["owner"], a["status"]] for a in raid.get("assumptions") or []]),
            "## Issues",
            "",
            table(
                ["ID", "Issue", "Impact", "Action", "Owner", "Status"],
                [[i["id"], i["description"], i.get("impact"), i.get("action"), i["owner"], i["status"]] for i in raid.get("issues") or []],
            ),
            "## Dependencies",
            "",
            table(
                ["ID", "Dependency", "On", "Needed by", "Owner", "Status"],
                [[d["id"], d["description"], d.get("on"), day(d["needed_by"]), d["owner"], d["status"]] for d in raid.get("dependencies") or []],
            ),
        ]
    )


def raci_markdown(pack: dict) -> str:
    roles = pack["raci"].get("roles") or []
    rows = [[a.get("name")] + [a.get(role, "") for role in roles] for a in pack["raci"].get("activities") or []]
    return "\n".join(
        [
            "# RACI",
            "",
            "**R** responsible, **A** accountable, **C** consulted, **I** informed.",
            "",
            table(["Activity"] + roles, rows),
        ]
    )


# --- Workbook --------------------------------------------------------------

THIN = Side(style="thin", color="C9CED6")
BORDER = Border(left=THIN, right=THIN, top=THIN, bottom=THIN)


def fill(colour: str) -> PatternFill:
    return PatternFill("solid", start_color=colour.lstrip("#").upper())


def sheet(book: Workbook, title: str, headers: list[str], rows: list[list], widths: list[int], brand: dict):
    page = book.create_sheet(title)
    page.append(headers)
    for row in rows:
        page.append(row)
    for column, width in enumerate(widths, start=1):
        page.column_dimensions[get_column_letter(column)].width = width
    for head in page[1]:
        head.font = Font(bold=True, color="FFFFFF")
        head.fill = fill(brand["primary_colour"])
        head.alignment = Alignment(vertical="center", wrap_text=True)
        head.border = BORDER
    for row in page.iter_rows(min_row=2):
        for value in row:
            value.alignment = Alignment(vertical="top", wrap_text=True)
            value.border = BORDER
            if isinstance(value.value, datetime.date):
                value.number_format = "d mmm yyyy"
    page.freeze_panes = "A2"
    if rows:
        page.auto_filter.ref = page.dimensions
    return page


def workbook(pack: dict, brand: dict, target: Path) -> None:
    book = Workbook()
    summary = book.active
    summary.title = "Summary"
    status, plan = pack["status"], pack["plan"]
    summary.column_dimensions["A"].width = 22
    summary.column_dimensions["B"].width = 90
    summary["A1"] = str(plan.get("project") or "")
    summary["A1"].font = Font(bold=True, size=18, color=brand["primary_colour"].lstrip("#").upper())
    lines = [
        ("Organisation", brand["organisation"]),
        ("Classification", brand["classification"]),
        ("Description", plan.get("description")),
        ("Sponsor", plan.get("sponsor")),
        ("Manager", plan.get("manager")),
        ("Start", pack["start"]),
        ("Reporting period", status.get("period")),
        ("Summary", str(status.get("summary") or "").strip()),
    ]
    for offset, (label, value) in enumerate(lines, start=3):
        summary.cell(offset, 1, label).font = Font(bold=True)
        entry = summary.cell(offset, 2, value)
        entry.alignment = Alignment(wrap_text=True, vertical="top")
        if isinstance(value, datetime.date):
            entry.number_format = "d mmm yyyy"
            entry.alignment = Alignment(horizontal="left")
    row = len(lines) + 4
    for measure in ("overall", "schedule", "scope", "budget", "quality"):
        summary.cell(row, 1, measure.capitalize()).font = Font(bold=True)
        rag = summary.cell(row, 2, str(status["rag"][measure]).capitalize())
        rag.fill = fill(RAG[status["rag"][measure]])
        row += 1

    milestones = pack["milestones"]
    first = min(m["start"] for m in milestones)
    first -= datetime.timedelta(days=first.weekday())
    last = max(m["end"] for m in milestones)
    weeks = (last - first).days // 7 + 1
    fixed = ["ID", "Phase", "Milestone", "Owner", "Start", "End", "Status", "Depends on"]
    page = sheet(
        book,
        "Plan",
        fixed + [first + datetime.timedelta(weeks=w) for w in range(weeks)],
        [[m["id"], m["phase"], m["name"], m["owner"], m["start"], m["end"], m["status"], ", ".join(m["depends_on"])] for m in milestones],
        [8, 14, 44, 20, 13, 13, 14, 14] + [5] * weeks,
        brand,
    )
    page.auto_filter.ref = f"A1:{get_column_letter(len(fixed))}{len(milestones) + 1}"
    page.freeze_panes = "D2"
    for week in range(weeks):
        head = page.cell(1, len(fixed) + 1 + week)
        head.number_format = "d mmm"
        head.alignment = Alignment(text_rotation=90, horizontal="center")
    page.row_dimensions[1].height = 48
    for index, milestone in enumerate(milestones, start=2):
        page.cell(index, 7).fill = fill(MILESTONE_STATUS[milestone["status"]])
        for week in range(weeks):
            monday = first + datetime.timedelta(weeks=week)
            if milestone["start"] <= monday + datetime.timedelta(days=6) and milestone["end"] >= monday:
                page.cell(index, len(fixed) + 1 + week).fill = fill(MILESTONE_STATUS[milestone["status"]])

    raid = pack["raid"]
    risks = sorted(raid.get("risks") or [], key=lambda r: -(r["probability"] * r["impact"]))
    page = sheet(
        book,
        "Risks",
        ["ID", "Risk", "Probability", "Impact", "Score", "Response", "Owner", "Status"],
        [[r["id"], r["description"], r["probability"], r["impact"], None, r.get("response"), r["owner"], r["status"]] for r in risks],
        [8, 50, 12, 10, 9, 50, 20, 10],
        brand,
    )
    for index, risk in enumerate(risks, start=2):
        # A formula, so the score follows when someone edits the workbook.
        score = page.cell(index, 5, f"=C{index}*D{index}")
        value = risk["probability"] * risk["impact"]
        score.fill = fill(RAG["red" if value >= 15 else "amber" if value >= 8 else "green"])
    sheet(book, "Assumptions", ["ID", "Assumption", "Owner", "Status"], [[a["id"], a["description"], a["owner"], a["status"]] for a in raid.get("assumptions") or []], [8, 70, 20, 10], brand)
    sheet(
        book,
        "Issues",
        ["ID", "Issue", "Impact", "Action", "Owner", "Status"],
        [[i["id"], i["description"], i.get("impact"), i.get("action"), i["owner"], i["status"]] for i in raid.get("issues") or []],
        [8, 50, 30, 40, 20, 10],
        brand,
    )
    sheet(
        book,
        "Dependencies",
        ["ID", "Dependency", "On", "Needed by", "Owner", "Status"],
        [[d["id"], d["description"], d.get("on"), d["needed_by"], d["owner"], d["status"]] for d in raid.get("dependencies") or []],
        [8, 50, 24, 13, 20, 10],
        brand,
    )

    roles = pack["raci"].get("roles") or []
    activities = pack["raci"].get("activities") or []
    page = sheet(book, "RACI", ["Activity"] + roles, [[a.get("name")] + [a.get(role, "") for role in roles] for a in activities], [44] + [16] * len(roles), brand)
    for row in page.iter_rows(min_row=2, min_col=2):
        for value in row:
            value.alignment = Alignment(horizontal="center", vertical="center")
            if value.value in RACI:
                value.fill = fill(RACI[value.value])
                value.font = Font(bold=value.value == "A")

    for page in book.worksheets:
        page.oddFooter.left.text = " · ".join(part for part in (brand["organisation"], brand["classification"]) if part)
        page.oddFooter.right.text = "Page &P of &N"
        page.page_setup.orientation = "landscape"
        page.page_setup.fitToWidth = 1
        page.page_setup.fitToHeight = 0
        page.sheet_properties.pageSetUpPr.fitToPage = True
    book.save(target)


# --- Status report ---------------------------------------------------------


def shade(cell_, colour: str) -> None:
    shading = OxmlElement("w:shd")
    shading.set(qn("w:val"), "clear")
    shading.set(qn("w:fill"), colour.lstrip("#").upper())
    cell_._tc.get_or_add_tcPr().append(shading)


def report_docx(pack: dict, brand: dict, target: Path) -> None:
    status, plan = pack["status"], pack["plan"]
    rgb = RGBColor.from_string(brand["primary_colour"].lstrip("#").upper())
    document = Document()
    for section in document.sections:
        section.page_width, section.page_height = Mm(210), Mm(297)
        section.left_margin = section.right_margin = Mm(22)
        footer = section.footer.paragraphs[0]
        footer.text = " · ".join(part for part in (brand["organisation"], brand["classification"]) if part)
        footer.alignment = WD_ALIGN_PARAGRAPH.RIGHT
    document.styles["Normal"].font.name = "Arial"
    document.styles["Normal"].font.size = Pt(10.5)
    for name in ("Title", "Heading 1", "Heading 2"):
        document.styles[name].font.color.rgb = rgb
        document.styles[name].font.name = "Arial"

    if brand["logo"]:
        document.add_picture(str(brand["logo"]), height=Mm(16))
    document.add_heading(str(plan.get("project") or ""), level=0)
    document.add_paragraph(f"Status report: {status.get('period', '')} · {day(datetime.date.today())}")

    measures = ("overall", "schedule", "scope", "budget", "quality")
    grid = document.add_table(rows=2, cols=len(measures))
    grid.style = "Table Grid"
    for column, measure in enumerate(measures):
        grid.cell(0, column).text = measure.capitalize()
        grid.cell(0, column).paragraphs[0].runs[0].font.bold = True
        grid.cell(1, column).text = str(status["rag"][measure]).capitalize()
        shade(grid.cell(1, column), RAG[status["rag"][measure]])

    document.add_heading("Summary", level=1)
    document.add_paragraph(str(status.get("summary") or "").strip())
    for heading, key in (("Achieved this period", "achievements"), ("Next period", "next"), ("Decisions needed", "decisions_needed")):
        document.add_heading(heading, level=1)
        items = status.get(key) or []
        for item in items:
            document.add_paragraph(str(item), style="List Bullet")
        if not items:
            document.add_paragraph("None.")

    def rows(heading: str, headers: list[str], body: list[list]) -> None:
        document.add_heading(heading, level=1)
        if not body:
            document.add_paragraph("None recorded.")
            return
        grid = document.add_table(rows=1, cols=len(headers))
        grid.style = "Table Grid"
        for column, text in enumerate(headers):
            grid.cell(0, column).text = text
            grid.cell(0, column).paragraphs[0].runs[0].font.bold = True
            grid.cell(0, column).paragraphs[0].runs[0].font.color.rgb = RGBColor(0xFF, 0xFF, 0xFF)
            shade(grid.cell(0, column), brand["primary_colour"])
        for line in body:
            cells = grid.add_row().cells
            for column, value in enumerate(line):
                cells[column].text = str(value if value is not None else "")

    rows(
        "Milestones",
        ["ID", "Milestone", "Owner", "Due", "Status"],
        [[m["id"], m["name"], m["owner"], day(m["end"]), str(m["status"]).capitalize()] for m in pack["milestones"]],
    )
    risks = sorted((r for r in pack["raid"].get("risks") or [] if r["status"] == "open"), key=lambda r: -(r["probability"] * r["impact"]))[:5]
    rows("Top open risks", ["ID", "Risk", "Score", "Response", "Owner"], [[r["id"], r["description"], r["probability"] * r["impact"], r.get("response"), r["owner"]] for r in risks])
    issues = [i for i in pack["raid"].get("issues") or [] if i["status"] == "open"]
    rows("Open issues", ["ID", "Issue", "Action", "Owner"], [[i["id"], i["description"], i.get("action"), i["owner"]] for i in issues])
    document.save(target)


def typst_string(text) -> str:
    return '"' + str(text if text is not None else "").replace("\\", "\\\\").replace('"', '\\"') + '"'


def typst_table(headers: list[str], body: list[list], widths: str) -> str:
    if not body:
        return "None recorded.\n"
    cells = ", ".join(f"[*#{typst_string(h)}*]" for h in headers)
    lines = [f"#table(columns: {widths}, table.header({cells}),"]
    lines += ["  " + ", ".join(f"[#{typst_string(v)}]" for v in line) + "," for line in body]
    return "\n".join(lines) + "\n)\n"


def report_pdf(pack: dict, brand: dict, target: Path) -> bool:
    if shutil.which("typst") is None:
        note("typst is not on the PATH, so out/status-report.pdf was not written.")
        return False
    status, plan = pack["status"], pack["plan"]
    footer = " · ".join(part for part in (brand["organisation"], brand["classification"]) if part)
    logo = f"#image({typst_string(Path(brand['logo']).resolve())}, height: 14mm)\n" if brand["logo"] else ""
    measures = ("overall", "schedule", "scope", "budget", "quality")
    rag = ", ".join(
        f'table.cell(fill: rgb("#{RAG[status["rag"][m]]}"))[#{typst_string(str(status["rag"][m]).capitalize())}]' for m in measures
    )

    def listing(key: str) -> str:
        items = status.get(key) or []
        return "\n".join(f"- #{typst_string(item)}" for item in items) + "\n" if items else "None.\n"

    risks = sorted((r for r in pack["raid"].get("risks") or [] if r["status"] == "open"), key=lambda r: -(r["probability"] * r["impact"]))[:5]
    issues = [i for i in pack["raid"].get("issues") or [] if i["status"] == "open"]
    source = f"""
#let brand = rgb({typst_string(brand["primary_colour"])})
#set page(paper: "a4", margin: (x: 22mm, top: 22mm, bottom: 22mm), footer: context [
  #set text(size: 9pt, fill: luma(90))
  #{typst_string(footer)} #h(1fr) #counter(page).display()
])
#set text(font: ("Liberation Sans", "Helvetica Neue", "Arial"), size: 10.5pt)
#show heading: set text(fill: brand)
#set table(stroke: 0.5pt + luma(190), inset: 6pt)
#show table.cell.where(y: 0): set text(fill: brand)
{logo}
#text(size: 24pt, weight: "bold", fill: brand)[#{typst_string(plan.get("project"))}]

#{typst_string(f"Status report: {status.get('period', '')} · {day(datetime.date.today())}")}

#table(columns: (1fr,) * 5, table.header({", ".join(f"[*#{typst_string(m.capitalize())}*]" for m in measures)}), {rag})

= Summary
#{typst_string(str(status.get("summary") or "").strip())}

= Achieved this period
{listing("achievements")}
= Next period
{listing("next")}
= Decisions needed
{listing("decisions_needed")}
= Milestones
{typst_table(["ID", "Milestone", "Owner", "Due", "Status"], [[m["id"], m["name"], m["owner"], day(m["end"]), str(m["status"]).capitalize()] for m in pack["milestones"]], "(auto, 1fr, auto, auto, auto)")}
= Top open risks
{typst_table(["ID", "Risk", "Score", "Response", "Owner"], [[r["id"], r["description"], r["probability"] * r["impact"], r.get("response"), r["owner"]] for r in risks], "(auto, 1fr, auto, 1fr, auto)")}
= Open issues
{typst_table(["ID", "Issue", "Action", "Owner"], [[i["id"], i["description"], i.get("action"), i["owner"]] for i in issues], "(auto, 1fr, 1fr, auto)")}
"""
    work = OUT / "status-report.typ"
    work.write_text(source, encoding="utf-8")
    result = subprocess.run(["typst", "compile", "--root", "/", str(work), str(target)], capture_output=True, text=True)
    work.unlink()
    if result.returncode != 0:
        sys.exit(f"typst failed:\n{result.stderr.strip()}")
    return True


def main() -> None:
    pack, problems = read_pack()
    if problems:
        sys.exit("The delivery data has problems:\n" + "\n".join(f"  - {problem}" for problem in problems))
    OUT.mkdir(exist_ok=True)
    brand = load_brand()
    for name, text in (("status", status_markdown), ("plan", plan_markdown), ("raid", raid_markdown), ("raci", raci_markdown)):
        (DOCS / f"{name}.md").write_text(text(pack).rstrip("\n") + "\n", encoding="utf-8")
    workbook(pack, brand, OUT / "delivery-workbook.xlsx")
    report_docx(pack, brand, OUT / "status-report.docx")
    written = ["out/delivery-workbook.xlsx", "out/status-report.docx"]
    if report_pdf(pack, brand, OUT / "status-report.pdf"):
        written.append("out/status-report.pdf")
    print("docs/status.md  docs/plan.md  docs/raid.md  docs/raci.md")
    print("  ".join(written))


if __name__ == "__main__":
    main()
