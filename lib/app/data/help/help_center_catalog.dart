import 'package:flutter/material.dart';

import '../../routes/app_pages.dart';
import 'help_center_models.dart';

/// Central catalog of help articles, feature index, and guided tour steps.
class HelpCenterCatalog {
  HelpCenterCatalog._();

  static const guides = <HelpGuide>[
    HelpGuide(
      id: 'getting_started_bnb',
      titleEn: 'Get started with BnB',
      titleSw: 'Anza na BnB',
      summaryEn: 'Set up properties, take bookings, and track revenue.',
      summarySw: 'Sanidi mali, pokea uhifadhi, na fuatilia mapato.',
      workspace: HelpWorkspace.bnb,
      categoryEn: 'Getting started',
      categorySw: 'Mwanzo',
      icon: Icons.hotel_class_outlined,
      estimatedMinutes: 5,
      steps: [
        HelpGuideStep(
          titleEn: 'Open your dashboard',
          titleSw: 'Fungua dashibodi yako',
          bodyEn:
              'From the bottom bar, open Dashboard to see bookings, guests, revenue, and occupancy for the week.',
          bodySw:
              'Kutoka kwenye menyu ya chini, fungua Dashibodi kuona uhifadhi, wageni, mapato, na ukaaji wa wiki.',
          route: Routes.MAIN,
        ),
        HelpGuideStep(
          titleEn: 'Add a property',
          titleSw: 'Ongeza mali',
          bodyEn:
              'Tap the + button on Home, choose Property, and complete the listing wizard with photos, units, and pricing.',
          bodySw:
              'Gusa kitufe cha + kwenye Nyumbani, chagua Mali, na kamilisha hatua za kuongeza picha, vyumba, na bei.',
          route: Routes.ADD_LISTING,
        ),
        HelpGuideStep(
          titleEn: 'Record a guest payment',
          titleSw: 'Rekodi malipo ya mgeni',
          bodyEn:
              'Use Record payment from the FAB or booking flow. Amounts feed your financial overview and reports.',
          bodySw:
              'Tumia Rekodi malipo kutoka FAB au mtiririko wa uhifadhi. Kiasi huonekana kwenye muhtasari wa fedha.',
          route: Routes.RECORD_PAYMENT,
        ),
        HelpGuideStep(
          titleEn: 'View calendar & bookings',
          titleSw: 'Angalia kalenda na uhifadhi',
          bodyEn:
              'Host Calendar shows arrivals and departures. All Bookings lists every reservation in one place.',
          bodySw:
              'Kalenda ya Mwenyeji inaonyesha kuwasili na kuondoka. Uhifadhi Wote unaorodhesha kila uhifadhi.',
          route: Routes.HOST_CALENDAR,
        ),
      ],
    ),
    HelpGuide(
      id: 'getting_started_rent',
      titleEn: 'Get started with Rent',
      titleSw: 'Anza na Kodi',
      summaryEn: 'Manage leases, collect rent, and monitor portfolio health.',
      summarySw: 'Simamia mikataba, kusanya kodi, na fuatilia afya ya mali zako.',
      workspace: HelpWorkspace.rent,
      categoryEn: 'Getting started',
      categorySw: 'Mwanzo',
      icon: Icons.apartment_outlined,
      estimatedMinutes: 6,
      steps: [
        HelpGuideStep(
          titleEn: 'Open Rent hub',
          titleSw: 'Fungua kitovu cha Kodi',
          bodyEn:
              'Switch to the Rent workspace from the hub header. Review monthly income, occupancy, active leases, and arrears cards.',
          bodySw:
              'Badilisha kwenye nafasi ya Kodi kutoka kichwa cha ukurasa. Angalia mapato, ukaaji, mikataba hai, na deni.',
          route: Routes.RENT_HUB,
        ),
        HelpGuideStep(
          titleEn: 'Add a rental property',
          titleSw: 'Ongeza mali ya kukodisha',
          bodyEn: 'Create a listing with units, expected rent, and location details.',
          bodySw: 'Unda tangazo lenye vyumba, kodi inayotarajiwa, na maelezo ya eneo.',
          route: Routes.RENT_ADD_NEW_LISTING,
        ),
        HelpGuideStep(
          titleEn: 'Onboard a tenant',
          titleSw: 'Sajili mpangaji',
          bodyEn:
              'Add tenant name, lease dates, rent amount, and frequency. This powers payment tracking and reminders.',
          bodySw:
              'Ongeza jina, tarehe za mkataba, kodi, na mzunguko wa malipo. Hii inaendesha ufuatiliaji na vikumbusho.',
          route: Routes.RENT_ADD_TENANT_FORM,
        ),
        HelpGuideStep(
          titleEn: 'Record rent income',
          titleSw: 'Rekodi mapato ya kodi',
          bodyEn: 'Log each payment received. Income updates hub KPIs and tenant ledgers automatically.',
          bodySw:
              'Andika kila malipo yaliyopokelewa. Mapato yanasasisha kadi za kitovu na daftari la mpangaji.',
          route: Routes.RENT_ADD_INCOME_FORM,
        ),
        HelpGuideStep(
          titleEn: 'Open Tenancy Insights',
          titleSw: 'Fungua Maarifa ya Upangaji',
          bodyEn:
              'See all tenants, payment status, exports, and comparison charts in one portfolio view.',
          bodySw:
              'Ona wapangaji wote, hali ya malipo, pakua Excel, na chati za kulinganisha.',
          route: Routes.RENT_TENANT_RESIDENCY_PAYMENT_TRACKER,
        ),
      ],
    ),
    HelpGuide(
      id: 'record_rent_payment',
      titleEn: 'Record a rent payment',
      titleSw: 'Rekodi malipo ya kodi',
      summaryEn: 'Step-by-step: log tenant rent in the Rent workspace.',
      summarySw: 'Hatua kwa hatua: andika kodi ya mpangaji.',
      workspace: HelpWorkspace.rent,
      categoryEn: 'Common tasks',
      categorySw: 'Kazi za kawaida',
      icon: Icons.payments_outlined,
      steps: [
        HelpGuideStep(
          titleEn: 'Choose tenant & amount',
          titleSw: 'Chagua mpangaji na kiasi',
          bodyEn: 'Open Add income, select the tenant and property, enter amount and payment date.',
          bodySw: 'Fungua Ongeza mapato, chagua mpangaji na mali, weka kiasi na tarehe.',
          route: Routes.RENT_ADD_INCOME_FORM,
        ),
        HelpGuideStep(
          titleEn: 'Verify in Manage payments',
          titleSw: 'Thibitisha katika Simamia malipo',
          bodyEn: 'The payment appears under the current month. Filter by apartment if needed.',
          bodySw: 'Malipo yanaonekana chini ya mwezi huu. Chuja kwa chumba ikiwa inahitajika.',
          route: Routes.RENT_MANAGE_PAYMENTS,
        ),
        HelpGuideStep(
          titleEn: 'Check tenant ledger',
          titleSw: 'Angalia daftari la mpangaji',
          bodyEn: 'Open the tenant from Tenancy Insights to see balance and lease progress.',
          bodySw: 'Fungua mpangaji kutoka Maarifa ya Upangaji kuona salio na maendeleo ya mkataba.',
          route: Routes.RENT_TENANT_RESIDENCY_PAYMENT_TRACKER,
        ),
      ],
    ),
    HelpGuide(
      id: 'add_tenant_lease',
      titleEn: 'Add a tenant & lease',
      titleSw: 'Ongeza mpangaji na mkataba',
      summaryEn: 'Create a tenant record with lease terms and contact info.',
      summarySw: 'Unda rekodi ya mpangaji na masharti ya mkataba.',
      workspace: HelpWorkspace.rent,
      categoryEn: 'Common tasks',
      categorySw: 'Kazi za kawaida',
      icon: Icons.person_add_alt_1_outlined,
      steps: [
        HelpGuideStep(
          titleEn: 'Start tenant form',
          titleSw: 'Anza fomu ya mpangaji',
          bodyEn: 'From a property or Tenancy Insights, tap Add tenant.',
          bodySw: 'Kutoka kwenye mali au Maarifa ya Upangaji, gusa Ongeza mpangaji.',
          route: Routes.RENT_ADD_TENANT_FORM,
        ),
        HelpGuideStep(
          titleEn: 'Set lease & rent',
          titleSw: 'Weka mkataba na kodi',
          bodyEn: 'Enter lease start/end, monthly rent, and frequency (per month, week, etc.).',
          bodySw: 'Weka mwanzo/mwisho wa mkataba, kodi, na mzunguko (kwa mwezi, wiki, n.k.).',
        ),
        HelpGuideStep(
          titleEn: 'Upload contract (optional)',
          titleSw: 'Pakia mkataba (si lazima)',
          bodyEn: 'Attach a PDF or image of the signed lease in the Contract hub later.',
          bodySw: 'Ambatisha PDF au picha ya mkataba katika Kitovu cha Mikataba baadaye.',
          route: Routes.RENT_CONTRACT_HUB,
        ),
      ],
    ),
    HelpGuide(
      id: 'track_arrears',
      titleEn: 'Track arrears & collections',
      titleSw: 'Fuatilia deni na makusanyo',
      summaryEn: 'Monitor who is behind and export reports.',
      summarySw: 'Fuatilia waliochelewa na pakua ripoti.',
      workspace: HelpWorkspace.rent,
      categoryEn: 'Common tasks',
      categorySw: 'Kazi za kawaida',
      icon: Icons.warning_amber_rounded,
      steps: [
        HelpGuideStep(
          titleEn: 'Portfolio arrears card',
          titleSw: 'Kadi ya deni la jumla',
          bodyEn: 'Rent hub shows total arrears across all properties for quick triage.',
          bodySw: 'Kitovu cha Kodi kinaonyesha jumla ya deni kwa mali zote.',
          route: Routes.RENT_HUB,
        ),
        HelpGuideStep(
          titleEn: 'Tenancy Insights',
          titleSw: 'Maarifa ya Upangaji',
          bodyEn: 'Each tenant card shows paid vs expected and highlights lease-ending soon.',
          bodySw: 'Kadi ya mpangaji inaonyesha kilicholipwa dhidi ya kinachotarajiwa.',
          route: Routes.RENT_TENANT_RESIDENCY_PAYMENT_TRACKER,
        ),
        HelpGuideStep(
          titleEn: 'Export Excel report',
          titleSw: 'Pakua ripoti ya Excel',
          bodyEn: 'Use the menu to download rent details or tenant summary and share via WhatsApp.',
          bodySw: 'Tumia menyu kupakua maelezo ya kodi au muhtasari na kutuma WhatsApp.',
          route: Routes.RENT_TENANT_RESIDENCY_PAYMENT_TRACKER,
        ),
        HelpGuideStep(
          titleEn: 'Schedule reminders',
          titleSw: 'Panga vikumbusho',
          bodyEn: 'Set payment reminders per tenant from their ledger screen.',
          bodySw: 'Weka vikumbusho vya malipo kwa kila mpangaji kutoka daftari lake.',
          route: Routes.RENT_SCHEDULE_PAYMENT_REMINDER,
        ),
      ],
    ),
    HelpGuide(
      id: 'property_roi_break_even',
      titleEn: 'ROI & break-even estimates',
      titleSw: 'Makadirio ya ROI na umiliki',
      summaryEn: 'Enter property costs and track when income recovers investment.',
      summarySw: 'Weka gharama za mali na fuatilia wakati mapato yanarudisha uwekezaji.',
      workspace: HelpWorkspace.rent,
      categoryEn: 'Finances',
      categorySw: 'Fedha',
      icon: Icons.trending_up_outlined,
      steps: [
        HelpGuideStep(
          titleEn: 'Add cost estimates',
          titleSw: 'Ongeza makadirio ya gharama',
          bodyEn: 'From listing details or ROI analysis, open Estimates and enter purchase and maintenance costs.',
          bodySw: 'Kutoka maelezo ya mali au uchambuzi wa ROI, fungua Makadirio.',
          route: Routes.RENT_PROPERTY_ROI_ESTIMATE_FORM,
          routeParameters: {'propertyRef': '', 'propertyLabel': 'Property'},
        ),
        HelpGuideStep(
          titleEn: 'View principal vs income',
          titleSw: 'Angalia mtaji dhidi ya mapato',
          bodyEn: 'Charts on listing details and financial overview show income vs capital deployed.',
          bodySw: 'Chati zinaonyesha mapato dhidi ya mtaji uliotumika.',
          route: Routes.RENT_PROPERTY_ROI_ANALYSIS,
        ),
        HelpGuideStep(
          titleEn: 'Break-even notifications',
          titleSw: 'Arifa za umiliki',
          bodyEn: 'You receive a notification when projected or actual break-even is reached.',
          bodySw: 'Utapokea arifa wakati umiliki unafikiwa kwa makadirio au halisi.',
        ),
      ],
    ),
    HelpGuide(
      id: 'expected_payment_schedule',
      titleEn: 'Expected payment schedule',
      titleSw: 'Ratiba ya malipo yanayotarajiwa',
      summaryEn: 'See which months rent is due across all properties this year.',
      summarySw: 'Angalia miezi ambayo kodi inatarajiwa kwa mali zote mwaka huu.',
      workspace: HelpWorkspace.rent,
      categoryEn: 'Finances',
      categorySw: 'Fedha',
      icon: Icons.calendar_view_month_outlined,
      steps: [
        HelpGuideStep(
          titleEn: 'Open year schedule',
          titleSw: 'Fungua ratiba ya mwaka',
          bodyEn: 'More → Expected Payments shows a month-by-month grid per property.',
          bodySw: 'Zaidi → Malipo Yanayotarajiwa inaonyesha jedwali la miezi kwa kila mali.',
          route: Routes.RENT_EXPECTED_PAYMENT_SCHEDULE,
        ),
        HelpGuideStep(
          titleEn: 'Expand a property',
          titleSw: 'Panua mali',
          bodyEn: 'Tap a property row to see each tenant’s expected amounts by month.',
          bodySw: 'Gusa mstari wa mali kuona kiasi cha kila mpangaji kwa mwezi.',
        ),
      ],
    ),
    HelpGuide(
      id: 'schedule_maintenance',
      titleEn: 'Schedule maintenance',
      titleSw: 'Panga matengenezo',
      summaryEn: 'Plan upkeep tasks and get reminded before due dates.',
      summarySw: 'Panga kazi za matengenezo na upate kikumbusho kabla ya tarehe.',
      workspace: HelpWorkspace.rent,
      categoryEn: 'Operations',
      categorySw: 'Uendeshaji',
      icon: Icons.build_circle_outlined,
      steps: [
        HelpGuideStep(
          titleEn: 'Create maintenance task',
          titleSw: 'Unda kazi ya matengenezo',
          bodyEn: 'More → Schedule Maintenance. Pick property, category, and date.',
          bodySw: 'Zaidi → Panga Matengenezo. Chagua mali, aina, na tarehe.',
          route: Routes.RENT_SCHEDULE_MAINTENANCE_FORM,
        ),
        HelpGuideStep(
          titleEn: 'Log maintenance costs',
          titleSw: 'Rekodi gharama za matengenezo',
          bodyEn: 'Add expenses tagged to the property so ROI and P&L stay accurate.',
          bodySw: 'Ongeza matumizi yaliyowekwa lebo kwa mali ili ROI iwe sahihi.',
          route: Routes.RENT_ADD_NEW_EXPENSE,
        ),
        HelpGuideStep(
          titleEn: 'Maintenance analysis',
          titleSw: 'Uchambuzi wa matengenezo',
          bodyEn: 'Review spending trends in Maintenance cost analysis.',
          bodySw: 'Kagua mwenendo wa matumizi katika uchambuzi wa matengenezo.',
          route: Routes.RENT_MAINTENANCE_COST_ANALYSIS,
        ),
      ],
    ),
    HelpGuide(
      id: 'ai_manager_help',
      titleEn: 'Use AI Manager',
      titleSw: 'Tumia Msimamizi wa AI',
      summaryEn: 'Ask questions about your portfolio in plain language.',
      summarySw: 'Uliza maswali kuhusu mali zako kwa lugha rahisi.',
      workspace: HelpWorkspace.both,
      categoryEn: 'AI & automation',
      categorySw: 'AI na otomatiki',
      icon: Icons.auto_awesome_outlined,
      steps: [
        HelpGuideStep(
          titleEn: 'Open AI Manager',
          titleSw: 'Fungua Msimamizi wa AI',
          bodyEn: 'Available from Rent → More or BnB shortcuts. Ask about income, tenants, or occupancy.',
          bodySw: 'Inapatikana kutoka Zaidi. Uliza kuhusu mapato, wapangaji, au ukaaji.',
          route: Routes.AI_MANAGER,
        ),
        HelpGuideStep(
          titleEn: 'Try suggested prompts',
          titleSw: 'Jaribu maswali yaliyopendekezwa',
          bodyEn: 'Tap a starter question or type your own. Answers use your local portfolio data.',
          bodySw: 'Gusa swali la mwanzo au andika lako. Majibu hutumia data yako ya ndani.',
        ),
      ],
    ),
    HelpGuide(
      id: 'workspace_switch',
      titleEn: 'Switch BnB ↔ Rent',
      titleSw: 'Badilisha BnB ↔ Kodi',
      summaryEn: 'Use one app for short-stay bookings and long-term rentals.',
      summarySw: 'Tumia programu moja kwa uhifadhi na kodi za muda mrefu.',
      workspace: HelpWorkspace.both,
      categoryEn: 'Getting started',
      categorySw: 'Mwanzo',
      icon: Icons.swap_horiz_rounded,
      steps: [
        HelpGuideStep(
          titleEn: 'BnB workspace',
          titleSw: 'Nafasi ya BnB',
          bodyEn: 'Optimized for nightly bookings, guest calendar, and daily revenue.',
          bodySw: 'Imeboreshwa kwa uhifadhi wa kila usiku, kalenda ya wageni, na mapato ya kila siku.',
          route: Routes.MAIN,
        ),
        HelpGuideStep(
          titleEn: 'Rent workspace',
          titleSw: 'Nafasi ya Kodi',
          bodyEn: 'Tap RENT in the hub header (or switch from BnB link) for leases and tenants.',
          bodySw: 'Gusa KODI kwenye kichwa (au kiungo cha BnB) kwa mikataba na wapangaji.',
          route: Routes.RENT_HUB,
        ),
      ],
    ),
  ];

  static const features = <HelpFeature>[
    HelpFeature(
      id: 'f_dashboard',
      titleEn: 'Dashboard',
      titleSw: 'Dashibodi',
      descriptionEn: 'Overview of bookings, revenue, occupancy, and weekly trends (BnB).',
      descriptionSw: 'Muhtasari wa uhifadhi, mapato, ukaaji, na mwenendo wa wiki (BnB).',
      workspace: HelpWorkspace.bnb,
      icon: Icons.dashboard_outlined,
      route: Routes.MAIN,
      relatedGuideId: 'getting_started_bnb',
    ),
    HelpFeature(
      id: 'f_home',
      titleEn: 'Home & properties',
      titleSw: 'Nyumbani na mali',
      descriptionEn: 'Browse and manage all your listings.',
      descriptionSw: 'Vinjari na simamia tangazo zako zote.',
      workspace: HelpWorkspace.bnb,
      icon: Icons.home_outlined,
      route: Routes.HOME,
    ),
    HelpFeature(
      id: 'f_calendar',
      titleEn: 'Host calendar',
      titleSw: 'Kalenda ya mwenyeji',
      descriptionEn: 'See check-ins, check-outs, and availability.',
      descriptionSw: 'Ona kuwasili, kuondoka, na upatikanaji.',
      workspace: HelpWorkspace.bnb,
      icon: Icons.calendar_month_outlined,
      route: Routes.HOST_CALENDAR,
    ),
    HelpFeature(
      id: 'f_bookings',
      titleEn: 'All bookings',
      titleSw: 'Uhifadhi wote',
      descriptionEn: 'Search and manage every reservation.',
      descriptionSw: 'Tafuta na simamia kila uhifadhi.',
      workspace: HelpWorkspace.bnb,
      icon: Icons.event_note_outlined,
      route: Routes.ALL_BOOKINGS,
    ),
    HelpFeature(
      id: 'f_record_payment_bnb',
      titleEn: 'Record payment',
      titleSw: 'Rekodi malipo',
      descriptionEn: 'Log guest payments for BnB stays.',
      descriptionSw: 'Andika malipo ya wageni wa BnB.',
      workspace: HelpWorkspace.bnb,
      icon: Icons.point_of_sale_outlined,
      route: Routes.RECORD_PAYMENT,
    ),
    HelpFeature(
      id: 'f_financial_overview',
      titleEn: 'Financial overview',
      titleSw: 'Muhtasari wa fedha',
      descriptionEn: 'Income vs expense trends and monthly growth charts.',
      descriptionSw: 'Mwenendo wa mapato dhidi ya matumizi na chati za ukuaji.',
      workspace: HelpWorkspace.bnb,
      icon: Icons.insights_outlined,
      route: Routes.FINANCIAL_OVERVIEW,
    ),
    HelpFeature(
      id: 'f_rent_hub',
      titleEn: 'Rent hub',
      titleSw: 'Kitovu cha Kodi',
      descriptionEn: 'Portfolio KPIs, net profit, and weekly income vs expense chart.',
      descriptionSw: 'Vipimo vya mali, faida halisi, na chati ya mapato dhidi ya matumizi.',
      workspace: HelpWorkspace.rent,
      icon: Icons.apartment,
      route: Routes.RENT_HUB,
      relatedGuideId: 'getting_started_rent',
    ),
    HelpFeature(
      id: 'f_tenancy_insights',
      titleEn: 'Tenancy insights',
      titleSw: 'Maarifa ya upangaji',
      descriptionEn: 'Tenants, payment ledger, Excel export, and comparisons.',
      descriptionSw: 'Wapangaji, daftari la malipo, Excel, na kulinganisha.',
      workspace: HelpWorkspace.rent,
      icon: Icons.groups_outlined,
      route: Routes.RENT_TENANT_RESIDENCY_PAYMENT_TRACKER,
      relatedGuideId: 'track_arrears',
    ),
    HelpFeature(
      id: 'f_manage_payments',
      titleEn: 'Manage payments',
      titleSw: 'Simamia malipo',
      descriptionEn: 'Filter rent received by month, apartment, and status.',
      descriptionSw: 'Chuja kodi iliyopokelewa kwa mwezi, chumba, na hali.',
      workspace: HelpWorkspace.rent,
      icon: Icons.receipt_long_outlined,
      route: Routes.RENT_MANAGE_PAYMENTS,
      relatedGuideId: 'record_rent_payment',
    ),
    HelpFeature(
      id: 'f_manage_expenses',
      titleEn: 'Manage expenses',
      titleSw: 'Simamia matumizi',
      descriptionEn: 'Track operating and maintenance spend.',
      descriptionSw: 'Fuatilia matumizi ya uendeshaji na matengenezo.',
      workspace: HelpWorkspace.rent,
      icon: Icons.money_off_csred_outlined,
      route: Routes.RENT_MANAGE_EXPENSES,
    ),
    HelpFeature(
      id: 'f_expected_schedule',
      titleEn: 'Expected payment schedule',
      titleSw: 'Ratiba ya malipo',
      descriptionEn: 'Yearly grid of expected rent by property and month.',
      descriptionSw: 'Jedwali la kodi inayotarajiwa kwa mwezi na mali.',
      workspace: HelpWorkspace.rent,
      icon: Icons.grid_on_outlined,
      route: Routes.RENT_EXPECTED_PAYMENT_SCHEDULE,
      relatedGuideId: 'expected_payment_schedule',
    ),
    HelpFeature(
      id: 'f_contract_hub',
      titleEn: 'Contract hub',
      titleSw: 'Kitovu cha mikataba',
      descriptionEn: 'Store and share lease documents.',
      descriptionSw: 'Hifadhi na shiriki nyaraka za mkataba.',
      workspace: HelpWorkspace.rent,
      icon: Icons.article_outlined,
      route: Routes.RENT_CONTRACT_HUB,
    ),
    HelpFeature(
      id: 'f_staff',
      titleEn: 'Staff management',
      titleSw: 'Usimamizi wa wafanyakazi',
      descriptionEn: 'Onboard estate staff and payroll reminders.',
      descriptionSw: 'Sajili wafanyakazi na vikumbusho vya mishahara.',
      workspace: HelpWorkspace.rent,
      icon: Icons.badge_outlined,
      route: Routes.RENT_STAFF_MANAGEMENT,
    ),
    HelpFeature(
      id: 'f_ai_manager',
      titleEn: 'AI Manager',
      titleSw: 'Msimamizi wa AI',
      descriptionEn: 'Chat assistant for portfolio questions.',
      descriptionSw: 'Msaidizi wa mazungumzo kwa maswali ya mali.',
      workspace: HelpWorkspace.both,
      icon: Icons.auto_awesome,
      route: Routes.AI_MANAGER,
      relatedGuideId: 'ai_manager_help',
    ),
    HelpFeature(
      id: 'f_documents',
      titleEn: 'Documents & vault',
      titleSw: 'Nyaraka na vault',
      descriptionEn: 'Scan and organize property documents.',
      descriptionSw: 'Changanua na panga nyaraka za mali.',
      workspace: HelpWorkspace.both,
      icon: Icons.folder_copy_outlined,
      route: Routes.DOCUMENTS,
    ),
    HelpFeature(
      id: 'f_settings',
      titleEn: 'Settings',
      titleSw: 'Mipangilio',
      descriptionEn: 'Currency, language, theme, security, and help.',
      descriptionSw: 'Sarafu, lugha, mandhari, usalama, na msaada.',
      workspace: HelpWorkspace.both,
      icon: Icons.settings_outlined,
      route: Routes.SETTINGS,
    ),
    HelpFeature(
      id: 'f_send_sms',
      titleEn: 'Send SMS / WhatsApp',
      titleSw: 'Tuma SMS / WhatsApp',
      descriptionEn: 'Message tenants or guests in bulk.',
      descriptionSw: 'Watumie wapangaji au wageni ujumbe kwa wingi.',
      workspace: HelpWorkspace.both,
      icon: Icons.sms_outlined,
      route: Routes.SEND_SMS,
    ),
    HelpFeature(
      id: 'f_whatsapp_templates',
      titleEn: 'WhatsApp templates',
      titleSw: 'Violezo vya WhatsApp',
      descriptionEn: 'Create and manage message templates for WhatsApp Business API.',
      descriptionSw: 'Tengeneza na simamia violezo vya ujumbe kwa WhatsApp Business API.',
      workspace: HelpWorkspace.both,
      icon: Icons.chat_outlined,
      route: Routes.RENT_WHATSAPP_TEMPLATE_BUILDER,
    ),
    HelpFeature(
      id: 'f_smart_access',
      titleEn: 'Smart access',
      titleSw: 'Ufikiaji mahiri',
      descriptionEn: 'Guest access codes and smart locks (where configured).',
      descriptionSw: 'Nambari za wageni na kufuli mahiri (ikiwa imesanidiwa).',
      workspace: HelpWorkspace.bnb,
      icon: Icons.lock_outline,
      route: Routes.SMART_ACCESS,
    ),
    HelpFeature(
      id: 'f_maintenance_tasks',
      titleEn: 'Maintenance tasks',
      titleSw: 'Kazi za matengenezo',
      descriptionEn: 'BnB maintenance task list and tracking.',
      descriptionSw: 'Orodha ya matengenezo ya BnB.',
      workspace: HelpWorkspace.bnb,
      icon: Icons.handyman_outlined,
      route: Routes.MAINTENANCE_TASKS,
    ),
    HelpFeature(
      id: 'f_tenant_charges',
      titleEn: 'Define tenant charges',
      titleSw: 'Bainisha tozo za mpangaji',
      descriptionEn: 'Set recurring or one-off charges for tenants.',
      descriptionSw: 'Weka tozo za mara kwa mara au mara moja kwa wapangaji.',
      workspace: HelpWorkspace.rent,
      icon: Icons.payments_outlined,
      route: Routes.RENT_DEFINE_TENANT_CHARGES,
    ),
    HelpFeature(
      id: 'f_loyalty_program',
      titleEn: 'Loyalty program',
      titleSw: 'Programu ya uaminifu',
      descriptionEn: 'Create and manage tenant loyalty offers.',
      descriptionSw: 'Tengeneza na simamia ofa za uaminifu kwa wapangaji.',
      workspace: HelpWorkspace.rent,
      icon: Icons.loyalty_outlined,
      route: Routes.RENT_DEFINE_LOYALTY_OFFERS,
    ),
    HelpFeature(
      id: 'f_design_studio',
      titleEn: 'Design studio',
      titleSw: 'Studio ya ubunifu',
      descriptionEn: 'Interior design tools for your properties.',
      descriptionSw: 'Zana za ubunifu wa mali zako.',
      workspace: HelpWorkspace.bnb,
      icon: Icons.palette_outlined,
      route: Routes.INTERIOR_DESIGN_STUDIO,
    ),
    HelpFeature(
      id: 'f_moodboards',
      titleEn: 'Moodboards',
      titleSw: 'Moodboard',
      descriptionEn: 'Collect inspiration boards per property.',
      descriptionSw: 'Kusanya mabodi ya mawazo kwa kila mali.',
      workspace: HelpWorkspace.bnb,
      icon: Icons.grid_view_rounded,
      route: Routes.DESIGN_MOODBOARDS,
    ),
    HelpFeature(
      id: 'f_property_vault',
      titleEn: 'Property vault',
      titleSw: 'Hifadhi ya nyaraka',
      descriptionEn: 'Store leases, IDs, and property documents.',
      descriptionSw: 'Hifadhi mikataba, vitambulisho, na nyaraka za mali.',
      workspace: HelpWorkspace.both,
      icon: Icons.folder_copy_outlined,
      route: Routes.PROPERTY_VAULT,
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

  static List<String> categories(bool isSw, HelpWorkspace? filter) {
    final set = <String>{};
    for (final g in guides) {
      if (filter != null && filter != HelpWorkspace.both && g.workspace != filter && g.workspace != HelpWorkspace.both) {
        continue;
      }
      set.add(g.category(isSw));
    }
    final list = set.toList()..sort();
    return list;
  }
}
