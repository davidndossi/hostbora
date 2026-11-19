(function () {
  const PLANS = {
    starter: { amount: 19000 },
    pro: { amount: 49000 },
    ultra: { amount: 99000 },
  };

  const params = new URLSearchParams(location.search);
  const requestedPlan = (params.get('plan') || 'starter').toLowerCase();
  const plan = PLANS[requestedPlan] ? requestedPlan : 'starter';
  const referralCode = (params.get('ref') || params.get('referral') || '').trim();

  const state = {
    step: 0,
    firstName: '',
    lastName: '',
    phone: '',
    hasEmail: null,
    email: '',
    channel: 'SMS',
    otp: '',
    registered: false,
  };

  const steps = ['name', 'phone', 'email', 'code', 'done'];
  let submitting = false;

  function t(key) {
    return (window.HostBoraI18n && window.HostBoraI18n.t(key)) || '';
  }

  function apiBase() {
    if (window.HOSTBORA_API) return String(window.HOSTBORA_API).replace(/\/$/, '');
    const host = location.hostname;
    if (host === 'localhost' || host === '127.0.0.1') return 'http://localhost:8080';
    if (host === '167.86.89.92') return 'http://167.86.89.92:8082';
    return 'https://hostbora.co.tz:8444';
  }

  function localPhone(raw) {
    let digits = String(raw || '').replace(/\D/g, '');
    if (digits.startsWith('255') && digits.length >= 12) digits = '0' + digits.slice(3);
    if (digits.length === 9 && /^[678]/.test(digits)) digits = '0' + digits;
    if (!/^0[678]\d{8}$/.test(digits)) return null;
    return digits;
  }

  function formatAmount(n) {
    return String(n).replace(/\B(?=(\d{3})+(?!\d))/g, ',');
  }

  function setStatus(message, type) {
    const el = document.getElementById('registerFeedback');
    if (!el) return;
    el.textContent = message || '';
    el.classList.remove('form__status--error', 'form__status--success');
    if (type) el.classList.add('form__status--' + type);
  }

  function showPanel(id) {
    document.querySelectorAll('[data-step]').forEach((panel) => {
      panel.hidden = panel.getAttribute('data-step') !== id;
    });
  }

  function updateProgress() {
    const idx = Math.min(state.step, steps.length - 1);
    const fill = document.getElementById('wizardFill');
    if (fill) fill.style.width = ((idx + 1) / steps.length) * 100 + '%';
    const label = document.getElementById('wizardStepLabel');
    if (label) {
      const keys = [
        'register.stepName',
        'register.stepPhone',
        'register.stepEmail',
        'register.stepCode',
        'register.successTitle',
      ];
      label.textContent = t(keys[idx] || keys[0]);
    }
  }

  function setBusy(busy, labelKey) {
    const btn = document.getElementById('registerContinue');
    if (!btn) return;
    btn.disabled = !!busy;
    const span = btn.querySelector('[data-continue-label]');
    if (span) span.textContent = t(labelKey || (state.step === 3 ? 'register.verify' : 'register.continue'));
  }

  function renderPlan() {
    const nameEl = document.getElementById('selectedPlanName');
    const amountEl = document.getElementById('selectedPlanAmount');
    if (nameEl) nameEl.textContent = plan.charAt(0).toUpperCase() + plan.slice(1);
    if (amountEl) amountEl.textContent = formatAmount(PLANS[plan].amount) + ' TZS';
  }

  function syncEmailChoice() {
    const field = document.getElementById('emailField');
    if (field) field.hidden = state.hasEmail !== true;
    document.querySelectorAll('[data-email-choice]').forEach((btn) => {
      const value = btn.getAttribute('data-email-choice') === 'yes';
      btn.classList.toggle('is-selected', state.hasEmail === value);
    });
  }

  function primaryLabelKey() {
    if (state.step === 3) return 'register.verify';
    if (state.step === 4) return 'register.openApp';
    return 'register.continue';
  }

  function goTo(step) {
    state.step = step;
    const id = steps[step] || 'name';
    showPanel(id);
    updateProgress();
    setBusy(false, primaryLabelKey());
    const back = document.getElementById('registerBack');
    if (back) back.hidden = step === 0 || step === 4;
    const continueBtn = document.getElementById('registerContinue');
    if (continueBtn) continueBtn.hidden = step === 4;
    const successActions = document.getElementById('successActions');
    if (successActions) successActions.hidden = step !== 4;
    if (step === 2) syncEmailChoice();
  }

  async function postJson(path, body) {
    const response = await fetch(apiBase() + path, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify(body),
    });
    const data = await response.json().catch(() => ({}));
    return { response: response, data: data };
  }

  async function submitRegister() {
    const payload = {
      firstName: state.firstName,
      surname: state.lastName || undefined,
      mobileNumber: state.phone,
      username: state.phone,
      channel: state.channel,
    };
    if (state.hasEmail === true && state.email) payload.email = state.email;
    if (referralCode) payload.referralCode = referralCode.toUpperCase();

    const { response, data } = await postJson('/api/auth/reg', payload);
    const ok = response.ok && (data.responseCode === '0' || data.responseCode == null);
    if (!ok) {
      const message = data.message || t('register.error');
      if (/already exists/i.test(message)) {
        setStatus(t('register.exists'), 'error');
        const actions = document.getElementById('successActions');
        if (actions) actions.hidden = false;
        if (window.HostBoraOpenApp && window.HostBoraOpenApp.platform() !== 'other') {
          window.HostBoraOpenApp.openApp({ storeFallback: true });
        }
        return false;
      }
      throw new Error(message);
    }
    state.registered = true;
    state.channel = (data.data && data.data.channel) || payload.channel;
    return true;
  }

  async function submitVerifyAndPay() {
    const { response, data } = await postJson('/api/website/verify-and-pay', {
      msisdn: state.phone,
      otp: state.otp,
      plan: plan,
    });
    const ok = response.ok && (data.responseCode === '0' || data.responseCode == null);
    if (!ok) throw new Error(data.message || t('register.invalidCode'));
    return data.data || {};
  }

  function showSuccess(pay) {
    const payOk = pay && pay.paymentStarted === true;
    const payEl = document.getElementById('successPay');
    if (payEl) {
      payEl.textContent = payOk ? t('register.successPay') : t('register.successPayFail');
    }
    const desktop = document.getElementById('successDesktop');
    const platform = window.HostBoraOpenApp ? window.HostBoraOpenApp.platform() : 'other';
    if (desktop) desktop.hidden = platform !== 'other';
    goTo(4);
    if (platform !== 'other' && window.HostBoraOpenApp) {
      window.setTimeout(function () {
        window.HostBoraOpenApp.openApp({ storeFallback: true });
      }, 400);
    }
  }

  async function onContinue() {
    if (submitting) return;
    submitting = true;
    setStatus('', null);
    try {
      if (state.step === 0) {
        const first = document.getElementById('reg-first').value.trim();
        const last = document.getElementById('reg-last').value.trim();
        if (!first) {
          setStatus(t('register.invalidName'), 'error');
          return;
        }
        state.firstName = first;
        state.lastName = last;
        goTo(1);
        return;
      }

      if (state.step === 1) {
        const phone = localPhone(document.getElementById('reg-phone').value);
        if (!phone) {
          setStatus(t('register.invalidPhone'), 'error');
          return;
        }
        state.phone = phone;
        goTo(2);
        return;
      }

      if (state.step === 2) {
        if (state.hasEmail === true) {
          const email = document.getElementById('reg-email').value.trim();
          if (!email || email.indexOf('@') < 1) {
            setStatus(t('register.invalidEmail'), 'error');
            return;
          }
          state.email = email;
          state.channel = 'EMAIL';
        } else {
          state.email = '';
          state.channel = 'SMS';
          if (state.hasEmail !== false) {
            setStatus(t('register.emailAsk'), 'error');
            return;
          }
        }
        setBusy(true, 'register.sending');
        const sent = await submitRegister();
        if (sent) goTo(3);
        return;
      }

      if (state.step === 3) {
        const otp = document.getElementById('reg-otp').value.replace(/\D/g, '');
        if (otp.length !== 4) {
          setStatus(t('register.invalidCode'), 'error');
          return;
        }
        state.otp = otp;
        setBusy(true, 'register.paying');
        const pay = await submitVerifyAndPay();
        showSuccess(pay);
      }
    } catch (err) {
      setStatus((err && err.message) || t('register.error'), 'error');
    } finally {
      submitting = false;
      setBusy(false, primaryLabelKey());
    }
  }

  function bind() {
    renderPlan();
    goTo(0);

    document.getElementById('registerContinue')?.addEventListener('click', (e) => {
      e.preventDefault();
      onContinue();
    });
    document.getElementById('registerBack')?.addEventListener('click', (e) => {
      e.preventDefault();
      if (state.step > 0 && state.step < 4) goTo(state.step - 1);
    });
    document.querySelectorAll('[data-email-choice]').forEach((btn) => {
      btn.addEventListener('click', () => {
        state.hasEmail = btn.getAttribute('data-email-choice') === 'yes';
        syncEmailChoice();
        setStatus('', null);
      });
    });
    document.getElementById('openAppBtn')?.addEventListener('click', (e) => {
      e.preventDefault();
      if (window.HostBoraOpenApp) {
        const result = window.HostBoraOpenApp.openApp({ storeFallback: true });
        if (result.platform === 'other') location.href = result.store;
      }
    });
    document.getElementById('downloadAppBtn')?.addEventListener('click', (e) => {
      e.preventDefault();
      if (!window.HostBoraOpenApp) return;
      location.href = window.HostBoraOpenApp.storeUrl();
    });
    document.getElementById('reg-otp')?.addEventListener('input', (e) => {
      const digits = e.target.value.replace(/\D/g, '').slice(0, 4);
      e.target.value = digits;
      if (digits.length === 4) onContinue();
    });
    document.getElementById('registerForm')?.addEventListener('submit', (e) => {
      e.preventDefault();
      onContinue();
    });
    window.addEventListener('hostbora:langchange', () => {
      renderPlan();
      updateProgress();
      setBusy(false, primaryLabelKey());
    });
  }

  if (document.readyState === 'loading') {
    document.addEventListener('DOMContentLoaded', bind);
  } else {
    bind();
  }
})();
