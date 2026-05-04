const CACHE = 'mytelescope-v1.1.6';
const ASSETS = [
  '/index.html',
  '/style.css',
  '/js/alpaca.js',
  '/js/coords.js',
  '/js/app.js',
  '/manifest.json'
];

self.addEventListener('install', e => {
  e.waitUntil(caches.open(CACHE).then(c => c.addAll(ASSETS)));
  self.skipWaiting();
});

self.addEventListener('activate', e => {
  e.waitUntil(
    caches.keys().then(keys =>
      Promise.all(keys.filter(k => k !== CACHE).map(k => caches.delete(k)))
    )
  );
  self.clients.claim();
});

// Cache-first for app assets; network-only for Alpaca API calls
self.addEventListener('fetch', e => {
  if (e.request.url.includes('/api/v1/')) return; // always live for telescope data
  e.respondWith(
    caches.match(e.request).then(cached => cached || fetch(e.request))
  );
});
