# Host Bora — Feature matrix

Use this as the master checklist. Route paths match `lib/app/routes/app_routes.dart`.

Legend: **Auto** = covered by Firebase YAML · **Manual** = interactive/agent · **Gate** = plan/staff expected

## 0. Auth & session

| ID | Case | Route / entry | Expect | Coverage |
|----|------|---------------|--------|----------|
| A01 | Login phone + password | `/auth` | Reach Home, PIN setup, or OTP | Auto `00` |
| A02 | PIN unlock Welcome Back | `/welcome-back` | Unlock to `/main` with PIN | Auto `00` |
| A03 | Forgot password | `/reset-password` | OTP / code-sent state | Auto `00` |
| A04 | Change password | `/change-password` | Form validates; success feedback | Auto `00` |
| A05 | Onboarding | `/onboarding` | Completes or skips to Login | Auto `01` |
| A06 | Create host account + OTP | `/create-host-account`, `/otp` | Account created / OTP accepted | Auto `01` |
| A07 | Change PIN | `/change-pin` | PIN updated | Manual |
| A08 | Session expiry / logout | Settings / session | Returns to `/auth` | Manual |
| A09 | Offline returning session | cold start offline | Last session usable if supported | Manual |

## 1. Shell & navigation

| ID | Case | Entry | Expect | Coverage |
|----|------|-------|--------|----------|
| N01 | Bottom tab Home | Main | `HomeView` | Auto / Manual |
| N02 | Bottom tab Properties | Main | `MyPropertiesView` | Auto `02` |
| N03 | Bottom tab Finances | Main | `DashboardView` | Auto `04` |
| N04 | Bottom tab Services | Main | Maintenance tasks | Auto `08` |
| N05 | More Options FAB sheet | Center FAB | Shortcuts sheet opens | Auto `16` |
| N06 | More grid | More | Network, help, reports, etc. | Auto `15`/`16` |
| N07 | Staff-restricted tabs | Staff login | Denied tabs hidden / blocked | Manual Gate |

## 2. Properties & BnB

| ID | Case | Route | Expect | Coverage |
|----|------|-------|--------|----------|
| P01 | Property list | `/my-properties` | Lists or empty CTA | Auto `02` |
| P02 | Add listing | `/add-listing` | Wizard/form saves listing | Auto `02` |
| P03 | Listing details | `/listing-details` | Summary + actions | Auto `02` |
| P04 | Edit listing / unit | `/edit-listing`, `/edit-unit` | Saves changes | Auto `02` |
| P05 | Unit occupancy | `/listing-unit-occupancy` | Occupancy UI | Manual |
| P06 | All bookings | `/all-bookings` | List + filters | Auto `02` |
| P07 | Add / booking details | `/add-new-booking`, `/booking-details` | Create + view | Auto `02` |
| P08 | Host calendar | `/host-calendar` | Calendar loads | Auto `03` |
| P09 | Calendar sync | `/calendar-sync` | Sync options | Auto `03` |
| P10 | Guest history | `/guest-history` | Guest list | Auto `03` |
| P11 | Guest access codes | `/guest-access-codes` | Codes UI | Auto `03` |

## 3. Rent

| ID | Case | Route | Expect | Coverage |
|----|------|-------|--------|----------|
| R01 | Add tenant | `/add-new-tenant` | Tenant + lease saved | Auto `05` |
| R02 | All tenants / residency tracker | `/all-tenants`, `/rent/tenant-residency-payment-tracker` | Tenants visible | Auto `05` |
| R03 | Tenant ledger / occupancy | `/rent/tenant-ledger-occupancy` | Ledger loads | Auto `05` |
| R04 | Define tenant charges | `/rent/define-tenant-charges` | Charges form | Auto `05` |
| R05 | Manage rent payments | `/rent/manage-payments` | Payments UI | Auto `05` |
| R06 | Expected schedule / reminders | `/rent/expected-payment-schedule`, reminders routes | Schedule + reminder forms | Auto `05` |
| R07 | Lease renewal + share | `/rent/lease-renewal-form`, `/rent/share-renewed-lease` | Forms work | Auto `05` |
| R08 | Contract hub | `/rent/contract-hub` | Contracts list | Auto `05` |
| R09 | Profit / listing analytics | profit + listing analytics | Charts/summary | Auto `05`/`06` |
| R10 | ROI analysis / estimate | ROI routes | Metrics or form | Auto `06` |
| R11 | Staff management (rent) | `/rent/staff-management` | Staff roster | Auto `08` |
| R12 | Utilities + usage graph | smart utility + graph | Dashboard loads | Auto `06` |
| R13 | Loyalty programs | loyalty routes | Define + active lists | Auto `06` |
| R14 | Concierge inbox | `/rent/concierge-inbox` | Inbox UI | Auto `06` |
| R15 | Apartment reports + PDF | `/rent/apartment-reports` | Report UI; export if available | Auto `16` |
| R16 | WhatsApp template builder | `/rent/whatsapp-template-builder` | Builder opens | Manual |
| R17 | Client story | `/client-story` | Timeline | Auto `13` |
| R18 | Listing activity log | `/rent/listing-activity-log` | Events list | Auto `13` |
| R19 | Host payment alerts | `/rent/host-dashboard-payment-alerts` | Alerts UI | Manual |
| R20 | Monthly P&L / expenses / payroll | related rent routes | Screens load | Manual |

## 4. Finance

| ID | Case | Route | Expect | Coverage |
|----|------|-------|--------|----------|
| F01 | Financial overview / dashboard | Finances tab, `/financial-overview` | Totals render | Auto `04` |
| F02 | Record payment | `/record-payment` | Payment saved | Auto `04` |
| F03 | Add expense | `/add-expense` | Expense saved | Auto `04` |
| F04 | Expense analysis | `/expense-analysis` | Analysis UI | Auto `04` |
| F05 | Reports hub + monthly income | `/reports-hub`, `/reports/monthly-income` | Reports load | Auto `04`/`12` |

## 5. Documents & inventory

| ID | Case | Route | Expect | Coverage |
|----|------|-------|--------|----------|
| D01 | Documents | `/documents` | List / empty | Auto `07` |
| D02 | Property vault | `/property-vault` | Vault opens | Auto `07` |
| D03 | Add document form | `/add-document` | Name, folder, three sources; save disabled until a file | Auto `17` |
| D03a | Folder choice | `/add-document` | Default Legal Documents; folder can change | Auto `17` |
| D03b | Name without a file | `/add-document` | Name stays; save stays disabled | Auto `17` |
| D03c | Gallery / file cancel | `/add-document` | Back on the form, no preview | Auto `17` |
| D03d | Scan then back | scanner from Add Document | Scanner or permission; back returns to the form | Auto `17` |
| D03e | Stage, remove, save | `/add-document` | Preview + Remove; save lands in the chosen folder | Auto `17` |
| D03f | Document vault plan gate | Property Vault | Free/Starter: upgrade sheet. Pro/Ultra: form | Auto `17` Gate |
| D04 | Document scanner / refine | scanner routes | Navigation only (no camera) | Auto `07` |
| D05 | Inventory list + item form | `/inventory-tracking`, `/inventory-item-form` | CRUD UI | Auto `16` |

## 6. Tasks & staff

| ID | Case | Route | Expect | Coverage |
|----|------|-------|--------|----------|
| T01 | Maintenance tasks list | `/maintenance-tasks` | Tasks list | Auto `08` |
| T02 | Add / edit / detail task | add/edit/detail | CRUD works | Auto `08` |
| T03 | Team and staff | `/team-and-staff` | Roster | Auto `08` |
| T04 | Staff detail | `/staff-detail` | Detail | Auto `08` |

## 7. AI, pricing, design

| ID | Case | Route | Expect | Coverage |
|----|------|-------|--------|----------|
| I01 | AI Manager | `/ai-manager` | Chat/manager UI | Auto `09` |
| I02 | Price analysis / AI pricing | pricing routes | Analysis UI | Auto `09` |
| I03 | Interior design studio / moodboards | design routes | Studio opens (token may gate) | Auto `09` |
| I04 | Home quick actions + Other(AI) | Home dialog | Wizards / routing | Auto `14` |

## 8. Communications & subscription

| ID | Case | Route | Expect | Coverage |
|----|------|-------|--------|----------|
| C01 | Send SMS | `/send-sms` | Pro: composer · non-Pro: Upgrade → Subscription | Auto `10` Gate |
| C02 | Subscription plans | `/subscription` | Plans visible; platform pay method | Auto `12` |
| C03 | Admin WhatsApp credentials | `/admin/whatsapp-credentials` | Admin-only; else blocked | Manual Gate |

## 9. Smart access

| ID | Case | Route | Expect | Coverage |
|----|------|-------|--------|----------|
| S01 | Smart access | `/smart-access` | UI / Tuya connect states | Auto `11` |
| S02 | Entry logs | `/entry-logs` | Logs list | Auto `11` |

## 10. Network, managers, rewards

| ID | Case | Route | Expect | Coverage |
|----|------|-------|--------|----------|
| M01 | My Network | `/my-network` | Network list/empty | Auto `15` |
| M02 | Property manager directory | `/property-managers` | Directory list | Auto `15` |
| M03 | Manager profile | `/property-managers/profile` | Profile detail | Auto `15` |
| M04 | Challenges & rewards | `/challenges-rewards` | Dashboard | Auto `15` |

## 11. Help & settings

| ID | Case | Route | Expect | Coverage |
|----|------|-------|--------|----------|
| H01 | Help center + guide | `/help-center`, `/help-center/guide` | Tabs + article | Auto `13` |
| H02 | Support / feedback | `/support`, `/feedback` | Forms | Auto `13` |
| H03 | About / terms / privacy | about/legal | Content visible | Auto `13` |
| H04 | Settings language / security | `/settings`, `/security` | Options work | Auto `13` |
| H05 | Notifications | `/notifications` | List | Manual |
| H06 | Guided tour | Help tour service | Tour starts/stops cleanly | Manual |

## 12. Admin / sales (role-specific)

| ID | Case | Route | Expect | Coverage |
|----|------|-------|--------|----------|
| X01 | Sales agents admin | `/admin/sales-agents` | Admin-only | Manual Gate |
| X02 | Growth metrics | `/admin/growth-metrics` | Admin-only | Manual Gate |
| X03 | Sales agent dashboard | `/sales-agent/dashboard` | Agent role | Manual Gate |

## Declared but not registered (flag if UI links them)

- `/splash`, `/success`, `/failed`
- `/rent/financial-comparison`
- `/rent/loyalty-thresholds`
- `/rent/estate-manager-dashboard`

Opening these via deep link should not crash; report if dead links exist in UI.
