# CRUD test cases by module

Four checks for every folder under `lib/app/modules/`. Rent’s child folders are listed under `rent/`, because that is where those writes live.

## How to mark a store

| Store | Pass when |
|---|---|
| Phone | Force-close the app, reopen, and the same record is still there. SQLite tables are in the app database. Vault documents and a few drafts live in GetStorage, not SQLite. |
| Remote | Sign in on a second device, or clear app data and sign in again, then let sync finish. The record must come back from the API. A “saved on this device” message is a phone pass only. |

The phone schema does **not** declare SQL `FOREIGN KEY` clauses. Parent links are plain text (`property_ref`, `apartment_unit_id`, `tenant_id`). Orphan rows are possible. The only unique indexes are listed under Unique below.

Use a marker name `QA-<module>-<timestamp>` so rows are easy to find and delete afterward. Do not run deletes against production data you need to keep.

Unique indexes that do exist:

| Table | Unique key |
|---|---|
| `exchange_rates` | `currency` |
| `rent_property_estimate` | `property_ref` |
| `rent_whatsapp_template` | `(name, language)` |
| `property_members` | `(property_ref, user_id, workspace_type)` |
| `offline_sync_queue` | `dedupe_key` when not empty |

---

## Screens with no create/update/delete

These folders only navigate, read, or call a non-record API. Round-trip, constraint, unique, and foreign-key checks are **N/A**. Pass if the screen opens and does not write a new business row.

`about`, `admin_growth_metrics`, `admin_sales_agents`, `ai_automations`, `ai_insights`, `ai_pricing_optimizer`, `design_moodboard`, `design_moodboards`, `entry_logs`, `expense_analysis`, `financial_overview`, `help_center`, `home`, `host_dashboard`, `interior_design_studio`, `listing_published`, `main`, `more`, `notifications`, `onboarding`, `other`, `password_updated`, `price_analysis`, `privacy`, `sales_agent_dashboard`, `smart_access`, `support`, `terms`, `unit_occupancy`, `welcome_back`.

`home` and `ai_manager` can launch other modules. Run the target module’s cases, not a second CRUD set here.

Read-only rent folders (same N/A): `hub`, `my_properties_hub`, `apartment_reports`, `concierge_inbox`, `contract_hub`, `host_dashboard_payment_alerts`, `listing_activity_log` (except expense delete, covered under expenses), `listing_analytics_dashboard`, `maintenance_cost_analysis`, `monthly_pl_summary`, `profit_analysis_dashboard`, `property_roi_analysis`, `smart_utility_dashboard` (top-ups are under utility), `staff_payroll_details`, `tenant_residency_payment_tracker`, `utility_usage_graph`, `active_loyalty_programs`, `widgets`.

---

## auth, otp, create_host_account, verify_identity

Remote: `POST /api/auth/login`, OTP request/verify, `POST /api/auth/reg`. Phone: session and user profile in preferences.

| Test | Steps and expected result |
|---|---|
| Round-trip | Register a host, confirm OTP, sign out, sign in. Phone keeps the session. Remote user exists and the second login returns that same account. There is no in-app delete of the auth user except Settings → delete account (`DELETE /api/users/me`). |
| Constraint | Empty phone, a number that is not `0[678]XXXXXXXX`, a short password, and a wrong OTP each show an error and do not create a session. |
| Unique | Registering the same phone again is rejected. A second login does not create a second user. |
| Foreign key | OTP verify requires the registration/login request that issued the code. A code from another phone fails. |

## change_password, reset_password, new_password

Remote password endpoints. Phone session stays on the same user.

| Test | Steps and expected result |
|---|---|
| Round-trip | Change the password, sign out, sign in with the new password. The old password fails. |
| Constraint | Mismatched confirmation, empty fields, and a wrong current password are rejected. |
| Unique | N/A. One password per account. |
| Foreign key | Reset OTP must belong to that phone. |

## change_pin, security

Remote: change/verify PIN. Phone: PIN gate on Welcome Back.

| Test | Steps and expected result |
|---|---|
| Round-trip | Set a PIN, lock the app, unlock with it. Wrong PIN does not unlock. |
| Constraint | PIN length must match the form. Empty submit is rejected. |
| Unique | Replacing the PIN overwrites the previous one. Two PINs are not stored. |
| Foreign key | PIN is stored for the signed-in user only. |

## settings

Remote: `POST /api/user/update/preference`. Phone: preference flags.

| Test | Steps and expected result |
|---|---|
| Round-trip | Change language or a saved preference, force-close, reopen. The value remains. Sign in on a second device and confirm the preference syncs if the server stores it. |
| Constraint | Invalid values are not offered by the controls. |
| Unique | One preference row per user. A second save updates it. |
| Foreign key | Preferences belong to the signed-in user. Logout must not show the previous user’s data (`LocalAccountDataReset`). |

## subscription

Remote subscription status. Phone caches the plan.

| Test | Steps and expected result |
|---|---|
| Round-trip | Open plans. The active plan matches the account. Do not complete a live charge unless explicitly approved. |
| Constraint | Free and Starter cannot open Pro routes; the upgrade sheet names the feature. |
| Unique | One subscription state per user. Refresh replaces it. |
| Foreign key | Plan gates use the signed-in user. A staff session does not inherit the host’s Ultra tools beyond `getMyAccess`. |

## feedback

Remote: `submitFeedback`. No phone table.

| Test | Steps and expected result |
|---|---|
| Round-trip | Send feedback. Success message. A second device does not list sent feedback (no local list). |
| Constraint | Empty message is rejected. |
| Unique | Two sends create two feedback records. |
| Foreign key | Feedback is attributed to the signed-in user. |

## add_listing, edit_listing, edit_unit, my_properties, listing_details

Phone: `properties`, `property_units`. Remote: `POST /api/properties`, `PUT /api/properties/ref/{propertyRef}`, `DELETE /api/properties/{id}`. Units travel inside `units_json`. The app does **not** insert rows into a remote `property_units` table.

| Test | Steps and expected result |
|---|---|
| Round-trip | Create a house with location and rent. It appears in My Properties after reopen (phone). After sync, a second device shows one property, not two. Edit the name. Both devices show the new name. Delete it from My Properties or listing details. It is gone locally and is not returned by `GET /api/properties`. |
| Constraint | Empty location is rejected. An apartment with no unit is rejected. A non-apartment without a positive rent is rejected. Unit name and rent are required when adding a unit. |
| Unique | Saving once creates one remote row. Creating the same name twice is allowed (no unique index on name or `property_ref`). Confirm the in-session create lock does not insert a second row for one save. |
| Foreign key | Add a unit, then a tenant on that unit. The tenant’s `property_ref` and `apartment_unit_id` match the property and the unit id in `units_json`. Deleting the property removes or hides its units and must not leave the tenant pointing at a live property. Multi-unit `rent_amount` on the remote property is the monthly sum of rent-mode units, or empty when every unit is BnB. `tenants` on the property equals the count of active tenancies. |

## add_new_booking, all_bookings, booking_details, host_calendar, guest_history

Phone: tenant row for the stay, plus `pending_bookings` if the API fails. Remote: `POST /api/bookings`, checkout, cancel, update. Calendar reads bookings.

| Test | Steps and expected result |
|---|---|
| Round-trip | Create a booking on a BnB unit. It shows in All Bookings and on the calendar after reopen. Second device shows it after sync. Update dates. Cancel or check out. The status matches on both stores. |
| Constraint | Check-out must be after check-in by at least one night. A missing property or unit is rejected. |
| Unique | One save creates one booking. Overlapping the same unit is a product failure if both stays are accepted for the same dates. |
| Foreign key | Booking property and unit must exist. A booking whose property was deleted must not still appear as active on the calendar. |

## guest_access_codes

Phone/remote depend on the codes screen reading bookings and locks. Treat as read plus any code create the screen actually saves.

| Test | Steps and expected result |
|---|---|
| Round-trip | Open codes for a booking that exists. If the screen only displays a code, create/update/delete are N/A. |
| Constraint | No code is shown for a property with no booking. |
| Unique | N/A if codes are derived. |
| Foreign key | The code is for that booking’s unit, not another listing. |

## calendar_sync

Remote: calendar subscription create, update, delete, import. Phone: subscription list from the API.

| Test | Steps and expected result |
|---|---|
| Round-trip | Add a calendar subscription for one listing, see it, edit it, delete it. Second device matches after refresh. Pro gate: Free/Starter see the upgrade sheet. |
| Constraint | Empty URL or listing is rejected. |
| Unique | A second subscription for the same feed should update or be rejected, not create an endless duplicate. Record which one the server does. |
| Foreign key | Subscription `listingId` must be a real property. Deleting the property should remove or orphan the subscription; record which. |

## add_tenant_form, all_tenants, rent/tenant_ledger_occupancy

Phone: `tenant`. Remote: `POST/PUT/DELETE /api/tenants`. Ending a tenancy sets `tenancy_status` to `ended` and updates `properties.tenants`.

| Test | Steps and expected result |
|---|---|
| Round-trip | Add a rent tenant with phone, rent, and lease dates. Reopen All Tenants (phone). Second device shows the tenant (remote). Edit a field if the ledger allows it. End the tenancy. The tenant is no longer active, and the property’s tenant count drops on both the phone and, after sync, the remote `properties.tenants` column. |
| Constraint | Rent amount must be a positive number. BnB check-out must be after check-in. A unit is required when the property has units. |
| Unique | The same person can be saved twice if you submit twice; there is no unique index on phone + property. Replacing the tenant on a unit ends the previous active row instead of leaving two active tenants on that unit. |
| Foreign key | `property_ref` must match a property. `apartment_unit_id` must match a unit on that property. A tenant with a made-up property ref must not show under a real listing. Ending the tenant does not delete the property or the unit. |

## record_payment, rent/manage_payments, dashboard

Phone: `income`. Remote: `POST/PUT/DELETE /api/payments`.

| Test | Steps and expected result |
|---|---|
| Round-trip | Record a payment for a tenant. Finances and the tenant ledger show it after reopen. Second device shows it. Edit the amount if update exists. Delete from listing activity. Gone in both stores. |
| Constraint | Amount must be numeric and greater than zero. A date is required. |
| Unique | Two payments of the same amount are allowed. One submit must not create two income rows. |
| Foreign key | Payment property and tenant/unit labels refer to a real property. Deleting the tenant does not have a SQL cascade; the payment can remain as history. Deleting the payment must not delete the tenant. |

## add_expense, rent/manage_expenses

Phone: `expense`. Remote: `POST/PUT/DELETE /api/expenses`.

| Test | Steps and expected result |
|---|---|
| Round-trip | Add an expense with category and amount. It remains after reopen and appears on a second device. Edit it. Delete it from listing activity. Both stores drop it. |
| Constraint | Amount and category are required. Zero or blank amount is rejected. |
| Unique | Duplicate amounts are allowed. One save creates one row. |
| Foreign key | Property label/ref on the expense matches the listing you picked. Deleting the property does not SQL-delete the expense; confirm the UI hides it. |

## add_task, edit_task, task_detail, maintenance_tasks

Phone: scheduled maintenance / task assignment store. Remote: `POST/PUT/DELETE /api/tasks`.

| Test | Steps and expected result |
|---|---|
| Round-trip | Create a task with a title and property. It is on the tasks list after reopen and on a second device. Edit the title. Delete it. Both stores drop it. Assignment to staff is Pro. |
| Constraint | Empty title or missing property is rejected. |
| Unique | One save creates one task. |
| Foreign key | Task property ref matches a property. Assigned staff id matches a staff row. Deleting the staff member leaves the task unassigned or still named; record which. Deleting the property does not SQL-delete the task. |

## team_and_staff, staff_detail, rent/staff_management

Phone: `rent_staff` and/or `staff`. Remote: staff create, update, delete.

| Test | Steps and expected result |
|---|---|
| Round-trip | Add a staff member with name and phone. Reopen the roster. Second device shows them. Edit the job title. Delete them. Both stores drop them. Free/Starter see the upgrade sheet. |
| Constraint | Name is required. Pay amount, when collected, must be numeric. |
| Unique | The same phone can be added twice unless the form blocks it. Confirm one submit does not create two rows. |
| Foreign key | Staff linked to a property use that `property_ref`. Deleting the property does not SQL-delete staff. A task assigned to a deleted staff id must not crash the task list. |

## inventory_tracking

Phone: `inventory_item`, `inventory_movement`. Remote: create/update item and create movement.

| Test | Steps and expected result |
|---|---|
| Round-trip | Add an item with quantity. Reopen. Second device shows it. Adjust quantity. The movement row exists locally and remotely. Delete if the UI offers it; otherwise update quantity to zero and record that delete is absent. |
| Constraint | Name is required. Quantity and reorder level are integers. Negative stock is rejected or clamped; record which. |
| Unique | Same item name on one property is allowed unless the form blocks it. One save creates one item. |
| Foreign key | `property_ref` and unit id match the listing. A movement’s `item_local_id` matches the item. Deleting the item should remove or orphan movements; record which. There is no SQL foreign key. |

## add_document, documents, document_scanner, refine_scan, property_vault

Phone: GetStorage vault documents and recent-access, plus a file under the app documents `vault/` folder. Remote: upload, update, delete vault document.

| Test | Steps and expected result |
|---|---|
| Round-trip | From Property Vault +, stage a file, save into Tax Records. Reopen that folder and the file is still there (phone). Second device shows it after sync (remote). Rename if edit exists. Delete it. The file, the GetStorage row, and the remote document are gone. Scanner and refine must end on the vault with one saved document, not two. |
| Constraint | Save stays disabled until a file is chosen. A typed name alone does not save. A missing file shows “That file is no longer available”. |
| Unique | Saving once creates one document. The same file name may be saved twice; record whether both appear. |
| Foreign key | `directoryId` is one of the vault folders (default Legal Documents). A document does not require a property. Deleting a folder must not leave a tappable document that opens a missing file. |

## send_sms, rent/whatsapp_template_builder, rent/schedule_payment_reminder, rent/recurring_reminders

Phone: `scheduled_sms`, `scheduled_whatsapp`, `rent_payment_reminder`, `recurring_reminder`, `rent_whatsapp_template`. Remote: SMS send, WhatsApp send, template draft CRUD, payment reminder, recurring reminder.

| Test | Steps and expected result |
|---|---|
| Round-trip | Save a WhatsApp template, reopen the builder list, then confirm it on a second device. Edit and delete it. Schedule a reminder for a tenant and confirm it locally and on the server. Free/Starter are stopped by the Pro upgrade sheet before send. |
| Constraint | Template body is required. Phone number is required for SMS/WhatsApp. Reminder needs a tenant and a future time. |
| Unique | Template `(name, language)` is unique locally. A second save of the same name and language must update or be rejected, not crash. Reminder duplicates are allowed. |
| Foreign key | Reminder `tenant_id` / phone matches a tenant. A template send uses a template that still exists. Deleting the tenant does not SQL-delete reminders. |

## rent/define_tenant_charges

Phone: `rent_tenant_charge`. Remote: `createTenantCharge`.

| Test | Steps and expected result |
|---|---|
| Round-trip | Add a charge with type, amount, and property. It remains after reopen. Confirm the server received it. Update/delete only if the screen offers them. |
| Constraint | Amount and charge type are required. |
| Unique | Two charges of the same type are allowed. |
| Foreign key | Property label matches a real property. |

## rent/define_loyalty_offers

Phone: `rent_loyalty_offer`. Remote: `createLoyaltyOffer`.

| Test | Steps and expected result |
|---|---|
| Round-trip | Create an offer with a stay threshold and terms. It shows under active programs after reopen and on the server. |
| Constraint | Threshold and offer type are required. |
| Unique | Duplicate offers are allowed. |
| Foreign key | Offer is account-scoped. It is not tied to one tenant row. |

## rent/expected_payment_schedule, rent/schedule_maintenance_form

Phone: `rent_payment_reminder` or `scheduled_maintenance`. Remote: schedule reminder / scheduled maintenance.

| Test | Steps and expected result |
|---|---|
| Round-trip | Schedule one item on a property. Reopen. Second device shows it. |
| Constraint | Date and property are required. |
| Unique | One submit creates one row. |
| Foreign key | Property ref and unit id match the listing. |

## rent/lease_renewal_form, rent/share_renewed_lease

Remote: `renewLease`. Phone: tenant lease dates updated locally.

| Test | Steps and expected result |
|---|---|
| Round-trip | Renew a lease. The tenant’s end date changes after reopen and on a second device. Share opens the share sheet for that lease. |
| Constraint | New end date must be after the start. |
| Unique | Renewing once does not create a second tenant. |
| Foreign key | Renewal targets the selected tenant and property. |

## rent/property_roi_estimate_form

Phone: `rent_property_estimate` (`property_ref` unique). Remote: save/update estimate.

| Test | Steps and expected result |
|---|---|
| Round-trip | Save costs and expected income for one property. Reopen. Second device matches. Saving again updates the same estimate. |
| Constraint | Amounts must be numeric. |
| Unique | A second save for the same `property_ref` updates the row. It must not insert a second estimate. |
| Foreign key | `property_ref` matches a property. An estimate for a deleted property is hidden or left orphaned; record which. |

## rent utility top-up (from the utility dashboard)

Phone: `rent_utility_topup`. Remote: `addUtilityTopUp`.

| Test | Steps and expected result |
|---|---|
| Round-trip | Add a top-up with units and amount. The dashboard still shows it after reopen and on a second device. |
| Constraint | Units and amount must be numeric. Kind is required. |
| Unique | Two top-ups are allowed. |
| Foreign key | Property ref and unit id match the listing. |

## my_network, property_manager_directory

Remote: network, invites, property-manager contact. Phone: cached responses only.

| Test | Steps and expected result |
|---|---|
| Round-trip | Invite a manager, see them in the network, revoke them. Second device matches. Directory search is read-only. Contact does not create a local staff row. |
| Constraint | Invite requires a phone and name. |
| Unique | Inviting the same phone twice must not create two active managers. |
| Foreign key | Revoke uses that manager’s user id. A manager is not a `rent_staff` row. |

## challenges_rewards

Remote: rewards, academy, redeem. Phone: cached dashboard.

| Test | Steps and expected result |
|---|---|
| Round-trip | Open rewards. Complete academy if offered. Redeem only if it does not spend real value you need. The balance matches after refresh and on a second device. |
| Constraint | Redeem of an unaffordable item is rejected. |
| Unique | Completing academy twice does not double the grant. |
| Foreign key | Rewards belong to the signed-in host. |

## admin_whatsapp_credentials

Remote: admin WhatsApp credentials. Admin only.

| Test | Steps and expected result |
|---|---|
| Round-trip | Save credentials, reload, values persist on the server. A non-admin cannot open the screen. |
| Constraint | Required credential fields cannot be blank. |
| Unique | Save updates the single credential record. |
| Foreign key | Credentials are account/admin scoped, not per property. |

## client_story

Reads tenant events. Writes only if the story screen itself records an event (`client_event`).

| Test | Steps and expected result |
|---|---|
| Round-trip | Open a tenant’s story. Events from add-tenant and end-tenancy appear. Creating those events is covered by the tenant cases. |
| Constraint | A tenant with no events shows an empty story, not another tenant’s events. |
| Unique | N/A on this screen. |
| Foreign key | Every event `tenant_id` / `property_ref` matches the open tenant. |

## reports

Reads income, expenses, and properties. No new table.

| Test | Steps and expected result |
|---|---|
| Round-trip | N/A for writes. Totals match the payments and expenses created above. |
| Constraint | Empty account shows an empty report, not another user’s figures. |
| Unique | N/A. |
| Foreign key | Report lines use the same property refs as the source rows. |

---

## Cross-store failures to fail the run

- The phone shows the row and a second device never receives it after sync, for any entity whose remote column above is not “none”.
- One tap creates two remote rows (properties are the known risk).
- A child row (unit, tenant, payment, task, inventory movement) is visible under the wrong property.
- Delete on the phone still returns the row from the API after sync.
- `property_units` on the remote database stays empty after a property save. That is a current client limit: units are inside `properties.units_json` only. Do not mark that as a phone failure.
