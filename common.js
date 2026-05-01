(function () {
  'use strict';

  var NAV_LINKS = [
    { label: 'Home',       href: '/index.html' },
    { label: 'About',      href: '/about.html' },
    { label: 'People',     href: '/people.html' },
    { label: 'SkillVerse', href: '/SkillVerse/index.html' },
  ];
  var CTA = { label: 'Contact', href: '/contact.html' };

  function isActive(href) {
    var p = window.location.pathname;
    if (href === '/index.html') return p === '/' || p === '/index.html';
    // /people.html should also match /people/* paths
    var base = href.replace(/\.html$/, '');
    return p === href || p === base || p.startsWith(base + '/');
  }

  /* ── NAV ── */
  var nav = document.querySelector('nav');
  if (nav) {
    var navLinksHTML = NAV_LINKS.map(function (l) {
      return '<a href="' + l.href + '"' + (isActive(l.href) ? ' class="active"' : '') + '>' + l.label + '</a>';
    }).join('');
    var ctaClass = isActive(CTA.href) ? 'active cta' : 'cta';
    nav.innerHTML =
      '<a class="nav-logo" href="/index.html">' +
        '<img class="nav-icon" src="/SkillVerse/logo.png" alt="Squared Studio" />' +
        '<span class="nav-title">squared-studio</span>' +
      '</a>' +
      '<div class="nav-links">' +
        navLinksHTML +
        '<a href="' + CTA.href + '" class="' + ctaClass + '">' + CTA.label + '</a>' +
      '</div>';
  }

  /* ── FOOTER ── */
  var footer = document.querySelector('footer');
  if (footer) {
    var footerLinksHTML = NAV_LINKS.concat([CTA]).map(function (l) {
      return '<a href="' + l.href + '">' + l.label + '</a>';
    }).join('');
    footer.innerHTML =
      '<div class="footer-links">' +
        footerLinksHTML +
        '<a href="https://github.com/squared-studio" target="_blank" rel="noopener">GitHub</a>' +
      '</div>' +
      '<p>Copyright &copy; 2026 <span>squared-studio</span> &mdash; All content open-source under their respective licences.</p>';
  }
})();
