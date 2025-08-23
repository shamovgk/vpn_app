// public/landing.js
(function () {
  const header = document.querySelector('.header');
  const EXTRA = 8; // маленький зазор
  const getOffset = () => (header ? header.getBoundingClientRect().height + EXTRA : 0);

  function getHashFromHref(href) {
    try {
      if (!href) return '';
      if (href.startsWith('#')) return href;
      const url = new URL(href, window.location.href);
      // скроллим только в рамках текущего документа
      const sameDoc = url.pathname === window.location.pathname && url.origin === window.location.origin;
      return sameDoc ? (url.hash || '') : '';
    } catch { return ''; }
  }

  function animateScrollTo(top) {
    const start = window.pageYOffset;
    const dist = top - start;
    const dur = 450; // мс
    if (Math.abs(dist) < 2) { window.scrollTo(0, top); return; }

    let t0 = null;
    function step(ts) {
      if (!t0) t0 = ts;
      const t = Math.min(1, (ts - t0) / dur);
      // easeInOutQuad
      const eased = t < 0.5 ? 2 * t * t : -1 + (4 - 2 * t) * t;
      window.scrollTo(0, start + dist * eased);
      if (t < 1) requestAnimationFrame(step);
    }
    requestAnimationFrame(step);
  }

  function scrollToHash(hash, push = true) {
    if (!hash || hash === '#') return;
    const el = document.querySelector(hash);
    if (!el) return;
    const top = el.getBoundingClientRect().top + window.pageYOffset - getOffset();
    if (push) history.pushState(null, '', hash);
    // пробуем нативно; если браузер не поддерживает — наш аниматор
    try {
      window.scrollTo({ top, behavior: 'smooth' });
    } catch {
      animateScrollTo(top);
    }
  }

  // 1) Перехватываем клики В ФАЗЕ ЗАХВАТА (раньше дефолта и сторонних обработчиков)
  document.addEventListener('click', function onClickCapture(e) {
    const a = e.target.closest('a[href]');
    if (!a) return;
    const hash = getHashFromHref(a.getAttribute('href'));
    if (!hash) return;
    if (!document.querySelector(hash)) return;

    // стопаем дефолт ещё до фазы всплытия
    e.preventDefault();
    e.stopImmediatePropagation();
    scrollToHash(hash, true);
  }, true); // <-- ВАЖНО: useCapture = true

  // 2) Если кто-то меняет hash программно или дефолт проскочил — плавно переедем сами
  window.addEventListener('hashchange', function (e) {
    e.preventDefault?.();
    const hash = location.hash;
    if (document.querySelector(hash)) {
      // мгновенный скролл мог уже произойти — вернёмся и поедем плавно
      const top = document.querySelector(hash).getBoundingClientRect().top + window.pageYOffset - getOffset();
      try {
        window.scrollTo({ top, behavior: 'smooth' });
      } catch { animateScrollTo(top); }
    }
  });

  // 3) Если пользователь открыл сразу с хешем — скорректируем позицию (без анимации)
  window.addEventListener('load', function () {
    if (location.hash && document.querySelector(location.hash)) {
      setTimeout(() => {
        const top = document.querySelector(location.hash).getBoundingClientRect().top + window.pageYOffset - getOffset();
        window.scrollTo(0, top);
      }, 0);
    }
  });

  // 4) При ресайзе держим текущую секцию в зоне после хедера
  window.addEventListener('resize', () => {
    if (location.hash && document.querySelector(location.hash)) {
      const top = document.querySelector(location.hash).getBoundingClientRect().top + window.pageYOffset - getOffset();
      window.scrollTo(0, top);
    }
  });

  console.log('[landing.js] ready; header offset =', getOffset());
})();
