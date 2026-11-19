import 'package:flutter/material.dart';

import '../../routes/app_pages.dart';
import 'help_center_models.dart';

/// Help guides, features, and tour steps aligned with the current HostBora app.
class HelpCenterCatalog {
  HelpCenterCatalog._();

  static const guides = <HelpGuide>[
    HelpGuide(
      id: 'getting_started_bnb',
      titleEn: 'Get started with short stays (BnB)',
      titleSw: 'Anza na makao ya muda mfupi (BnB)',
      summaryEn: 'Add a BnB property, take bookings, and track guest payments.',
      summarySw: 'Ongeza mali ya BnB, pokea uhifadhi, na fuatilia malipo ya wageni.',
      workspace: HelpWorkspace.bnb,
      categoryEn: 'Getting started',
      categorySw: 'Mwanzo',
      icon: Icons.hotel_class_outlined,
      estimatedMinutes: 5,
      steps: [
        HelpGuideStep(
          titleEn: 'Home dashboard',
          titleSw: 'Dashibodi ya Nyumbani',
          bodyEn:
              'Home shows bookings, revenue, today’s check-ins/check-outs, and Create shortcuts. Filter All / BnB / Rent at the top.',
          bodySw:
              'Nyumbani inaonyesha uhifadhi, mapato, kuingia/kutoka leo, na njia za Unda. Chuja Zote / BnB / Kodi juu.',
          route: Routes.HOME,
        ),
        HelpGuideStep(
          titleEn: 'Add a BnB property',
          titleSw: 'Ongeza mali ya BnB',
          bodyEn:
              'Properties tab → home-plus (or Add Property). Set mode to BnB, add units and photos, then save.',
          bodySw:
              'Kichupo cha Mali → kitufe cha home-plus. Weka hali BnB, ongeza vyumba na picha, kisha hifadhi.',
          route: Routes.ADD_LISTING,
        ),
        HelpGuideStep(
          titleEn: 'Record a guest payment',
          titleSw: 'Rekodi malipo ya mgeni',
          bodyEn:
              'From Home Create or a booking, open Record payment. Amounts feed Finances and reports.',
          bodySw:
              'Kutoka Unda kwenye Nyumbani au uhifadhi, fungua Rekodi malipo. Kiasi huonekana kwenye Fedha.',
          route: Routes.RECORD_PAYMENT,
        ),
        HelpGuideStep(
          titleEn: 'Calendar & bookings',
          titleSw: 'Kalenda na uhifadhi',
          bodyEn:
              'More → Host calendar for arrivals. More → Reports for booking lists and exports.',
          bodySw:
              'Zaidi → Kalenda kwa kuwasili. Zaidi → Ripoti kwa orodha ya uhifadhi.',
          route: Routes.HOST_CALENDAR,
        ),
      ],
    ),
    HelpGuide(
      id: 'getting_started_rent',
      titleEn: 'Get started with long-term rent',
      titleSw: 'Anza na upangishaji wa muda mrefu',
      summaryEn: 'Add a rent property, onboard tenants, collect rent, open Tenants.',
      summarySw: 'Ongeza mali ya kodi, sajili wapangaji, kusanya kodi, fungua Wapangaji.',
      workspace: HelpWorkspace.rent,
      categoryEn: 'Getting started',
      categorySw: 'Mwanzo',
      icon: Icons.apartment_outlined,
      estimatedMinutes: 6,
      steps: [
        HelpGuideStep(
          titleEn: 'Add a rental property',
          titleSw: 'Ongeza mali ya kukodisha',
          bodyEn:
              'Properties → Add Property. Set mode to Rent (or Both), add units and expected rent.',
          bodySw:
              'Mali → Ongeza Mali. Weka hali Kodi (au Zote), ongeza vyumba na kodi inayotarajiwa.',
          route: Routes.ADD_LISTING,
        ),
        HelpGuideStep(
          titleEn: 'Open property details',
          titleSw: 'Fungua maelezo ya mali',
          bodyEn:
              'Tap Manage on a property card. Overview has ROI Analysis, Tenants, estimation costs, and quick actions.',
          bodySw:
              'Gonga Simamia kwenye kadi. Muhtasari una ROI, Wapangaji, makadirio, na vitendo vya haraka.',
          route: Routes.MY_PROPERTIES,
        ),
        HelpGuideStep(
          titleEn: 'Add a tenant',
          titleSw: 'Ongeza mpangaji',
          bodyEn:
              'From property details Quick Management → Add tenant, or from Tenants.',
          bodySw:
              'Kutoka maelezo ya mali → Ongeza mpangaji, au kutoka Wapangaji.',
          route: Routes.ADD_NEW_TENANT,
          requiresContext: HelpNavContext.property,
        ),
        HelpGuideStep(
          titleEn: 'Record rent & check Finances',
          titleSw: 'Rekodi kodi na angalia Fedha',
          bodyEn:
              'Record payment from Home or the property. Finances shows income vs expenses, net, and arrears.',
          bodySw:
              'Rekodi malipo kutoka Nyumbani au mali. Fedha inaonyesha mapato dhidi ya matumizi na deni.',
          route: Routes.RECORD_PAYMENT,
        ),
        HelpGuideStep(
          titleEn: 'Tenants',
          titleSw: 'Wapangaji',
          bodyEn:
              'Property details → Tenants: tenants, collection rate, Excel exports, comparisons.',
          bodySw:
              'Maelezo ya mali → Wapangaji: wapangaji, kiwango cha makusanyo, Excel, kulinganisha.',
          route: Routes.RENT_TENANT_RESIDENCY_PAYMENT_TRACKER,
          requiresContext: HelpNavContext.property,
        ),
      ],
    ),
    HelpGuide(
      id: 'property_roi_break_even',
      titleEn: 'ROI & break-even',
      titleSw: 'ROI na umiliki',
      summaryEn: 'Enter cost estimates, then open Property ROI Analysis from listing details.',
      summarySw: 'Weka makadirio ya gharama, kisha fungua Uchambuzi wa ROI kutoka maelezo ya mali.',
      workspace: HelpWorkspace.both,
      categoryEn: 'Finances',
      categorySw: 'Fedha',
      icon: Icons.trending_up_outlined,
      estimatedMinutes: 4,
      steps: [
        HelpGuideStep(
          titleEn: 'Add cost estimates',
          titleSw: 'Ongeza makadirio',
          bodyEn:
              'Property details → Property Estimation Costs. Enter purchase and renovation amounts.',
          bodySw:
              'Maelezo ya mali → Makadirio ya gharama. Weka bei ya ununuzi na ukarabati.',
          route: Routes.RENT_PROPERTY_ROI_ESTIMATE_FORM,
          requiresContext: HelpNavContext.property,
        ),
        HelpGuideStep(
          titleEn: 'Open ROI Analysis',
          titleSw: 'Fungua Uchambuzi wa ROI',
          bodyEn:
              'Property details → Property ROI Analysis for principal vs income charts and break-even.',
          bodySw:
              'Maelezo ya mali → Uchambuzi wa ROI kwa chati za mtaji dhidi ya mapato.',
          route: Routes.RENT_PROPERTY_ROI_ANALYSIS,
          requiresContext: HelpNavContext.property,
        ),
      ],
    ),
    HelpGuide(
      id: 'tenancy_collections',
      titleEn: 'Tenants, collections & Excel',
      titleSw: 'Wapangaji, makusanyo na Excel',
      summaryEn: 'Use Tenants for collection rate, filters, compare, and WhatsApp Excel schedules.',
      summarySw: 'Tumia Wapangaji kwa makusanyo, vichujio, kulinganisha, na Excel kwa WhatsApp.',
      workspace: HelpWorkspace.rent,
      categoryEn: 'Common tasks',
      categorySw: 'Kazi za kawaida',
      icon: Icons.groups_outlined,
      estimatedMinutes: 4,
      steps: [
        HelpGuideStep(
          titleEn: 'Open Tenants',
          titleSw: 'Fungua Wapangaji',
          bodyEn:
              'From property details (Overview or Rent tab) open Tenants for that property.',
          bodySw:
              'Kutoka maelezo ya mali fungua Wapangaji kwa mali hiyo.',
          route: Routes.RENT_TENANT_RESIDENCY_PAYMENT_TRACKER,
          requiresContext: HelpNavContext.property,
        ),
        HelpGuideStep(
          titleEn: 'Read collection rate',
          titleSw: 'Soma kiwango cha makusanyo',
          bodyEn:
              'The overview card shows collection rate to two decimal places and active leases.',
          bodySw:
              'Kadi ya muhtasari inaonyesha kiwango cha makusanyo kwa desimali mbili na mikataba hai.',
        ),
        HelpGuideStep(
          titleEn: 'Export Excel',
          titleSw: 'Pakua Excel',
          bodyEn:
              'Use the tools menu for Rent details or Tenant summary. Optionally schedule WhatsApp reports.',
          bodySw:
              'Tumia menyu ya zana kwa maelezo ya kodi au muhtasari. Unaweza kupanga ripoti za WhatsApp.',
          route: Routes.RENT_TENANT_RESIDENCY_PAYMENT_TRACKER,
          requiresContext: HelpNavContext.property,
        ),
      ],
    ),
    HelpGuide(
      id: 'staff_payroll_reminders',
      titleEn: 'Staff & salary reminders',
      titleSw: 'Wafanyakazi na vikumbusho vya mishahara',
      summaryEn: 'Register staff on a property and get payday notifications (2 days, 1 day, 6 hours before).',
      summarySw: 'Sajili wafanyakazi na pata arifa za siku ya malipo (siku 2, siku 1, saa 6 kabla).',
      workspace: HelpWorkspace.rent,
      categoryEn: 'Staff',
      categorySw: 'Wafanyakazi',
      icon: Icons.badge_outlined,
      estimatedMinutes: 3,
      steps: [
        HelpGuideStep(
          titleEn: 'Open Staff on a property',
          titleSw: 'Fungua Wafanyakazi kwenye mali',
          bodyEn:
              'Property details → Staff tab → Add staff. Set pay day label (day of month).',
          bodySw:
              'Maelezo ya mali → Wafanyakazi → Ongeza. Weka siku ya malipo (tarehe ya mwezi).',
          route: Routes.RENT_STAFF_MANAGEMENT,
          requiresContext: HelpNavContext.property,
        ),
        HelpGuideStep(
          titleEn: 'Allow notifications',
          titleSw: 'Ruhusu arifa',
          bodyEn:
              'HostBora sends local alerts 2 days before, 1 day before, and 6 hours before payday.',
          bodySw:
              'HostBora hutuma arifa siku 2 kabla, siku 1 kabla, na saa 6 kabla ya siku ya malipo.',
          route: Routes.NOTIFICATIONS,
        ),
      ],
    ),
    HelpGuide(
      id: 'luku_utility',
      titleEn: 'LUKU utility tracking',
      titleSw: 'Ufuatiliaji wa LUKU',
      summaryEn: 'Log electricity top-ups per unit; scan an SMS photo to autofill token details.',
      summarySw: 'Andika malipo ya umeme kwa chumba; scan picha ya SMS kujaza tokeni.',
      workspace: HelpWorkspace.rent,
      categoryEn: 'Utilities',
      categorySw: 'Huduma',
      icon: Icons.bolt_outlined,
      estimatedMinutes: 3,
      steps: [
        HelpGuideStep(
          titleEn: 'Open Smart Utility',
          titleSw: 'Fungua Matumizi Mahiri',
          bodyEn:
              'Property details → Utility Dashboard, or Quick Management → Utility Dashboard.',
          bodySw:
              'Maelezo ya mali → Dashibodi ya Huduma, au Usimamizi wa Haraka.',
          route: Routes.RENT_SMART_UTILITY_DASHBOARD,
          requiresContext: HelpNavContext.property,
        ),
        HelpGuideStep(
          titleEn: 'Scan SMS photo',
          titleSw: 'Scan picha ya SMS',
          bodyEn:
              'Add LUKU top-up → Scan SMS photo. Review token, units, meter, and amount, then save.',
          bodySw:
              'Ongeza LUKU → Scan picha ya SMS. Hakiki tokeni, vitengo, mita, na kiasi, kisha hifadhi.',
          route: Routes.RENT_SMART_UTILITY_DASHBOARD,
          requiresContext: HelpNavContext.property,
        ),
      ],
    ),
    HelpGuide(
      id: 'navigate_the_app',
      titleEn: 'Navigate the main tabs',
      titleSw: 'Zunguka vichupo vikuu',
      summaryEn: 'Home, Properties, Finances, Services (maintenance), and More — plus the center More menu.',
      summarySw: 'Nyumbani, Mali, Fedha, Huduma (matengenezo), na Zaidi — pamoja na menyu ya kati.',
      workspace: HelpWorkspace.both,
      categoryEn: 'Basics',
      categorySw: 'Misingi',
      icon: Icons.explore_outlined,
      estimatedMinutes: 3,
      steps: [
        HelpGuideStep(
          titleEn: 'Home',
          titleSw: 'Nyumbani',
          bodyEn: 'Portfolio snapshot, Create menu, and AI FAB.',
          bodySw: 'Muhtasari wa mali, menyu ya Unda, na FAB ya AI.',
          route: Routes.HOME,
        ),
        HelpGuideStep(
          titleEn: 'Properties',
          titleSw: 'Mali',
          bodyEn: 'All listings with mode filters. Open Manage for property details.',
          bodySw: 'Orodha ya mali na vichujio. Fungua Simamia kwa maelezo.',
          route: Routes.MY_PROPERTIES,
        ),
        HelpGuideStep(
          titleEn: 'Finances',
          titleSw: 'Fedha',
          bodyEn: 'Income vs expense charts, net, arrears, and Financial Overview.',
          bodySw: 'Chati za mapato/matumizi, faida, deni, na Muhtasari wa Fedha.',
          route: Routes.FINANCIAL_OVERVIEW,
        ),
        HelpGuideStep(
          titleEn: 'Services & More',
          titleSw: 'Huduma na Zaidi',
          bodyEn:
              'Services lists maintenance tasks. Center + opens More options. More tab has Help, Network, Reports, Calendar, Settings.',
          bodySw:
              'Huduma ina kazi za matengenezo. + ya kati inafungua Zaidi. Kichupo cha Zaidi kina Msaada, Mtandao, Ripoti, Kalenda, Mipangilio.',
          route: Routes.MAINTENANCE_TASKS,
        ),
      ],
    ),
    HelpGuide(
      id: 'multi_currency',
      titleEn: 'Multi-currency amounts',
      titleSw: 'Kiasi cha sarafu nyingi',
      summaryEn: 'Record income and expenses in any currency; dashboards convert to your base currency.',
      summarySw: 'Andika mapato/matumizi kwa sarafu yoyote; dashibodi hubadilisha hadi sarafu yako ya msingi.',
      workspace: HelpWorkspace.both,
      categoryEn: 'Finances',
      categorySw: 'Fedha',
      icon: Icons.currency_exchange_outlined,
      estimatedMinutes: 2,
      steps: [
        HelpGuideStep(
          titleEn: 'Pick currency on forms',
          titleSw: 'Chagua sarafu kwenye fomu',
          bodyEn:
              'On income, expense, or tenant forms, use the currency dropdown next to the amount.',
          bodySw:
              'Kwenye fomu za mapato, matumizi, au mpangaji, tumia menyu ya sarafu karibu na kiasi.',
          route: Routes.RECORD_PAYMENT,
        ),
        HelpGuideStep(
          titleEn: 'Set base currency',
          titleSw: 'Weka sarafu ya msingi',
          bodyEn: 'Settings → Currency. Totals convert to this currency while originals are kept.',
          bodySw: 'Mipangilio → Sarafu. Jumla hubadilishwa; kiasi asili kinahifadhiwa.',
          route: Routes.SETTINGS,
        ),
      ],
    ),
  ];

  static const features = <HelpFeature>[
    HelpFeature(
      id: 'f_home',
      titleEn: 'Home',
      titleSw: 'Nyumbani',
      descriptionEn: 'Bookings, revenue, arrivals, Create menu, AI assistant.',
      descriptionSw: 'Uhifadhi, mapato, kuwasili, menyu ya Unda, AI.',
      workspace: HelpWorkspace.both,
      icon: Icons.home_outlined,
      route: Routes.HOME,
      categoryEn: 'Main tabs',
      categorySw: 'Vichupo vikuu',
      relatedGuideId: 'navigate_the_app',
    ),
    HelpFeature(
      id: 'f_my_properties',
      titleEn: 'My properties',
      titleSw: 'Mali zangu',
      descriptionEn: 'Browse listings, mode filters, add property from the filter row.',
      descriptionSw: 'Orodha ya mali, vichujio, ongeza mali kutoka safu ya vichujio.',
      workspace: HelpWorkspace.both,
      icon: Icons.domain_outlined,
      route: Routes.MY_PROPERTIES,
      categoryEn: 'Main tabs',
      categorySw: 'Vichupo vikuu',
    ),
    HelpFeature(
      id: 'f_listing_details',
      titleEn: 'Property details',
      titleSw: 'Maelezo ya mali',
      descriptionEn: 'KPIs, ROI, Tenants, units, staff, finance trends, tenant charges.',
      descriptionSw: 'Vipimo, ROI, Wapangaji, vyumba, wafanyakazi, fedha, tozo.',
      workspace: HelpWorkspace.both,
      icon: Icons.info_outline,
      route: Routes.LISTING_DETAILS,
      requiresContext: HelpNavContext.property,
      categoryEn: 'Property',
      categorySw: 'Mali',
    ),
    HelpFeature(
      id: 'f_finances',
      titleEn: 'Finances tab',
      titleSw: 'Kichupo cha Fedha',
      descriptionEn: 'Income vs expense charts, net income, arrears, Financial Overview.',
      descriptionSw: 'Chati za mapato/matumizi, faida, deni, Muhtasari wa Fedha.',
      workspace: HelpWorkspace.both,
      icon: Icons.account_balance_wallet_outlined,
      route: Routes.FINANCIAL_OVERVIEW,
      categoryEn: 'Main tabs',
      categorySw: 'Vichupo vikuu',
    ),
    HelpFeature(
      id: 'f_maintenance_tasks',
      titleEn: 'Maintenance / Services',
      titleSw: 'Matengenezo / Huduma',
      descriptionEn: 'Task list with filters; mark done persists locally until API catches up.',
      descriptionSw: 'Orodha ya kazi; kukamilisha kunahifadhiwa ndani hadi API isasishe.',
      workspace: HelpWorkspace.both,
      icon: Icons.handyman_outlined,
      route: Routes.MAINTENANCE_TASKS,
      categoryEn: 'Main tabs',
      categorySw: 'Vichupo vikuu',
    ),
    HelpFeature(
      id: 'f_tenancy_insights',
      titleEn: 'Tenants',
      titleSw: 'Wapangaji',
      descriptionEn: 'Per-property tenants, collection rate, Excel, compare up to 4 tenants.',
      descriptionSw: 'Wapangaji kwa mali, makusanyo, Excel, linganisha hadi 4.',
      workspace: HelpWorkspace.rent,
      icon: Icons.groups_outlined,
      route: Routes.RENT_TENANT_RESIDENCY_PAYMENT_TRACKER,
      requiresContext: HelpNavContext.property,
      relatedGuideId: 'tenancy_collections',
      categoryEn: 'Rent',
      categorySw: 'Kodi',
    ),
    HelpFeature(
      id: 'f_tenant_ledger',
      titleEn: 'Tenant ledger',
      titleSw: 'Daftari la mpangaji',
      descriptionEn: 'Payment history, balance, contract, and end tenancy for one tenant.',
      descriptionSw: 'Historia ya malipo, salio, mkataba, na kumaliza upangaji.',
      workspace: HelpWorkspace.rent,
      icon: Icons.account_balance_wallet_outlined,
      route: Routes.RENT_TENANT_LEDGER_OCCUPANCY,
      requiresContext: HelpNavContext.tenant,
      categoryEn: 'Rent',
      categorySw: 'Kodi',
    ),
    HelpFeature(
      id: 'f_tenant_charges',
      titleEn: 'Define tenant charges',
      titleSw: 'Bainisha tozo za mpangaji',
      descriptionEn: 'Security deposit, service charge, and other fees for a property.',
      descriptionSw: 'Depositi, tozo ya huduma, na ada nyingine kwa mali.',
      workspace: HelpWorkspace.rent,
      icon: Icons.payments_outlined,
      route: Routes.RENT_DEFINE_TENANT_CHARGES,
      requiresContext: HelpNavContext.property,
      categoryEn: 'Rent',
      categorySw: 'Kodi',
    ),
    HelpFeature(
      id: 'f_roi_analysis',
      titleEn: 'Property ROI Analysis',
      titleSw: 'Uchambuzi wa ROI',
      descriptionEn: 'Principal vs income pie chart, break-even, quarterly trends.',
      descriptionSw: 'Chati ya mtaji dhidi ya mapato, umiliki, mwenendo.',
      workspace: HelpWorkspace.both,
      icon: Icons.pie_chart_outline,
      route: Routes.RENT_PROPERTY_ROI_ANALYSIS,
      requiresContext: HelpNavContext.property,
      relatedGuideId: 'property_roi_break_even',
      categoryEn: 'Finances',
      categorySw: 'Fedha',
    ),
    HelpFeature(
      id: 'f_roi_estimates',
      titleEn: 'Property estimation costs',
      titleSw: 'Makadirio ya gharama',
      descriptionEn: 'Purchase and renovation estimates used by ROI Analysis.',
      descriptionSw: 'Makadirio ya ununuzi/ukarabati yanayotumiwa na ROI.',
      workspace: HelpWorkspace.both,
      icon: Icons.calculate_outlined,
      route: Routes.RENT_PROPERTY_ROI_ESTIMATE_FORM,
      requiresContext: HelpNavContext.property,
      categoryEn: 'Finances',
      categorySw: 'Fedha',
    ),
    HelpFeature(
      id: 'f_expected_schedule',
      titleEn: 'Expected payment schedule',
      titleSw: 'Ratiba ya malipo',
      descriptionEn: 'Yearly expected rent by property and tenant.',
      descriptionSw: 'Kodi inayotarajiwa kwa mwaka kwa mali na mpangaji.',
      workspace: HelpWorkspace.rent,
      icon: Icons.grid_on_outlined,
      route: Routes.RENT_EXPECTED_PAYMENT_SCHEDULE,
      categoryEn: 'Finances',
      categorySw: 'Fedha',
    ),
    HelpFeature(
      id: 'f_manage_payments',
      titleEn: 'Manage payments',
      titleSw: 'Simamia malipo',
      descriptionEn: 'Filter recorded rent by month and status.',
      descriptionSw: 'Chuja kodi iliyorekodiwa kwa mwezi na hali.',
      workspace: HelpWorkspace.rent,
      icon: Icons.receipt_long_outlined,
      route: Routes.RENT_MANAGE_PAYMENTS,
      categoryEn: 'Finances',
      categorySw: 'Fedha',
    ),
    HelpFeature(
      id: 'f_staff',
      titleEn: 'Staff management',
      titleSw: 'Usimamizi wa wafanyakazi',
      descriptionEn: 'Register staff, pay day, and payroll summary for a property.',
      descriptionSw: 'Sajili wafanyakazi, siku ya malipo, na muhtasari wa mishahara.',
      workspace: HelpWorkspace.rent,
      icon: Icons.badge_outlined,
      route: Routes.RENT_STAFF_MANAGEMENT,
      requiresContext: HelpNavContext.property,
      relatedGuideId: 'staff_payroll_reminders',
      categoryEn: 'Staff',
      categorySw: 'Wafanyakazi',
    ),
    HelpFeature(
      id: 'f_smart_utility',
      titleEn: 'Smart utility (LUKU)',
      titleSw: 'Matumizi mahiri (LUKU)',
      descriptionEn: 'Electricity top-ups per unit; scan SMS photo to import.',
      descriptionSw: 'Malipo ya LUKU kwa chumba; scan SMS kuingiza.',
      workspace: HelpWorkspace.rent,
      icon: Icons.bolt_outlined,
      route: Routes.RENT_SMART_UTILITY_DASHBOARD,
      requiresContext: HelpNavContext.property,
      relatedGuideId: 'luku_utility',
      categoryEn: 'Utilities',
      categorySw: 'Huduma',
    ),
    HelpFeature(
      id: 'f_schedule_maintenance',
      titleEn: 'Schedule maintenance',
      titleSw: 'Panga matengenezo',
      descriptionEn: 'Plan a visit; get a day-before local notification.',
      descriptionSw: 'Panga ziara; pata arifa siku moja kabla.',
      workspace: HelpWorkspace.rent,
      icon: Icons.build_circle_outlined,
      route: Routes.RENT_SCHEDULE_MAINTENANCE_FORM,
      requiresContext: HelpNavContext.property,
      categoryEn: 'Maintenance',
      categorySw: 'Matengenezo',
    ),
    HelpFeature(
      id: 'f_contract_hub',
      titleEn: 'Contract hub',
      titleSw: 'Kitovu cha mikataba',
      descriptionEn: 'Store and share lease documents.',
      descriptionSw: 'Hifadhi na shiriki mikataba.',
      workspace: HelpWorkspace.rent,
      icon: Icons.article_outlined,
      route: Routes.RENT_CONTRACT_HUB,
      categoryEn: 'Documents',
      categorySw: 'Nyaraka',
    ),
    HelpFeature(
      id: 'f_calendar',
      titleEn: 'Host calendar',
      titleSw: 'Kalenda',
      descriptionEn: 'Check-ins, check-outs, and availability.',
      descriptionSw: 'Kuingia, kutoka, na upatikanaji.',
      workspace: HelpWorkspace.bnb,
      icon: Icons.calendar_month_outlined,
      route: Routes.HOST_CALENDAR,
      categoryEn: 'BnB',
      categorySw: 'BnB',
    ),
    HelpFeature(
      id: 'f_bookings',
      titleEn: 'All bookings',
      titleSw: 'Uhifadhi wote',
      descriptionEn: 'Search and manage reservations.',
      descriptionSw: 'Tafuta na simamia uhifadhi.',
      workspace: HelpWorkspace.bnb,
      icon: Icons.event_note_outlined,
      route: Routes.ALL_BOOKINGS,
      categoryEn: 'BnB',
      categorySw: 'BnB',
    ),
    HelpFeature(
      id: 'f_ai_manager',
      titleEn: 'AI Manager',
      titleSw: 'Msimamizi wa AI',
      descriptionEn: 'Ask about income, arrears, occupancy, or maintenance in plain language.',
      descriptionSw: 'Uliza kuhusu mapato, deni, ukaaji, au matengenezo.',
      workspace: HelpWorkspace.both,
      icon: Icons.auto_awesome,
      route: Routes.AI_MANAGER,
      categoryEn: 'Tools',
      categorySw: 'Zana',
    ),
    HelpFeature(
      id: 'f_my_network',
      titleEn: 'My Network',
      titleSw: 'Mtandao wangu',
      descriptionEn: 'Hosts you manage and contact shortcuts.',
      descriptionSw: 'Wenyeji unawasimamia na njia za mawasiliano.',
      workspace: HelpWorkspace.both,
      icon: Icons.hub_outlined,
      route: Routes.MY_NETWORK,
      categoryEn: 'More',
      categorySw: 'Zaidi',
    ),
    HelpFeature(
      id: 'f_property_managers',
      titleEn: 'Property managers',
      titleSw: 'Wasimamizi',
      descriptionEn: 'Directory of property managers and profiles.',
      descriptionSw: 'Orodha ya wasimamizi na wasifu.',
      workspace: HelpWorkspace.both,
      icon: Icons.manage_accounts_outlined,
      route: Routes.PROPERTY_MANAGERS,
      categoryEn: 'More',
      categorySw: 'Zaidi',
    ),
    HelpFeature(
      id: 'f_documents',
      titleEn: 'Documents & vault',
      titleSw: 'Nyaraka na vault',
      descriptionEn: 'Scan and organize property documents.',
      descriptionSw: 'Changanua na panga nyaraka.',
      workspace: HelpWorkspace.both,
      icon: Icons.folder_copy_outlined,
      route: Routes.DOCUMENTS,
      categoryEn: 'Documents',
      categorySw: 'Nyaraka',
    ),
    HelpFeature(
      id: 'f_send_sms',
      titleEn: 'Send SMS / WhatsApp',
      titleSw: 'Tuma SMS / WhatsApp',
      descriptionEn: 'Message tenants or guests (Pro+ for SMS/WhatsApp sending).',
      descriptionSw: 'Watumie wapangaji/wageni (Pro+ kwa kutuma SMS/WhatsApp).',
      workspace: HelpWorkspace.both,
      icon: Icons.sms_outlined,
      route: Routes.SEND_SMS,
      categoryEn: 'Messaging',
      categorySw: 'Ujumbe',
    ),
    HelpFeature(
      id: 'f_notifications',
      titleEn: 'Notifications',
      titleSw: 'Arifa',
      descriptionEn: 'In-app notification log (salary, maintenance, payments).',
      descriptionSw: 'Kumbukumbu za arifa (mishahara, matengenezo, malipo).',
      workspace: HelpWorkspace.both,
      icon: Icons.notifications_outlined,
      route: Routes.NOTIFICATIONS,
      categoryEn: 'Tools',
      categorySw: 'Zana',
    ),
    HelpFeature(
      id: 'f_settings',
      titleEn: 'Settings',
      titleSw: 'Mipangilio',
      descriptionEn: 'Currency, language, theme, security, subscription.',
      descriptionSw: 'Sarafu, lugha, mandhari, usalama, usajili.',
      workspace: HelpWorkspace.both,
      icon: Icons.settings_outlined,
      route: Routes.SETTINGS,
      relatedGuideId: 'multi_currency',
      categoryEn: 'Account',
      categorySw: 'Akaunti',
    ),
  ];

  static HelpGuide? guideById(String id) {
    for (final g in guides) {
      if (g.id == id) return g;
    }
    return null;
  }

  static HelpFeature? featureById(String id) {
    for (final f in features) {
      if (f.id == id) return f;
    }
    return null;
  }
}
