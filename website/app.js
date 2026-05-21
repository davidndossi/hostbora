(function () {
  const menuBtn = document.getElementById('menuBtn');
  const nav = document.getElementById('nav');

  function setMenu(open) {
    if (!menuBtn || !nav) return;
    nav.classList.toggle('is-open', open);
    menuBtn.setAttribute('aria-expanded', String(open));
    menuBtn.setAttribute('aria-label', open ? 'Close menu' : 'Open menu');
  }

  if (menuBtn && nav) {
    menuBtn.addEventListener('click', () => {
      setMenu(!nav.classList.contains('is-open'));
    });

    nav.addEventListener('click', (e) => {
      const link = e.target && e.target.closest ? e.target.closest('a') : null;
      if (link && !link.hasAttribute('aria-disabled')) setMenu(false);
    });

    document.addEventListener('keydown', (e) => {
      if (e.key === 'Escape') setMenu(false);
    });

    document.addEventListener('click', (e) => {
      if (!nav.classList.contains('is-open')) return;
      const inside = nav.contains(e.target) || menuBtn.contains(e.target);
      if (!inside) setMenu(false);
    });
  }

  const contactForm = document.getElementById('contactForm');
  const contactBtn = document.getElementById('contactBtn');

  if (contactForm && contactBtn) {
    contactForm.addEventListener('submit', async (e) => {
      e.preventDefault();

      const name = contactForm.querySelector('input[name="name"]')?.value?.trim() || '';
      const email = contactForm.querySelector('input[name="email"]')?.value?.trim() || '';
      const message = contactForm.querySelector('textarea[name="message"]')?.value?.trim() || '';

      const subject = encodeURIComponent('HostBora — Website inquiry');
      const bodyText = [
        'HostBora website inquiry',
        '',
        `Name: ${name || '-'}`,
        `Email: ${email || '-'}`,
        '',
        message || '(no message)',
      ].join('\n');

      const mailto = `mailto:support@paayangu.com?subject=${subject}&body=${encodeURIComponent(bodyText)}`;

      try {
        await navigator.clipboard.writeText(bodyText);
        contactBtn.textContent = 'Copied — open email';
        setTimeout(() => {
          contactBtn.textContent = 'Send via email';
        }, 2000);
      } catch (_) {
        /* clipboard unavailable */
      }

      window.location.href = mailto;
    });
  }
})();
