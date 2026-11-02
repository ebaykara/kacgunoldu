// Kaç Gün Oldu? — emalabs.info/kacgunoldu. Generated into the site by build.py.
(function () {
  var doc = document.documentElement;
  doc.classList.add('js');

  // Nav: solid once scrolled, menu toggle on small screens.
  var nav = document.querySelector('.nav');
  var onScroll = function () { nav.classList.toggle('is-scrolled', window.scrollY > 8); };
  onScroll();
  window.addEventListener('scroll', onScroll, { passive: true });

  var menuBtn = document.querySelector('.menu-btn');
  var links = document.getElementById('nav-links');
  if (menuBtn && links) {
    var setMenu = function (open) {
      menuBtn.setAttribute('aria-expanded', String(open));
      links.classList.toggle('is-open', open);
      nav.classList.toggle('menu-open', open);
    };
    menuBtn.addEventListener('click', function () { setMenu(menuBtn.getAttribute('aria-expanded') !== 'true'); });
    links.addEventListener('click', function (e) { if (e.target.closest('a')) setMenu(false); });
    document.addEventListener('keydown', function (e) { if (e.key === 'Escape') setMenu(false); });
  }

  // Reveal on scroll.
  var items = document.querySelectorAll('.reveal');
  if ('IntersectionObserver' in window) {
    var io = new IntersectionObserver(function (entries) {
      entries.forEach(function (en) {
        if (en.isIntersecting) { en.target.classList.add('is-in'); io.unobserve(en.target); }
      });
    }, { rootMargin: '0px 0px -8% 0px', threshold: 0.08 });
    items.forEach(function (el) { io.observe(el); });
  } else {
    items.forEach(function (el) { el.classList.add('is-in'); });
  }

  // Status demo: the same rules as lib/domain/logic.dart.
  var demo = document.querySelector('.demo');
  if (demo) {
    var every = Number(demo.dataset.every);
    var tile = document.getElementById('demo-tile');
    var ring = document.getElementById('demo-ring');
    var num = document.getElementById('demo-num');
    var status = document.getElementById('demo-status');
    var out = document.getElementById('demo-out');
    var slider = document.getElementById('demo-days');
    var render = function (days) {
      var ratio = days / every;
      var tier = days > every * 1.25 + 1 ? 'late' : ratio > 0.95 ? 'soon' : ratio < 0.5 ? 'fresh' : 'calm';
      var pct = Math.min(100, Math.max(3, Math.round(ratio * 100)));
      var left = every - days;
      tile.className = 'tile demo-tile tile--' + tier;
      ring.style.setProperty('--p', pct);
      num.textContent = days;
      out.textContent = days;
      status.textContent = left > 0 ? demo.dataset.left.replace('{n}', left)
        : left === 0 ? demo.dataset.today
        : demo.dataset.over.replace('{n}', -left);
      slider.style.setProperty('--fill', (days / slider.max * 100) + '%');
    };
    slider.addEventListener('input', function () { render(Number(slider.value)); });
    document.getElementById('demo-reset').addEventListener('click', function () {
      slider.value = 0;
      render(0);
    });
    render(Number(slider.value));
  }

  // Legal pages: highlight the section in view.
  var toc = document.querySelectorAll('.toc a');
  if (toc.length && 'IntersectionObserver' in window) {
    var byId = {};
    toc.forEach(function (a) { byId[a.getAttribute('href').slice(1)] = a; });
    var spy = new IntersectionObserver(function (entries) {
      entries.forEach(function (en) {
        if (!en.isIntersecting) return;
        toc.forEach(function (a) { a.classList.remove('is-active'); });
        var a = byId[en.target.id];
        if (a) a.classList.add('is-active');
      });
    }, { rootMargin: '-20% 0px -70% 0px' });
    document.querySelectorAll('.doc-section[id]').forEach(function (s) { spy.observe(s); });
  }
})();
