// Cache only this app's assets; external fonts are optional.
const CACHE_NAME = 'git-tools-v2';
const ASSETS_TO_CACHE = ['./', './index.html', './styles.css', './app.js',
  './manifest.json', './icon-192.png', './icon-512.png'];

self.addEventListener('install', event => {
  event.waitUntil(caches.open(CACHE_NAME)
    .then(cache => cache.addAll(ASSETS_TO_CACHE))
    .then(() => self.skipWaiting()));
});
self.addEventListener('activate', event => {
  event.waitUntil(caches.keys().then(keys => Promise.all(
    keys.filter(key => key.startsWith('git-tools-') && key !== CACHE_NAME)
      .map(key => caches.delete(key))
  )).then(() => self.clients.claim()));
});
self.addEventListener('fetch', event => {
  if (event.request.method !== 'GET' ||
      new URL(event.request.url).origin !== self.location.origin) return;
  event.respondWith(caches.open(CACHE_NAME).then(async cache => {
    const cached = await cache.match(event.request);
    if (cached) return cached;
    try {
      return await fetch(event.request);
    } catch {
      if (event.request.mode === 'navigate') {
        const fallback = await cache.match('./index.html');
        if (fallback) return fallback;
      }
      return Response.error();
    }
  }));
});