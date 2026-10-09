// RadRecon - Main JavaScript

document.addEventListener('DOMContentLoaded', () => {
  // Mobile Menu Toggle
  const toggleBtn = document.querySelector('.mobile-menu-toggle');
  const nav = document.querySelector('nav');

  if (toggleBtn && nav) {
    toggleBtn.addEventListener('click', (e) => {
      e.stopPropagation();
      const isActive = nav.classList.toggle('active');
      toggleBtn.classList.toggle('active');
      toggleBtn.setAttribute('aria-expanded', isActive ? 'true' : 'false');
    });

    // Close menu when clicking outside
    document.addEventListener('click', (e) => {
      if (!nav.contains(e.target) && !toggleBtn.contains(e.target)) {
        nav.classList.remove('active');
        toggleBtn.classList.remove('active');
        toggleBtn.setAttribute('aria-expanded', 'false');
      }
    });

    // Close menu when clicking any nav link
    nav.querySelectorAll('a').forEach(link => {
      link.addEventListener('click', () => {
        nav.classList.remove('active');
        toggleBtn.classList.remove('active');
        toggleBtn.setAttribute('aria-expanded', 'false');
      });
    });
  }
  // Coming-soon modal for download buttons
  const modal = document.getElementById('coming-soon-modal');
  if (modal) {
    let lastFocus = null;
    const openModal = (trigger) => {
      lastFocus = trigger;
      modal.hidden = false;
      document.body.style.overflow = 'hidden';
      const first = modal.querySelector('.btn');
      if (first) first.focus();
    };
    const closeModal = () => {
      modal.hidden = true;
      document.body.style.overflow = '';
      if (lastFocus) lastFocus.focus();
    };
    document.querySelectorAll('[data-coming-soon]').forEach((el) => {
      el.addEventListener('click', (e) => {
        e.preventDefault();
        openModal(el);
      });
    });
    modal.querySelectorAll('[data-modal-close]').forEach((b) => b.addEventListener('click', closeModal));
    modal.addEventListener('click', (e) => {
      if (e.target === modal) closeModal();
    });
    document.addEventListener('keydown', (e) => {
      if (e.key === 'Escape' && !modal.hidden) closeModal();
    });
  }
  // Contributors list, rendered from the shared contributors.json
  const contribSection = document.getElementById('contributors');
  const contribList = document.getElementById('contributors-list');
  if (contribSection && contribList && window.fetch) {
    const d = contribSection.dataset;
    const roleLabel = (r) => d['role' + r.charAt(0).toUpperCase() + r.slice(1)] || r;
    const safeUrl = (u) => (typeof u === 'string' && /^https?:\/\//i.test(u) ? u : null);
    const renderGroup = (title, items) => {
      if (!Array.isArray(items)) return null;
      const valid = items.filter((c) => c && typeof c.name === 'string' && c.name.trim());
      if (!valid.length) return null;
      const wrap = document.createElement('div');
      const h = document.createElement('h3');
      h.textContent = title;
      const ul = document.createElement('ul');
      valid.forEach((c) => {
        const li = document.createElement('li');
        const url = safeUrl(c.url);
        if (url) {
          const a = document.createElement('a');
          a.href = url;
          a.rel = 'noopener nofollow';
          a.target = '_blank';
          a.textContent = c.name.trim();
          li.appendChild(a);
        } else {
          li.appendChild(document.createTextNode(c.name.trim()));
        }
        const meta = [];
        if (typeof c.organization === 'string' && c.organization.trim()) meta.push(c.organization.trim());
        if (Array.isArray(c.roles)) c.roles.filter((r) => typeof r === 'string').forEach((r) => meta.push(roleLabel(r)));
        if (meta.length) {
          const m = document.createElement('span');
          m.className = 'contrib-meta';
          m.textContent = meta.join(' \u00b7 ');
          li.appendChild(m);
        }
        ul.appendChild(li);
      });
      wrap.appendChild(h);
      wrap.appendChild(ul);
      return wrap;
    };
    fetch('../contributors.json', { cache: 'no-cache' })
      .then((r) => (r.ok ? r.json() : Promise.reject(new Error('http'))))
      .then((data) => {
        const groups = [renderGroup(d.orgs, data.organizations), renderGroup(d.people, data.people)].filter(Boolean);
        if (!groups.length) return;
        contribList.textContent = '';
        groups.forEach((g) => contribList.appendChild(g));
      })
      .catch(() => {});
  }
});