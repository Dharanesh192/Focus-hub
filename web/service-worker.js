// ─────────────────────────────────────────────
// Focus Hub — Service Worker
// Handles: Offline caching + Push notifications
// ─────────────────────────────────────────────

const CACHE_NAME = 'focus-hub-v2';

const CACHE_URLS = [
  // Source code of the app
  '/',
  '/index.html',
  '/flutter_bootstrap.js',
  '/main.dart.js',
  '/manifest.json',
  '/favicon.png',
  '/icons/Icon-192.png',
  '/icons/Icon-512.png',
  // Font configuration and Icons
  '/assets/FontManifest.json',
  '/assets/packages/cupertino_icons/assets/CupertinoIcons.ttf',
  '/assets/fonts/MaterialIcons-Regular.otf',
  '/assets/assets/fonts/Teko-Regular.ttf'
];

// ─── INSTALL ──────────────────────────────────
self.addEventListener('install', (event) => {
  console.log('[SW] Installing...');
  event.waitUntil(
    caches.open(CACHE_NAME).then((cache) => {
      console.log('[SW] Caching app shell');
      return cache.addAll(CACHE_URLS);
    })
  );
  self.skipWaiting();
});

// ─── ACTIVATE ─────────────────────────────────
self.addEventListener('activate', (event) => {
  console.log('[SW] Activating...');
  event.waitUntil(
    caches.keys().then((cacheNames) => {
      return Promise.all(
        cacheNames
          .filter((name) => name !== CACHE_NAME)
          .map((name) => {
            console.log('[SW] Deleting old cache:', name);
            return caches.delete(name);
          })
      );
    })
  );
  self.clients.claim();
});

// ─── FETCH ────────────────────────────────────
self.addEventListener('fetch', (event) => {
  event.respondWith(
    caches.match(event.request).then((cached) => {
      return cached || fetch(event.request);
    })
  );
});
