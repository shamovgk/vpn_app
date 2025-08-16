(function () {
  // === Утилиты
  function q(sel, root=document){ return root.querySelector(sel); }
  function qa(sel, root=document){ return Array.from(root.querySelectorAll(sel)); }
  function toast(msg, isErr=true) {
    console[isErr ? 'error' : 'log'](msg);
    let box = q('#admin-error-box');
    if (!box) {
      box = document.createElement('div');
      box.id = 'admin-error-box';
      box.style.cssText = 'position:fixed;bottom:12px;left:12px;max-width:60ch;background:#ffe6e6;color:#a00;padding:8px 12px;border:1px solid #f5a9a9;border-radius:8px;z-index:9999;font:13px/1.4 system-ui';
      document.body.appendChild(box);
    }
    const div = document.createElement('div');
    div.textContent = '[Admin UI] ' + msg;
    box.appendChild(div);
    setTimeout(() => div.remove(), 6000);
  }
  function getCSRF() {
    const m = q('meta[name="csrf-token"]');
    return m ? m.getAttribute('content') || '' : '';
  }
  function toISODateOrNull(v) {
    const s = (v || '').trim();
    if (!s) return null;
    const d = new Date(s);
    if (isNaN(d.getTime())) return null;
    return d.toISOString();
  }
  async function apiFetch(url, options = {}) {
    const opt = { credentials: 'same-origin', headers: { 'Accept':'application/json', ...(options.headers || {}) }, ...options };
    const res = await fetch(url, opt);
    if (res.status === 401 || res.status === 403) {
      const nextUrl = encodeURIComponent(location.pathname + location.search);
      location.href = `/admin/login?next=${nextUrl}`;
      throw new Error('Unauthorized');
    }
    if (!res.ok) {
      const txt = await res.text().catch(()=> '');
      throw new Error(`HTTP ${res.status}: ${txt || 'request failed'}`);
    }
    const ct = (res.headers.get('content-type') || '').toLowerCase();
    return ct.includes('application/json') ? res.json() : null;
  }
  function readINIT() {
    try {
      const el = q('#init');
      if (!el) return { page:1, limit:20, q:'', sort:'id', dir:'desc', filter:'all' };
      const data = JSON.parse(el.textContent || '{}');
      return Object.assign({ page:1, limit:20, q:'', sort:'id', dir:'desc', filter:'all' }, data || {});
    } catch (e) {
      toast('INIT parse failed: ' + e.message);
      return { page:1, limit:20, q:'', sort:'id', dir:'desc', filter:'all' };
    }
  }

  // === Состояние/URL
  const INIT = readINIT();
  function stateFromURL() {
    const s = new URLSearchParams(location.search);
    return {
      page:  parseInt(s.get('page')  || INIT.page, 10)  || 1,
      limit: parseInt(s.get('limit') || INIT.limit, 10) || 20,
      q:     s.get('q')      || INIT.q,
      sort:  s.get('sort')   || INIT.sort,
      dir:   s.get('dir')    || INIT.dir,
      filter:s.get('filter') || INIT.filter,
    };
  }
  function setURL(state, replace=false) {
    const s = new URLSearchParams();
    if (state.q) s.set('q', state.q);
    s.set('page', state.page);
    s.set('limit', state.limit);
    s.set('sort', state.sort);
    s.set('dir', state.dir);
    s.set('filter', state.filter);
    const url = '/admin?' + s.toString();
    if (replace) history.replaceState(state, '', url);
    else history.pushState(state, '', url);
  }

  // === Рендер
  function renderTable(users) {
    const tbody = q('#usersTable tbody');
    if (!tbody) return;
    tbody.innerHTML = users.map(u => `
      <tr data-id="${u.id}">
        <td>${u.id}</td>
        <td>${u.username}</td>
        <td>${u.email}</td>
        <td>${u.email_verified ? 'Да' : 'Нет'}</td>
        <td><input type="checkbox" class="js-is-paid" ${u.is_paid ? 'checked' : ''}></td>
        <td>
          <input type="date" class="js-paid-until" value="${u.paid_until ? u.paid_until.split('T')[0] : ''}">
          <button class="btn mini js-grant30">+30 дней</button>
        </td>
        <td><input type="date" class="js-trial-until" value="${u.trial_until ? u.trial_until.split('T')[0] : ''}"></td>
        <td class="devices-count">${u.device_count}</td>
        <td><button class="edit-btn btn js-open-devices">Устройства</button></td>
      </tr>
    `).join('');

    const state = stateFromURL();
    qa('.th-btn').forEach(btn => btn.dataset.sort = '');
    const active = document.querySelector(`.th-btn[data-col="${state.sort}"]`);
    if (active) active.dataset.sort = state.dir;
  }

  function renderPager(p) {
    const elCur   = q('#p_cur');   if (elCur)   elCur.textContent   = p.page;
    const elPages = q('#p_pages'); if (elPages) elPages.textContent = p.pages;
    const elTotal = q('#p_total'); if (elTotal) elTotal.textContent = p.total;

    const first = q('#pager .pager-first');
    const prev  = q('#pager .pager-prev');
    const next  = q('#pager .pager-next');
    const last  = q('#pager .pager-last');

    if (first) { first.dataset.goto = 1; first.disabled = p.page <= 1; }
    if (prev)  { prev.dataset.goto  = Math.max(1, p.page - 1); prev.disabled  = p.page <= 1; }
    if (next)  { next.dataset.goto  = Math.min(p.pages, p.page + 1); next.disabled = p.page >= p.pages; }
    if (last)  { last.dataset.goto  = p.pages; last.disabled = p.page >= p.pages; }
  }

  // === Действия
  async function fetchUsers(state) {
    const s = new URLSearchParams(state);
    return apiFetch('/admin/users?' + s.toString());
  }
  async function applyState(state, replace=false) {
    const data = await fetchUsers(state);
    renderTable(data.users);
    renderPager(data.pagination);
    state.pages = data.pagination.pages;
    setURL(state, replace);
  }
  async function goPage(page) {
    const state = stateFromURL();
    state.page = Math.max(1, Math.min(page, state.pages || 1));
    await applyState(state);
  }
  async function sortBy(col) {
    const state = stateFromURL();
    if (state.sort === col) state.dir = state.dir === 'asc' ? 'desc' : 'asc';
    else { state.sort = col; state.dir = 'asc'; }
    state.page = 1;
    await applyState(state);
  }
  async function applyFilters() {
    const state = stateFromURL();
    const qEl = q('#q'); const fEl = q('#filter'); const lEl = q('#limit');
    state.q = (qEl && qEl.value ? qEl.value.trim() : '');
    state.filter = (fEl && fEl.value) || 'all';
    state.limit = parseInt(lEl && lEl.value || state.limit, 10) || state.limit;
    state.page = 1;
    await applyState(state);
  }
  async function resetFilters() {
    const state = { page:1, limit:20, q:'', sort:'id', dir:'desc', filter:'all' };
    const qEl = q('#q'); if (qEl) qEl.value = '';
    const fEl = q('#filter'); if (fEl) fEl.value = 'all';
    const lEl = q('#limit'); if (lEl) lEl.value = '20';
    await applyState(state);
  }

  function getRowUserId(el) {
    const tr = el.closest('tr');
    return tr ? tr.getAttribute('data-id') : null;
  }
  function updateUser(userId, patch) {
    const csrf = getCSRF();
    return apiFetch(`/admin/users/${userId}`, {
      method: 'PUT',
      headers: { 'Content-Type':'application/json', 'X-CSRF-Token': csrf },
      body: JSON.stringify(patch)
    });
  }
  function grant30(userId) {
    const csrf = getCSRF();
    return apiFetch(`/admin/users/${userId}/grant-30d`, {
      method: 'POST',
      headers: { 'X-CSRF-Token': csrf }
    });
  }
  function openDevices(userId, username) {
    const modal = q('#devicesModal');
    const body = q('#devicesBody');
    const title = q('#devicesTitle');
    if (!modal || !body || !title) return;
    title.textContent = `Устройства — ${username} (id=${userId})`;
    body.innerHTML = 'Загрузка...';
    modal.style.display = 'flex';

    apiFetch(`/admin/users/${userId}/devices`)
      .then(list => {
        if (!list || !list.length) {
          body.innerHTML = '<p>Нет устройств.</p>';
          return;
        }
        const rows = list.map(d => `
          <tr>
            <td>${d.id}</td>
            <td>${d.device_token}</td>
            <td>${d.device_model || ''}</td>
            <td>${d.device_os || ''}</td>
            <td>${d.last_seen || ''}</td>
            <td>
              <button class="btn mini js-unlink-device" data-user-id="${userId}" data-device-id="${d.id}">Отвязать</button>
            </td>
          </tr>
        `).join('');
        body.innerHTML = `
          <table>
            <thead><tr>
              <th>ID</th><th>Device Token</th><th>Model</th><th>OS</th><th>Last Seen</th><th></th>
            </tr></thead>
            <tbody>${rows}</tbody>
          </table>
        `;
      })
      .catch(() => { body.innerHTML = '<p class="error">Ошибка загрузки устройств</p>'; });
  }
  function closeModal() {
    const modal = q('#devicesModal');
    if (modal) modal.style.display = 'none';
  }
  function unlinkDevice(userId, deviceId) {
    const csrf = getCSRF();
    return apiFetch(`/admin/users/${userId}/devices/${deviceId}`, {
      method: 'DELETE',
      headers: { 'X-CSRF-Token': csrf }
    });
  }

  // === События
  function bindListPageEvents() {
    // сортировка
    qa('.th-btn').forEach(btn => {
      btn.addEventListener('click', () => {
        const col = btn.dataset.col;
        if (col) sortBy(col).catch(e => toast(e.message));
      });
    });

    // пагинация
    const pager = q('#pager');
    if (pager) {
      pager.addEventListener('click', (e) => {
        const b = e.target.closest('[data-goto]');
        if (!b) return;
        e.preventDefault();
        const p = Number(b.dataset.goto) || 1;
        goPage(p).catch(err => toast(err.message));
      });
    }

    // фильтры
    const applyBtn = q('#applyBtn'); if (applyBtn) applyBtn.addEventListener('click', () => applyFilters().catch(e => toast(e.message)));
    const resetBtn = q('#resetBtn'); if (resetBtn) resetBtn.addEventListener('click', () => resetFilters().catch(e => toast(e.message)));

    // делегирование по таблице
    const table = q('#usersTable');
    if (table) {
      table.addEventListener('change', (e) => {
        const t = e.target;
        const userId = getRowUserId(t);
        if (!userId) return;

        if (t.classList.contains('js-is-paid')) {
          updateUser(userId, { is_paid: t.checked })
            .then(() => applyState(stateFromURL(), true))
            .catch(err => toast('Ошибка обновления: ' + err.message));
        }
        if (t.classList.contains('js-paid-until')) {
          const iso = toISODateOrNull(t.value);
          updateUser(userId, { paid_until: iso })
            .then(() => applyState(stateFromURL(), true))
            .catch(err => toast('Ошибка обновления: ' + err.message));
        }
        if (t.classList.contains('js-trial-until')) {
          const iso = toISODateOrNull(t.value);
          updateUser(userId, { trial_until: iso })
            .then(() => applyState(stateFromURL(), true))
            .catch(err => toast('Ошибка обновления: ' + err.message));
        }
      });

      table.addEventListener('click', (e) => {
        const t = e.target;

        const grantBtn = t.closest('.js-grant30');
        if (grantBtn) {
          const userId = getRowUserId(grantBtn);
          if (!userId) return;
          e.preventDefault();
          grant30(userId)
            .then(() => applyState(stateFromURL(), true))
            .catch(err => toast('Ошибка: ' + err.message));
          return;
        }

        const devicesBtn = t.closest('.js-open-devices');
        if (devicesBtn) {
          const tr = devicesBtn.closest('tr');
          const userId = tr && tr.getAttribute('data-id');
          const username = tr ? tr.children[1].textContent : ('user ' + (userId || ''));
          if (userId) openDevices(userId, username);
          return;
        }
      });
    }

    // unlink в модалке
    const devicesBody = q('#devicesBody');
    if (devicesBody) {
      devicesBody.addEventListener('click', (e) => {
        const btn = e.target.closest('.js-unlink-device');
        if (!btn) return;
        const userId = btn.getAttribute('data-user-id');
        const deviceId = btn.getAttribute('data-device-id');
        unlinkDevice(userId, deviceId)
          .then((data) => {
            openDevices(userId, q('#devicesTitle').textContent || '');
            const cell = q(`tr[data-id="${userId}"] .devices-count`);
            if (cell && data && typeof data.deviceCount === 'number') cell.textContent = data.deviceCount;
            return applyState(stateFromURL(), true);
          })
          .catch(err => toast('Ошибка: ' + err.message));
      });
    }

    // Закрыть модалку
    const close = q('#devicesModal .btn.close');
    if (close) close.addEventListener('click', closeModal);

    // первый запрос
    applyState(stateFromURL(), true).catch(err => toast(err.message));
  }

  function bindCommon() {
    // logout
    const logoutBtn = q('#logoutBtn');
    if (logoutBtn) {
      logoutBtn.addEventListener('click', () => {
        const f = q('#logoutForm');
        if (f) f.submit();
      });
    }
    // back/forward
    window.addEventListener('popstate', () => {
      const table = q('#usersTable');
      if (table) applyState(stateFromURL(), true).catch(err => toast(err.message));
    });
    // глобальные ошибки
    window.addEventListener('error', (e) => toast(e.message));
  }

  document.addEventListener('DOMContentLoaded', () => {
    bindCommon();
    if (q('#usersTable')) bindListPageEvents();
  });
})();
