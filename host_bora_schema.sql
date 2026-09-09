-- ============================================================
-- Host Bora — SQL Server (T-SQL) Schema
-- Converted from lib/app/data/local/db/app_local_database.dart
--
-- Conversion notes:
--   INTEGER PRIMARY KEY AUTOINCREMENT  → INT IDENTITY(1,1) PRIMARY KEY
--   TEXT (short labels)                → NVARCHAR(255) / NVARCHAR(500)
--   TEXT (long / unbounded)            → NVARCHAR(MAX)
--   REAL                               → FLOAT
--   INTEGER (boolean 0/1 flags)        → BIT
--   INTEGER (epoch milliseconds)       → BIGINT
--   CREATE TABLE IF NOT EXISTS         → IF OBJECT_ID(...) IS NULL + dynamic block
--   Partial index (WHERE col != '')    → filtered index on SQL Server
--   AUTOINCREMENT default ''           → DEFAULT N''
-- ============================================================

USE paa_yangu;   -- change to your target database name
GO

-- ── properties ───────────────────────────────────────────────────────────────

IF OBJECT_ID(N'dbo.properties', N'U') IS NULL
CREATE TABLE dbo.properties (
    id                   INT           NOT NULL IDENTITY(1,1) PRIMARY KEY,
    location             NVARCHAR(MAX) NOT NULL,
    name                 NVARCHAR(255) NOT NULL DEFAULT N'',
    type                 NVARCHAR(100) NOT NULL DEFAULT N'',
    tenants              INT           NOT NULL DEFAULT 0,
    units                INT           NOT NULL DEFAULT 0,
    property_ref         NVARCHAR(255) NOT NULL DEFAULT N'',
    owner_user_id        NVARCHAR(255) NOT NULL DEFAULT N'',
    workspace_type       NVARCHAR(50)  NOT NULL DEFAULT N'rent',
    created_at_ms        BIGINT        NOT NULL,
    rent_amount          NVARCHAR(100) NOT NULL DEFAULT N'',
    rent_frequency       NVARCHAR(100) NOT NULL DEFAULT N'',
    min_rental_duration  NVARCHAR(100) NOT NULL DEFAULT N'',
    units_json           NVARCHAR(MAX) NULL,
    floor_count          INT           NOT NULL DEFAULT 1,
    cover_photo_path     NVARCHAR(500) NOT NULL DEFAULT N''
);
GO

IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = N'idx_properties_id_workspace' AND object_id = OBJECT_ID(N'dbo.properties'))
    CREATE INDEX idx_properties_id_workspace ON dbo.properties (id, workspace_type);
GO

-- ── property_units ───────────────────────────────────────────────────────────

IF OBJECT_ID(N'dbo.property_units', N'U') IS NULL
CREATE TABLE dbo.property_units (
    id                 INT           NOT NULL IDENTITY(1,1) PRIMARY KEY,
    property_unit_ref  NVARCHAR(255) NOT NULL DEFAULT N'',
    property_ref       NVARCHAR(255) NOT NULL DEFAULT N'',
    unit_name          NVARCHAR(255) NOT NULL,
    status             NVARCHAR(100) NOT NULL DEFAULT N'',
    rent_amount        FLOAT         NOT NULL DEFAULT 0,
    rent_frequency     NVARCHAR(100) NOT NULL DEFAULT N'',
    min_rent_duration  NVARCHAR(100) NOT NULL DEFAULT N'',
    max_guests         INT           NOT NULL DEFAULT 0,
    rooms              INT           NOT NULL DEFAULT 0,
    floor              INT           NOT NULL DEFAULT 0,
    operation_mode     NVARCHAR(50)  NOT NULL DEFAULT N'bnb',
    notes              NVARCHAR(MAX) NULL,
    created_at_ms      BIGINT        NOT NULL
);
GO

IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = N'idx_property_units_property_ref' AND object_id = OBJECT_ID(N'dbo.property_units'))
    CREATE INDEX idx_property_units_property_ref ON dbo.property_units (property_ref);
GO

-- ── staff ────────────────────────────────────────────────────────────────────

IF OBJECT_ID(N'dbo.staff', N'U') IS NULL
CREATE TABLE dbo.staff (
    id               INT           NOT NULL IDENTITY(1,1) PRIMARY KEY,
    name             NVARCHAR(255) NOT NULL,
    property_ref     NVARCHAR(255) NOT NULL DEFAULT N'',
    job_title        NVARCHAR(255) NOT NULL DEFAULT N'',
    pay_amount_label NVARCHAR(100) NOT NULL DEFAULT N'',
    pay_day_label    NVARCHAR(100) NOT NULL DEFAULT N'',
    created_at_ms    BIGINT        NOT NULL,
    payment_type     NVARCHAR(50)  NOT NULL DEFAULT N'monthly',
    amount_value     FLOAT         NOT NULL DEFAULT 0
);
GO

-- ── income ───────────────────────────────────────────────────────────────────

IF OBJECT_ID(N'dbo.income', N'U') IS NULL
CREATE TABLE dbo.income (
    id                  INT           NOT NULL IDENTITY(1,1) PRIMARY KEY,
    tenant_name         NVARCHAR(255) NOT NULL,
    amount_value        FLOAT         NOT NULL,
    date_paid_iso       NVARCHAR(30)  NOT NULL,
    category            NVARCHAR(100) NOT NULL,
    notes               NVARCHAR(MAX) NULL,
    apartment           NVARCHAR(255) NOT NULL DEFAULT N'',
    apartment_unit      NVARCHAR(255) NOT NULL DEFAULT N'',
    property_ref        NVARCHAR(255) NOT NULL DEFAULT N'',
    booking_id          NVARCHAR(255) NOT NULL DEFAULT N'',
    workspace_type      NVARCHAR(50)  NOT NULL DEFAULT N'rent',
    currency_code       NVARCHAR(10)  NOT NULL DEFAULT N'TZS',
    input_amount_value  FLOAT         NOT NULL DEFAULT 0,
    created_at_ms       BIGINT        NOT NULL
);
GO

-- Filtered index mirrors SQLite's partial index WHERE booking_id != ''
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = N'idx_income_booking_id' AND object_id = OBJECT_ID(N'dbo.income'))
    CREATE INDEX idx_income_booking_id ON dbo.income (booking_id)
    WHERE booking_id <> N'';
GO

-- ── expense ───────────────────────────────────────────────────────────────────

IF OBJECT_ID(N'dbo.expense', N'U') IS NULL
CREATE TABLE dbo.expense (
    id                  INT           NOT NULL IDENTITY(1,1) PRIMARY KEY,
    tenant_name         NVARCHAR(255) NOT NULL DEFAULT N'',
    amount_value        FLOAT         NOT NULL,
    date_paid_iso       NVARCHAR(30)  NOT NULL,
    category            NVARCHAR(100) NOT NULL,
    notes               NVARCHAR(MAX) NULL,
    apartment           NVARCHAR(255) NOT NULL DEFAULT N'',
    apartment_unit      NVARCHAR(255) NOT NULL DEFAULT N'',
    workspace_type      NVARCHAR(50)  NOT NULL DEFAULT N'rent',
    currency_code       NVARCHAR(10)  NOT NULL DEFAULT N'TZS',
    input_amount_value  FLOAT         NOT NULL DEFAULT 0,
    created_at_ms       BIGINT        NOT NULL
);
GO

-- ── exchange_rates ────────────────────────────────────────────────────────────

IF OBJECT_ID(N'dbo.exchange_rates', N'U') IS NULL
CREATE TABLE dbo.exchange_rates (
    currency      NVARCHAR(10) NOT NULL PRIMARY KEY,
    buying        FLOAT        NOT NULL,
    selling       FLOAT        NOT NULL,
    updated_at_ms BIGINT       NOT NULL
);
GO

-- ── tenant ────────────────────────────────────────────────────────────────────

IF OBJECT_ID(N'dbo.tenant', N'U') IS NULL
CREATE TABLE dbo.tenant (
    id                  INT           NOT NULL IDENTITY(1,1) PRIMARY KEY,
    property_label      NVARCHAR(255) NOT NULL,
    property_ref        NVARCHAR(255) NOT NULL DEFAULT N'',
    apartment_unit_id   NVARCHAR(255) NOT NULL DEFAULT N'',
    unit_label          NVARCHAR(255) NOT NULL DEFAULT N'',
    tenant_name         NVARCHAR(255) NOT NULL,
    gender              NVARCHAR(20)  NOT NULL,
    amount_paid         FLOAT         NOT NULL DEFAULT 0,
    rent_frequency      NVARCHAR(100) NOT NULL,
    phone_number        NVARCHAR(30)  NOT NULL,
    email               NVARCHAR(255) NOT NULL DEFAULT N'',
    is_whatsapp         BIT           NOT NULL DEFAULT 0,
    lease_start_iso     NVARCHAR(30)  NOT NULL,
    lease_end_iso       NVARCHAR(30)  NOT NULL,
    payment_status      NVARCHAR(50)  NOT NULL DEFAULT N'pending',
    contract_file_path  NVARCHAR(500) NOT NULL DEFAULT N'',
    contract_file_name  NVARCHAR(255) NOT NULL DEFAULT N'',
    notes               NVARCHAR(MAX) NULL,
    created_at_ms       BIGINT        NOT NULL
);
GO

IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = N'idx_tenant_listing_dates' AND object_id = OBJECT_ID(N'dbo.tenant'))
    CREATE INDEX idx_tenant_listing_dates ON dbo.tenant (property_ref, lease_start_iso, lease_end_iso);
GO

-- ── scheduled_maintenance ─────────────────────────────────────────────────────

IF OBJECT_ID(N'dbo.scheduled_maintenance', N'U') IS NULL
CREATE TABLE dbo.scheduled_maintenance (
    id                  INT           NOT NULL IDENTITY(1,1) PRIMARY KEY,
    property_label      NVARCHAR(255) NOT NULL,
    property_ref        NVARCHAR(255) NOT NULL DEFAULT N'',
    apartment_unit_id   NVARCHAR(255) NOT NULL DEFAULT N'',
    workspace_type      NVARCHAR(50)  NOT NULL DEFAULT N'rent',
    category            NVARCHAR(100) NOT NULL,
    description         NVARCHAR(MAX) NOT NULL,
    scheduled_date_iso  NVARCHAR(30)  NOT NULL,
    priority            NVARCHAR(50)  NOT NULL,
    notification_id     INT           NOT NULL,
    sync_status         NVARCHAR(50)  NOT NULL DEFAULT N'pending',
    created_at_ms       BIGINT        NOT NULL
);
GO

-- ── rent_staff ────────────────────────────────────────────────────────────────

IF OBJECT_ID(N'dbo.rent_staff', N'U') IS NULL
CREATE TABLE dbo.rent_staff (
    id               INT           NOT NULL IDENTITY(1,1) PRIMARY KEY,
    name             NVARCHAR(255) NOT NULL,
    job_title        NVARCHAR(255) NOT NULL DEFAULT N'',
    pay_amount_label NVARCHAR(100) NOT NULL DEFAULT N'',
    pay_day_label    NVARCHAR(100) NOT NULL DEFAULT N'',
    created_at_ms    BIGINT        NOT NULL,
    payment_type     NVARCHAR(50)  NOT NULL DEFAULT N'monthly',
    amount_value     FLOAT         NOT NULL DEFAULT 0
);
GO

-- ── rent_loyalty_offer ────────────────────────────────────────────────────────

IF OBJECT_ID(N'dbo.rent_loyalty_offer', N'U') IS NULL
CREATE TABLE dbo.rent_loyalty_offer (
    id                    INT           NOT NULL IDENTITY(1,1) PRIMARY KEY,
    min_stay_months       INT           NOT NULL,
    revenue_threshold_tsh FLOAT         NOT NULL,
    offer_type            NVARCHAR(100) NOT NULL,
    terms                 NVARCHAR(MAX) NOT NULL,
    created_at_ms         BIGINT        NOT NULL
);
GO

-- ── rent_tenant_charge ────────────────────────────────────────────────────────

IF OBJECT_ID(N'dbo.rent_tenant_charge', N'U') IS NULL
CREATE TABLE dbo.rent_tenant_charge (
    id             INT           NOT NULL IDENTITY(1,1) PRIMARY KEY,
    property_label NVARCHAR(255) NOT NULL,
    charge_type    NVARCHAR(100) NOT NULL,
    amount_tsh     FLOAT         NOT NULL,
    description    NVARCHAR(MAX) NOT NULL,
    created_at_ms  BIGINT        NOT NULL
);
GO

-- ── rent_payment_reminder ─────────────────────────────────────────────────────

IF OBJECT_ID(N'dbo.rent_payment_reminder', N'U') IS NULL
CREATE TABLE dbo.rent_payment_reminder (
    id               INT           NOT NULL IDENTITY(1,1) PRIMARY KEY,
    tenant_name      NVARCHAR(255) NOT NULL,
    property_label   NVARCHAR(255) NOT NULL,
    balance_tsh      BIGINT        NOT NULL,
    reminder_at_iso  NVARCHAR(30)  NOT NULL,
    push_enabled     BIT           NOT NULL DEFAULT 1,
    whatsapp_enabled BIT           NOT NULL DEFAULT 1,
    email_enabled    BIT           NOT NULL DEFAULT 0,
    notification_id  INT           NOT NULL,
    sync_status      NVARCHAR(50)  NOT NULL DEFAULT N'pending',
    created_at_ms    BIGINT        NOT NULL
);
GO

-- ── scheduled_whatsapp ────────────────────────────────────────────────────────

IF OBJECT_ID(N'dbo.scheduled_whatsapp', N'U') IS NULL
CREATE TABLE dbo.scheduled_whatsapp (
    id                      INT           NOT NULL IDENTITY(1,1) PRIMARY KEY,
    workspace               NVARCHAR(50)  NOT NULL DEFAULT N'rent',
    recipient_phone         NVARCHAR(30)  NOT NULL,
    recipient_label         NVARCHAR(255) NOT NULL DEFAULT N'',
    message_body            NVARCHAR(MAX) NULL,
    template_name           NVARCHAR(255) NOT NULL DEFAULT N'',
    language_code           NVARCHAR(20)  NOT NULL DEFAULT N'',
    body_parameters_json    NVARCHAR(MAX) NULL,
    header_parameters_json  NVARCHAR(MAX) NULL,
    scheduled_at_iso        NVARCHAR(30)  NOT NULL,
    notification_id         INT           NOT NULL DEFAULT 0,
    sent                    BIT           NOT NULL DEFAULT 0,
    created_at_ms           BIGINT        NOT NULL
);
GO

-- ── rent_notification_log ─────────────────────────────────────────────────────

IF OBJECT_ID(N'dbo.rent_notification_log', N'U') IS NULL
CREATE TABLE dbo.rent_notification_log (
    id            INT           NOT NULL IDENTITY(1,1) PRIMARY KEY,
    type          NVARCHAR(100) NOT NULL,
    title         NVARCHAR(255) NOT NULL,
    subtitle      NVARCHAR(MAX) NOT NULL,
    action_label  NVARCHAR(255) NOT NULL DEFAULT N'',
    payload       NVARCHAR(MAX) NULL,
    is_read       BIT           NOT NULL DEFAULT 0,
    created_at_ms BIGINT        NOT NULL
);
GO

-- ── rent_property_estimate ────────────────────────────────────────────────────

IF OBJECT_ID(N'dbo.rent_property_estimate', N'U') IS NULL
CREATE TABLE dbo.rent_property_estimate (
    id                        INT           NOT NULL IDENTITY(1,1) PRIMARY KEY,
    property_ref              NVARCHAR(255) NOT NULL,
    property_label            NVARCHAR(255) NOT NULL,
    purchase_cost             FLOAT         NOT NULL DEFAULT 0,
    renovation_cost           FLOAT         NOT NULL DEFAULT 0,
    expected_monthly_income   FLOAT         NOT NULL DEFAULT 0,
    expected_monthly_expense  FLOAT         NOT NULL DEFAULT 0,
    target_occupancy_percent  FLOAT         NOT NULL DEFAULT 0,
    created_at_ms             BIGINT        NOT NULL,
    updated_at_ms             BIGINT        NOT NULL,
    CONSTRAINT uq_rent_property_estimate_ref UNIQUE (property_ref)
);
GO

-- ── rent_utility_topup ────────────────────────────────────────────────────────

IF OBJECT_ID(N'dbo.rent_utility_topup', N'U') IS NULL
CREATE TABLE dbo.rent_utility_topup (
    id             INT           NOT NULL IDENTITY(1,1) PRIMARY KEY,
    kind           NVARCHAR(50)  NOT NULL,
    units_added    FLOAT         NOT NULL,
    amount_tsh     FLOAT         NOT NULL DEFAULT 0,
    provider       NVARCHAR(255) NOT NULL DEFAULT N'',
    notes          NVARCHAR(MAX) NULL,
    property_label NVARCHAR(255) NOT NULL DEFAULT N'',
    property_ref   NVARCHAR(255) NOT NULL DEFAULT N'',
    date_iso       NVARCHAR(30)  NOT NULL,
    created_at_ms  BIGINT        NOT NULL
);
GO

IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = N'idx_rent_utility_topup_kind_date' AND object_id = OBJECT_ID(N'dbo.rent_utility_topup'))
    CREATE INDEX idx_rent_utility_topup_kind_date ON dbo.rent_utility_topup (kind, date_iso);
GO

-- ── rent_whatsapp_template ────────────────────────────────────────────────────

IF OBJECT_ID(N'dbo.rent_whatsapp_template', N'U') IS NULL
CREATE TABLE dbo.rent_whatsapp_template (
    id                    INT           NOT NULL IDENTITY(1,1) PRIMARY KEY,
    name                  NVARCHAR(255) NOT NULL,
    category              NVARCHAR(100) NOT NULL DEFAULT N'utility',
    language              NVARCHAR(20)  NOT NULL DEFAULT N'en_US',
    header_type           NVARCHAR(50)  NOT NULL DEFAULT N'none',
    header_text           NVARCHAR(MAX) NULL,
    body_text             NVARCHAR(MAX) NOT NULL,
    footer_text           NVARCHAR(MAX) NULL,
    buttons_json          NVARCHAR(MAX) NULL,
    sample_variables_json NVARCHAR(MAX) NULL,
    status                NVARCHAR(50)  NOT NULL DEFAULT N'draft',
    submitted_at_ms       BIGINT        NOT NULL DEFAULT 0,
    approved_at_ms        BIGINT        NOT NULL DEFAULT 0,
    rejection_reason      NVARCHAR(MAX) NULL,
    created_at_ms         BIGINT        NOT NULL,
    updated_at_ms         BIGINT        NOT NULL,
    CONSTRAINT uq_whatsapp_template_name_lang UNIQUE (name, language)
);
GO

-- ── property_members ──────────────────────────────────────────────────────────

IF OBJECT_ID(N'dbo.property_members', N'U') IS NULL
CREATE TABLE dbo.property_members (
    id             INT           NOT NULL IDENTITY(1,1) PRIMARY KEY,
    property_ref   NVARCHAR(255) NOT NULL,
    user_id        NVARCHAR(255) NOT NULL,
    workspace_type NVARCHAR(50)  NOT NULL DEFAULT N'rent',
    role           NVARCHAR(50)  NOT NULL DEFAULT N'co_host',
    created_at_ms  BIGINT        NOT NULL,
    CONSTRAINT uq_property_members UNIQUE (property_ref, user_id, workspace_type)
);
GO

IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = N'idx_property_members_workspace_user' AND object_id = OBJECT_ID(N'dbo.property_members'))
    CREATE INDEX idx_property_members_workspace_user ON dbo.property_members (workspace_type, user_id);
GO

-- ── portfolio_managers ────────────────────────────────────────────────────────
-- Portfolio-level grant: manager may fully manage the host's properties.

IF OBJECT_ID(N'dbo.portfolio_managers', N'U') IS NULL
CREATE TABLE dbo.portfolio_managers (
    id               NVARCHAR(36)  NOT NULL PRIMARY KEY,
    host_user_id     NVARCHAR(36)  NOT NULL,
    manager_user_id  NVARCHAR(36)  NOT NULL,
    status           NVARCHAR(50)  NOT NULL DEFAULT N'active',
    created_at_ms    BIGINT        NOT NULL,
    CONSTRAINT uq_portfolio_managers_host_manager UNIQUE (host_user_id, manager_user_id)
);
GO

IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = N'idx_portfolio_managers_manager' AND object_id = OBJECT_ID(N'dbo.portfolio_managers'))
    CREATE INDEX idx_portfolio_managers_manager ON dbo.portfolio_managers (manager_user_id, status);
GO

-- ── offline_sync_queue ────────────────────────────────────────────────────────
-- dedupe_key is NULL when there is no key; UNIQUE ignores NULLs in SQL Server,
-- mirroring SQLite's partial index (WHERE dedupe_key != '').

IF OBJECT_ID(N'dbo.offline_sync_queue', N'U') IS NULL
CREATE TABLE dbo.offline_sync_queue (
    id            INT            NOT NULL IDENTITY(1,1) PRIMARY KEY,
    entity_type   NVARCHAR(100)  NOT NULL,
    operation     NVARCHAR(100)  NOT NULL,
    payload_json  NVARCHAR(MAX)  NOT NULL,
    -- NULL = no deduplication key; multiple NULLs are permitted by UNIQUE
    dedupe_key    NVARCHAR(500)  NULL,
    status        NVARCHAR(50)   NOT NULL DEFAULT N'pending',
    attempt_count INT            NOT NULL DEFAULT 0,
    last_error    NVARCHAR(MAX)  NULL,
    created_at_ms BIGINT         NOT NULL,
    updated_at_ms BIGINT         NOT NULL,
    CONSTRAINT uq_offline_sync_queue_dedupe UNIQUE (dedupe_key)
);
GO

IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = N'idx_offline_sync_queue_status_created' AND object_id = OBJECT_ID(N'dbo.offline_sync_queue'))
    CREATE INDEX idx_offline_sync_queue_status_created ON dbo.offline_sync_queue (status, created_at_ms);
GO
