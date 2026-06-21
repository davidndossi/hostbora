(function () {
  // WhatsApp: 255789287509 — keep in sync with support_controller.dart (supportWhatsAppE164)

  const menuBtn = document.getElementById('menuBtn');
  const nav = document.getElementById('nav');

  function setMenu(open) {
    if (!menuBtn || !nav) return;
    nav.classList.toggle('is-open', open);
    menuBtn.setAttribute('aria-expanded', String(open));
    const t = window.HostBoraI18n?.t || ((key) => key);
    menuBtn.setAttribute('aria-label', open ? t('menu.close') : t('menu.open'));
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

  const navSectionLinks = nav
    ? [...nav.querySelectorAll('a[href^="#"]')].filter((link) => {
        const id = link.getAttribute('href').slice(1);
        return id && document.getElementById(id);
      })
    : [];

  if (navSectionLinks.length && 'IntersectionObserver' in window) {
    const linkBySectionId = new Map(
      navSectionLinks.map((link) => [link.getAttribute('href').slice(1), link]),
    );
    const sectionVisibility = new Map();
    const headerHeight =
      parseFloat(getComputedStyle(document.documentElement).getPropertyValue('--header-h')) || 66;

    function setActiveSection(sectionId) {
      navSectionLinks.forEach((link) => {
        const isActive = link.getAttribute('href') === `#${sectionId}`;
        link.classList.toggle('is-active', isActive);
        if (isActive) {
          link.setAttribute('aria-current', 'true');
        } else {
          link.removeAttribute('aria-current');
        }
      });
    }

    function updateActiveSection() {
      let bestId = null;
      let bestRatio = 0;

      for (const [id, ratio] of sectionVisibility) {
        if (ratio > bestRatio) {
          bestRatio = ratio;
          bestId = id;
        }
      }

      if (bestId && bestRatio > 0) {
        setActiveSection(bestId);
        return;
      }

      navSectionLinks.forEach((link) => {
        link.classList.remove('is-active');
        link.removeAttribute('aria-current');
      });
    }

    const sectionObserver = new IntersectionObserver(
      (entries) => {
        entries.forEach((entry) => {
          sectionVisibility.set(entry.target.id, entry.intersectionRatio);
        });
        updateActiveSection();
      },
      {
        rootMargin: `-${headerHeight + 8}px 0px -55% 0px`,
        threshold: [0, 0.1, 0.25, 0.5, 0.75, 1],
      },
    );

    linkBySectionId.forEach((_link, sectionId) => {
      const section = document.getElementById(sectionId);
      if (section) sectionObserver.observe(section);
    });
  }

  const contactForm = document.getElementById('contactForm');
  const contactBtn = document.getElementById('contactBtn');
  const emailBtn = document.getElementById('emailBtn');
  const contactFeedback = document.getElementById('contactFeedback');

  const contactApiUrl =
    window.HOSTBORA_CONTACT_API ||
    (location.hostname === 'localhost' || location.hostname === '127.0.0.1'
      ? 'http://localhost:8080/api/website/contact'
      : 'https://hostbora.co.tz:8444/api/website/contact');

  const supportEmail = 'support@hostbora.co.tz';

  function isContactSuccess(data) {
    return data && (data.ok === true || data.responseCode === '0' || data.responseCode === '201');
  }

  function setContactStatus(message, type) {
    if (!contactFeedback) return;
    contactFeedback.textContent = '';
    contactFeedback.classList.remove('form__status--error', 'form__status--success');
    if (!message) return;

    requestAnimationFrame(() => {
      contactFeedback.textContent = message;
      if (type) contactFeedback.classList.add(`form__status--${type}`);
    });
  }

  function contactT(key) {
    return window.HostBoraI18n?.t(key) || '';
  }

  window.addEventListener('hostbora:langchange', () => {
    if (contactBtn && !contactBtn.disabled) {
      contactBtn.textContent = contactT('contact.submit');
    }
  });

  if (emailBtn) {
    emailBtn.addEventListener('click', async (e) => {
      const mailtoHref = emailBtn.getAttribute('href');
      if (!mailtoHref) return;

      e.preventDefault();

      try {
        if (navigator.clipboard?.writeText) {
          await navigator.clipboard.writeText(supportEmail);
          setContactStatus(contactT('contact.copied'), 'success');
        } else {
          setContactStatus(contactT('contact.openingEmail'), 'success');
        }
      } catch {
        setContactStatus(contactT('contact.openingEmail'), 'success');
      }

      window.setTimeout(() => {
        window.location.href = mailtoHref;
      }, 600);
    });
  }

  if (contactForm && contactBtn) {
    contactForm.addEventListener('submit', async (e) => {
      e.preventDefault();

      if (!contactForm.reportValidity()) return;

      const name = contactForm.querySelector('input[name="name"]')?.value?.trim() || '';
      const email = contactForm.querySelector('input[name="email"]')?.value?.trim() || '';
      const message = contactForm.querySelector('textarea[name="message"]')?.value?.trim() || '';
      const website = contactForm.querySelector('input[name="website"]')?.value?.trim() || '';

      contactBtn.disabled = true;
      contactBtn.textContent = contactT('contact.sending') || 'Sending…';
      setContactStatus(contactT('contact.sending'), null);

      try {
        const response = await fetch(contactApiUrl, {
          method: 'POST',
          headers: { 'Content-Type': 'application/json' },
          body: JSON.stringify({ name, email, message, website }),
        });

        const data = await response.json().catch(() => ({}));

        if (!response.ok || !isContactSuccess(data)) {
          throw new Error(data.message || data.error || 'Could not send your message.');
        }

        contactForm.reset();
        setContactStatus(contactT('contact.sent'), 'success');
      } catch (err) {
        setContactStatus(
          err instanceof Error && err.message ? err.message : contactT('contact.error'),
          'error',
        );
      } finally {
        contactBtn.disabled = false;
        contactBtn.textContent = contactT('contact.submit');
      }
    });
  }
})();
