(function () {
  'use strict';

  var NAV_LINKS = [
    { label: 'Home',       href: 'index.html' },
    { label: 'About',      href: 'about.html' },
    { label: 'People',     href: 'people.html' },
    { label: 'SkillVerse', href: 'SkillVerse/index.html' },
  ];
  var CTA = { label: 'Contact', href: 'contact.html' };
  var script = document.currentScript;
  var siteRoot = script && script.src ? new URL('./', script.src) : new URL('./', window.location.href);

  function injectNavStyles() {
    if (document.getElementById('shared-nav-styles')) return;

    var style = document.createElement('style');
    style.id = 'shared-nav-styles';
    style.textContent = [
      '.nav-toggle{display:none;align-items:center;justify-content:center;flex-direction:column;gap:4px;width:42px;height:42px;margin-left:auto;border:1px solid var(--border);border-radius:10px;background:rgba(255,255,255,.03);color:var(--text);cursor:pointer;transition:border-color .15s,background .15s}',
      '.nav-toggle:hover{border-color:var(--accent1);background:rgba(0,204,255,.08)}',
      '.nav-toggle-bar{display:block;width:18px;height:2px;border-radius:999px;background:currentColor;transition:transform .2s,opacity .2s}',
      '@media(max-width:640px){',
      '  nav{flex-wrap:wrap;align-items:center}',
      '  .nav-toggle{display:inline-flex}',
      '  .nav-links{display:none;width:100%;margin-left:0;flex-direction:column;align-items:stretch;padding-top:8px}',
      '  nav.nav-open .nav-links{display:flex}',
      '  .nav-links a{display:block;width:100%;text-align:center;padding:10px 12px}',
      '  .nav-links a.cta{padding:10px 12px}',
      '  nav.nav-open .nav-toggle-bar:nth-child(1){transform:translateY(6px) rotate(45deg)}',
      '  nav.nav-open .nav-toggle-bar:nth-child(2){opacity:0}',
      '  nav.nav-open .nav-toggle-bar:nth-child(3){transform:translateY(-6px) rotate(-45deg)}',
      '}'
    ].join('');
    document.head.appendChild(style);
  }

  function toURL(href) {
    return new URL(href, siteRoot).toString();
  }

  function getCurrentRoute() {
    var path = window.location.pathname;
    var rootPath = siteRoot.pathname;

    if (path.indexOf(rootPath) === 0) {
      path = path.slice(rootPath.length);
    } else {
      path = path.replace(/^\/+/, '');
    }

    return path || 'index.html';
  }

  function isActive(href) {
    var p = getCurrentRoute();
    if (href === 'index.html') return p === 'index.html';
    // people.html should also match people/* paths
    var base = href.replace(/\.html$/, '');
    return p === href || p === base || p.startsWith(base + '/');
  }

  /* ── NAV ── */
  var nav = document.querySelector('nav');
  if (nav) {
    injectNavStyles();

    var navLinksHTML = NAV_LINKS.map(function (l) {
      return '<a href="' + toURL(l.href) + '"' + (isActive(l.href) ? ' class="active"' : '') + '>' + l.label + '</a>';
    }).join('');
    var ctaClass = isActive(CTA.href) ? 'active cta' : 'cta';
    nav.innerHTML =
      '<a class="nav-logo" href="' + toURL('index.html') + '">' +
        '<img class="nav-icon" src="' + toURL('SkillVerse/logo.png') + '" alt="Squared Studio" />' +
        '<span class="nav-title">squared-studio</span>' +
      '</a>' +
      '<button class="nav-toggle" type="button" aria-expanded="false" aria-label="Toggle navigation">' +
        '<span class="nav-toggle-bar"></span>' +
        '<span class="nav-toggle-bar"></span>' +
        '<span class="nav-toggle-bar"></span>' +
      '</button>' +
      '<div class="nav-links">' +
        navLinksHTML +
        '<a href="' + toURL(CTA.href) + '" class="' + ctaClass + '">' + CTA.label + '</a>' +
      '</div>';

    var navToggle = nav.querySelector('.nav-toggle');
    var navLinks = nav.querySelector('.nav-links');

    function closeNav() {
      nav.classList.remove('nav-open');
      navToggle.setAttribute('aria-expanded', 'false');
    }

    navToggle.addEventListener('click', function () {
      var willOpen = !nav.classList.contains('nav-open');
      nav.classList.toggle('nav-open', willOpen);
      navToggle.setAttribute('aria-expanded', willOpen ? 'true' : 'false');
    });

    navLinks.addEventListener('click', function (event) {
      if (event.target.tagName === 'A') {
        closeNav();
      }
    });

    window.addEventListener('resize', function () {
      if (window.innerWidth > 640) {
        closeNav();
      }
    });
  }

  /* ── FOOTER ── */
  var footer = document.querySelector('footer');
  if (footer) {
    var footerLinksHTML = NAV_LINKS.concat([CTA]).map(function (l) {
      return '<a href="' + toURL(l.href) + '">' + l.label + '</a>';
    }).join('');
    footer.innerHTML =
      '<div class="footer-links">' +
        footerLinksHTML +
        '<a href="https://github.com/squared-studio" target="_blank" rel="noopener">GitHub</a>' +
      '</div>' +
      '<p>Copyright &copy; 2026 <span>squared-studio</span> &mdash; All content open-source under their respective licences.</p>';
  }
})();
