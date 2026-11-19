(function (root) {
  const PLAY = 'https://play.google.com/store/apps/details?id=tz.co.artbel.paa_yangu';
  const APP_STORE = 'https://apps.apple.com/app/host-bora/id6760237277';
  const ANDROID_PACKAGE = 'tz.co.artbel.paa_yangu';

  function platform() {
    const ua = navigator.userAgent || '';
    if (/iPhone|iPad|iPod/i.test(ua)) return 'ios';
    if (/Android/i.test(ua)) return 'android';
    return 'other';
  }

  function signInUrl() {
    try {
      return new URL('/app/signin/', location.origin).href;
    } catch (_) {
      return '/app/signin/';
    }
  }

  function storeUrl(kind) {
    const p = kind || platform();
    return p === 'ios' ? APP_STORE : PLAY;
  }

  function openApp(options) {
    const opts = options || {};
    const p = platform();
    const store = storeUrl(p);
    const universal = signInUrl();

    if (p === 'other') {
      return { platform: p, store: PLAY, universal: universal, attempted: false };
    }

    if (p === 'android') {
      const fallback = opts.storeFallback === false ? universal : store;
      const intent =
        'intent://hostbora.co.tz/app/signin#Intent;scheme=https;package=' +
        ANDROID_PACKAGE +
        ';S.browser_fallback_url=' +
        encodeURIComponent(fallback) +
        ';end';
      location.href = intent;
    } else {
      location.href = 'hostbora://signin';
      if (opts.universalFallback !== false) {
        window.setTimeout(function () {
          if (!document.hidden) location.href = universal;
        }, 450);
      }
    }

    if (opts.storeFallback !== false) {
      window.setTimeout(function () {
        if (!document.hidden) location.href = store;
      }, 1600);
    }

    return { platform: p, store: store, universal: universal, attempted: true };
  }

  root.HostBoraOpenApp = {
    PLAY: PLAY,
    APP_STORE: APP_STORE,
    platform: platform,
    storeUrl: storeUrl,
    signInUrl: signInUrl,
    openApp: openApp,
  };
})(window);
