'use strict';

const CACHE_NAME = 'focus-hub-v5';
const MAX_RETRIES = 3;
const FETCH_TIMEOUT_MS = 10000;
const RETRY_DELAY_MS = 1000;

// 1. Essential application resources.
// Installation fails if any of these cannot be cached.
const CORE_URLS = [
  '/',
  '/index.html',
  '/flutter_bootstrap.js',
  '/main.dart.js',
  '/manifest.json',
];

// 2. Optional resources.
// Each resource is cached independently.
const OPTIONAL_URLS = [
  '/favicon.png',
  '/icons/Icon-192.png',
  '/icons/Icon-512.png',
  '/assets/FontManifest.json',
  '/assets/packages/cupertino_icons/assets/CupertinoIcons.ttf',
  '/assets/fonts/MaterialIcons-Regular.otf',
  '/assets/assets/fonts/Teko-Regular.ttf'
];

// --------------------------------------------------
// Utilities: delay and retry with timeout
// --------------------------------------------------

function delay(ms) {
  return new Promise((resolve) => setTimeout(resolve, ms));
}

async function fetchWithRetry(request) {
  let lastError;

  for (let attempt = 1; attempt <= MAX_RETRIES; attempt++) {
    const controller = new AbortController();

    const timeoutId = setTimeout(
      () => controller.abort(),
      FETCH_TIMEOUT_MS
    );

    try {
      const response = await fetch(request, {
        signal: controller.signal,
      });

      if (response.ok) {
        return response;
      }

      lastError = new Error(
        `HTTP ${response.status}: ${request.url}`
      );
    } catch (error) {
      lastError = error;

      console.warn(
        `[SW] Attempt ${attempt}/${MAX_RETRIES} failed:`,
        request.url,
        error.message
      );
    } finally {
      clearTimeout(timeoutId);
    }

    if (attempt < MAX_RETRIES) {
      await delay(RETRY_DELAY_MS * attempt);
    }
  }

  throw lastError || new Error(`Fetch failed: ${request.url}`);
}

// --------------------------------------------------
// INSTALL: cache core and optional resources
// --------------------------------------------------

self.addEventListener('install', (event) => {
  event.waitUntil((async () => {
    const cache = await caches.open(CACHE_NAME);

    // Core resources must be available for installation.
    await cache.addAll(CORE_URLS);

    // Optional resources must not block one another.
    await Promise.allSettled(
      OPTIONAL_URLS.map(async (url) => {
        const request = new Request(url);
        const response = await fetchWithRetry(request);

        await cache.put(request, response);
      })
    );

    console.log('[SW] Installation caching completed.');

    await self.skipWaiting();
  })());
});

// --------------------------------------------------
// ACTIVATE: remove old caches and claim clients
// --------------------------------------------------

self.addEventListener('activate', (event) => {
  event.waitUntil((async () => {
    const cacheNames = await caches.keys();

    await Promise.all(
      cacheNames
        .filter(
          (name) =>
            name.startsWith('focus-hub-') &&
            name !== CACHE_NAME
        )
        .map((name) => caches.delete(name))
    );

    await self.clients.claim();

    console.log('[SW] Activated:', CACHE_NAME);
  })());
});

// --------------------------------------------------
// FETCH: prioritize CanvasKit, then other resources
// --------------------------------------------------

self.addEventListener('fetch', (event) => {
  const request = event.request;

  if (request.method !== 'GET') {
    return;
  }

  const url = new URL(request.url);
  // 1. Identify CanvasKit and google font resources.
  const isneeded =
    (url.hostname === 'www.gstatic.com' &&
    url.pathname.includes('/flutter-canvaskit/') &&
    (url.pathname.endsWith('/canvaskit.js') || url.pathname.endsWith('/canvaskit.wasm'))) ||
    (url.hostname === 'fonts.gstatic.com' &&
    url.pathname.endsWith('.woff2'));

  if (!isneeded) {
    return; // If the request if otherthen the canvaskit and google font it will be handle to the browser
  }
  // 2. CanvasKit and google font: cache first, then retry the network and handle Google Fonts dynamically.
  else {
    event.respondWith((async () => {
      const cache = await caches.open(CACHE_NAME);
      const cached = await cache.match(request);

      if (cached) {
        console.log('[SW] CanvasKit cache hit:', url.pathname);
        return cached;
      }

      console.log('[SW] Downloading CanvasKit:', url.pathname);

      // Register cache-writing work while handling the fetch event.
      const cacheTask = (async () => {
        try {
          const response = await fetchWithRetry(request);

          if (response.type === 'opaque') {
            return response;
          }

          const responseForPage = response.clone();

          await cache.put(request, response.clone());

          console.log('[SW] CanvasKit cached:', url.pathname);

          return responseForPage;
        } catch (error) {
          console.error(
            '[SW] CanvasKit download failed:',
            url.href,
            error
          );

          throw error;
        }
      })();

      event.waitUntil(cacheTask.then(() => undefined));

      return cacheTask;
    })());

    return;
  }

  // 3. Other resources: cache first, then network with retries.
  event.respondWith((async () => {
    const cached = await caches.match(request);

    if (cached) {
      return cached;
    }

    return fetchWithRetry(request);
  })());
});
