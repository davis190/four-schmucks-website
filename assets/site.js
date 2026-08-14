/* ==========================================================================
   Four Schmucks — shared behaviour
   --------------------------------------------------------------------------
   Three jobs: the mobile nav toggle, scroll reveal, and rendering anything
   driven by the brand registry in brands.js. No dependencies, no build step.
   ========================================================================== */

(function () {
  'use strict';

  /* --- brand links ---------------------------------------------------------
     In production each brand lives on its own subdomain. When previewing from
     a local server (or file://) those hostnames don't resolve, so fall back to
     the sibling .html file — that keeps `python3 -m http.server` usable. */

  var LOCAL = /^(localhost|127\.0\.0\.1|0\.0\.0\.0|\[::1\])$/.test(location.hostname) ||
              location.protocol === 'file:';

  function brandHref(brand) {
    return LOCAL ? brand.file : 'https://' + brand.sub + '.fourschmucks.com';
  }

  var brands = window.SCHMUCK_BRANDS || [];
  var currentKey = document.body.getAttribute('data-brand') || '';

  /* --- mobile nav ---------------------------------------------------------- */

  function initNav() {
    var toggle = document.querySelector('.nav-toggle');
    var links = document.querySelector('.nav-links');
    if (!toggle || !links) return;

    function setOpen(open) {
      toggle.setAttribute('aria-expanded', String(open));
      links.setAttribute('data-open', String(open));
    }

    toggle.addEventListener('click', function () {
      setOpen(toggle.getAttribute('aria-expanded') !== 'true');
    });

    // Close after tapping a link, and on Escape.
    links.addEventListener('click', function (e) {
      if (e.target.closest('a')) setOpen(false);
    });
    document.addEventListener('keydown', function (e) {
      if (e.key === 'Escape') setOpen(false);
    });

    // Reset state if the viewport grows past the mobile breakpoint while open.
    window.matchMedia('(min-width: 861px)').addEventListener('change', function (e) {
      if (e.matches) setOpen(false);
    });
  }

  /* --- scroll reveal ------------------------------------------------------- */

  function initReveal() {
    var targets = document.querySelectorAll('.reveal');
    if (!targets.length) return;

    // No IntersectionObserver, or the user prefers less motion: show everything.
    if (!('IntersectionObserver' in window) ||
        window.matchMedia('(prefers-reduced-motion: reduce)').matches) {
      targets.forEach(function (el) { el.classList.add('in'); });
      return;
    }

    var io = new IntersectionObserver(function (entries) {
      entries.forEach(function (entry) {
        if (!entry.isIntersecting) return;
        entry.target.classList.add('in');
        io.unobserve(entry.target);
      });
    }, { rootMargin: '0px 0px -12% 0px', threshold: 0.08 });

    targets.forEach(function (el) { io.observe(el); });
  }

  /* --- footer brand strip -------------------------------------------------- */

  function renderStrip() {
    var host = document.querySelector('[data-brand-strip]');
    if (!host || !brands.length) return;

    var list = document.createElement('ul');
    list.className = 'brand-chips';

    brands.forEach(function (brand) {
      var li = document.createElement('li');
      var a = document.createElement('a');
      a.href = brandHref(brand);
      a.style.setProperty('--chip', brand.accent);
      a.textContent = brand.short;
      if (brand.key === currentKey) a.setAttribute('aria-current', 'page');
      li.appendChild(a);
      list.appendChild(li);
    });

    host.innerHTML = '';
    var label = document.createElement('p');
    label.className = 'strip-label';
    label.textContent = 'The rest of the portfolio';
    host.appendChild(label);
    host.appendChild(list);
  }

  /* --- homepage brand grid ------------------------------------------------- */

  function renderGrid() {
    var host = document.querySelector('[data-brand-grid]');
    if (!host || !brands.length) return;

    var frag = document.createDocumentFragment();

    brands.forEach(function (brand) {
      var a = document.createElement('a');
      a.className = 'card brand-card reveal';
      a.href = brandHref(brand);
      // Re-theme the card to the brand it links to, so the homepage previews
      // all eight identities at once.
      a.style.setProperty('--accent', brand.accent);
      a.style.setProperty('--glow', brand.accent + '59');
      a.style.setProperty('--surface-tint', brand.accent + '14');

      var icon = document.createElement('div');
      icon.className = 'icon';
      icon.textContent = brand.icon;

      var h3 = document.createElement('h3');
      h3.textContent = brand.name;

      var p = document.createElement('p');
      p.textContent = brand.tagline;

      var go = document.createElement('span');
      go.className = 'go';
      go.textContent = brand.sub + '.fourschmucks.com';

      a.append(icon, h3, p, go);
      frag.appendChild(a);
    });

    host.innerHTML = '';
    host.appendChild(frag);

    // The grid is injected after the observer would normally have run.
    initReveal();
  }

  /* --- go ------------------------------------------------------------------ */

  function init() {
    initNav();
    renderStrip();
    renderGrid();
    initReveal();
  }

  if (document.readyState === 'loading') {
    document.addEventListener('DOMContentLoaded', init);
  } else {
    init();
  }
})();
