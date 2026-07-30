#!/usr/bin/env python3
"""Generate Host Bora QA test plan PDF."""

from datetime import date
from fpdf import FPDF


class QAPdf(FPDF):
    def header(self):
        if self.page_no() == 1:
            return
        self.set_font("Helvetica", "I", 8)
        self.set_text_color(100, 100, 100)
        self.set_x(self.l_margin)
        self.cell(95, 8, "Host Bora - QA Test Plan", align="L")
        self.cell(95, 8, f"Page {self.page_no()}", align="R", new_x="LMARGIN", new_y="NEXT")
        self.ln(2)

    def footer(self):
        self.set_y(-12)
        self.set_font("Helvetica", "I", 8)
        self.set_text_color(120, 120, 120)
        self.cell(0, 8, f"Generated {date.today().isoformat()} | Confidential - Internal QA", align="C")

    def section_title(self, title: str):
        self.set_x(self.l_margin)
        self.ln(4)
        self.set_font("Helvetica", "B", 13)
        self.set_text_color(20, 80, 70)
        self.multi_cell(0, 8, title)
        self.set_draw_color(20, 80, 70)
        self.line(10, self.get_y(), 200, self.get_y())
        self.ln(3)
        self.set_text_color(0, 0, 0)

    def subsection(self, title: str):
        self.set_x(self.l_margin)
        self.ln(2)
        self.set_font("Helvetica", "B", 11)
        self.multi_cell(0, 6, title)
        self.ln(1)

    def body(self, text: str):
        self.set_x(self.l_margin)
        self.set_font("Helvetica", "", 9)
        self.multi_cell(0, 5, text)
        self.ln(1)

    def test_case(self, case_id: str, title: str, steps: str, expected: str, priority: str = "P1"):
        w = self.epw
        self.set_x(self.l_margin)
        self.set_font("Helvetica", "B", 9)
        self.multi_cell(w, 5, f"[ ] {case_id} ({priority}) - {title}")
        self.set_x(self.l_margin)
        self.set_font("Helvetica", "", 8)
        self.set_text_color(40, 40, 40)
        self.multi_cell(w, 4, f"Steps: {steps}")
        self.set_x(self.l_margin)
        self.multi_cell(w, 4, f"Expected: {expected}")
        self.set_text_color(0, 0, 0)
        self.ln(2)


def build_pdf(output_path: str):
    pdf = QAPdf()
    pdf.set_margins(15, 15, 15)
    pdf.set_auto_page_break(auto=True, margin=15)
    pdf.add_page()

    # Cover
    pdf.ln(30)
    pdf.set_font("Helvetica", "B", 24)
    pdf.cell(0, 12, "Host Bora", align="C", new_x="LMARGIN", new_y="NEXT")
    pdf.set_font("Helvetica", "B", 16)
    pdf.cell(0, 10, "Comprehensive QA Test Plan", align="C", new_x="LMARGIN", new_y="NEXT")
    pdf.ln(8)
    pdf.set_x(pdf.l_margin)
    pdf.set_font("Helvetica", "", 11)
    pdf.multi_cell(
        0,
        6,
        "Manual test checklist for Android and iOS builds.\n"
        f"Document date: {date.today().strftime('%d %B %Y')}\n"
        "App: Host Bora (BnB + Rent property management)",
    )
    pdf.ln(20)
    pdf.set_x(pdf.l_margin)
    pdf.set_font("Helvetica", "", 9)
    pdf.multi_cell(
        0,
        5,
        "How to use this document:\n"
        "- Mark each checkbox when tested (Pass/Fail in your tracker).\n"
        "- P1 = must pass before release. P2 = important. P3 = nice to verify.\n"
        "- Test on both online and offline where noted.\n"
        "- Test English and Swahili on key flows.\n"
        "- Record: device model, OS version, app build, server environment (stage/prod).",
    )

    pdf.add_page()
    pdf.set_x(pdf.l_margin)
    pdf.section_title("0. Test Environment & Prerequisites")
    pdf.body(
        "Before testing, confirm:\n"
        "- Backend deployed with refresh-token auth and recurring-reminders APIs.\n"
        "- Test account with at least one BnB property and one Rent property.\n"
        "- WhatsApp Business credentials configured (if testing messaging).\n"
        "- Push notifications enabled on device.\n"
        "- Optional: Tuya smart lock paired for smart-access tests."
    )
    pdf.test_case(
        "ENV-01", "App installs and launches",
        "Install build from TestFlight/Play Internal. Cold start app.",
        "Splash/loading resolves; no crash; reaches onboarding or main shell.",
    )
    pdf.test_case(
        "ENV-02", "Version check",
        "Launch app with outdated min-version (if test build available).",
        "Force-update dialog appears when below min version.",
        "P2",
    )

    pdf.section_title("1. Authentication, Session & Security")
    pdf.subsection("1.1 Registration & Login")
    pdf.test_case(
        "AUTH-01", "New host registration",
        "Create account with phone, password, name. Complete OTP if prompted.",
        "Account created; user proceeds to PIN setup or home.",
    )
    pdf.test_case(
        "AUTH-02", "Login with phone and password",
        "Sign in with valid credentials.",
        "Login succeeds; lands on home or PIN setup if first time.",
    )
    pdf.test_case(
        "AUTH-03", "Invalid credentials",
        "Enter wrong password.",
        "Clear error message; no crash; can retry.",
    )
    pdf.test_case(
        "AUTH-04", "Forgot password flow",
        "From login, tap forgot password. Request OTP, verify, set new password.",
        "Password resets; can login with new password.",
    )
    pdf.subsection("1.2 Login-once session (refresh token)")
    pdf.test_case(
        "AUTH-10", "Stay signed in after closing app",
        "Login once. Kill app. Reopen within 90 days.",
        "User enters app without password (PIN/biometric or straight to home).",
    )
    pdf.test_case(
        "AUTH-11", "PIN unlock without password",
        "Set PIN. Background app past app-lock timeout. Unlock with PIN.",
        "Enters app without password prompt; no login API error toast.",
    )
    pdf.test_case(
        "AUTH-12", "Biometric unlock",
        "Enable Face ID/fingerprint. Lock app. Unlock with biometrics.",
        "Enters app without password.",
    )
    pdf.test_case(
        "AUTH-13", "Silent token refresh",
        "Stay logged in past 60 min JWT expiry (or simulate). Use any API feature.",
        "Session renews silently; user not kicked to login.",
    )
    pdf.test_case(
        "AUTH-14", "Forgot PIN while session valid",
        "From Welcome Back, tap Forgot PIN.",
        "Routes to set new PIN without full password login.",
    )
    pdf.test_case(
        "AUTH-15", "Logout clears session",
        "Settings > Log out. Reopen app.",
        "Full login required.",
    )
    pdf.subsection("1.3 PIN & App lock")
    pdf.test_case(
        "AUTH-20", "Create 4-digit PIN",
        "First login without PIN. Set and confirm PIN.",
        "PIN saved; Welcome Back not shown immediately after password login.",
    )
    pdf.test_case(
        "AUTH-21", "Change PIN",
        "Settings > Security > Change PIN.",
        "New PIN works on next lock.",
    )
    pdf.test_case(
        "AUTH-22", "PIN lockout",
        "Enter wrong PIN 5 times.",
        "Lockout message; retry after cooldown.",
    )
    pdf.test_case(
        "AUTH-23", "App lock timeout",
        "Change timeout in Settings (15s to 30 min). Background and return.",
        "Welcome Back appears only after selected timeout.",
    )

    pdf.section_title("2. Onboarding & First Run")
    pdf.test_case(
        "ONB-01", "First-time onboarding slides",
        "Fresh install. Complete onboarding.",
        "Onboarding not shown again on next launch.",
    )
    pdf.test_case(
        "ONB-02", "Language selection",
        "Switch app language EN/SW in Settings.",
        "UI strings update across main tabs.",
    )
    pdf.test_case(
        "ONB-03", "In-app review prompt",
        "Complete 3rd login or use app 7+ days (per rules).",
        "Two-step review dialog; max 2 prompts, 90 days apart.",
        "P2",
    )

    pdf.section_title("3. Navigation & Workspaces")
    pdf.test_case(
        "NAV-01", "Bottom navigation tabs",
        "Tap Home, Properties, Finances, Maintenance, More.",
        "Each tab loads without error.",
    )
    pdf.test_case(
        "NAV-02", "BnB workspace switch",
        "Switch to BnB workspace from home/header.",
        "BnB-specific home metrics and actions shown.",
    )
    pdf.test_case(
        "NAV-03", "Rent workspace switch",
        "Switch to Rent workspace.",
        "Rent hub, tenants, arrears context shown.",
    )
    pdf.test_case(
        "NAV-04", "More tab shortcuts",
        "Open Calendar, Reports, Settings, Help from More.",
        "Each screen opens correctly.",
    )

    pdf.section_title("4. Home Dashboard & Quick Actions")
    pdf.test_case(
        "HOME-01", "Home data load",
        "Open Home tab. Pull to refresh.",
        "Bookings/revenue cards populate; refresh updates data.",
    )
    pdf.test_case(
        "HOME-02", "Quick actions dialog",
        "Trigger quick actions (FAB or prompt).",
        "Dialog shows Add Property, Income, Expense, Booking, Tenant, Send Reminder.",
    )
    pdf.test_case(
        "HOME-03", "Quick add property wizard",
        "Quick Actions > Add Property. Complete wizard.",
        "Property created and visible in Properties tab.",
    )
    pdf.test_case(
        "HOME-04", "Quick add income",
        "Quick Actions > Add Income. Record payment.",
        "Payment saved; reflects in finances.",
    )
    pdf.test_case(
        "HOME-05", "Quick add expense",
        "Quick Actions > Add Expense.",
        "Expense saved; reflects in finances.",
    )
    pdf.test_case(
        "HOME-06", "AI quick action resolver",
        "Quick Actions > Other. Type natural language request.",
        "Correct screen or wizard opens.",
        "P2",
    )
    pdf.test_case(
        "HOME-07", "AI Manager FAB",
        "Tap floating AI button. Ask about income or arrears.",
        "Response uses portfolio context; no crash offline/online.",
        "P2",
    )

    pdf.section_title("5. Properties & Listings")
    pdf.test_case(
        "PROP-01", "Add listing wizard",
        "Properties > + Add listing. Complete all steps with photo.",
        "Listing saved locally and syncs online.",
    )
    pdf.test_case(
        "PROP-02", "Edit listing",
        "Open listing > Edit. Change name, address, pricing.",
        "Changes persist after refresh.",
    )
    pdf.test_case(
        "PROP-03", "Add/edit units",
        "Add unit to property. Edit unit details.",
        "Units appear on listing details.",
    )
    pdf.test_case(
        "PROP-04", "Cover photo",
        "Upload cover photo. Reopen listing.",
        "User photo displays (not misleading stock if placeholder policy applied).",
    )
    pdf.test_case(
        "PROP-05", "Listing details tabs",
        "Open listing. Switch BnB/Rent tabs, activity, staff panels.",
        "Data scoped to property; no cross-property bleed.",
    )
    pdf.test_case(
        "PROP-06", "Unit occupancy view",
        "Open unit occupancy from listing.",
        "Occupancy status accurate.",
        "P2",
    )
    pdf.test_case(
        "PROP-07", "Favourites / property list",
        "Browse My Properties. Search/filter if available.",
        "All properties listed with correct thumbnails.",
    )

    pdf.section_title("6. BnB (Short-Stay) Features")
    pdf.subsection("6.1 Bookings")
    pdf.test_case(
        "BNB-01", "Create booking",
        "Add new booking with guest, dates, unit, amount.",
        "Booking appears on home and All Bookings.",
    )
    pdf.test_case(
        "BNB-02", "Booking details",
        "Open booking. View guest info, payment status, dates.",
        "Details match created data.",
    )
    pdf.test_case(
        "BNB-03", "Check-in / check-out",
        "Perform check-in and check-out actions.",
        "Status updates; calendar reflects change.",
    )
    pdf.test_case(
        "BNB-04", "Cancel booking",
        "Cancel an active booking.",
        "Booking marked cancelled; calendar updated.",
    )
    pdf.test_case(
        "BNB-05", "All bookings list",
        "More > All Bookings. Search/filter.",
        "List complete; pull-to-refresh works.",
    )
    pdf.subsection("6.2 Calendar & Sync")
    pdf.test_case(
        "BNB-10", "Host calendar",
        "Open Host Calendar. Navigate months.",
        "Check-ins, check-outs, blocked nights visible.",
    )
    pdf.test_case(
        "BNB-11", "Calendar sync (iCal)",
        "Configure calendar subscription import/export.",
        "Sync settings save; export URL accessible.",
        "P2",
    )
    pdf.subsection("6.3 Guests")
    pdf.test_case(
        "BNB-20", "Guest history",
        "Open Guest History.",
        "Past/upcoming guests with stay and payment info.",
    )
    pdf.test_case(
        "BNB-21", "Guest access codes",
        "Create/share guest access code.",
        "Code generated and shareable.",
        "P2",
    )
    pdf.test_case(
        "BNB-22", "Guest reliability rating",
        "Rate guest after stay.",
        "Rating submitted; cooling-off before publish.",
        "P2",
    )

    pdf.section_title("7. Rent (Long-Term) Features")
    pdf.subsection("7.1 Tenants & Leases")
    pdf.test_case(
        "RENT-01", "Add tenant",
        "Add tenant with lease dates, rent, frequency, currency.",
        "Tenant linked to unit; appears in Tenancy Insights.",
    )
    pdf.test_case(
        "RENT-02", "Edit tenant / lease",
        "Update rent amount or lease end date.",
        "Ledger and expected schedule update.",
    )
    pdf.test_case(
        "RENT-03", "Tenant ledger",
        "Open tenant ledger. View payments and balance.",
        "Running balance correct.",
    )
    pdf.test_case(
        "RENT-04", "All tenants list",
        "Open All Tenants. Filter by property.",
        "Tenants listed with payment status.",
    )
    pdf.test_case(
        "RENT-05", "Lease renewal",
        "Start lease renewal flow. Share renewed lease.",
        "Renewal form saves; share action works.",
        "P2",
    )
    pdf.subsection("7.2 Payments & Arrears")
    pdf.test_case(
        "RENT-10", "Record rent payment",
        "Record payment from tenant or Quick Add Income.",
        "Payment in Manage Payments and tenant ledger.",
    )
    pdf.test_case(
        "RENT-11", "Manage payments",
        "Filter by month and property.",
        "Correct payments listed.",
    )
    pdf.test_case(
        "RENT-12", "Expected payment schedule",
        "Open yearly schedule for property.",
        "Monthly expected amounts match lease terms.",
    )
    pdf.test_case(
        "RENT-13", "Arrears tracking",
        "Leave tenant unpaid. Check Finances and Rent hub.",
        "Arrears total increases correctly.",
    )
    pdf.test_case(
        "RENT-14", "Multi-currency payment",
        "Record payment in non-base currency.",
        "Exchange rate captured; base currency totals correct.",
    )
    pdf.subsection("7.3 Tenant charges & contracts")
    pdf.test_case(
        "RENT-20", "Define tenant charges",
        "Add charge types incl. Service Charge.",
        "Charges apply to tenant billing context.",
    )
    pdf.test_case(
        "RENT-21", "Contract hub",
        "Upload lease PDF. View and share.",
        "Document stored and retrievable.",
    )

    pdf.section_title("8. Recurring Reminders (Rent)")
    pdf.test_case(
        "REM-01", "Open recurring reminders",
        "Quick Actions > Send Reminder OR listing/tenant entry point.",
        "Recurring reminders screen opens.",
    )
    pdf.test_case(
        "REM-02", "Create Pay Rent reminder",
        "New reminder: Pay Rent, monthly 1st, WhatsApp+SMS, one tenant.",
        "Reminder saved and listed.",
    )
    pdf.test_case(
        "REM-03", "Create Service Charge reminder",
        "Type Service Charge. Monthly recurrence.",
        "Reminder created with correct type.",
    )
    pdf.test_case(
        "REM-04", "Custom reminder type",
        "Add custom type name. Save reminder.",
        "Custom type available for reuse.",
    )
    pdf.test_case(
        "REM-05", "Custom recurrence - every N days",
        "Set custom: every 7 days.",
        "Preview label and saved rule correct.",
    )
    pdf.test_case(
        "REM-06", "Custom recurrence - every N months",
        "Set custom: every 2 months.",
        "Rule encoded and displayed correctly.",
    )
    pdf.test_case(
        "REM-07", "Custom recurrence - Nth day of month",
        "Set custom: 15th of each month.",
        "Next run date logic reasonable.",
    )
    pdf.test_case(
        "REM-08", "Bulk by property / all properties",
        "Create bulk reminder for all tenants in property.",
        "Multiple recipients configured.",
    )
    pdf.test_case(
        "REM-09", "Edit and delete reminder",
        "Edit channel or recurrence. Delete reminder.",
        "Changes persist; delete removes from list.",
    )
    pdf.test_case(
        "REM-10", "Lease expiry prompt",
        "Tenant with expired lease.",
        "Prompt to continue or remove recurring reminders.",
        "P2",
    )
    pdf.test_case(
        "REM-11", "Dispatch (backend)",
        "Wait for scheduled window or trigger test on stage.",
        "WhatsApp/SMS sent per template; no duplicate spam.",
        "P1",
    )

    pdf.section_title("9. Finances, Reports & Analytics")
    pdf.test_case(
        "FIN-01", "Financial overview",
        "Open Finances tab.",
        "Income vs expense, net income, arrears charts load.",
    )
    pdf.test_case(
        "FIN-02", "Record payment (generic)",
        "Record BnB or Rent payment with method and date.",
        "Appears in financial totals.",
    )
    pdf.test_case(
        "FIN-03", "Add expense",
        "Add expense tagged to property.",
        "Expense in Manage Expenses and P&L.",
    )
    pdf.test_case(
        "FIN-04", "Manage expenses",
        "Filter expenses by month/property.",
        "List accurate.",
    )
    pdf.test_case(
        "FIN-05", "Expense analysis",
        "Open expense analysis charts.",
        "Categories and trends display.",
        "P2",
    )
    pdf.test_case(
        "FIN-06", "Reports hub",
        "Open Reports. Generate/export report.",
        "Report data matches app records.",
    )
    pdf.test_case(
        "FIN-07", "Monthly P&L summary",
        "Open monthly P&L for Rent property.",
        "Income and expenses reconcile.",
        "P2",
    )
    pdf.test_case(
        "FIN-08", "ROI / break-even",
        "Enter ROI estimates. View break-even charts.",
        "Calculations display; notification on break-even if configured.",
        "P2",
    )
    pdf.test_case(
        "FIN-09", "Profit analysis dashboard",
        "Open profit analysis for listing.",
        "KPIs match recorded transactions.",
        "P2",
    )
    pdf.test_case(
        "FIN-10", "Payment alerts dashboard",
        "Open payment alerts.",
        "Overdue/at-risk tenants highlighted.",
        "P2",
    )

    pdf.section_title("10. Maintenance")
    pdf.test_case(
        "MNT-01", "BnB maintenance tasks",
        "Maintenance tab > add task. Set date and priority.",
        "Task listed; appears on calendar.",
    )
    pdf.test_case(
        "MNT-02", "Rent scheduled maintenance",
        "Schedule maintenance from Rent flow.",
        "Task saves; day-before push reminder fires.",
    )
    pdf.test_case(
        "MNT-03", "Edit/complete task",
        "Mark task complete or edit details.",
        "Status updates.",
    )
    pdf.test_case(
        "MNT-04", "Maintenance cost analysis",
        "View maintenance spending analysis.",
        "Totals align with logged expenses.",
        "P2",
    )

    pdf.section_title("11. Utilities (LUKU / Smart Utility)")
    pdf.test_case(
        "UTIL-01", "Smart utility dashboard",
        "Open utility dashboard for Rent property.",
        "LUKU balance and history visible.",
    )
    pdf.test_case(
        "UTIL-02", "Per-unit filter",
        "Select unit chip. Log top-up.",
        "Stats scoped to unit; top-up tagged correctly.",
    )
    pdf.test_case(
        "UTIL-03", "SMS receipt scan",
        "Scan LUKU SMS receipt.",
        "Top-up parsed and recorded.",
        "P2",
    )
    pdf.test_case(
        "UTIL-04", "Usage graph",
        "Open utility usage graph.",
        "Chart renders for selected period.",
        "P2",
    )

    pdf.section_title("12. Messaging (SMS & WhatsApp)")
    pdf.test_case(
        "MSG-01", "Send SMS",
        "More > Send SMS. Message one tenant.",
        "SMS queued/sent via backend.",
    )
    pdf.test_case(
        "MSG-02", "Bulk WhatsApp",
        "Send bulk WhatsApp to multiple tenants.",
        "Messages sent with rate limiting.",
    )
    pdf.test_case(
        "MSG-03", "WhatsApp template builder",
        "Create/edit WhatsApp template with placeholders.",
        "Template saves and usable in reminders.",
    )
    pdf.test_case(
        "MSG-04", "WhatsApp connection status",
        "Check WhatsApp status in Send SMS screen.",
        "Connected/disconnected state accurate.",
        "P2",
    )
    pdf.test_case(
        "MSG-05", "Concierge inbox",
        "Open Rent concierge inbox.",
        "Messages/threads load.",
        "P2",
    )

    pdf.section_title("13. Documents, Vault & Scanner")
    pdf.test_case(
        "DOC-01", "Document scanner",
        "Scan document with camera.",
        "Preview and save flow works.",
    )
    pdf.test_case(
        "DOC-02", "Refine scan",
        "Crop/adjust scanned image.",
        "Saved document quality acceptable.",
    )
    pdf.test_case(
        "DOC-03", "Property vault",
        "Upload document to vault. Categorize.",
        "Document retrievable offline after sync.",
    )
    pdf.test_case(
        "DOC-04", "Documents list",
        "Browse all documents.",
        "Filter/search works.",
        "P2",
    )

    pdf.section_title("14. Smart Access & Security Devices")
    pdf.test_case(
        "ACC-01", "Smart access screen",
        "Open Smart Access from More.",
        "Devices list or setup prompt shown.",
        "P2",
    )
    pdf.test_case(
        "ACC-02", "Entry logs",
        "View entry logs for connected lock.",
        "Events listed with timestamps.",
        "P3",
    )
    pdf.test_case(
        "ACC-03", "Tuya lock integration",
        "Pair/control lock if hardware available.",
        "Lock status updates.",
        "P3",
    )

    pdf.section_title("15. AI & Design Tools")
    pdf.test_case(
        "AI-01", "AI Manager chat",
        "Ask portfolio questions online.",
        "Relevant answers; handles empty portfolio gracefully.",
        "P2",
    )
    pdf.test_case(
        "AI-02", "AI offline behavior",
        "Ask AI Manager while offline.",
        "Uses local data or clear offline message.",
        "P2",
    )
    pdf.test_case(
        "AI-03", "AI pricing optimizer",
        "Open pricing optimizer for listing.",
        "Suggestions display without crash.",
        "P3",
    )
    pdf.test_case(
        "AI-04", "Price analysis",
        "Run price analysis.",
        "Results render.",
        "P3",
    )
    pdf.test_case(
        "DS-01", "Interior design studio",
        "Open design studio. Run generation if available.",
        "UI functional; errors handled.",
        "P3",
    )
    pdf.test_case(
        "DS-02", "Moodboards",
        "Create moodboard; add images.",
        "Board saves per property.",
        "P3",
    )

    pdf.section_title("16. Staff, Inventory & Loyalty")
    pdf.test_case(
        "STF-01", "Staff management",
        "Add staff member to property.",
        "Staff appears on listing/team screen.",
        "P2",
    )
    pdf.test_case(
        "STF-02", "Staff payroll details",
        "View payroll reminders/details.",
        "Data consistent with staff records.",
        "P3",
    )
    pdf.test_case(
        "INV-01", "Inventory tracking",
        "Add inventory item. Record movement.",
        "Stock levels update.",
        "P2",
    )
    pdf.test_case(
        "LOY-01", "Define loyalty offers",
        "Create loyalty program offer.",
        "Offer listed in active programs.",
        "P3",
    )
    pdf.test_case(
        "LOY-02", "Loyalty thresholds",
        "Configure thresholds.",
        "Settings persist.",
        "P3",
    )

    pdf.section_title("17. Subscription & Payments (App)")
    pdf.test_case(
        "SUB-01", "View subscription status",
        "Open Subscription screen.",
        "Current plan/status from server.",
        "P2",
    )
    pdf.test_case(
        "SUB-02", "Purchase/renew (iOS)",
        "Test IAP on iOS sandbox.",
        "Subscription activates after Apple confirmation.",
        "P2",
    )
    pdf.test_case(
        "SUB-03", "Snippe payment link",
        "Send payment link to tenant if feature enabled.",
        "Link created; webhook updates status.",
        "P3",
    )

    pdf.section_title("18. Admin & Sales Agent (Role-Based)")
    pdf.test_case(
        "ADM-01", "Admin WhatsApp credentials",
        "Login as admin. Open WhatsApp credentials report.",
        "Admin-only access enforced.",
        "P2",
    )
    pdf.test_case(
        "ADM-02", "Sales agents list",
        "Admin views sales agents.",
        "List and detail screens work.",
        "P3",
    )
    pdf.test_case(
        "ADM-03", "Sales agent dashboard",
        "Login as sales agent role.",
        "Dashboard scoped to agent permissions.",
        "P3",
    )

    pdf.section_title("19. Settings, Profile & Support")
    pdf.test_case(
        "SET-01", "Change base currency",
        "Settings > Currency. Change TZS/USD etc.",
        "Dashboard totals convert; originals preserved.",
    )
    pdf.test_case(
        "SET-02", "Dark mode",
        "Toggle theme.",
        "UI readable in light and dark.",
    )
    pdf.test_case(
        "SET-03", "Notifications preferences",
        "Toggle notification settings.",
        "Preferences persist.",
        "P2",
    )
    pdf.test_case(
        "SET-04", "Clear offline data",
        "Settings > Clear offline data (test account only).",
        "Local DB cleared; re-sync from server.",
        "P2",
    )
    pdf.test_case(
        "SET-05", "Help center",
        "Open Help Center. Open a guide. Deep link to feature.",
        "Guides open; navigation works.",
    )
    pdf.test_case(
        "SET-06", "Support & feedback",
        "Submit support message and feedback.",
        "Submission succeeds or shows error.",
        "P2",
    )
    pdf.test_case(
        "SET-07", "Terms & privacy",
        "Open Terms and Privacy screens.",
        "Content loads.",
        "P3",
    )
    pdf.test_case(
        "SET-08", "About / app version",
        "Open About.",
        "Version matches build.",
        "P3",
    )

    pdf.section_title("20. Offline Mode & Sync")
    pdf.test_case(
        "SYNC-01", "Offline property view",
        "Load properties online. Go offline. Browse listings.",
        "Cached data visible.",
    )
    pdf.test_case(
        "SYNC-02", "Offline create",
        "Create expense or payment offline.",
        "Queued locally; syncs when online.",
    )
    pdf.test_case(
        "SYNC-03", "Sync after reconnect",
        "Perform offline writes. Restore network.",
        "Queue drains; no duplicate records.",
    )
    pdf.test_case(
        "SYNC-04", "Conflict handling",
        "Edit same record on two devices (if testable).",
        "Predictable resolution or last-write wins documented.",
        "P3",
    )

    pdf.section_title("21. Notifications & Background")
    pdf.test_case(
        "NOT-01", "Push notification receive",
        "Trigger maintenance/reminder notification.",
        "Notification received on device.",
        "P2",
    )
    pdf.test_case(
        "NOT-02", "Notification tap deep link",
        "Tap notification.",
        "Opens relevant in-app screen.",
        "P2",
    )
    pdf.test_case(
        "NOT-03", "In-app notifications list",
        "Open Notifications screen.",
        "List loads and marks read.",
        "P2",
    )

    pdf.section_title("22. Platform-Specific (iOS & Android)")
    pdf.test_case(
        "PLAT-01", "iOS Face ID",
        "Full auth + app lock flow on iPhone.",
        "Face ID works; no Keychain errors.",
    )
    pdf.test_case(
        "PLAT-02", "Android fingerprint",
        "Full auth + app lock on Android.",
        "Biometric prompt works.",
    )
    pdf.test_case(
        "PLAT-03", "Camera & gallery permissions",
        "Add listing photo, scan document.",
        "Permission prompts and fallbacks correct.",
    )
    pdf.test_case(
        "PLAT-04", "Share sheet",
        "Share report/lease via WhatsApp.",
        "OS share sheet opens with content.",
    )
    pdf.test_case(
        "PLAT-05", "Background/foreground",
        "Background app 5+ min. Return.",
        "App lock or resume without crash.",
    )

    pdf.add_page()
    pdf.section_title("Appendix A. Bug Report Template")
    pdf.body(
        "For each failure, record:\n"
        "1. Test ID (e.g. AUTH-11)\n"
        "2. Build number & environment (stage/prod)\n"
        "3. Device & OS\n"
        "4. Steps to reproduce\n"
        "5. Expected vs actual\n"
        "6. Screenshot or screen recording\n"
        "7. Severity: Blocker / Major / Minor / Trivial"
    )
    pdf.section_title("Appendix B. Suggested Test Order")
    pdf.body(
        "Day 1: Sections 0-2 (Auth, onboarding)\n"
        "Day 2: Sections 3-7 (Core BnB + Rent flows)\n"
        "Day 3: Sections 8-12 (Reminders, finances, messaging)\n"
        "Day 4: Sections 13-20 (Documents, AI, settings, offline)\n"
        "Day 5: Sections 21-22 + regression on P1 failures"
    )

    pdf.output(output_path)


if __name__ == "__main__":
    build_pdf("host_bora_qa_test_plan.pdf")
    print("Wrote host_bora_qa_test_plan.pdf")
