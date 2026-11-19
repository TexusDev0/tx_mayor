const backdropEl = document.getElementById('backdrop');
const homeScreenEl = document.getElementById('home-screen');
const appDashboardEl = document.getElementById('app-dashboard');

const closeBtn = document.getElementById('closeBtn');
const ipadHomeBtn = document.getElementById('ipadHomeBtn');
const backHomeBtn = document.getElementById('backHomeBtn');

const treasuryEl = document.getElementById('treasuryValue');
const taxRateEl = document.getElementById('taxRateValue');
const taxMeterFillEl = document.getElementById('taxMeterFill');
const logsListEl = document.getElementById('logsList');
const logsSectionEl = document.getElementById('logsSection');

const formPanelEl = document.getElementById('formPanel');
const formTitleEl = document.getElementById('formTitle');
const actionFormEl = document.getElementById('actionForm');
const cancelFormBtn = document.getElementById('cancelFormBtn');
const workspaceGridEl = document.querySelector('.workspace-grid');

const statusBannerEl = document.getElementById('statusBanner');
const statusTextEl = document.getElementById('statusText');
const clockEl = document.getElementById('ipadClock');

let currentTreasury = 0;
let currentTaxRate = 0;
let activeAction = null;
let currentLocale = {};
let currentLicenses = [];

function getResourceName() {
  return typeof GetParentResourceName === 'function' ? GetParentResourceName() : 'tx_mayor';
}

function postNui(eventName, data = {}) {
  return fetch(`https://${getResourceName()}/${eventName}`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json; charset=UTF-8' },
    body: JSON.stringify(data)
  }).catch(() => {});
}

function setStatus(msg) {
  if (!msg) {
    statusBannerEl.classList.add('hidden');
    return;
  }
  statusTextEl.textContent = msg;
  statusBannerEl.classList.remove('hidden');
}

function showScreen(screenName) {
  if (screenName === 'dashboard') {
    homeScreenEl.classList.add('hidden');
    homeScreenEl.classList.remove('active');
    appDashboardEl.classList.remove('hidden');
    appDashboardEl.classList.add('active');
    animateCounter(treasuryEl, currentTreasury, currentTreasury, '$', '', 450);
    animateCounter(taxRateEl, currentTaxRate, currentTaxRate, '', '%', 450);
  } else {
    closeForm();
    appDashboardEl.classList.add('hidden');
    appDashboardEl.classList.remove('active');
    homeScreenEl.classList.remove('hidden');
    homeScreenEl.classList.add('active');
  }
}

function animateCounter(el, fromVal, toVal, prefix = '', suffix = '', duration = 550) {
  const start = Number(fromVal) || 0;
  const end = Number(toVal) || 0;
  if (start === end) {
    el.textContent = `${prefix}${end.toLocaleString()}${suffix}`;
    return;
  }

  const startTime = performance.now();
  function step(now) {
    const elapsed = now - startTime;
    const progress = Math.min(elapsed / duration, 1);
    const eased = 1 - Math.pow(1 - progress, 3);
    const value = Math.round(start + (end - start) * eased);
    el.textContent = `${prefix}${value.toLocaleString()}${suffix}`;
    if (progress < 1) {
      requestAnimationFrame(step);
    }
  }
  requestAnimationFrame(step);
}

function applyLocale(strings = {}, licenses = []) {
  currentLocale = strings || {};
  if (Array.isArray(licenses) && licenses.length > 0) {
    currentLicenses = licenses;
  }

  const map = {
    locDeviceBrand: 'deviceBrand',
    locDeviceTitle: 'deviceTitle',
    locStatusTag: 'statusTag',
    homeTitle: 'headerTitle',
    locHomeHint: 'homeHint',
    locAppDashboardTitle: 'appDashboardTitle',
    locAppDashboardDesc: 'appDashboardDesc',
    locAppLicenseTitle: 'appLicenseTitle',
    locAppLicenseDesc: 'appLicenseDesc',
    locAppAnnounceTitle: 'appAnnounceTitle',
    locAppAnnounceDesc: 'appAnnounceDesc',
    locAppLogsTitle: 'appLogsTitle',
    locAppLogsDesc: 'appLogsDesc',
    locHeaderTitle: 'headerTitle',
    locHeaderBadge: 'headerBadge',
    locHeaderSubtitle: 'headerSubtitle',
    backHomeBtn: 'backToHome',
    locTreasuryLabel: 'treasuryLabel',
    locTreasuryTag: 'treasuryTag',
    locTreasurySub: 'treasurySub',
    locTaxLabel: 'taxLabel',
    locTaxTag: 'taxTag',
    locTaxSub: 'taxSub',
    locActionsTitle: 'actionsTitle',
    locActionsHint: 'actionsHint',
    locLogsTitle: 'logsTitle',
    locLogsHint: 'logsHint',
    locActionDepositTitle: 'actionDepositTitle',
    locActionDepositDesc: 'actionDepositDesc',
    locActionWithdrawTitle: 'actionWithdrawTitle',
    locActionWithdrawDesc: 'actionWithdrawDesc',
    locActionTaxTitle: 'actionTaxTitle',
    locActionTaxDesc: 'actionTaxDesc',
    locActionLicenseTitle: 'actionLicenseTitle',
    locActionLicenseDesc: 'actionLicenseDesc',
    locActionAnnounceTitle: 'actionAnnounceTitle',
    locActionAnnounceDesc: 'actionAnnounceDesc',
    locFormKicker: 'formKicker',
    cancelFormBtn: 'cancelBtn'
  };

  Object.entries(map).forEach(([elId, key]) => {
    const el = document.getElementById(elId);
    if (el && currentLocale[key]) {
      el.textContent = currentLocale[key];
    }
  });
}

function renderLogs(logs = []) {
  logsListEl.innerHTML = '';
  if (!Array.isArray(logs) || logs.length === 0) {
    const empty = document.createElement('div');
    empty.className = 'empty-log';
    empty.textContent = currentLocale.emptyLog || 'ยังไม่มีประวัติการทำรายการ';
    logsListEl.appendChild(empty);
    return;
  }

  logs.slice(0, 15).forEach((item) => {
    const row = document.createElement('div');
    row.className = 'log-item';

    const info = document.createElement('div');
    info.className = 'log-info';

    const badge = document.createElement('span');
    const safeType = String(item.type || 'info').replace(/[^a-zA-Z0-9_-]/g, '');
    badge.className = `log-badge ${safeType}`;
    badge.textContent = safeType;

    const text = document.createElement('span');
    text.className = 'log-text';
    text.textContent = item.text || '';

    const time = document.createElement('span');
    time.className = 'log-time';
    time.textContent = item.time || '';

    info.appendChild(badge);
    info.appendChild(text);
    row.appendChild(info);
    row.appendChild(time);
    logsListEl.appendChild(row);
  });
}

function updateState(data = {}, animate = true) {
  const prevTreasury = currentTreasury;
  const prevTax = currentTaxRate;

  const nextTreasury = Math.max(0, Number(data.treasury ?? currentTreasury) || 0);
  const nextTax = Math.min(50, Math.max(0, Number(data.taxRate ?? currentTaxRate) || 0));

  currentTreasury = nextTreasury;
  currentTaxRate = nextTax;

  if (animate) {
    animateCounter(treasuryEl, prevTreasury, nextTreasury, '$', '', 600);
    animateCounter(taxRateEl, prevTax, nextTax, '', '%', 500);
  } else {
    treasuryEl.textContent = `$${nextTreasury.toLocaleString()}`;
    taxRateEl.textContent = `${nextTax}%`;
  }

  taxMeterFillEl.style.width = `${(nextTax / 50) * 100}%`;
  renderLogs(data.logs || []);
}

function closeForm() {
  activeAction = null;
  formPanelEl.classList.add('hidden');
  workspaceGridEl.classList.remove('has-form');
  actionFormEl.innerHTML = '';
  document.querySelectorAll('.action-btn').forEach((btn) => btn.classList.remove('active'));
}

function openForm(actionType) {
  activeAction = actionType;
  document.querySelectorAll('.action-btn').forEach((btn) => {
    btn.classList.toggle('active', btn.dataset.action === actionType);
  });

  actionFormEl.innerHTML = '';
  formPanelEl.classList.remove('hidden');
  workspaceGridEl.classList.add('has-form');

  const titles = {
    deposit: currentLocale.actionDepositTitle || 'ฝากเงินเข้าคลัง',
    withdraw: currentLocale.actionWithdrawTitle || 'ถอนเงินจากคลัง',
    tax: currentLocale.actionTaxTitle || 'ปรับอัตราภาษี',
    license: currentLocale.actionLicenseTitle || 'ออกใบอนุญาตพิเศษ',
    announce: currentLocale.actionAnnounceTitle || 'ประกาศคำสั่งเมือง'
  };
  formTitleEl.textContent = titles[actionType] || 'ทำรายการ';

  if (actionType === 'deposit' || actionType === 'withdraw') {
    actionFormEl.innerHTML = `
      <div class="field">
        <label for="amountInput">${currentLocale.amountLabel || 'จำนวนเงิน ($)'}</label>
        <input id="amountInput" type="number" min="1" step="1" placeholder="${currentLocale.amountPlaceholder || 'เช่น 50000'}" required />
      </div>
      <button type="submit" class="submit-btn">${currentLocale.submitBtn || 'ยืนยันรายการ'}</button>
    `;
  } else if (actionType === 'tax') {
    actionFormEl.innerHTML = `
      <div class="field">
        <label for="taxInput">${currentLocale.taxInputLabel || 'อัตราภาษีใหม่ (0 – 50%)'}</label>
        <input id="taxInput" type="number" min="0" max="50" step="1" value="${currentTaxRate}" required />
      </div>
      <button type="submit" class="submit-btn">${currentLocale.submitBtn || 'ยืนยันรายการ'}</button>
    `;
  } else if (actionType === 'license') {
    const optionsHtml = (currentLicenses.length > 0 ? currentLicenses : [
      { value: 'weapon', label: 'ใบอนุญาตพกพาอาวุธ (Weapon License)' },
      { value: 'business', label: 'ใบอนุญาตประกอบธุรกิจ (Business License)' }
    ]).map((opt) => `<option value="${opt.value}">${opt.label}</option>`).join('');

    actionFormEl.innerHTML = `
      <div class="field">
        <label for="targetIdInput">${currentLocale.targetIdLabel || 'เลข ID ผู้เล่นในเมือง'}</label>
        <input id="targetIdInput" type="number" min="1" step="1" placeholder="${currentLocale.targetIdPlaceholder || 'เช่น 1'}" required />
      </div>
      <div class="field">
        <label for="licenseTypeSelect">${currentLocale.licenseTypeLabel || 'ประเภทใบอนุญาต'}</label>
        <select id="licenseTypeSelect">${optionsHtml}</select>
      </div>
      <button type="submit" class="submit-btn">${currentLocale.submitBtn || 'ยืนยันรายการ'}</button>
    `;
  } else if (actionType === 'announce') {
    actionFormEl.innerHTML = `
      <div class="field">
        <label for="announceInput">${currentLocale.announceLabel || 'ข้อความประกาศคำสั่งเมือง'}</label>
        <textarea id="announceInput" placeholder="${currentLocale.announcePlaceholder || 'พิมพ์ประกาศราชการ...'}" required></textarea>
      </div>
      <button type="submit" class="submit-btn">${currentLocale.submitBtn || 'ยืนยันรายการ'}</button>
    `;
  }
}

actionFormEl.addEventListener('submit', (e) => {
  e.preventDefault();
  if (!activeAction) return;

  const payload = { action: activeAction };

  if (activeAction === 'deposit' || activeAction === 'withdraw') {
    const amount = Number(document.getElementById('amountInput')?.value || 0);
    if (!Number.isFinite(amount) || amount <= 0) {
      setStatus(currentLocale.statusInvalidAmount || 'จำนวนเงินไม่ถูกต้อง');
      return;
    }
    payload.amount = Math.floor(amount);
  } else if (activeAction === 'tax') {
    const taxRate = Number(document.getElementById('taxInput')?.value ?? -1);
    if (!Number.isFinite(taxRate) || taxRate < 0 || taxRate > 50) {
      setStatus(currentLocale.statusInvalidTax || 'อัตราภาษีต้องอยู่ระหว่าง 0 ถึง 50%');
      return;
    }
    payload.taxRate = Math.floor(taxRate);
  } else if (activeAction === 'license') {
    const targetId = Number(document.getElementById('targetIdInput')?.value || 0);
    const licenseType = document.getElementById('licenseTypeSelect')?.value || 'weapon';
    if (!Number.isFinite(targetId) || targetId <= 0) {
      setStatus(currentLocale.statusInvalidId || 'เลข ID ผู้เล่นไม่ถูกต้อง');
      return;
    }
    payload.targetId = Math.floor(targetId);
    payload.licenseType = licenseType;
  } else if (activeAction === 'announce') {
    const message = String(document.getElementById('announceInput')?.value || '').trim();
    if (!message) {
      setStatus(currentLocale.statusEmptyAnnounce || 'กรุณาพิมพ์ข้อความประกาศ');
      return;
    }
    payload.message = message;
  }

  postNui('submitAction', payload);
  setStatus(currentLocale.statusSent || 'ส่งคำสั่งเรียบร้อยแล้ว');
  closeForm();
});

document.querySelectorAll('.action-btn').forEach((btn) => {
  btn.addEventListener('click', () => {
    const action = btn.dataset.action;
    if (activeAction === action) {
      closeForm();
    } else {
      openForm(action);
    }
  });
});

document.querySelectorAll('.app-tile').forEach((tile) => {
  tile.addEventListener('click', () => {
    const target = tile.dataset.targetScreen || 'dashboard';
    const preset = tile.dataset.preset || 'none';
    showScreen(target);

    if (preset === 'license' || preset === 'announce') {
      openForm(preset);
    } else if (preset === 'logs') {
      closeForm();
      logsSectionEl?.scrollIntoView({ behavior: 'smooth', block: 'nearest' });
    } else {
      closeForm();
    }
  });
});

function requestCloseUi() {
  backdropEl.classList.add('hidden');
  closeForm();
  setStatus('');
  postNui('closeUi');
}

closeBtn.addEventListener('click', requestCloseUi);
cancelFormBtn.addEventListener('click', closeForm);
ipadHomeBtn.addEventListener('click', () => showScreen('home'));
backHomeBtn.addEventListener('click', () => showScreen('home'));

document.addEventListener('keydown', (e) => {
  if (e.key === 'Escape' && !backdropEl.classList.contains('hidden')) {
    requestCloseUi();
  }
});

function refreshClock() {
  const now = new Date();
  const hh = String(now.getHours()).padStart(2, '0');
  const mm = String(now.getMinutes()).padStart(2, '0');
  if (clockEl) clockEl.textContent = `${hh}:${mm}`;
}
refreshClock();
setInterval(refreshClock, 15000);

window.addEventListener('message', (event) => {
  const msg = event.data || {};
  if (msg.action === 'openUi') {
    applyLocale(msg.locale, msg.licenses);
    backdropEl.classList.remove('hidden');
    showScreen('home');
    updateState(msg.data || {}, true);
  } else if (msg.action === 'syncState') {
    applyLocale(msg.locale, msg.licenses);
    updateState(msg.data || {}, true);
  } else if (msg.action === 'closeUi') {
    backdropEl.classList.add('hidden');
    closeForm();
    setStatus('');
  }
});