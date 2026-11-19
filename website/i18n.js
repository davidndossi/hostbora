(function () {
  const STORAGE_KEY = 'hostbora-lang-choice';

  const messages = {
    en: {
      /* ---------------------------------------------------------- meta -- */
      'meta.title': 'HostBora — Property management that stays clear',
      'meta.description':
        'HostBora brings short-stay BnB and long-term rent into one app for landlords and property managers in Tanzania. Track bookings and tenants, record payments in TZS, and see how each property performs.',

      /* ---------------------------------------------------------- chrome -- */
      'skip': 'Skip to content',
      'brand.home': 'HostBora home',
      'menu.open': 'Open menu',
      'menu.close': 'Close menu',
      'nav.label': 'Primary',
      'nav.home': 'Home',
      'nav.features': 'Features',
      'nav.workspaces': 'Workspaces',
      'nav.audience': 'Who uses it',
      'nav.pricing': 'Pricing',
      'nav.trust': 'Trust',
      'nav.getStarted': 'Get Started',
      'cta.register': 'Create account',
      'pricing.choose': 'Choose this plan',
      'nav.privacy': 'Privacy policy',
      'nav.about': 'About',
      'nav.whatsapp': 'WhatsApp',
      'lang.label': 'Language',
      'lang.en': 'English',
      'lang.sw': 'Kiswahili',

      /* ------------------------------------------------------------ hero -- */
      'hero.badge': 'Early access — join 200+ landlords already using HostBora',
      'hero.title': 'Property management that stays clear — from guest nights to monthly rent.',
      'hero.tagline': 'Manage your properties with ease — short-stay BnB and long-term rent.',
      'hero.lead':
        'HostBora brings short-stay hosting and long-term rentals into one trustworthy app. Track bookings and tenants, record payments in TZS, manage staff and expenses, and see how each property performs.',
      'cta.install': 'Install Now',
      'cta.availableOn': 'Available on',
      'app.version': 'App v1.5.8 · Updated October 2026',
      'chip.vault': 'Document Vault',
      'chip.calendar': 'Host Calendar',
      'chip.access': 'Guest Access',
      'chip.ai': 'AI Help Chat',
      'chip.report': 'Daily Report',
      'chip.maintenance': 'Maintenance',

      /* -------------------------------------------------------- features -- */
      'features.kicker': 'Daily toolkit',
      'features.title': 'Everything landlords and managers need daily',
      'features.sub':
        'One calm toolkit for income, operations, people, and records — whether you host nights or collect monthly rent.',

      'feat.payments.title': 'Payments & expenses',
      'feat.payments.desc':
        'Track M-Pesa and mobile money payments — Tigo Pesa, Airtel Money, and more. Record rent and guest income, log expenses, and see cash flow without spreadsheet chaos.',
      'feat.workspaces.title': 'BnB & long-term rent',
      'feat.workspaces.desc':
        'Run short-stay bookings and monthly leases from the same portfolio — switch when you need to.',
      'feat.reports.title': 'Reports & profitability',
      'feat.reports.desc':
        'Understand income vs spend per property with summaries that support real decisions.',
      'feat.staff.title': 'Staff and Tasks',
      'feat.staff.desc':
        'Assign cleaners, guards, or maintenance — with due dates and status so nothing is missed.',
      'feat.reminders.title': 'WhatsApp reminders',
      'feat.reminders.desc':
        'Send tenants rent-due and lease reminders on WhatsApp, from the app.',
      'feat.reminders.tag': 'On WhatsApp',
      'feat.vault.title': 'Document vault',
      'feat.vault.desc':
        'Store leases, IDs, manuals, and tax records in clear folders — ready when you need them.',

      'more.vault.title': 'Document vault',
      'more.vault.desc': 'Leases, IDs and receipts per property',
      'more.calendar.title': 'Calendar sync',
      'more.calendar.desc': 'Link channels, cut double bookings',
      'more.reminders.title': 'WhatsApp reminders',
      'more.reminders.desc': 'Rent and lease notices to tenants',
      'more.fx.title': 'Multi-currency',
      'more.fx.desc': 'TZS first, with live FX for diaspora owners',
      'more.referrals.title': 'Referrals & rewards',
      'more.referrals.desc': 'Invite other landlords, earn free months',
      'more.score.title': 'Host Score',
      'more.score.desc': 'Challenges that keep records up to date',

      /* ------------------------------------------------------ workspaces -- */
      'workspaces.kicker': 'BnB + Rent',
      'workspaces.title': 'Two workspaces, one app',
      'workspaces.sub': 'Switch between BnB and Rent anytime — same properties, tailored flows.',
      'workspaces.bnb.badge': 'BnB',
      'workspaces.bnb.title': 'Short-stay hosting',
      'workspaces.bnb.desc':
        'Manage nightly bookings, guest turnover, cleaning schedules and hospitality-style income. Ideal for furnished apartments, guest houses and holiday lets.',
      'workspaces.rent.badge': 'Rent',
      'workspaces.rent.title': 'Long-term rentals',
      'workspaces.rent.desc':
        'Run monthly leases, tenant records, rent collection and building-level expenses. Built for landlords and managers with recurring income.',

      /* -------------------------------------------------------- audience -- */
      'audience.kicker': 'Who it’s for',
      'audience.title': 'Made for people who run properties',
      'audience.sub':
        'Whether you own one unit or manage a growing portfolio across Dar, Arusha or beyond.',
      'audience.landlords.title': 'Landlords',
      'audience.landlords.desc':
        'Whether you own one unit or manage a growing portfolio across Dar, Arusha, or beyond.',
      'audience.managers.title': 'Property Managers',
      'audience.managers.desc':
        'Oversee multiple owners or buildings with staff workflows, expenses, and reports your clients can trust.',
      'audience.hosts.title': 'Hosts & operators',
      'audience.hosts.desc':
        'Run BnB or mixed portfolios — from boutique stays to serviced apartments — with bookings and ops in sync.',
      'audience.hosts.tag1': 'Nightly + monthly income side by side',
      'audience.hosts.tag2': 'Cleaning and turnover tasks',
      'audience.hosts.tag3': 'Guest codes and entry logs',
      'audience.hosts.tag4': 'One report per owner',

      /* ----------------------------------------------------------- offer -- */
      'offer.badge': 'Lunch Offer!',
      'offer.leadStrong': 'Free for a limited time,',
      'offer.lead':
        "Full access to HostBora while we're in early access — every feature, no credit card, no commitment.",
      'offer.cta': 'Download for Free Now',

      /* --------------------------------------------------------- pricing -- */
      'pricing.kicker': 'Pricing',
      'pricing.title': 'Simple, transparent pricing',
      'pricing.sub':
        'No surprises — start free today, then pick a plan that fits your portfolio when billing begins.',
      'pricing.period': 'TZS / month',
      'pricing.renews': 'Renews automatically. Cancel anytime.',
      'pricing.footnote':
        'Planned rates shown in Tanzanian shillings. M-Pesa and mobile money supported when billing starts. <a href="#contact">Questions?</a> Chat with us on WhatsApp or email.',

      'pricing.starter.name': 'Starter',
      'pricing.starter.summary': 'For solo hosts getting organised.',
      'pricing.starter.li1': 'Up to 3 properties',
      'pricing.starter.li2': 'BnB or Rent workspace',
      'pricing.starter.li3': 'Payments, expenses & reminders',
      'pricing.starter.li4': 'Basic reports',

      'pricing.pro.badge': 'Our Recommendation',
      'pricing.pro.name': 'Pro',
      'pricing.pro.summary': 'For growing portfolios and small teams.',
      'pricing.pro.li1': 'Up to 10 properties',
      'pricing.pro.li2': 'Staff, tasks & calendar sync',
      'pricing.pro.li3': 'Document vault & advanced reports',
      'pricing.pro.li4': 'SMS / WhatsApp add-on available',

      'pricing.ultra.name': 'Ultra',
      'pricing.ultra.summary': 'For major operators and property managers.',
      'pricing.ultra.li1': 'Unlimited properties',
      'pricing.ultra.li2': 'Smart locks & entry logs',
      'pricing.ultra.li3': 'AI Manager & design tools',
      'pricing.ultra.li4': 'Priority support',

      /* ----------------------------------------------------------- trust -- */
      'trust.kicker': 'Trust',
      'trust.title': 'Built for how you work in Africa',
      'trust.sub':
        'Professional, dependable, and respectful of local realities — not a generic import.',
      'trust.offline.title': 'Works offline',
      'trust.offline.desc':
        'Keep recording payments, notes and tasks when connectivity dips — everything syncs when you are back online.',
      'trust.tzs.title': 'TZS-friendly',
      'trust.tzs.desc':
        'Think in Tanzanian shillings and the mobile money you already use — M-Pesa, Tigo Pesa and Airtel Money — with live FX when an owner thinks in dollars.',
      'trust.security.title': 'Security & privacy',
      'trust.security.desc':
        'Your property and tenant data stay yours, encrypted in transit and at rest. We collect only what the service needs — see our <a href="./privacy-policy.html">Privacy Policy</a>.',
      'trust.chart.title': 'Yearly Status',
      'trust.chart.income': 'Income',
      'trust.chart.expenses': 'Expenses',
      'trust.chart.caption': 'Income',

      /* --------------------------------------------------------- contact -- */
      'contact.kicker': 'Connect',
      'contact.title': 'Kick things off with HostBora!',
      'contact.sub':
        'Available on mobile for hosts, landlords, and managers in Tanzania and the wider East Africa region. Reach out for early access, partnerships, or support.',
      'contact.whatsapp': 'Chat on WhatsApp',
      'contact.or': 'Or directly connect with us',
      'contact.name': 'Name',
      'contact.namePlaceholder': 'Joseph Mwita',
      'contact.email': 'Email *',
      'contact.emailPlaceholder': 'yourname@email.com',
      'contact.propertyType': 'Property Type? *',
      'contact.select': 'Select',
      'contact.typeBnb': 'Short-stay / BnB',
      'contact.typeRent': 'Long-term rent',
      'contact.typeMixed': 'Both',
      'contact.typeManaging': 'I manage for owners',
      'contact.message': 'Your Message',
      'contact.messagePlaceholder': 'Tell us more about your project',
      'contact.submit': 'Submit Now',
      'contact.hint': 'WhatsApp is fastest — or use the form and we’ll reply by email.',
      'contact.sending': 'Sending…',
      'contact.sent': 'Thanks — we’ve got your message and will reply by email.',
      'contact.error': 'Could not send your message. Please try WhatsApp or email instead.',
      'contact.copied': 'Email address copied. Opening your mail app…',
      'contact.openingEmail': 'Opening your mail app…',

      /* ---------------------------------------------------------- footer -- */
      'footer.about':
        'Property management for landlords, managers, and hosts. Built by <strong>Artbel Technologies</strong> in Dar es Salaam — a Tanzanian team behind HostBora.',
      'footer.getApp': 'Get The App Now',
      'footer.navLabel': 'Footer',
      'footer.sections': 'Sections',
      'footer.policies': 'Policies',
      'footer.social': 'Social Links',
      'footer.terms': 'Terms & conditions',
      'footer.vulnerability': 'Report a vulnerability',
      'footer.copyright': '© 2026 Artbel Technologies. All rights reserved.',

      /* ------------------------------------------------------- register -- */
      'register.meta.title': 'Create your HostBora account',
      'register.meta.description':
        'Sign up for HostBora the same way as in the app — name, phone, optional email, then a 4-digit code.',
      'register.kicker': 'Create account',
      'register.title': 'Set up HostBora in a few steps',
      'register.lead':
        'Same onboarding as the app. After you verify, we send a payment prompt to the phone you registered, for the plan you picked.',
      'register.planLabel': 'Selected plan',
      'register.stepName': 'Your name',
      'register.stepPhone': 'Phone number',
      'register.stepEmail': 'Email',
      'register.stepCode': 'Verification code',
      'register.firstName': 'First name',
      'register.lastName': 'Last name (optional)',
      'register.firstNamePlaceholder': 'Amina',
      'register.lastNamePlaceholder': 'Mwamba',
      'register.phone': 'Tanzanian mobile number',
      'register.phonePlaceholder': '0712 345 678',
      'register.phoneHint': 'We will send a 4-digit code by SMS.',
      'register.emailAsk': 'Do you have an email address?',
      'register.emailYes': 'Yes',
      'register.emailNo': 'No, use SMS only',
      'register.email': 'Email',
      'register.emailPlaceholder': 'you@email.com',
      'register.emailHint': 'Optional. You can receive the code by email instead of SMS.',
      'register.code': 'Enter the 4-digit code',
      'register.codeHintSms': 'We sent a code by SMS to your phone.',
      'register.codeHintEmail': 'We sent a code to your email.',
      'register.continue': 'Continue',
      'register.back': 'Back',
      'register.verify': 'Verify and pay',
      'register.sending': 'Sending…',
      'register.paying': 'Starting payment…',
      'register.successTitle': 'Account created',
      'register.successPay':
        'Check your phone for the mobile-money prompt to pay this plan.',
      'register.successPayFail':
        'Your account is ready. Open the app to pay for your plan if the prompt does not arrive.',
      'register.successDesktop': 'Download HostBora and sign in with this phone number.',
      'register.openApp': 'Open HostBora',
      'register.download': 'Download the app',
      'register.signinHint':
        'After installing, return here and tap Open HostBora — you will land on Sign in.',
      'register.exists': 'An account with this phone already exists. Open the app to sign in.',
      'register.error': 'Something went wrong. Try again.',
      'register.invalidPhone': 'Enter a valid Tanzanian mobile number (e.g. 0712345678).',
      'register.invalidName': 'Enter your first name.',
      'register.invalidEmail': 'Enter a valid email, or choose SMS only.',
      'register.invalidCode': 'Enter the 4-digit code.',
      'register.terms':
        'By continuing you agree to the <a href="./terms-of-service.html">Terms</a> and <a href="./privacy-policy.html">Privacy policy</a>.',
      'signin.meta.title': 'Open HostBora',
      'signin.meta.description': 'Open HostBora to sign in, or download the app first.',
      'signin.title': 'Sign in to HostBora',
      'signin.lead':
        'If the app is installed it opens on Sign in. If not, download it, then come back and tap Open HostBora.',
      'signin.open': 'Open HostBora',
      'signin.play': 'Get it on Google Play',
      'signin.appstore': 'Download on the App Store',
    },

    sw: {
      /* ---------------------------------------------------------- meta -- */
      'meta.title': 'HostBora — Usimamizi wa majengo ulio wazi',
      'meta.description':
        'HostBora inaunganisha BnB ya muda mfupi na upangaji wa muda mrefu katika app moja kwa wamiliki na wasimamizi wa majengo Tanzania. Fuatilia nafasi na wapangaji, rekodi malipo kwa TZS, na uone jinsi kila mali inavyofanya kazi.',

      /* ---------------------------------------------------------- chrome -- */
      'skip': 'Nenda kwenye maudhui',
      'brand.home': 'Mwanzo wa HostBora',
      'menu.open': 'Fungua menyu',
      'menu.close': 'Funga menyu',
      'nav.label': 'Kuu',
      'nav.home': 'Mwanzo',
      'nav.features': 'Vipengele',
      'nav.workspaces': 'Maeneo ya kazi',
      'nav.audience': 'Wanaotumia',
      'nav.pricing': 'Bei',
      'nav.trust': 'Uaminifu',
      'nav.getStarted': 'Anza sasa',
      'cta.register': 'Fungua akaunti',
      'pricing.choose': 'Chagua mpango huu',
      'nav.privacy': 'Sera ya faragha',
      'nav.about': 'Kuhusu',
      'nav.whatsapp': 'WhatsApp',
      'lang.label': 'Lugha',
      'lang.en': 'Kiingereza',
      'lang.sw': 'Kiswahili',

      /* ------------------------------------------------------------ hero -- */
      'hero.badge': 'Ufikiaji wa mwanzo — jiunge na wamiliki 200+ wanaotumia HostBora',
      'hero.title': 'Usimamizi wa majengo unaobaki wazi — kutoka usiku wa wageni hadi kodi ya mwezi.',
      'hero.tagline': 'Simamia mali zako kwa urahisi — BnB ya muda mfupi na upangaji wa muda mrefu.',
      'hero.lead':
        'HostBora inaunganisha ukaribishaji wa muda mfupi na upangaji wa muda mrefu katika app moja ya kuaminika. Fuatilia nafasi na wapangaji, rekodi malipo kwa TZS, simamia wafanyakazi na matumizi, na uone jinsi kila mali inavyofanya kazi.',
      'cta.install': 'Pakua sasa',
      'cta.availableOn': 'Inapatikana kwenye',
      'app.version': 'App v1.5.8 · Imeboreshwa Oktoba 2026',
      'chip.vault': 'Hifadhi ya nyaraka',
      'chip.calendar': 'Kalenda ya mwenyeji',
      'chip.access': 'Ufikiaji wa wageni',
      'chip.ai': 'Mazungumzo ya AI',
      'chip.report': 'Ripoti ya kila siku',
      'chip.maintenance': 'Matengenezo',

      /* -------------------------------------------------------- features -- */
      'features.kicker': 'Zana za kila siku',
      'features.title': 'Kila kitu wamiliki na wasimamizi wanahitaji kila siku',
      'features.sub':
        'Zana moja tulivu kwa mapato, uendeshaji, watu na kumbukumbu — iwe unapangisha kwa siku au unakusanya kodi ya mwezi.',

      'feat.payments.title': 'Malipo na matumizi',
      'feat.payments.desc':
        'Fuatilia malipo ya M-Pesa na pesa za simu — Tigo Pesa, Airtel Money, na zaidi. Rekodi kodi na mapato ya wageni, weka matumizi, na uone mtiririko wa fedha bila lahajedwali.',
      'feat.workspaces.title': 'BnB na upangaji wa muda mrefu',
      'feat.workspaces.desc':
        'Endesha nafasi za muda mfupi na mikataba ya mwezi kutoka kwenye majengo yale yale — badilisha unapohitaji.',
      'feat.reports.title': 'Ripoti na faida',
      'feat.reports.desc':
        'Elewa mapato dhidi ya matumizi kwa kila jengo kwa muhtasari unaosaidia maamuzi halisi.',
      'feat.staff.title': 'Wafanyakazi na kazi',
      'feat.staff.desc':
        'Gawia wasafishaji, walinzi au matengenezo — kwa tarehe za mwisho na hali ili kitu kisikosewe.',
      'feat.reminders.title': 'Vikumbusho vya WhatsApp',
      'feat.reminders.desc':
        'Wapangaji wanapata vikumbusho vya kodi na mkataba kwenye WhatsApp.',
      'feat.reminders.tag': 'Kwenye WhatsApp',
      'feat.vault.title': 'Hifadhi ya nyaraka',
      'feat.vault.desc':
        'Hifadhi mikataba, vitambulisho, miongozo na kumbukumbu za kodi kwenye folda zilizo wazi — tayari unapohitaji.',

      'more.vault.title': 'Hifadhi ya nyaraka',
      'more.vault.desc': 'Mikataba, vitambulisho na risiti kwa kila jengo',
      'more.calendar.title': 'Kuunganisha kalenda',
      'more.calendar.desc': 'Unganisha njia, punguza kuweka nafasi mara mbili',
      'more.reminders.title': 'Vikumbusho vya WhatsApp',
      'more.reminders.desc': 'Taarifa za kodi na mkataba kwa wapangaji',
      'more.fx.title': 'Sarafu nyingi',
      'more.fx.desc': 'TZS kwanza, na viwango vya ubadilishaji kwa wamiliki wa ugenini',
      'more.referrals.title': 'Marejeleo na zawadi',
      'more.referrals.desc': 'Karibisha wamiliki wengine, pata miezi ya bure',
      'more.score.title': 'Alama ya mwenyeji',
      'more.score.desc': 'Changamoto zinazoweka kumbukumbu zako sawa',

      /* ------------------------------------------------------ workspaces -- */
      'workspaces.kicker': 'BnB + Kodi',
      'workspaces.title': 'Maeneo mawili ya kazi, app moja',
      'workspaces.sub':
        'Badilisha kati ya BnB na Kodi wakati wowote — majengo yale yale, mifumo iliyobinafsishwa.',
      'workspaces.bnb.badge': 'BnB',
      'workspaces.bnb.title': 'Upangishaji wa muda mfupi',
      'workspaces.bnb.desc':
        'Simamia nafasi za usiku, mabadiliko ya wageni, ratiba za usafi na mapato ya ukarimu. Inafaa kwa vyumba vilivyo na vifaa, nyumba za wageni na mapumziko.',
      'workspaces.rent.badge': 'Kodi',
      'workspaces.rent.title': 'Upangaji wa muda mrefu',
      'workspaces.rent.desc':
        'Endesha mikataba ya mwezi, kumbukumbu za wapangaji, ukusanyaji wa kodi na matumizi ya jengo. Imeundwa kwa wamiliki na wasimamizi wenye mapato ya kila mwezi.',

      /* -------------------------------------------------------- audience -- */
      'audience.kicker': 'Kwa nani',
      'audience.title': 'Imeundwa kwa watu wanaoendesha majengo',
      'audience.sub':
        'Iwe unamiliki chumba kimoja au unasimamia majengo yanayoongezeka Dar, Arusha au kwingine.',
      'audience.landlords.title': 'Wamiliki wa majengo',
      'audience.landlords.desc':
        'Iwe unamiliki chumba kimoja au unasimamia majengo yanayoongezeka Dar, Arusha au kwingine.',
      'audience.managers.title': 'Wasimamizi wa majengo',
      'audience.managers.desc':
        'Simamia wamiliki au majengo mengi kwa mifumo ya wafanyakazi, matumizi na ripoti ambazo wateja wako wanaweza kuziamini.',
      'audience.hosts.title': 'Wenyeji na waendeshaji',
      'audience.hosts.desc':
        'Endesha BnB au majengo mchanganyiko — kutoka nyumba ndogo za kipekee hadi vyumba vya huduma — na nafasi na uendeshaji vikiwa sawa.',
      'audience.hosts.tag1': 'Mapato ya siku na ya mwezi pamoja',
      'audience.hosts.tag2': 'Kazi za usafi na mabadiliko ya wageni',
      'audience.hosts.tag3': 'Namba za wageni na kumbukumbu za kuingia',
      'audience.hosts.tag4': 'Ripoti moja kwa kila mmiliki',

      /* ----------------------------------------------------------- offer -- */
      'offer.badge': 'Ofa ya chakula cha mchana!',
      'offer.leadStrong': 'Bure kwa muda mfupi,',
      'offer.lead':
        'Ufikiaji kamili wa HostBora tukiwa katika ufikiaji wa mwanzo — kila kipengele, hakuna kadi ya benki, hakuna ahadi.',
      'offer.cta': 'Pakua bure sasa',

      /* --------------------------------------------------------- pricing -- */
      'pricing.kicker': 'Bei',
      'pricing.title': 'Bei rahisi na wazi',
      'pricing.sub':
        'Hakuna mshangao — anza bure leo, kisha chagua mpango unaolingana na majengo yako malipo yanapoanza.',
      'pricing.period': 'TZS / mwezi',
      'pricing.renews': 'Inajiongeza yenyewe. Sitisha wakati wowote.',
      'pricing.footnote':
        'Bei zilizopangwa zinaonyeshwa kwa shilingi za Tanzania. M-Pesa na pesa za simu zitaungwa mkono malipo yanapoanza. <a href="#contact">Maswali?</a> Zungumza nasi kwa WhatsApp au barua pepe.',

      'pricing.starter.name': 'Starter',
      'pricing.starter.summary': 'Kwa wenyeji wa pekee wanaoanza kujipanga.',
      'pricing.starter.li1': 'Hadi majengo 3',
      'pricing.starter.li2': 'Eneo la kazi la BnB au Kodi',
      'pricing.starter.li3': 'Malipo, matumizi na vikumbusho',
      'pricing.starter.li4': 'Ripoti za msingi',

      'pricing.pro.badge': 'Tunapendekeza',
      'pricing.pro.name': 'Pro',
      'pricing.pro.summary': 'Kwa majengo yanayoongezeka na timu ndogo.',
      'pricing.pro.li1': 'Hadi majengo 10',
      'pricing.pro.li2': 'Wafanyakazi, kazi na kuunganisha kalenda',
      'pricing.pro.li3': 'Hifadhi ya nyaraka na ripoti za kina',
      'pricing.pro.li4': 'SMS / WhatsApp inapatikana kama nyongeza',

      'pricing.ultra.name': 'Ultra',
      'pricing.ultra.summary': 'Kwa waendeshaji wakubwa na wasimamizi wa majengo.',
      'pricing.ultra.li1': 'Majengo bila kikomo',
      'pricing.ultra.li2': 'Kufuli mahiri na kumbukumbu za kuingia',
      'pricing.ultra.li3': 'Msimamizi wa AI na zana za ubunifu',
      'pricing.ultra.li4': 'Msaada wa kipaumbele',

      /* ----------------------------------------------------------- trust -- */
      'trust.kicker': 'Uaminifu',
      'trust.title': 'Imeundwa kwa jinsi unavyofanya kazi Afrika',
      'trust.sub':
        'Ya kitaalamu, ya kutegemewa na inayoheshimu mazingira ya hapa — si bidhaa ya kuagiza tu.',
      'trust.offline.title': 'Inafanya kazi bila intaneti',
      'trust.offline.desc':
        'Endelea kurekodi malipo, maelezo na kazi mtandao unaposhuka — kila kitu kinasawazishwa unaporejea mtandaoni.',
      'trust.tzs.title': 'Rafiki kwa TZS',
      'trust.tzs.desc':
        'Fikiri kwa shilingi za Tanzania na pesa za simu unazotumia — M-Pesa, Tigo Pesa na Airtel Money — na viwango vya ubadilishaji mmiliki anapofikiri kwa dola.',
      'trust.security.title': 'Usalama na faragha',
      'trust.security.desc':
        'Taarifa za majengo na wapangaji wako zinabaki zako, zikiwa zimefichwa wakati wa kusafirishwa na kuhifadhiwa. Tunakusanya tu kinachohitajika — ona <a href="./privacy-policy.html">Sera yetu ya Faragha</a>.',
      'trust.chart.title': 'Hali ya mwaka',
      'trust.chart.income': 'Mapato',
      'trust.chart.expenses': 'Matumizi',
      'trust.chart.caption': 'Mapato',

      /* --------------------------------------------------------- contact -- */
      'contact.kicker': 'Ungana nasi',
      'contact.title': 'Anza safari yako na HostBora!',
      'contact.sub':
        'Inapatikana kwa simu kwa wenyeji, wamiliki na wasimamizi Tanzania na Afrika Mashariki kwa ujumla. Wasiliana nasi kwa ufikiaji wa mwanzo, ushirikiano au msaada.',
      'contact.whatsapp': 'Zungumza kwa WhatsApp',
      'contact.or': 'Au wasiliana nasi moja kwa moja',
      'contact.name': 'Jina',
      'contact.namePlaceholder': 'Joseph Mwita',
      'contact.email': 'Barua pepe *',
      'contact.emailPlaceholder': 'jina@email.com',
      'contact.propertyType': 'Aina ya jengo? *',
      'contact.select': 'Chagua',
      'contact.typeBnb': 'Muda mfupi / BnB',
      'contact.typeRent': 'Kodi ya muda mrefu',
      'contact.typeMixed': 'Zote mbili',
      'contact.typeManaging': 'Nasimamia kwa wamiliki',
      'contact.message': 'Ujumbe wako',
      'contact.messagePlaceholder': 'Tuambie zaidi kuhusu mradi wako',
      'contact.submit': 'Tuma sasa',
      'contact.hint': 'WhatsApp ni haraka zaidi — au tumia fomu na tutajibu kwa barua pepe.',
      'contact.sending': 'Inatuma…',
      'contact.sent': 'Asante — tumepokea ujumbe wako na tutajibu kwa barua pepe.',
      'contact.error': 'Hatuwezi kutuma ujumbe wako. Tafadhali tumia WhatsApp au barua pepe.',
      'contact.copied': 'Barua pepe imenakiliwa. Tunafungua app yako ya barua…',
      'contact.openingEmail': 'Tunafungua app yako ya barua…',

      /* ---------------------------------------------------------- footer -- */
      'footer.about':
        'Usimamizi wa majengo kwa wamiliki, wasimamizi na wenyeji. Imeundwa na <strong>Artbel Technologies</strong> Dar es Salaam — timu ya Kitanzania iliyo nyuma ya HostBora.',
      'footer.getApp': 'Pata app sasa',
      'footer.navLabel': 'Chini ya ukurasa',
      'footer.sections': 'Sehemu',
      'footer.policies': 'Sera',
      'footer.social': 'Mitandao ya kijamii',
      'footer.terms': 'Vigezo na masharti',
      'footer.vulnerability': 'Ripoti udhaifu wa kiusalama',
      'footer.copyright': '© 2026 Artbel Technologies. Haki zote zimehifadhiwa.',

      /* ------------------------------------------------------- register -- */
      'register.meta.title': 'Fungua akaunti ya HostBora',
      'register.meta.description':
        'Jisajili HostBora kama kwenye app — jina, simu, barua pepe ya hiari, kisha msimbo wa tarakimu 4.',
      'register.kicker': 'Fungua akaunti',
      'register.title': 'Anzisha HostBora kwa hatua chache',
      'register.lead':
        'Usajili ni ule ule wa app. Baada ya kuthibitisha, tutatuma ombi la malipo kwenye simu uliyosajili, kwa mpango uliochagua.',
      'register.planLabel': 'Mpango uliochaguliwa',
      'register.stepName': 'Jina lako',
      'register.stepPhone': 'Namba ya simu',
      'register.stepEmail': 'Barua pepe',
      'register.stepCode': 'Msimbo wa uthibitisho',
      'register.firstName': 'Jina la kwanza',
      'register.lastName': 'Jina la ukoo (si lazima)',
      'register.firstNamePlaceholder': 'Amina',
      'register.lastNamePlaceholder': 'Mwamba',
      'register.phone': 'Namba ya simu Tanzania',
      'register.phonePlaceholder': '0712 345 678',
      'register.phoneHint': 'Tutakutumia msimbo wa tarakimu 4 kwa SMS.',
      'register.emailAsk': 'Una barua pepe?',
      'register.emailYes': 'Ndiyo',
      'register.emailNo': 'Hapana, tumia SMS pekee',
      'register.email': 'Barua pepe',
      'register.emailPlaceholder': 'wewe@email.com',
      'register.emailHint': 'Si lazima. Unaweza kupokea msimbo kwa barua pepe badala ya SMS.',
      'register.code': 'Weka msimbo wa tarakimu 4',
      'register.codeHintSms': 'Tumekutumia msimbo kwa SMS kwenye simu yako.',
      'register.codeHintEmail': 'Tumekutumia msimbo kwenye barua pepe yako.',
      'register.continue': 'Endelea',
      'register.back': 'Rudi',
      'register.verify': 'Thibitisha na ulipe',
      'register.sending': 'Inatuma…',
      'register.paying': 'Inaanzisha malipo…',
      'register.successTitle': 'Akaunti imefunguliwa',
      'register.successPay':
        'Angalia simu yako kwa ombi la malipo ya pesa taslimu ya simu kwa mpango huu.',
      'register.successPayFail':
        'Akaunti iko tayari. Fungua app kulipia mpango wako ikiwa ombi halijafika.',
      'register.successDesktop': 'Pakua HostBora na uingie kwa namba hii ya simu.',
      'register.openApp': 'Fungua HostBora',
      'register.download': 'Pakua app',
      'register.signinHint':
        'Baada ya kusakinisha, rudi hapa na ubonyeze Fungua HostBora — utafika kwenye Ingia.',
      'register.exists': 'Akaunti yenye namba hii ipo. Fungua app kuingia.',
      'register.error': 'Kumetokea hitilafu. Jaribu tena.',
      'register.invalidPhone': 'Weka namba sahihi ya simu Tanzania (mfano 0712345678).',
      'register.invalidName': 'Weka jina lako la kwanza.',
      'register.invalidEmail': 'Weka barua pepe sahihi, au chagua SMS pekee.',
      'register.invalidCode': 'Weka msimbo wa tarakimu 4.',
      'register.terms':
        'Kwa kuendelea unakubali <a href="./terms-of-service.html">Masharti</a> na <a href="./privacy-policy.html">Sera ya faragha</a>.',
      'signin.meta.title': 'Fungua HostBora',
      'signin.meta.description': 'Fungua HostBora kuingia, au pakua app kwanza.',
      'signin.title': 'Ingia HostBora',
      'signin.lead':
        'Ikiwa app imesakinishwa itafunguka kwenye Ingia. Ikiwa sivyo, ipakue, kisha rudi na ubonyeze Fungua HostBora.',
      'signin.open': 'Fungua HostBora',
      'signin.play': 'Pata kwenye Google Play',
      'signin.appstore': 'Pakua kwenye App Store',
    },
  };

  function isInTanzania() {
    try {
      const zone = Intl.DateTimeFormat().resolvedOptions().timeZone || '';
      if (zone === 'Africa/Dar_es_Salaam') return true;
      if (zone) return false;
    } catch (_) {}
    return true;
  }

  function getLang() {
    const requested = new URLSearchParams(location.search).get('lang');
    if (requested === 'en' || requested === 'sw') return requested;
    const saved = localStorage.getItem(STORAGE_KEY);
    if (saved === 'en' || saved === 'sw') return saved;
    return isInTanzania() ? 'sw' : 'en';
  }

  function t(key, lang) {
    const l = lang || getLang();
    return messages[l]?.[key] ?? messages.en[key] ?? '';
  }

  function applyLang(lang, options) {
    if (options && options.persist) {
      localStorage.setItem(STORAGE_KEY, lang);
    }
    document.documentElement.lang = lang === 'sw' ? 'sw' : 'en';

    document.querySelectorAll('[data-i18n]').forEach((el) => {
      const key = el.getAttribute('data-i18n');
      const val = t(key, lang);
      if (!val) return;
      if (el.hasAttribute('data-i18n-html')) {
        el.innerHTML = val;
      } else {
        el.textContent = val;
      }
    });

    document.querySelectorAll('[data-i18n-placeholder]').forEach((el) => {
      const key = el.getAttribute('data-i18n-placeholder');
      const val = t(key, lang);
      if (val) el.placeholder = val;
    });

    document.querySelectorAll('[data-i18n-aria-label]').forEach((el) => {
      const key = el.getAttribute('data-i18n-aria-label');
      const val = t(key, lang);
      if (val) el.setAttribute('aria-label', val);
    });

    document.querySelectorAll('[data-i18n-title]').forEach((el) => {
      const key = el.getAttribute('data-i18n-title');
      const val = t(key, lang);
      if (val) el.setAttribute('title', val);
    });

    const metaDesc = document.querySelector('meta[name="description"]');
    if (metaDesc) metaDesc.setAttribute('content', t('meta.description', lang));

    const titleEl = document.querySelector('title[data-i18n]');
    if (titleEl) document.title = t(titleEl.getAttribute('data-i18n'), lang);

    const langSelect = document.getElementById('langSelect');
    if (langSelect) {
      langSelect.value = lang;
      const enOpt = langSelect.querySelector('option[value="en"]');
      const swOpt = langSelect.querySelector('option[value="sw"]');
      if (enOpt) enOpt.textContent = t('lang.en', lang);
      if (swOpt) swOpt.textContent = t('lang.sw', lang);
    }

    window.dispatchEvent(new CustomEvent('hostbora:langchange', { detail: { lang } }));
  }

  window.HostBoraI18n = { getLang, t, applyLang, messages };

  document.addEventListener('DOMContentLoaded', () => {
    const langSelect = document.getElementById('langSelect');
    applyLang(getLang());
    langSelect?.addEventListener('change', (e) => applyLang(e.target.value, { persist: true }));
  });
})();
