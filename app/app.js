// App Logic for Git Tools PWA

document.addEventListener('DOMContentLoaded', () => {
  // Commands generated here target POSIX shells (Git Bash / sh).
  const shellQuote = value => "'" + value.replace(/'/g, "'\"'\"'") + "'";

  // 1. Tab Navigation
  const tabBtns = document.querySelectorAll('.tab-btn');
  const tabContents = document.querySelectorAll('.tab-content');

  tabBtns.forEach(btn => {
    btn.addEventListener('click', () => {
      const tabId = btn.getAttribute('data-tab');

      tabBtns.forEach(b => b.classList.remove('active'));
      tabContents.forEach(c => c.classList.remove('active'));

      btn.classList.add('active');
      const targetContent = document.getElementById(`tab-${tabId}`);
      if (targetContent) {
        targetContent.classList.add('active');
      }
    });
  });

  // 2. Dynamic Command Builder
  const startMsg = document.getElementById('start-msg');
  const startRemote = document.getElementById('start-remote');
  const cmdStartPrev = document.getElementById('cmd-start-preview');

  function updateCmdStart() {
    const msg = startMsg.value.trim() || 'Initial commit';
    const remote = startRemote.value.trim();
    if (remote) {
      cmdStartPrev.textContent = `git start ${shellQuote(msg)} ${shellQuote(remote)}`;
    } else {
      cmdStartPrev.textContent = `git start ${shellQuote(msg)}`;
    }
  }

  if (startMsg && startRemote && cmdStartPrev) {
    startMsg.addEventListener('input', updateCmdStart);
    startRemote.addEventListener('input', updateCmdStart);
    updateCmdStart();
  }

  const releaseMsg = document.getElementById('release-msg');
  const cmdReleasePrev = document.getElementById('cmd-release-preview');

  function updateCmdRelease() {
    const msg = releaseMsg.value.trim() || 'Versión estable';
    cmdReleasePrev.textContent = `git release ${shellQuote(msg)}`;
  }

  if (releaseMsg && cmdReleasePrev) {
    releaseMsg.addEventListener('input', updateCmdRelease);
    updateCmdRelease();
  }

  const rollbackTag = document.getElementById('rollback-tag');
  const cmdRollbackPrev = document.getElementById('cmd-rollback-preview');

  function updateCmdRollback() {
    const tag = rollbackTag.value.trim();
    if (tag) {
      cmdRollbackPrev.textContent = `git rollback ${shellQuote(tag)}`;
    } else {
      cmdRollbackPrev.textContent = `git rollback`;
    }
  }

  if (rollbackTag && cmdRollbackPrev) {
    rollbackTag.addEventListener('input', updateCmdRollback);
  }

  // 3. Copy to Clipboard & Toast System
  const toast = document.getElementById('toast');

  function showToast(message) {
    toast.textContent = message;
    toast.classList.remove('hidden');
    setTimeout(() => {
      toast.classList.add('hidden');
    }, 2000);
  }

  document.body.addEventListener('click', async (e) => {
    const btn = e.target.closest('.copy-btn');
    if (!btn) return;

    let textToCopy = '';
    const targetId = btn.getAttribute('data-target');
    const directText = btn.getAttribute('data-text');

    if (targetId) {
      const elem = document.getElementById(targetId);
      if (elem) textToCopy = elem.textContent;
    } else if (directText) {
      textToCopy = directText;
    }

    if (textToCopy) {
      try {
        await navigator.clipboard.writeText(textToCopy);
        showToast('Copiado al portapapeles 🚀');
      } catch {
        // Fallback for older browsers
        const textarea = document.createElement('textarea');
        textarea.value = textToCopy;
        document.body.appendChild(textarea);
        textarea.select();
        let copied = false;
        try { copied = document.execCommand('copy'); } catch { /* Manual copy remains available. */ }
        document.body.removeChild(textarea);
        showToast(copied ? 'Copiado al portapapeles 🚀' : 'No se pudo copiar. Seleccioná el comando manualmente.');
      }
    }
  });

  // 4. PWA Installation Event
  let deferredPrompt;
  const installBtn = document.getElementById('pwa-install-btn');

  window.addEventListener('beforeinstallprompt', (e) => {
    e.preventDefault();
    deferredPrompt = e;
    if (installBtn) {
      installBtn.classList.remove('hidden');
    }
  });

  if (installBtn) {
    installBtn.addEventListener('click', async () => {
      if (!deferredPrompt) return;
      deferredPrompt.prompt();
      const { outcome } = await deferredPrompt.userChoice;
      if (outcome === 'accepted') {
        installBtn.classList.add('hidden');
      }
      deferredPrompt = null;
    });
  }

  // 5. Offline Status Detector
  const offlineBanner = document.getElementById('offline-banner');
  function updateOnlineStatus() {
    if (!navigator.onLine) {
      offlineBanner.classList.remove('hidden');
    } else {
      offlineBanner.classList.add('hidden');
    }
  }

  window.addEventListener('online', updateOnlineStatus);
  window.addEventListener('offline', updateOnlineStatus);
  updateOnlineStatus();

  // 6. Service Worker Registration
  if ('serviceWorker' in navigator) {
    navigator.serviceWorker.register('sw.js')
      .then(reg => console.log('Service Worker registrado:', reg.scope))
      .catch(err => console.log('Error registrando Service Worker:', err));
  }
});
