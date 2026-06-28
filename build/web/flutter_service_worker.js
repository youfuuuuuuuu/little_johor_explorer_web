'use strict';
const MANIFEST = 'flutter-app-manifest';
const TEMP = 'flutter-temp-cache';
const CACHE_NAME = 'flutter-app-cache';

const RESOURCES = {"assets/AssetManifest.bin": "5994350714413fdd20c4d00ddb1077d9",
"assets/AssetManifest.bin.json": "46ada9f09acd28dee1e000d4f9edc405",
"assets/assets/fonts/NotoSans-VariableFont_wdth,wght.ttf": "b72e420edb95cdf06e6e0a27bc0d964d",
"assets/assets/images/avatars/capybara.webp": "05f0b021f24860e86d92c8ed5bd09809",
"assets/assets/images/avatars/greater_flamingo.webp": "f701e834eee67af2e1f287574ebe248b",
"assets/assets/images/avatars/malayan_tapir.webp": "894651c7f6d0331ad9d6ad61791bdeeb",
"assets/assets/images/avatars/malayan_tiger.webp": "b106e39ae891a0baba26ce693b1d7180",
"assets/assets/images/avatars/mandrill.webp": "3917b0873f1786afbcdae28a9fc45b82",
"assets/assets/images/avatars/saltwater_crocodile.webp": "4ad50522cef3a01cc84fb79bfeaa6763",
"assets/assets/images/avatars/sun_bear.webp": "dccd62f53889636c298b31281b5c52d6",
"assets/assets/images/avatars/wallaby.webp": "c728de46440ce529761eee0c6ffd1cc5",
"assets/assets/images/chingay/c1.webp": "b9245eea1cc799ea5eb9f7179b780079",
"assets/assets/images/chingay/c2.webp": "317e751d8b5c66b311ef1e3e2e62af37",
"assets/assets/images/chingay/c3.webp": "be14a3b241232d6b54386469456c54c4",
"assets/assets/images/chingay/c4.webp": "c7262d790aa37963e525776ab7ae32e4",
"assets/assets/images/chingay/c5.webp": "4ca888b494199778a7e43d58b525d699",
"assets/assets/images/chingay/c6.webp": "3725905f7e1e68fad6845330b78ac05c",
"assets/assets/images/chingay/c7.webp": "24d5c375464c7ed14794c0f81c9c9f80",
"assets/assets/images/chingay/c8.webp": "09d476faf728a80826f94f144b0ea0a3",
"assets/assets/images/johor/johor_1.webp": "dc78c69f56a9c0d8d8a85f3d4def846b",
"assets/assets/images/johor/johor_10.webp": "d3da658c3fe1f2b1a29d03106b878615",
"assets/assets/images/johor/johor_10c.webp": "dcbcd44061b316c15c9664a29ea4267c",
"assets/assets/images/johor/johor_11.webp": "755cb16a1f487a2684abfa8a2b3d73c3",
"assets/assets/images/johor/johor_12.webp": "d79bb9922b4437bf89a2c9587ac7fa92",
"assets/assets/images/johor/johor_13.webp": "76d89d5506276834001106156a1ac14b",
"assets/assets/images/johor/johor_14.webp": "587b6c695e827a98eadc572b78a69222",
"assets/assets/images/johor/johor_15.webp": "fcff0e11aecbe7d0fc0dd762cbe9d135",
"assets/assets/images/johor/johor_2.webp": "7a35df4856d073fd77cd997d0e72d70e",
"assets/assets/images/johor/johor_2c.webp": "81b035c3e0fa28acf6f76f8ace2e4287",
"assets/assets/images/johor/johor_3.webp": "6f1770927357f83285db67b2cf583773",
"assets/assets/images/johor/johor_3c.webp": "f764217456ed571c14044d9cd08e57de",
"assets/assets/images/johor/johor_4.webp": "7b4241482f0b67484e593224c80971b8",
"assets/assets/images/johor/johor_5.webp": "f0b1a18483ca382a60941b1620552f38",
"assets/assets/images/johor/johor_5c.webp": "0a6b700b858e303a738e848d6dad0ab3",
"assets/assets/images/johor/johor_6.webp": "ba93bd26d67d38e5d99fd13200d16590",
"assets/assets/images/johor/johor_7.webp": "39bac6e0d8cc956cb837baca15d602bf",
"assets/assets/images/johor/johor_7c.webp": "a56d37391a119b067f3fecfb6df71422",
"assets/assets/images/johor/johor_8.webp": "eae157bf69b45b79a6edd6989ad445f4",
"assets/assets/images/johor/johor_9.webp": "74e2bb250e92c53e162b5686b7b5654a",
"assets/assets/images/kota_jail/kj_1.webp": "1cbbca689e3d46c58746c9d88dd7b53d",
"assets/assets/images/kota_jail/kj_2.webp": "f09540624a33800239142c7a29a0bb1b",
"assets/assets/images/kota_jail/kj_3.webp": "335c89c2cf3daad6817bfe916d2eccfa",
"assets/assets/images/kota_jail/kj_4.webp": "970986d98e483036519ce19102db641e",
"assets/assets/images/kota_jail/kj_5.webp": "653f4933f7721adb0afd0d416fdfd00b",
"assets/assets/images/kota_jail/kj_6.webp": "97553d4df28311b64b59ef47f672e36d",
"assets/assets/images/kota_jail/kj_7.webp": "530c8574873ae27920b86738b2df804f",
"assets/assets/images/kota_jail/kj_8.webp": "51557987a8bccc35bc80afddc64bc571",
"assets/assets/images/kota_jail/kj_9.webp": "c6472bde7b4c201ce624128c36dfbca4",
"assets/assets/images/marteen_ke_johor_bahru/jb_1.webp": "38b47842618d320a57a97e1657372c0b",
"assets/assets/images/marteen_ke_johor_bahru/jb_2.webp": "d31ed43808559ad5c9b64a68fe9dd2f2",
"assets/assets/images/marteen_ke_johor_bahru/jb_3.webp": "cafda9ef1caa5ebec7d0990a08478bb8",
"assets/assets/images/marteen_ke_johor_bahru/jb_4.webp": "4ca6dd8ddc47f6813f3c29c29a851d6c",
"assets/assets/images/marteen_ke_johor_bahru/jb_5.webp": "a1d047432b741e7a45254073a059b1f8",
"assets/assets/images/marteen_ke_johor_bahru/jb_6.webp": "25e9ef003ccb2c3eee2b42465d20b4c6",
"assets/assets/images/marteen_ke_johor_bahru/jb_7.webp": "e70ae80aa0411f0695ab7a10660da24c",
"assets/assets/images/marteen_ke_johor_bahru/jb_8.webp": "bfa6de3a91bed153b0575aa90467b6a5",
"assets/assets/images/marteen_ke_johor_bahru/jb_9.webp": "bbece71af452f6e6e99cbc14a9d4a124",
"assets/assets/images/marteen_ke_kota_tinggi/kt_1.webp": "0d511a66430c4d5c9a8af59d317fbe81",
"assets/assets/images/marteen_ke_kota_tinggi/kt_2.webp": "18031e6fd9be4ed4f4aa4c046253f7e5",
"assets/assets/images/marteen_ke_kota_tinggi/kt_3.webp": "3c3ea171656af2b09e4ebc5e1be23b28",
"assets/assets/images/marteen_ke_kota_tinggi/kt_4.webp": "d067d040451d0a448945abd06e09d860",
"assets/assets/images/marteen_ke_kota_tinggi/kt_5.webp": "cea5e9633722daf3549ea6cdceda0d63",
"assets/assets/images/marteen_ke_kota_tinggi/kt_6.webp": "6dff24dd8308e016eaacdd0e7c782f08",
"assets/assets/images/marteen_ke_kota_tinggi/kt_7.webp": "983f72befadcd0f05c063461110dd722",
"assets/assets/images/marteen_ke_kota_tinggi/kt_8.webp": "a859a0f1dc4ee1e024f03786287c3796",
"assets/assets/images/marteen_ke_kota_tinggi/kt_9.webp": "805d697f59ba7db7b3138c648b30a8aa",
"assets/assets/images/marteen_ke_muar/muar_1.webp": "eaa4151f756a6e3410e6683b9f3afab7",
"assets/assets/images/marteen_ke_muar/muar_2.webp": "e32fd6941b6768fc9164de79abcce3c7",
"assets/assets/images/marteen_ke_muar/muar_3.webp": "29bbb110f37ade3792b5eb91a9afbb82",
"assets/assets/images/marteen_ke_muar/muar_4.webp": "41f53e9aa5d1e3f65e89540218eeae83",
"assets/assets/images/marteen_ke_muar/muar_5.webp": "18d112b1a7388b979e9ab013da9a22a5",
"assets/assets/images/marteen_ke_muar/muar_6.webp": "cf8e9ff1bb4d66ef996d0201970620dd",
"assets/assets/images/marteen_ke_muar/muar_7.webp": "e8fed9ee7d5aa03ae619d1eb4303c2e3",
"assets/assets/images/marteen_ke_muar/muar_8.webp": "3f542470b4f297ac93c61775c03f0394",
"assets/assets/images/marteen_ke_muar/muar_9.webp": "c7a1c331cabdb622060dc84e153cf699",
"assets/assets/images/masjid/m1.webp": "3083b2797500785daeb0c5609a645dbf",
"assets/assets/images/masjid/m2.webp": "4c99997b338663e1b57f394b33d97f43",
"assets/assets/images/masjid/m3.webp": "0f218f844903e15b9d9c0253c4edc733",
"assets/assets/images/masjid/m4.webp": "75962e3a1e51a31597145a86c718735f",
"assets/assets/images/masjid/m5.webp": "cfa6a00c8d3af49305fff2f21f29e3d6",
"assets/assets/images/masjid/m6.webp": "0ef7372851734a44ebd90b9c26de6611",
"assets/assets/images/masjid/m7.webp": "c4f0aec8a71506e750fb368e3fbb6a59",
"assets/assets/images/masjid/m8.webp": "1abcf02c4ac9108483c953e1765a4fee",
"assets/assets/images/masjid/m9.webp": "dc7e8383826dc99378d80bdde213a78f",
"assets/assets/images/sultan_abu_bakar/sab_1.webp": "215498949b66dc5f739847a7d1c1cba8",
"assets/assets/images/sultan_abu_bakar/sab_2.webp": "79b753cc2def6e67e07f53a73420d6e6",
"assets/assets/images/sultan_abu_bakar/sab_3.webp": "71f78766ad45a3c3e1d356b65f4d64af",
"assets/assets/images/sultan_abu_bakar/sab_4.webp": "2e7ed5388efffef414b5f02c6d540d1d",
"assets/assets/images/sultan_abu_bakar/sab_5.webp": "034dc1494ab9d57e9f521a81d89b2fda",
"assets/assets/images/sultan_abu_bakar/sab_6.webp": "9065624c50a9f0bcc3c5b34ac8ccb2c3",
"assets/assets/images/sultan_abu_bakar/sab_7.webp": "2a6a480096e04eda71fa22654f9b9722",
"assets/assets/images/sultan_abu_bakar/sab_8.webp": "ad36a48aa26b584cfe243ff1056a2191",
"assets/FontManifest.json": "6032dd37468172c5568b6b2a3578f066",
"assets/fonts/MaterialIcons-Regular.otf": "57eb8cb54e2a1748fb60812bf2ffc028",
"assets/NOTICES": "4058b22df1fac7d3f6e5ce282e20d777",
"assets/packages/cupertino_icons/assets/CupertinoIcons.ttf": "33b7d9392238c04c131b6ce224e13711",
"assets/packages/flutter_local_notifications_web/web/notifications_service_worker.js": "087634de8a8c1c49d00bcd212bf7feb4",
"assets/packages/record_web/assets/js/record.fixwebmduration.js": "1f0108ea80c8951ba702ced40cf8cdce",
"assets/packages/record_web/assets/js/record.worklet.js": "6d247986689d283b7e45ccdf7214c2ff",
"assets/shaders/ink_sparkle.frag": "ecc85a2e95f5e9f53123dcaf8cb9b6ce",
"assets/shaders/stretch_effect.frag": "40d68efbbf360632f614c731219e95f0",
"canvaskit/canvaskit.js": "8331fe38e66b3a898c4f37648aaf7ee2",
"canvaskit/canvaskit.js.symbols": "a3c9f77715b642d0437d9c275caba91e",
"canvaskit/canvaskit.wasm": "9b6a7830bf26959b200594729d73538e",
"canvaskit/chromium/canvaskit.js": "a80c765aaa8af8645c9fb1aae53f9abf",
"canvaskit/chromium/canvaskit.js.symbols": "e2d09f0e434bc118bf67dae526737d07",
"canvaskit/chromium/canvaskit.wasm": "a726e3f75a84fcdf495a15817c63a35d",
"canvaskit/skwasm.js": "8060d46e9a4901ca9991edd3a26be4f0",
"canvaskit/skwasm.js.symbols": "3a4aadf4e8141f284bd524976b1d6bdc",
"canvaskit/skwasm.wasm": "7e5f3afdd3b0747a1fd4517cea239898",
"canvaskit/skwasm_heavy.js": "740d43a6b8240ef9e23eed8c48840da4",
"canvaskit/skwasm_heavy.js.symbols": "0755b4fb399918388d71b59ad390b055",
"canvaskit/skwasm_heavy.wasm": "b0be7910760d205ea4e011458df6ee01",
"favicon.png": "5dcef449791fa27946b3d35ad8803796",
"flutter.js": "24bc71911b75b5f8135c949e27a2984e",
"flutter_bootstrap.js": "6c4efb1932de17ceed939ebc15632e44",
"icons/Icon-192.png": "ac9a721a12bbc803b44f645561ecb1e1",
"icons/Icon-512.png": "96e752610906ba2a93c65f8abe1645f1",
"icons/Icon-maskable-192.png": "c457ef57daa1d16f64b27b786ec2ea3c",
"icons/Icon-maskable-512.png": "301a7604d45b3e739efc881eb04896ea",
"index.html": "121100a1d99df08df0c0a68bf43022f1",
"/": "121100a1d99df08df0c0a68bf43022f1",
"logo.PNG": "12424bb29631c43c53ed29f7ba3f10f1",
"main.dart.js": "b0ddb568bb4f199b8fe1940bee16da79",
"manifest.json": "a54b6b171c919f7d00800ddae5b648c0",
"splash/img/dark-1x.png": "5b508038e332c9c416d05a92f1dde92a",
"splash/img/dark-2x.png": "a0697b24325d464d98699a57b219b58f",
"splash/img/dark-3x.png": "28a640f921af090179d26e62374e5e8b",
"splash/img/dark-4x.png": "f0b47d0f997927fffafdddddacff7bcd",
"splash/img/light-1x.png": "5b508038e332c9c416d05a92f1dde92a",
"splash/img/light-2x.png": "a0697b24325d464d98699a57b219b58f",
"splash/img/light-3x.png": "28a640f921af090179d26e62374e5e8b",
"splash/img/light-4x.png": "f0b47d0f997927fffafdddddacff7bcd",
"version.json": "ff908ad509154d96858c4a104812b7a9"};
// The application shell files that are downloaded before a service worker can
// start.
const CORE = ["main.dart.js",
"index.html",
"flutter_bootstrap.js",
"assets/AssetManifest.bin.json",
"assets/FontManifest.json"];

// During install, the TEMP cache is populated with the application shell files.
self.addEventListener("install", (event) => {
  self.skipWaiting();
  return event.waitUntil(
    caches.open(TEMP).then((cache) => {
      return cache.addAll(
        CORE.map((value) => new Request(value, {'cache': 'reload'})));
    })
  );
});
// During activate, the cache is populated with the temp files downloaded in
// install. If this service worker is upgrading from one with a saved
// MANIFEST, then use this to retain unchanged resource files.
self.addEventListener("activate", function(event) {
  return event.waitUntil(async function() {
    try {
      var contentCache = await caches.open(CACHE_NAME);
      var tempCache = await caches.open(TEMP);
      var manifestCache = await caches.open(MANIFEST);
      var manifest = await manifestCache.match('manifest');
      // When there is no prior manifest, clear the entire cache.
      if (!manifest) {
        await caches.delete(CACHE_NAME);
        contentCache = await caches.open(CACHE_NAME);
        for (var request of await tempCache.keys()) {
          var response = await tempCache.match(request);
          await contentCache.put(request, response);
        }
        await caches.delete(TEMP);
        // Save the manifest to make future upgrades efficient.
        await manifestCache.put('manifest', new Response(JSON.stringify(RESOURCES)));
        // Claim client to enable caching on first launch
        self.clients.claim();
        return;
      }
      var oldManifest = await manifest.json();
      var origin = self.location.origin;
      for (var request of await contentCache.keys()) {
        var key = request.url.substring(origin.length + 1);
        if (key == "") {
          key = "/";
        }
        // If a resource from the old manifest is not in the new cache, or if
        // the MD5 sum has changed, delete it. Otherwise the resource is left
        // in the cache and can be reused by the new service worker.
        if (!RESOURCES[key] || RESOURCES[key] != oldManifest[key]) {
          await contentCache.delete(request);
        }
      }
      // Populate the cache with the app shell TEMP files, potentially overwriting
      // cache files preserved above.
      for (var request of await tempCache.keys()) {
        var response = await tempCache.match(request);
        await contentCache.put(request, response);
      }
      await caches.delete(TEMP);
      // Save the manifest to make future upgrades efficient.
      await manifestCache.put('manifest', new Response(JSON.stringify(RESOURCES)));
      // Claim client to enable caching on first launch
      self.clients.claim();
      return;
    } catch (err) {
      // On an unhandled exception the state of the cache cannot be guaranteed.
      console.error('Failed to upgrade service worker: ' + err);
      await caches.delete(CACHE_NAME);
      await caches.delete(TEMP);
      await caches.delete(MANIFEST);
    }
  }());
});
// The fetch handler redirects requests for RESOURCE files to the service
// worker cache.
self.addEventListener("fetch", (event) => {
  if (event.request.method !== 'GET') {
    return;
  }
  var origin = self.location.origin;
  var key = event.request.url.substring(origin.length + 1);
  // Redirect URLs to the index.html
  if (key.indexOf('?v=') != -1) {
    key = key.split('?v=')[0];
  }
  if (event.request.url == origin || event.request.url.startsWith(origin + '/#') || key == '') {
    key = '/';
  }
  // If the URL is not the RESOURCE list then return to signal that the
  // browser should take over.
  if (!RESOURCES[key]) {
    return;
  }
  // If the URL is the index.html, perform an online-first request.
  if (key == '/') {
    return onlineFirst(event);
  }
  event.respondWith(caches.open(CACHE_NAME)
    .then((cache) =>  {
      return cache.match(event.request).then((response) => {
        // Either respond with the cached resource, or perform a fetch and
        // lazily populate the cache only if the resource was successfully fetched.
        return response || fetch(event.request).then((response) => {
          if (response && Boolean(response.ok)) {
            cache.put(event.request, response.clone());
          }
          return response;
        });
      })
    })
  );
});
self.addEventListener('message', (event) => {
  // SkipWaiting can be used to immediately activate a waiting service worker.
  // This will also require a page refresh triggered by the main worker.
  if (event.data === 'skipWaiting') {
    self.skipWaiting();
    return;
  }
  if (event.data === 'downloadOffline') {
    downloadOffline();
    return;
  }
});
// Download offline will check the RESOURCES for all files not in the cache
// and populate them.
async function downloadOffline() {
  var resources = [];
  var contentCache = await caches.open(CACHE_NAME);
  var currentContent = {};
  for (var request of await contentCache.keys()) {
    var key = request.url.substring(origin.length + 1);
    if (key == "") {
      key = "/";
    }
    currentContent[key] = true;
  }
  for (var resourceKey of Object.keys(RESOURCES)) {
    if (!currentContent[resourceKey]) {
      resources.push(resourceKey);
    }
  }
  return contentCache.addAll(resources);
}
// Attempt to download the resource online before falling back to
// the offline cache.
function onlineFirst(event) {
  return event.respondWith(
    fetch(event.request).then((response) => {
      return caches.open(CACHE_NAME).then((cache) => {
        cache.put(event.request, response.clone());
        return response;
      });
    }).catch((error) => {
      return caches.open(CACHE_NAME).then((cache) => {
        return cache.match(event.request).then((response) => {
          if (response != null) {
            return response;
          }
          throw error;
        });
      });
    })
  );
}
