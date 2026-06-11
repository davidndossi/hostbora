import 'package:flutter/material.dart';

import '../../routes/app_pages.dart';
import 'help_center_models.dart';

/// Central catalog of help articles, feature index, and guided tour steps.
class HelpCenterCatalog {
  HelpCenterCatalog._();

  static const guides = <HelpGuide>[
    HelpGuide(
      id: 'getting_started_bnb',
      titleEn: 'Get started with short-stay hosting',
      titleSw: 'Anza na upangishaji wa muda mfupi',
      summaryEn: 'Set up properties, manage bookings, and track nightly revenue.',
      summarySw: 'Sanidi mali, simamia uhifadhi, na fuatilia mapato ya kila usiku.',
      workspace: HelpWorkspace.bnb,
      categoryEn: 'Getting started',
      categorySw: 'Mwanzo',
      icon: Icons.hotel_class_outlined,
      estimatedMinutes: 5,
      steps: [
        HelpGuideStep(
          titleEn: 'View your Home dashboard',
          titleSw: 'Angalia dashibodi ya Nyumbani',
          bodyEn:
              'The Home tab shows active bookings, monthly revenue, today\'s check-ins and check-outs, and upcoming arrivals.',
          bodySw:
              'Kichupo cha Nyumbani kinaonyesha uhifadhi hai, mapato ya mwezi, kuwasili na kuondoka leo, na wageni wanaokuja.',
          route: Routes.HOME,
        ),
        HelpGuideStep(
          titleEn: 'Add a property',
          titleSw: 'Ongeza mali',
          bodyEn:
              'Open the Properties tab and tap the + FAB. Complete the listing wizard with photos, units, and pricing.',
          bodySw:
              'Fungua kichupo cha Mali na ugonge FAB ya +. Kamilisha hatua za kuongeza picha, vyumba, na bei.',
          route: Routes.ADD_LISTING,
        ),
        HelpGuideStep(
          titleEn: 'Record a guest payment',
          titleSw: 'Rekodi malipo ya mgeni',
          bodyEn:
              'Use Record payment from the FAB on Home or from a booking. Amounts feed your financial overview and reports.',
          bodySw:
              'Tumia Rekodi malipo kutoka FAB kwenye Nyumbani au kutoka uhifadhi. Kiasi huonekana kwenye muhtasari wa fedha.',
          route: Routes.RECORD_PAYMENT,
        ),
        HelpGuideStep(
          titleEn: 'View calendar & bookings',
          titleSw: 'Angalia kalenda na uhifadhi',
          bodyEn:
              'Go to More → Host Calendar for arrivals and departures. More → Reports shows all bookings in one place.',
          bodySw:
              'Nenda Zaidi → Kalenda kwa kuwasili na kuondoka. Zaidi → Ripoti inaonyesha uhifadhi wote.',
          route: Routes.HOST_CALENDAR,
        ),
      ],
    ),
    HelpGuide(
      id: 'getting_started_rent',
      titleEn: 'Get started with long-term rentals',
      titleSw: 'Anza na upangishaji wa muda mrefu',
      summaryEn: 'Manage leases, collect rent, and monitor portfolio health.',
      summarySw: 'Simamia mikataba, kusanya kodi, na fuatilia afya ya mali zako.',
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
              'Open the Properties tab and tap the + FAB. Create a listing with units, expected rent, and location details.',
          bodySw:
              'Fungua kichupo cha Mali na ugonge FAB ya +. Unda tangazo lenye vyumba, kodi inayotarajiwa, na maelezo ya eneo.',
          route: Routes.ADD_LISTING,
        ),
        HelpGuideStep(
          titleEn: 'Onboard a tenant',
          titleSw: 'Sajili mpangaji',
          bodyEn:
              'Open a property, tap Add tenant. Enter name, lease dates, rent amount, frequency, and currency. The unit\'s operation mode pre-fills a sensible frequency default.',
          bodySw:
              'Fungua mali, gonga Ongeza mpangaji. Weka jina, tarehe za mkataba, kodi, mzunguko, na sarafu. Hali ya chumba hujaza mzunguko wa kawaida.',
          route: Routes.ADD_NEW_TENANT,
        ),
        HelpGuideStep(
          titleEn: 'Record rent income',
          titleSw: 'Rekodi mapato ya kodi',
          bodyEn:
              'Log each payment received from the Home FAB or from a tenant record. Income updates the Finances tab KPIs and tenant ledgers automatically.',
          bodySw:
              'Andika kila malipo kutoka FAB ya Nyumbani au rekodi ya mpangaji. Mapato yanasasisha kadi za Fedha na daftari la mpangaji.',
          route: Routes.RECORD_PAYMENT,
        ),
        HelpGuideStep(
          titleEn: 'Check Finances & arrears',
          titleSw: 'Angalia Fedha na deni',
          bodyEn:
              'The Finances tab shows income vs expense, net income, and total arrears across all properties.',
          bodySw:
              'Kichupo cha Fedha kinaonyesha mapato dhidi ya matumizi, mapato halisi, na jumla ya deni kwa mali zote.',
          route: Routes.FINANCIAL_OVERVIEW,
        ),
        HelpGuideStep(
          titleEn: 'Open Tenancy Insights',
          titleSw: 'Fungua Maarifa ya Upangaji',
          bodyEn:
              'Open a property → Tenancy Insights to see all tenants, payment status, exports, and comparison charts.',
          bodySw:
              'Fungua mali → Maarifa ya Upangaji kuona wapangaji wote, hali ya malipo, pakua Excel, na chati.',
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
          titleEn: 'Choose tenant, amount & currency',
          titleSw: 'Chagua mpangaji, kiasi, na sarafu',
          bodyEn:
              'Open Add income, select the tenant and property, enter the amount and payment date. If the rent was paid in a different currency, choose it from the dropdown — the live exchange rate is captured automatically.',
          bodySw:
              'Fungua Ongeza mapato, chagua mpangaji na mali, weka kiasi na tarehe. Ikiwa kodi ilelipwa kwa sarafu tofauti, ichague kutoka menyu — kiwango cha ubadilishaji kinahifadhiwa moja kwa moja.',
          route: Routes.RECORD_PAYMENT,
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
          route: Routes.ADD_NEW_TENANT,
        ),
        HelpGuideStep(
          titleEn: 'Set lease, rent & currency',
          titleSw: 'Weka mkataba, kodi, na sarafu',
          bodyEn:
              'Enter lease start/end, monthly rent, frequency (monthly, weekly, nightly, etc.), and currency. Selecting the unit operation mode (BnB/Rent) pre-fills the most appropriate frequency. The exchange rate is stored at the time of each payment.',
          bodySw:
              'Weka mwanzo/mwisho wa mkataba, kodi, mzunguko (kwa mwezi, wiki, usiku, n.k.), na sarafu. Kuchagua hali ya chumba (BnB/Kodi) hujaza mzunguko wa kawaida. Kiwango cha ubadilishaji kinahifadhiwa wakati wa kila malipo.',
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
          route: Routes.FINANCIAL_OVERVIEW,
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
          bodyEn: 'Open a property → Expected Payments to see a month-by-month grid of due rent.',
          bodySw: 'Fungua mali → Malipo Yanayotarajiwa kuona jedwali la miezi la kodi inayolipwa.',
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
          bodyEn:
              'In the Maintenance tab, tap the + FAB. Pick property, category (Plumbing, Electrical, General, etc.), scheduled date, and priority. The task saves locally and syncs to the server when online. A push notification fires the day before as a reminder.',
          bodySw:
              'Katika kichupo cha Matengenezo, gonga FAB ya +. Chagua mali, aina (Mabomba, Umeme, Jumla, n.k.), tarehe, na kipaumbele. Kazi inahifadhiwa ndani na kusawazishwa na seva ukiwa mtandaoni. Arifa inatumwa siku moja kabla.',
          route: Routes.RENT_SCHEDULE_MAINTENANCE_FORM,
        ),
        HelpGuideStep(
          titleEn: 'Log maintenance costs',
          titleSw: 'Rekodi gharama za matengenezo',
          bodyEn: 'Add expenses tagged to the property so ROI and P&L stay accurate.',
          bodySw: 'Ongeza matumizi yaliyowekwa lebo kwa mali ili ROI iwe sahihi.',
          route: Routes.ADD_EXPENSE,
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
          bodyEn:
              'Tap the floating AI button on the home screen, or navigate from the main menu. Ask about income, tenants, occupancy, arrears, or maintenance in plain language.',
          bodySw:
              'Gonga kitufe cha AI kinachoelea kwenye skrini ya nyumbani, au nenda kupitia menyu kuu. Uliza kuhusu mapato, wapangaji, ukaaji, deni, au matengenezo kwa lugha rahisi.',
          route: Routes.AI_MANAGER,
        ),
        HelpGuideStep(
          titleEn: 'Try suggested prompts',
          titleSw: 'Jaribu maswali yaliyopendekezwa',
          bodyEn:
              'Tap a starter question or type your own. Answers use your local portfolio data and, when online, server-side analysis for deeper insights.',
          bodySw:
              'Gusa swali la mwanzo au andika lako. Majibu hutumia data yako ya ndani na, ukiwa mtandaoni, uchambuzi wa seva kwa undani zaidi.',
        ),
      ],
    ),
    HelpGuide(
      id: 'multi_currency',
      titleEn: 'Multi-currency payments',
      titleSw: 'Malipo ya sarafu nyingi',
      summaryEn: 'Record income and expenses in any currency with live rate capture.',
      summarySw: 'Rekodi mapato na gharama katika sarafu yoyote na kiwango cha sasa.',
      workspace: HelpWorkspace.both,
      categoryEn: 'Finances',
      categorySw: 'Fedha',
      icon: Icons.currency_exchange_outlined,
      estimatedMinutes: 3,
      steps: [
        HelpGuideStep(
          titleEn: 'Select a currency',
          titleSw: 'Chagua sarafu',
          bodyEn:
              'On any income, expense, or tenant form, tap the currency dropdown next to the amount field and choose from the list of supported currencies.',
          bodySw:
              'Katika fomu yoyote ya mapato, gharama, au mpangaji, gonga menyu ya sarafu karibu na sehemu ya kiasi na uchague kutoka kwenye orodha.',
        ),
        HelpGuideStep(
          titleEn: 'Live exchange rate',
          titleSw: 'Kiwango cha ubadilishaji cha sasa',
          bodyEn:
              'When the selected currency differs from your base currency, the current exchange rate appears below the field. Long-press the hint to see the full rate detail without truncation. The rate is saved with every record.',
          bodySw:
              'Kiwango cha ubadilishaji kinaonekana chini ya sehemu. Bonyeza kwa muda mrefu kidokezo kuona maelezo kamili. Kiwango kinahifadhiwa pamoja na rekodi kila wakati.',
        ),
        HelpGuideStep(
          titleEn: 'Change base currency',
          titleSw: 'Badilisha sarafu ya msingi',
          bodyEn:
              'Go to Settings → Currency to set your base currency. All dashboard totals convert to this currency for comparison while original amounts are always preserved.',
          bodySw:
              'Nenda Mipangilio → Sarafu ili kuweka sarafu yako ya msingi. Jumla zote kwenye dashibodi zinabadilishwa ingawa kiasi cha asili kinahifadhiwa.',
          route: Routes.SETTINGS,
        ),
      ],
    ),
    HelpGuide(
      id: 'luku_per_unit',
      titleEn: 'Track LUKU per unit',
      titleSw: 'Fuatilia LUKU kwa chumba',
      summaryEn: 'Filter electricity usage and top-ups by individual unit.',
      summarySw: 'Chuja matumizi ya umeme na malipo kwa chumba kimoja kimoja.',
      workspace: HelpWorkspace.rent,
      categoryEn: 'Operations',
      categorySw: 'Uendeshaji',
      icon: Icons.bolt_outlined,
      estimatedMinutes: 3,
      steps: [
        HelpGuideStep(
          titleEn: 'Open Utilities dashboard',
          titleSw: 'Fungua dashibodi ya Matumizi',
          bodyEn:
              'In the Rent workspace, navigate to a property and open the Smart Utility Dashboard.',
          bodySw:
              'Katika nafasi ya Rent, nenda kwenye mali na ufungue Dashibodi ya Matumizi Mahiri.',
          route: Routes.RENT_SMART_UTILITY_DASHBOARD,
        ),
        HelpGuideStep(
          titleEn: 'Select a unit chip',
          titleSw: 'Chagua kichupo cha chumba',
          bodyEn:
              'If the property has multiple units, a row of unit chips appears above the LUKU card. Tap a chip to filter all stats — balance, weekly chart, and activity log — to that unit only.',
          bodySw:
              'Ikiwa mali ina vyumba zaidi ya kimoja, safu ya vichwa vya chumba inaonekana juu ya kadi ya LUKU. Gonga kichupo kuchuja takwimu zote kwa chumba hicho peke yake.',
        ),
        HelpGuideStep(
          titleEn: 'Log a top-up for a unit',
          titleSw: 'Rekodi malipo ya umeme kwa chumba',
          bodyEn:
              'With a unit selected, tap Add LUKU top-up (or scan an SMS receipt). The top-up is tagged to that unit and counted separately from other units.',
          bodySw:
              'Ukiwa na chumba kilichochaguliwa, gonga Ongeza LUKU (au scan SMS). Malipo yanashikamana na chumba hicho na kuhesabiwa tofauti na vyumba vingine.',
        ),
      ],
    ),
    HelpGuide(
      id: 'tenant_guest_scoring',
      titleEn: 'Tenant & guest reliability scores',
      titleSw: 'Alama za uaminifu wa wapangaji na wageni',
      summaryEn: 'Rate tenants after a stay; check scores before onboarding new clients.',
      summarySw: 'Piga kura wapangaji baada ya kukaa; angalia alama kabla ya kusajili.',
      workspace: HelpWorkspace.both,
      categoryEn: 'Operations',
      categorySw: 'Uendeshaji',
      icon: Icons.verified_user_outlined,
      estimatedMinutes: 3,
      steps: [
        HelpGuideStep(
          titleEn: 'Rate a departing tenant',
          titleSw: 'Piga kura mpangaji anayeondoka',
          bodyEn:
              'After a lease ends, open the tenant profile and submit a reliability rating. The system considers payment history, partial payments, and your personal score.',
          bodySw:
              'Mkataba ukimalizika, fungua wasifu wa mpangaji na toa tathmini. Mfumo unazingatia historia ya malipo na alama yako ya kibinafsi.',
        ),
        HelpGuideStep(
          titleEn: 'Cooling-off period',
          titleSw: 'Muda wa kusubiri',
          bodyEn:
              'Scores are not published immediately. A cooling-off period applies before they become visible to other landlords, giving both parties time to resolve any disputes.',
          bodySw:
              'Alama hazichapishwi mara moja. Muda wa kusubiri unatumika kabla ya alama kuonekana kwa wamiliki wengine, ukiwapa pande zote muda wa kutatua mizozo.',
        ),
        HelpGuideStep(
          titleEn: 'Request a reference check',
          titleSw: 'Omba ukaguzi wa marejeo',
          bodyEn:
              'From the Tenant search screen, enter a phone number to request an anonymous cross-landlord reference. The result shows a reliability summary without revealing who submitted the rating.',
          bodySw:
              'Kutoka skrini ya Utafutaji wa Wapangaji, weka nambari ya simu kuomba marejeo ya siri kati ya wamiliki. Matokeo yanaonyesha muhtasari bila kufunua aliyetoa tathmini.',
        ),
      ],
    ),
    HelpGuide(
      id: 'navigate_the_app',
      titleEn: 'Navigate the app',
      titleSw: 'Elekea kwenye programu',
      summaryEn: 'Learn the five main tabs and where to find every feature.',
      summarySw: 'Jifunze vichupo vikuu vitano na mahali pa kila kipengele.',
      workspace: HelpWorkspace.both,
      categoryEn: 'Getting started',
      categorySw: 'Mwanzo',
      icon: Icons.grid_view_rounded,
      estimatedMinutes: 3,
      steps: [
        HelpGuideStep(
          titleEn: 'Home tab',
          titleSw: 'Kichupo cha Nyumbani',
          bodyEn:
              'Your main dashboard — Property Overview (active bookings, monthly revenue), today\'s check-ins and check-outs, and quick-action shortcuts.',
          bodySw:
              'Dashibodi yako kuu — Muhtasari wa Mali (uhifadhi hai, mapato ya mwezi), kuwasili na kuondoka leo, na njia za haraka.',
          route: Routes.HOME,
        ),
        HelpGuideStep(
          titleEn: 'Properties tab',
          titleSw: 'Kichupo cha Mali',
          bodyEn:
              'Browse and manage all your properties. Tap the + FAB to add a new property. Open any card to see units, income, and activity.',
          bodySw:
              'Vinjari na simamia mali zako zote. Gonga FAB ya + kuongeza mali mpya. Fungua kadi yoyote kuona vyumba, mapato, na historia.',
          route: Routes.MY_PROPERTIES,
        ),
        HelpGuideStep(
          titleEn: 'Finances tab',
          titleSw: 'Kichupo cha Fedha',
          bodyEn:
              'Income vs expense charts, net income, arrears, and financial overview across all properties.',
          bodySw:
              'Chati za mapato dhidi ya matumizi, mapato halisi, deni, na muhtasari wa fedha kwa mali zote.',
          route: Routes.FINANCIAL_OVERVIEW,
        ),
        HelpGuideStep(
          titleEn: 'Maintenance tab',
          titleSw: 'Kichupo cha Matengenezo',
          bodyEn:
              'View and manage maintenance tasks. Tap the + FAB to add a new task. Tasks sync online and appear in the host calendar.',
          bodySw:
              'Angalia na simamia kazi za matengenezo. Gonga FAB ya + kuongeza kazi mpya. Kazi zinasawazishwa na zinaonekana kwenye kalenda.',
          route: Routes.MAINTENANCE_TASKS,
        ),
        HelpGuideStep(
          titleEn: 'More tab',
          titleSw: 'Kichupo cha Zaidi',
          bodyEn:
              'A shortcut grid for secondary features: Host Calendar, Reports, Contract hub, Guest access, Send SMS/WhatsApp, Documents, Guest history, Design studio, and Settings.',
          bodySw:
              'Gridi ya njia za haraka kwa vipengele vya sekondari: Kalenda, Ripoti, Kitovu cha Mikataba, Ufikiaji, SMS/WhatsApp, Nyaraka, Historia ya Wageni, Studio, na Mipangilio.',
          route: Routes.MAIN,
        ),
      ],
    ),
  ];

  static const features = <HelpFeature>[
    HelpFeature(
      id: 'f_dashboard',
      titleEn: 'Finances tab',
      titleSw: 'Kichupo cha Fedha',
      descriptionEn: 'Income vs expense charts, net income, arrears, and monthly growth across all properties.',
      descriptionSw: 'Chati za mapato dhidi ya matumizi, mapato halisi, deni, na ukuaji wa kila mwezi kwa mali zote.',
      workspace: HelpWorkspace.both,
      icon: Icons.dashboard_outlined,
      route: Routes.FINANCIAL_OVERVIEW,
      relatedGuideId: 'getting_started_rent',
    ),
    HelpFeature(
      id: 'f_home',
      titleEn: 'Home tab',
      titleSw: 'Kichupo cha Nyumbani',
      descriptionEn: 'Active bookings, monthly revenue, today\'s check-ins/check-outs, and quick actions.',
      descriptionSw: 'Uhifadhi hai, mapato ya mwezi, kuwasili/kuondoka leo, na njia za haraka.',
      workspace: HelpWorkspace.both,
      icon: Icons.home_outlined,
      route: Routes.HOME,
      relatedGuideId: 'navigate_the_app',
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
      descriptionEn: 'Income vs expense trends, arrears calculation, net income, and monthly growth charts.',
      descriptionSw: 'Mwenendo wa mapato dhidi ya matumizi, hesabu ya deni, mapato halisi, na chati za ukuaji.',
      workspace: HelpWorkspace.bnb,
      icon: Icons.insights_outlined,
      route: Routes.FINANCIAL_OVERVIEW,
    ),
    HelpFeature(
      id: 'f_rent_hub',
      titleEn: 'Rental overview',
      titleSw: 'Muhtasari wa upangishaji',
      descriptionEn: 'Portfolio KPIs, net income, arrears, and weekly income vs expense — visible in the Finances tab.',
      descriptionSw: 'Vipimo vya mali, mapato halisi, deni, na chati ya mapato dhidi ya matumizi — kwenye kichupo cha Fedha.',
      workspace: HelpWorkspace.rent,
      icon: Icons.apartment,
      route: Routes.FINANCIAL_OVERVIEW,
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
      descriptionEn: 'Natural-language portfolio assistant — ask about income, arrears, occupancy, or maintenance.',
      descriptionSw: 'Msaidizi wa lugha ya kawaida — uliza kuhusu mapato, deni, ukaaji, au matengenezo.',
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
      id: 'f_scheduled_maintenance',
      titleEn: 'Scheduled maintenance',
      titleSw: 'Matengenezo yaliyopangwa',
      descriptionEn: 'Plan upkeep tasks, set priority, and get a day-before push reminder.',
      descriptionSw: 'Panga kazi za matengenezo, weka kipaumbele, na pata ukumbusho siku moja kabla.',
      workspace: HelpWorkspace.rent,
      icon: Icons.build_circle_outlined,
      route: Routes.RENT_SCHEDULE_MAINTENANCE_FORM,
      relatedGuideId: 'schedule_maintenance',
    ),
    HelpFeature(
      id: 'f_smart_utility',
      titleEn: 'Smart utility dashboard',
      titleSw: 'Dashibodi ya matumizi mahiri',
      descriptionEn: 'Track LUKU electricity top-ups per unit; scan SMS receipts automatically.',
      descriptionSw: 'Fuatilia malipo ya LUKU kwa kila chumba; scan risiti za SMS moja kwa moja.',
      workspace: HelpWorkspace.rent,
      icon: Icons.bolt_outlined,
      route: Routes.RENT_SMART_UTILITY_DASHBOARD,
      relatedGuideId: 'luku_per_unit',
    ),
    HelpFeature(
      id: 'f_my_properties',
      titleEn: 'My properties',
      titleSw: 'Mali zangu',
      descriptionEn: 'Browse all properties, mark favourites, and navigate to details.',
      descriptionSw: 'Vinjari mali zako zote, pendeza, na nenda kwenye maelezo.',
      workspace: HelpWorkspace.both,
      icon: Icons.domain_outlined,
      route: Routes.MY_PROPERTIES,
    ),
    HelpFeature(
      id: 'f_listing_details',
      titleEn: 'Listing details',
      titleSw: 'Maelezo ya orodha',
      descriptionEn: 'Units, net income, BnB/Rent tabs, expected income, and activity log per property.',
      descriptionSw: 'Vyumba, mapato halisi, vichupo vya BnB/Kodi, mapato yanayotarajiwa, na historia.',
      workspace: HelpWorkspace.both,
      icon: Icons.info_outline,
      route: Routes.LISTING_DETAILS,
    ),
    HelpFeature(
      id: 'f_guest_history',
      titleEn: 'Guest history',
      titleSw: 'Historia ya wageni',
      descriptionEn: 'Past and upcoming guests, stay durations, and payment history.',
      descriptionSw: 'Wageni wa zamani na wa sasa, muda wa kukaa, na historia ya malipo.',
      workspace: HelpWorkspace.bnb,
      icon: Icons.history_rounded,
      route: Routes.GUEST_HISTORY,
    ),
    HelpFeature(
      id: 'f_tenant_ledger',
      titleEn: 'Tenant ledger',
      titleSw: 'Daftari la mpangaji',
      descriptionEn: 'Per-tenant payment history, running balance, and occupancy timeline.',
      descriptionSw: 'Historia ya malipo ya kila mpangaji, salio la mwenendo, na mstari wa muda.',
      workspace: HelpWorkspace.rent,
      icon: Icons.account_balance_wallet_outlined,
      route: Routes.RENT_TENANT_LEDGER_OCCUPANCY,
    ),
    HelpFeature(
      id: 'f_tenant_scoring',
      titleEn: 'Tenant reliability scoring',
      titleSw: 'Alama za uaminifu wa mpangaji',
      descriptionEn: 'Rate tenants after a lease; request anonymous cross-landlord reference checks.',
      descriptionSw: 'Piga kura wapangaji baada ya mkataba; omba ukaguzi wa siri kati ya wamiliki.',
      workspace: HelpWorkspace.both,
      icon: Icons.verified_user_outlined,
      route: Routes.MAIN,
      relatedGuideId: 'tenant_guest_scoring',
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
