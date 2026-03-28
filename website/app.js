(function () {
  const menuBtn = document.getElementById('menuBtn');
  const nav = document.getElementById('nav');

  function setMenu(open) {
    if (!menuBtn || !nav) return;
    nav.classList.toggle('is-open', open);
    menuBtn.setAttribute('aria-expanded', String(open));
  }

  if (menuBtn && nav) {
    menuBtn.addEventListener('click', () => {
      const isOpen = nav.classList.contains('is-open');
      setMenu(!isOpen);
    });

    nav.addEventListener('click', (e) => {
      const a = e.target && e.target.closest ? e.target.closest('a') : null;
      if (a) setMenu(false);
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

  const accordion = document.querySelector('[data-accordion]');
  if (accordion) {
    const questions = accordion.querySelectorAll('.faq__q');
    questions.forEach((btn) => {
      btn.addEventListener('click', () => {
        const expanded = btn.getAttribute('aria-expanded') === 'true';
        btn.setAttribute('aria-expanded', String(!expanded));
        const answer = btn.nextElementSibling;
        if (answer) answer.hidden = expanded;
      });
    });
  }

  const contactBtn = document.getElementById('contactBtn');
  if (contactBtn) {
    contactBtn.addEventListener('click', async () => {
      const form = contactBtn.closest('form');
      if (!form) return;
      const name = form.querySelector('input[name="name"]')?.value?.trim() || '';
      const email = form.querySelector('input[name="email"]')?.value?.trim() || '';
      const message = form.querySelector('textarea[name="message"]')?.value?.trim() || '';

      const subject = encodeURIComponent('Paa Yangu — Website inquiry');
      const body = [
        `Name: ${name || '-'}`,
        `Email: ${email || '-'}`,
        '',
        message || '(no message)',
      ].join('\n');

      const mailto = `mailto:?subject=${subject}&body=${encodeURIComponent(body)}`;

      try {
        await navigator.clipboard.writeText(`${body}\n\nOpen email: ${mailto}`);
        contactBtn.textContent = 'Copied';
        setTimeout(() => (contactBtn.textContent = 'Copy message'), 1200);
      } catch (_) {
        window.location.href = mailto;
      }
    });
  }
})();
