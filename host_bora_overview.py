from fpdf import FPDF
from fpdf.enums import XPos, YPos
import os

PRIMARY   = (13,  92,  90)   # teal
ACCENT    = (22, 163,  74)   # green
DARK      = (30,  30,  30)
MID       = (80,  80,  80)
LIGHT_BG  = (245, 249, 249)
WHITE     = (255, 255, 255)
DIVIDER   = (210, 228, 227)

FONT_DIR  = "/System/Library/Fonts/Supplemental"
OUTPUT    = os.path.join(os.path.dirname(__file__), "Host_Bora_App_Overview.pdf")

BULLET = "-"   # ASCII safe bullet

class PDF(FPDF):
    def header(self):
        pass

    def footer(self):
        self.set_y(-14)
        self.set_font("Arial", "I", 8)
        self.set_text_color(*MID)
        self.cell(0, 10, f"Host Bora  |  Page {self.page_no()}", align="C")

    def _setup_fonts(self):
        self.add_font("Arial",  "",  f"{FONT_DIR}/Arial.ttf",            uni=True)
        self.add_font("Arial",  "B", f"{FONT_DIR}/Arial Bold.ttf",       uni=True)
        self.add_font("Arial",  "I", f"{FONT_DIR}/Arial Italic.ttf",     uni=True)
        self.add_font("ArialBI","",  f"{FONT_DIR}/Arial Bold Italic.ttf", uni=True)

    # ── helpers ────────────────────────────────────────────────────────────────
    def teal_bar(self, h=3):
        self.set_fill_color(*PRIMARY)
        self.rect(0, 0, 210, h, "F")

    def h2(self, txt):
        self.ln(4)
        self.set_font("Arial", "B", 13)
        self.set_text_color(*PRIMARY)
        self.cell(0, 8, txt, new_x=XPos.LMARGIN, new_y=YPos.NEXT)
        y = self.get_y()
        self.set_draw_color(*DIVIDER)
        self.set_line_width(0.4)
        self.line(self.l_margin, y, 210 - self.r_margin, y)
        self.ln(3)

    def body(self, txt):
        self.set_font("Arial", "", 10.5)
        self.set_text_color(*DARK)
        self.multi_cell(0, 6, txt)
        self.ln(1)

    def bullet(self, label, desc=""):
        self.set_font("Arial", "B", 10.5)
        self.set_text_color(*PRIMARY)
        self.set_x(self.l_margin + 4)
        dot_w = self.get_string_width(f"{BULLET} {label}") + 2
        self.cell(dot_w, 6, f"{BULLET} {label}", new_x=XPos.END, new_y=YPos.LAST)
        if desc:
            self.set_font("Arial", "", 10.5)
            self.set_text_color(*MID)
            self.multi_cell(0, 6, f" - {desc}")
        else:
            self.ln()

    def tag(self, txt, color=PRIMARY):
        self.set_font("Arial", "B", 8.5)
        self.set_fill_color(*color)
        self.set_text_color(*WHITE)
        w = self.get_string_width(txt) + 8
        self.cell(w, 7, txt, fill=True, new_x=XPos.END, new_y=YPos.LAST)
        self.cell(3, 7, "")

    def feature_block(self, icon_char, title, lines):
        line_h  = 5.5
        padding = 6
        n_lines = sum(1 + (len(l) // 82) for l in lines)
        block_h = padding * 2 + 10 + n_lines * line_h + 2

        if self.get_y() + block_h > 270:
            self.add_page()

        x0 = self.l_margin
        y0 = self.get_y()
        w  = 210 - self.l_margin - self.r_margin

        self.set_fill_color(*LIGHT_BG)
        self.set_draw_color(*DIVIDER)
        self.set_line_width(0.3)
        self.rect(x0, y0, w, block_h, "FD")

        # icon badge
        self.set_fill_color(*PRIMARY)
        self.ellipse(x0 + padding, y0 + padding, 9, 9, "F")
        self.set_font("Arial", "B", 9)
        self.set_text_color(*WHITE)
        self.set_xy(x0 + padding, y0 + padding + 0.5)
        self.cell(9, 8, icon_char, align="C")

        # title
        self.set_font("Arial", "B", 11)
        self.set_text_color(*PRIMARY)
        self.set_xy(x0 + padding + 12, y0 + padding + 1)
        self.cell(w - padding * 2 - 12, 8, title)

        # bullet lines
        self.set_font("Arial", "", 10)
        self.set_text_color(*DARK)
        self.set_xy(x0 + padding + 4, y0 + padding + 11)
        for line in lines:
            self.set_x(x0 + padding + 4)
            self.multi_cell(w - padding * 2 - 6, line_h, f"{BULLET}  {line}")

        self.set_y(y0 + block_h + 3)


# ═══════════════════════════════════════════════════════════════════════════════
pdf = PDF()
pdf._setup_fonts()
pdf.set_margins(18, 18, 18)
pdf.set_auto_page_break(auto=True, margin=18)
pdf.add_page()

# ── cover header ────────────────────────────────────────────────────────────
pdf.teal_bar(3)
pdf.ln(8)

pdf.set_font("Arial", "B", 32)
pdf.set_text_color(*PRIMARY)
pdf.cell(0, 12, "Host Bora", new_x=XPos.LMARGIN, new_y=YPos.NEXT)

pdf.set_font("Arial", "", 14)
pdf.set_text_color(*MID)
pdf.cell(0, 8, "Smart Property Management for Tanzanian Hosts & Landlords",
         new_x=XPos.LMARGIN, new_y=YPos.NEXT)
pdf.ln(3)

# tags
pdf.tag("Long-term Rental", PRIMARY)
pdf.tag("BnB / Short-stay", (22, 120, 100))
pdf.tag("Offline-first", (37, 99, 235))
pdf.tag("Swahili + English", (126, 34, 206))
pdf.ln(10)

# ── what is it ──────────────────────────────────────────────────────────────
pdf.h2("What is Host Bora?")
pdf.body(
    "Host Bora is a mobile property management application built for landlords and "
    "short-stay hosts in Tanzania.  It runs fully offline on the user's device and "
    "syncs data to a cloud backend whenever a connection is available.  A single "
    "account can manage multiple properties across both long-term rental (Rent) and "
    "BnB short-stay modes simultaneously."
)

# ── who is it for ───────────────────────────────────────────────────────────
pdf.h2("Who Is It For?")
pdf.bullet("Long-term landlords", "Manage tenants, leases, monthly rent collection and arrears.")
pdf.bullet("BnB / short-stay hosts", "Track guest bookings, check-ins, and occupancy calendar.")
pdf.bullet("Multi-property owners", "Oversee an entire portfolio from one dashboard.")
pdf.ln(4)

# ── feature grid ────────────────────────────────────────────────────────────
pdf.h2("Key Features")
pdf.ln(2)

features = [
    ("P", "Properties & Units",
     ["Add unlimited properties, each with individual units.",
      "Set operation mode per unit — long-term rent or BnB.",
      "Photo support via PropertyListingImage."]),

    ("T", "Tenants & Occupancy",
     ["Add tenants with lease start/end, rent amount, currency, and frequency.",
      "Full tenant ledger: payment history, arrears, and expected schedule.",
      "Tenant scoring / rating system.",
      "Guest history module for BnB stays."]),

    ("$", "Financials",
     ["Record income and expenses per property.",
      "Financial overview with net income, arrears, and revenue trends.",
      "Multi-currency support with live exchange-rate hints.",
      "Scheduled payment reminders with push notifications."]),

    ("M", "Maintenance",
     ["Schedule and track maintenance tasks per property.",
      "Syncs maintenance records to the backend server.",
      "Activity log with timestamps and status."]),

    ("L", "LUKU / Utility Tracking",
     ["Track electricity (LUKU) top-ups per property unit.",
      "Smart dashboard with per-unit stats.",
      "Meter number auto-extracted from SMS/notes via regex.",
      "OCR parser for LUKU receipt SMS messages."]),

    ("@", "Messaging (SMS & WhatsApp)",
     ["Send bulk SMS or WhatsApp messages to tenants and guests.",
      "WhatsApp Business template builder using Meta Cloud API.",
      "Variable substitution ({{1}}, {{2}}, ...) in templates.",
      "Save, reuse, and organise message templates.",
      "Device contact picker and saved group links."]),

    ("C", "Calendar",
     ["Host calendar showing bookings, check-ins, and check-outs.",
      "Visual gap detection between bookings.",
      "Colour-coded occupancy view."]),

    ("A", "AI Manager",
     ["Floating AI assistant for natural-language portfolio queries.",
      "Answers questions about income, occupancy, arrears, and maintenance.",
      "Uses local offline data — no internet required for insights.",
      "Accessible from any screen via a persistent FAB."]),

    ("S", "Security & Access",
     ["4-digit PIN lock with biometric (fingerprint / Face ID) support.",
      "Session token expiry with automatic logout.",
      "Subscription gating for SMS/WhatsApp features.",
      "App-lock timeout configurable by the user."]),

    ("O", "Offline-first Architecture",
     ["All data stored locally in SQLite (sqflite).",
      "Changes queued via OfflineSyncQueue and synced on reconnect.",
      "Works fully without internet — syncs transparently in background."]),
]

for icon, title, lines in features:
    pdf.feature_block(icon, title, lines)

# ── tech stack ──────────────────────────────────────────────────────────────
pdf.h2("Technology Stack")
pdf.bullet("Frontend", "Flutter (Dart) · GetX state management · sqflite local DB")
pdf.bullet("Backend",  "Kotlin · Spring Boot · SQL Server · Flyway migrations")
pdf.bullet("Integrations", "Meta WhatsApp Cloud API · Firebase (push notifications) · local_auth (biometrics)")
pdf.bullet("Languages", "English and Swahili (full i18n via ARB/localizations)")
pdf.ln(5)

# ── bottom rule ─────────────────────────────────────────────────────────────
pdf.set_draw_color(*DIVIDER)
pdf.set_line_width(0.5)
x = pdf.l_margin
pdf.line(x, pdf.get_y(), 210 - pdf.r_margin, pdf.get_y())
pdf.ln(4)
pdf.set_font("Arial", "I", 9)
pdf.set_text_color(*MID)
pdf.cell(0, 6, "© 2026 Artbel Technologies · Host Bora · All rights reserved.", align="C")

pdf.output(OUTPUT)
print(f"PDF saved to: {OUTPUT}")
