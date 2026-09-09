(function () {
  const STORAGE_KEY = 'hostbora-lang';

  const messages = {
    en: {
      'lang.label': 'Language',
      'lang.en': 'English',
      'lang.sw': 'Kiswahili',
      'skip': 'Skip to content',
      'brand.home': 'HostBora home',
      'menu.open': 'Open menu',
      'menu.close': 'Close menu',
      'nav.label': 'Primary',
      'nav.features': 'Features',
      'nav.workspaces': 'Workspaces',
      'nav.audience': 'Who uses it',
      'nav.pricing': 'Pricing',
      'nav.trust': 'Trust',
      'nav.privacy': 'Privacy',
      'nav.getStarted': 'Get started',
      'nav.contact': 'Contact',
      'nav.about': 'About',
      'nav.whatsapp': 'WhatsApp',
      'nav.terms': 'Terms',
      'meta.title': 'HostBora — Property management for East Africa',
      'meta.description':
        'HostBora helps landlords and property managers in Tanzania and East Africa run short-stay BnB and long-term rentals — bookings, payments, staff, and more.',
      'hero.badge': 'Early access — join 200+ landlords already using HostBora',
      'hero.eyebrow': 'Built for landlords & property managers',
      'hero.title': 'Property management that stays clear — from guest nights to monthly rent.',
      'hero.tagline': 'Manage your properties with ease — short-stay BnB and long-term rent.',
      'hero.lead':
        'HostBora brings short-stay hosting and long-term rentals into one trustworthy app. Track bookings and tenants, record payments in TZS, manage staff and expenses, and see how each property performs.',
      'cta.playTop': 'Download free on',
      'cta.playBottom': 'Google Play',
      'cta.explore': 'Explore features ↓',
      'app.version': 'App v1.2.3 · Updated June 2026',
      'hero.stats.label': 'Highlights',
      'hero.stats.bnb': 'BnB + Rent',
      'hero.stats.bnbSub': 'Two workspaces',
      'hero.stats.tzs': 'TZS-ready',
      'hero.stats.tzsSub': 'Local currency',
      'hero.stats.offline': 'Offline-friendly',
      'hero.stats.offlineSub': 'Works on the go',
      'features.kicker': 'Daily toolkit',
      'features.pain':
        'Most landlords in Dar manage rent via M-Pesa screenshots, WhatsApp threads, and handwritten notebooks. HostBora replaces that chaos.',
      'features.title': 'Everything landlords and managers need daily',
      'features.sub':
        'One calm toolkit for income, operations, people, and records — whether you host nights or collect monthly rent.',
      'demo.title': 'See HostBora in 60 seconds',
      'demo.sub': 'A quick walkthrough of the app — properties, payments, staff, and more.',
      'demo.iframeTitle': 'HostBora app walkthrough video',
      'feat.rentals.title': 'Rentals & tenants',
      'feat.rentals.desc':
        'List units, track leases, and keep tenant details organized across your portfolio.',
      'feat.payments.title': 'Payments & expenses',
      'feat.payments.desc':
        'Track M-Pesa and mobile money payments — Tigo Pesa, Airtel Money, and more. Record rent and guest income, log expenses, and see cash flow without spreadsheet chaos.',
      'feat.staff.title': 'Staff & tasks',
      'feat.staff.desc':
        'Assign cleaners, guards, or maintenance — with due dates and status so nothing is missed.',
      'feat.reminders.title': 'Reminders',
      'feat.reminders.desc':
        'Stay ahead of renewals, check-ins, payment follow-ups, and recurring property chores.',
      'feat.bnb.title': 'BnB & long-term rent',
      'feat.bnb.desc':
        'Run short-stay bookings and monthly leases from the same portfolio — switch when you need to.',
      'feat.reports.title': 'Reports & profitability',
      'feat.reports.desc':
        'Understand income vs spend per property with summaries that support real decisions.',
      'feat.access.title': 'Smart access',
      'feat.access.desc':
        'Coordinate digital locks and guest access where supported — fewer handoffs at check-in.',
      'feat.vault.title': 'Document vault',
      'feat.vault.desc':
        'Store leases, IDs, manuals, and tax records in clear folders — ready when you need them.',
      'feat.calendar.title': 'Calendar sync',
      'feat.calendar.desc':
        'Link external calendars to reduce double bookings and keep blocked dates aligned.',
      'workspaces.kicker': 'BnB + Rent',
      'workspaces.title': 'Two workspaces, one app',
      'workspaces.sub': 'Switch between BnB and Rent anytime — same properties, tailored flows.',
      'workspaces.bnb.badge': 'BnB',
      'workspaces.bnb.title': 'Short-stay hosting',
      'workspaces.bnb.desc':
        'Manage nightly bookings, guest turnover, cleaning schedules, and hospitality-style income. Ideal for furnished apartments, guest houses, and holiday lets.',
      'workspaces.bnb.li1': 'Booking calendar & check-in/out',
      'workspaces.bnb.li2': 'Guest payments & stay expenses',
      'workspaces.bnb.li3': 'Operations tuned for turnover',
      'workspaces.rent.badge': 'Rent',
      'workspaces.rent.title': 'Long-term rentals',
      'workspaces.rent.desc':
        'Run monthly leases, tenant records, rent collection, and building-level expenses. Built for landlords and managers with recurring income.',
      'workspaces.rent.li1': 'Tenants, units & lease tracking',
      'workspaces.rent.li2': 'Rent payments & arrears visibility',
      'workspaces.rent.li3': 'Staff, utilities & building costs',
      'audience.kicker': 'Who it’s for',
      'audience.title': 'Made for people who run properties',
      'audience.sub':
        'Whether you own one unit or manage a growing portfolio across Dar, Arusha, or beyond.',
      'audience.landlords.title': 'Landlords',
      'audience.landlords.desc':
        'Own apartments, houses, or blocks? See rent collected, vacancies, and costs per unit without juggling notebooks.',
      'audience.managers.title': 'Property managers',
      'audience.managers.desc':
        'Oversee multiple owners or buildings with staff workflows, expenses, and reports your clients can trust.',
      'audience.hosts.title': 'Hosts & operators',
      'audience.hosts.desc':
        'Run BnB or mixed portfolios — from boutique stays to serviced apartments — with bookings and ops in sync.',
      'pricing.kicker': 'Pricing',
      'pricing.title': 'Simple, transparent pricing',
      'pricing.sub':
        'No surprises — start free today, then pick a plan that fits your portfolio when billing begins.',
      'pricing.badge': 'Launch offer',
      'pricing.freeTitle': 'Free for a limited time',
      'pricing.freeLead':
        "Full access to HostBora while we're in early access — every feature, no credit card, no commitment.",
      'pricing.download': 'Download free on Android',
      'pricing.freeNote': "We'll notify you before any paid plan takes effect.",
      'pricing.intro': 'After the free period, choose the tier that matches how you manage properties:',
      'pricing.starter.name': 'Starter',
      'pricing.starter.period': 'TZS / month',
      'pricing.starter.summary': 'For solo hosts getting organised.',
      'pricing.starter.li1': 'Up to 3 properties',
      'pricing.starter.li2': 'BnB or Rent workspace',
      'pricing.starter.li3': 'Payments, expenses & reminders',
      'pricing.starter.li4': 'Basic reports',
      'pricing.pro.badge': 'Most popular',
      'pricing.pro.name': 'Pro',
      'pricing.pro.period': 'TZS / month',
      'pricing.pro.summary': 'For growing portfolios and small teams.',
      'pricing.pro.li1': 'Up to 10 properties',
      'pricing.pro.li2': 'Staff, tasks & calendar sync',
      'pricing.pro.li3': 'Document vault & advanced reports',
      'pricing.pro.li4': 'SMS / WhatsApp add-on available',
      'pricing.ultra.name': 'Ultra',
      'pricing.ultra.period': 'TZS / month',
      'pricing.ultra.summary': 'For operators and property managers at scale.',
      'pricing.ultra.li1': 'Unlimited properties',
      'pricing.ultra.li2': 'Smart locks & entry logs',
      'pricing.ultra.li3': 'AI Manager & design tools',
      'pricing.ultra.li4': 'Priority support',
      'pricing.footnote':
        'Planned rates shown in Tanzanian shillings. M-Pesa and mobile money supported when billing starts. <a href="#contact">Questions?</a> Chat with us on WhatsApp or email.',
      'trust.kicker': 'Trust',
      'trust.title': 'Built for how you work in East Africa',
      'trust.sub':
        'Professional, dependable, and respectful of local realities — not a generic import.',
      'trust.offline.title': 'Works offline',
      'trust.offline.desc':
        "Keep recording payments, notes, and tasks when connectivity dips — sync when you're back online.",
      'trust.tzs.title': 'TZS-friendly',
      'trust.tzs.desc':
        'Think in Tanzanian shillings and the mobile money you already use — M-Pesa, Tigo Pesa, and Airtel Money — not a foreign-currency mindset.',
      'trust.security.title': 'Security & privacy',
      'trust.security.desc':
        'Your property and tenant data stay yours. Data encrypted in transit and at rest. Hosted on servers meeting international security standards. We collect only what\'s needed to run the service — see our <a href="./privacy-policy.html">Privacy Policy</a>.',
      'contact.title': 'Get started with HostBora',
      'contact.sub':
        'Available on mobile for hosts, landlords, and managers in Tanzania and the wider East Africa region. Reach out for early access, partnerships, or support.',
      'contact.about':
        'Built by <strong>Artbel Technologies</strong> in Dar es Salaam — a Tanzanian team behind HostBora. <a href="./about.html">About us</a>',
      'contact.whatsapp': 'Chat on WhatsApp',
      'contact.email': 'Email us',
      'contact.region': 'Dar es Salaam · Tanzania · East Africa',
      'contact.form.label': 'Contact form',
      'contact.name': 'Name',
      'contact.namePh': 'Your name',
      'contact.emailLabel': 'Email',
      'contact.emailPh': 'you@example.com',
      'contact.message': 'Message',
      'contact.messagePh': 'Tell us about your properties (BnB, rent, or both)…',
      'contact.submit': 'Send message',
      'contact.hint': 'WhatsApp is fastest — or use the form and we’ll reply by email.',
      'contact.sending': 'Sending your message…',
      'contact.sent': 'Thanks — your message was sent. We’ll reply soon.',
      'contact.error': 'Could not send your message. Please try again.',
      'contact.copied': 'Copied — open email',
      'contact.openingEmail': 'Opening email…',
      'footer.tagline': 'Property management for landlords, managers, and hosts.',
      'footer.social.label': 'HostBora on social media',
      'footer.social.instagram': 'Instagram',
      'footer.social.facebook': 'Facebook',
      'footer.credit': 'Built by <a href="./about.html">Artbel</a>, Dar es Salaam',
      'footer.copy': '© 2026 HostBora. All rights reserved.',
      'footer.appMeta': 'App v1.2.3 · Updated',
      'wa.fab': 'Chat with HostBora on WhatsApp',
    },
    sw: {
      'lang.label': 'Lugha',
      'lang.en': 'Kiingereza',
      'lang.sw': 'Kiswahili',
      'skip': 'Ruka hadi maudhui',
      'brand.home': 'Mwanzo wa HostBora',
      'menu.open': 'Fungua menyu',
      'menu.close': 'Funga menyu',
      'nav.label': 'Msingi',
      'nav.features': 'Vipengele',
      'nav.workspaces': 'Nafasi za kazi',
      'nav.audience': 'Nani hutumia',
      'nav.pricing': 'Bei',
      'nav.trust': 'Uaminifu',
      'nav.privacy': 'Faragha',
      'nav.getStarted': 'Anza sasa',
      'nav.contact': 'Wasiliana',
      'nav.about': 'Kuhusu',
      'nav.whatsapp': 'WhatsApp',
      'nav.terms': 'Masharti',
      'meta.title': 'HostBora — Usimamizi wa mali kwa Afrika Mashariki',
      'meta.description':
        'HostBora inawasaidia wamiliki na wasimamizi wa mali nchini Tanzania na Afrika Mashariki kuendesha BnB za muda mfupi na kodi za muda mrefu — uhifadhi, malipo, wafanyakazi, na zaidi.',
      'hero.badge': 'Ufikiaji wa mapema — jiunge na wamiliki 200+ wanaotumia HostBora',
      'hero.eyebrow': 'Imeundwa kwa wamiliki na wasimamizi wa mali',
      'hero.title': 'Usimamizi wa mali unaobaki wazi — kutoka usiku wa wageni hadi kodi ya kila mwezi.',
      'hero.tagline': 'Simamia mali zako kwa urahisi — BnB na kodi za muda mrefu.',
      'hero.lead':
        'HostBora inaunganisha ukarimu wa muda mfupi na kodi za muda mrefu katika programu moja ya kuaminika. Fuatilia uhifadhi na wapangaji, rekodi malipo kwa TZS, simamia wafanyakazi na gharama, na uone utendaji wa kila mali.',
      'cta.playTop': 'Pakua bure kwenye',
      'cta.playBottom': 'Google Play',
      'cta.explore': 'Gundua vipengele ↓',
      'app.version': 'Programu v1.2.3 · Imesasishwa Juni 2026',
      'hero.stats.label': 'Muhtasari',
      'hero.stats.bnb': 'BnB + Kodi',
      'hero.stats.bnbSub': 'Nafasi mbili za kazi',
      'hero.stats.tzs': 'TZS-tayari',
      'hero.stats.tzsSub': 'Sarafu ya ndani',
      'hero.stats.offline': 'Inafanya kazi nje ya mtandao',
      'hero.stats.offlineSub': 'Inafanya kazi popote',
      'features.kicker': 'Zana za kila siku',
      'features.pain':
        'Wamiliki wengi Dar wanadhibiti kodi kupitia picha za M-Pesa, mazungumzo ya WhatsApp, na daftari za mkono. HostBora inachukua nafasi ya msukosuko huo.',
      'features.title': 'Kila kitu wamiliki na wasimamizi wanahitaji kila siku',
      'features.sub':
        'Zana moja tulivu kwa mapato, uendeshaji, watu, na rekodi — ukiwa unapokea wageni au ukusanya kodi ya kila mwezi.',
      'demo.title': 'Tazama HostBora kwa sekunde 60',
      'demo.sub': 'Muhtasari wa haraka wa programu — mali, malipo, wafanyakazi, na zaidi.',
      'demo.iframeTitle': 'Video ya muhtasari wa programu ya HostBora',
      'feat.rentals.title': 'Upangaji na wapangaji',
      'feat.rentals.desc':
        'Orodhesha vyumba, fuatilia mikataba, na weka maelezo ya wapangaji kwa mpangilio katika mali zako.',
      'feat.payments.title': 'Malipo na gharama',
      'feat.payments.desc':
        'Fuatilia malipo ya M-Pesa na pesa za simu — Tigo Pesa, Airtel Money, na zaidi. Rekodi mapato ya kodi na wageni, andika gharama, na uone mtiririko wa fedha bila machafuko ya spreadsheet.',
      'feat.staff.title': 'Wafanyakazi na kazi',
      'feat.staff.desc':
        'Pangia wasafishaji, walinzi, au matengenezo — na tarehe za mwisho na hali ili hakuna kinachopotea.',
      'feat.reminders.title': 'Vikumbusho',
      'feat.reminders.desc':
        'Kaa mbele ya upyaji wa mikataba, kuingia kwa wageni, ufuatiliaji wa malipo, na kazi za mara kwa mara za mali.',
      'feat.bnb.title': 'BnB na kodi ya muda mrefu',
      'feat.bnb.desc':
        'Endesha uhifadhi wa muda mfupi na mikataba ya kila mwezi kutoka kwenye mfuko huo huo — badilisha unapohitaji.',
      'feat.reports.title': 'Ripoti na faida',
      'feat.reports.desc':
        'Elewa mapato dhidi ya matumizi kwa kila mali kwa muhtasari unaounga mkono maamuzi halisi.',
      'feat.access.title': 'Ufikiaji mahiri',
      'feat.access.desc':
        'Ratibu kufuli za kidijitali na ufikiaji wa wageni pale inapoungwa mkono — mikataba machache wakati wa kuingia.',
      'feat.vault.title': 'Hifadhi ya nyaraka',
      'feat.vault.desc':
        'Hifadhi mikataba, vitambulisho, miongozo, na rekodi za kodi katika folda wazi — tayari unapozihitaji.',
      'feat.calendar.title': 'Usawazishaji wa kalenda',
      'feat.calendar.desc':
        'Unganisha kalenda za nje kupunguza uhifadhi maradufu na kuweka tarehe zilizozuiliwa sawa.',
      'workspaces.kicker': 'BnB + Kodi',
      'workspaces.title': 'Nafasi mbili za kazi, programu moja',
      'workspaces.sub': 'Badilisha kati ya BnB na Kodi wakati wowote — mali zile zile, mtiririko ulioboreshwa.',
      'workspaces.bnb.badge': 'BnB',
      'workspaces.bnb.title': 'Ukarimu wa muda mfupi',
      'workspaces.bnb.desc':
        'Simamia uhifadhi wa kila usiku, mabadiliko ya wageni, ratiba za usafi, na mapato ya ukarimu. Inafaa kwa vyumba vya furnished, nyumba za wageni, na makao ya likizo.',
      'workspaces.bnb.li1': 'Kalenda ya uhifadhi na kuingia/kutoka',
      'workspaces.bnb.li2': 'Malipo ya wageni na gharama za makao',
      'workspaces.bnb.li3': 'Uendeshaji ulioboreshwa kwa mabadiliko',
      'workspaces.rent.badge': 'Kodi',
      'workspaces.rent.title': 'Upangaji wa muda mrefu',
      'workspaces.rent.desc':
        'Endesha mikataba ya kila mwezi, rekodi za wapangaji, ukusanyaji wa kodi, na gharama za jengo. Imejengwa kwa wamiliki na wasimamizi wenye mapato ya mara kwa mara.',
      'workspaces.rent.li1': 'Wapangaji, vyumba na ufuatiliaji wa mikataba',
      'workspaces.rent.li2': 'Malipo ya kodi na mwonekano wa deni',
      'workspaces.rent.li3': 'Wafanyakazi, huduma na gharama za jengo',
      'audience.kicker': 'Kwa nani',
      'audience.title': 'Imeundwa kwa watu wanaodhibiti mali',
      'audience.sub':
        'Ukiwa unamiliki chumba kimoja au unasimamia mfuko unaokua katika Dar, Arusha, au zaidi.',
      'audience.landlords.title': 'Wamiliki',
      'audience.landlords.desc':
        'Unamiliki vyumba, nyumba, au majengo? Ona kodi iliyokusanywa, nafasi tupu, na gharama kwa kila chumba bila kusukumana na daftari.',
      'audience.managers.title': 'Wasimamizi wa mali',
      'audience.managers.desc':
        'Simamia wamiliki au majengo mengi kwa mtiririko wa wafanyakazi, gharama, na ripoti ambazo wateja wako wanaweza kuamini.',
      'audience.hosts.title': 'Wenyeji na waendeshaji',
      'audience.hosts.desc':
        'Endesha BnB au mali mchanganyiko — kutoka makao ya boutique hadi vyumba vya huduma — na uhifadhi na uendeshaji vikiendana.',
      'pricing.kicker': 'Bei',
      'pricing.title': 'Bei rahisi na wazi',
      'pricing.sub':
        'Hakuna mshangao — anza bure leo, kisha chagua mpango unaofaa mfuko wako wakati malipo yataanza.',
      'pricing.badge': 'Ofa ya uzinduzi',
      'pricing.freeTitle': 'Bure kwa muda mfupi',
      'pricing.freeLead':
        'Ufikiaji kamili wa HostBora tunapokuwa katika ufikiaji wa mapema — kila kipengele, hakuna kadi ya mkopo, hakuna ahadi.',
      'pricing.download': 'Pakua bure kwenye Android',
      'pricing.freeNote': 'Tutakujulisha kabla ya mpango wowote wa kulipia kuanza kutumika.',
      'pricing.intro': 'Baada ya kipindi cha bure, chagua kiwango kinacholingana na jinsi unavyosimamia mali:',
      'pricing.starter.name': 'Starter',
      'pricing.starter.period': 'TZS / mwezi',
      'pricing.starter.summary': 'Kwa wenyeji peke yao wanaopanga.',
      'pricing.starter.li1': 'Hadi mali 3',
      'pricing.starter.li2': 'Nafasi ya BnB au Kodi',
      'pricing.starter.li3': 'Malipo, gharama na vikumbusho',
      'pricing.starter.li4': 'Ripoti za msingi',
      'pricing.pro.badge': 'Inayopendwa zaidi',
      'pricing.pro.name': 'Pro',
      'pricing.pro.period': 'TZS / mwezi',
      'pricing.pro.summary': 'Kwa mali zinazokua na timu ndogo.',
      'pricing.pro.li1': 'Hadi mali 10',
      'pricing.pro.li2': 'Wafanyakazi, kazi na usawazishaji wa kalenda',
      'pricing.pro.li3': 'Hifadhi ya nyaraka na ripoti za hali ya juu',
      'pricing.pro.li4': 'Ongezeko la SMS / WhatsApp linapatikana',
      'pricing.ultra.name': 'Ultra',
      'pricing.ultra.period': 'TZS / mwezi',
      'pricing.ultra.summary': 'Kwa waendeshaji na wasimamizi wa mali kwa kiwango kikubwa.',
      'pricing.ultra.li1': 'Mali zisizo na kikomo',
      'pricing.ultra.li2': 'Kufuli mahiri na kumbukumbu za kuingia',
      'pricing.ultra.li3': 'Msimamizi wa AI na zana za muundo',
      'pricing.ultra.li4': 'Msaada wa kipaumbele',
      'pricing.footnote':
        'Viwango vilivyopangwa vinaonyeshwa kwa shilingi za Tanzania. M-Pesa na pesa za simu zinasaidiwa malipo yatakapoanza. <a href="#contact">Maswali?</a> Wasiliana nasi kupitia WhatsApp au barua pepe.',
      'trust.kicker': 'Uaminifu',
      'trust.title': 'Imeundwa kwa jinsi unavyofanya kazi Afrika Mashariki',
      'trust.sub':
        'Ya kitaalamu, ya kuaminika, na inayheshimu hali halisi ya ndani — si bidhaa ya jeneriki iliyoagizwa.',
      'trust.offline.title': 'Inafanya kazi nje ya mtandao',
      'trust.offline.desc':
        'Endelea kurekodi malipo, maelezo, na kazi mtandao unapopungua — sawazisha unapokuwa mtandaoni tena.',
      'trust.tzs.title': 'Rafiki kwa TZS',
      'trust.tzs.desc':
        'Fikiria kwa shilingi za Tanzania na pesa za simu unazotumia tayari — M-Pesa, Tigo Pesa, na Airtel Money — si mtazamo wa sarafu ya kigeni.',
      'trust.security.title': 'Usalama na faragha',
      'trust.security.desc':
        'Data yako ya mali na wapangaji inabaki yako. Data imesimbwa wakati wa usafirishaji na uhifadhi. Inahifadhiwa kwenye seva zinazokidhi viwango vya kimataifa vya usalama. Tunakusanya tu kinachohitajika kuendesha huduma — angalia <a href="./privacy-policy.html">Sera yetu ya Faragha</a>.',
      'contact.title': 'Anza na HostBora',
      'contact.sub':
        'Inapatikana kwenye simu kwa wenyeji, wamiliki, na wasimamizi nchini Tanzania na Afrika Mashariki pana. Wasiliana kwa ufikiaji wa mapema, ushirikiano, au msaada.',
      'contact.about':
        'Imeundwa na <strong>Artbel Technologies</strong> Dar es Salaam — timu ya Tanzania nyuma ya HostBora. <a href="./about.html">Kuhusu sisi</a>',
      'contact.whatsapp': 'Tuchat WhatsApp',
      'contact.email': 'Tutumie barua pepe',
      'contact.region': 'Dar es Salaam · Tanzania · Afrika Mashariki',
      'contact.form.label': 'Fomu ya mawasiliano',
      'contact.name': 'Jina',
      'contact.namePh': 'Jina lako',
      'contact.emailLabel': 'Barua pepe',
      'contact.emailPh': 'wewe@example.com',
      'contact.message': 'Ujumbe',
      'contact.messagePh': 'Tuambie kuhusu mali zako (BnB, kodi, au zote mbili)…',
      'contact.submit': 'Tuma ujumbe',
      'contact.hint': 'WhatsApp ni haraka zaidi — au tumia fomu na tutajibu kwa barua pepe.',
      'contact.sending': 'Inatuma ujumbe wako…',
      'contact.sent': 'Asante — ujumbe wako umetumwa. Tutajibu hivi karibuni.',
      'contact.error': 'Haikuwezekana kutuma ujumbe wako. Tafadhali jaribu tena.',
      'contact.copied': 'Imenakiliwa — fungua barua pepe',
      'contact.openingEmail': 'Inafungua barua pepe…',
      'footer.tagline': 'Usimamizi wa mali kwa wamiliki, wasimamizi, na wenyeji.',
      'footer.social.label': 'HostBora kwenye mitandao ya kijamii',
      'footer.social.instagram': 'Instagram',
      'footer.social.facebook': 'Facebook',
      'footer.credit': 'Imeundwa na <a href="./about.html">Artbel</a>, Dar es Salaam',
      'footer.copy': '© 2026 HostBora. Haki zote zimehifadhiwa.',
      'footer.appMeta': 'Programu v1.2.3 · Imesasishwa',
      'wa.fab': 'Piga gumzo na HostBora kwenye WhatsApp',
    },
  };

  function getLang() {
    const stored = localStorage.getItem(STORAGE_KEY);
    if (stored === 'en' || stored === 'sw') return stored;
    const nav = navigator.language || '';
    return nav.startsWith('sw') ? 'sw' : 'en';
  }

  function t(key, lang) {
    const l = lang || getLang();
    return messages[l]?.[key] ?? messages.en[key] ?? '';
  }

  function applyLang(lang) {
    localStorage.setItem(STORAGE_KEY, lang);
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
    langSelect?.addEventListener('change', (e) => applyLang(e.target.value));
  });
})();
