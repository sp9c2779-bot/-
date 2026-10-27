const CACHE='shot-note-19',TILES='shot-note-tiles';
const FILES=['./','./index.html','./assets-1.json?v=16','./assets-2.json?v=16'];
// Unchanged map data is copied from the previous version's cache instead of downloading 29MB again.
self.addEventListener('install',e=>{e.waitUntil(caches.open(CACHE).then(c=>Promise.all(FILES.map(f=>(f.includes('assets-')?caches.match(f):Promise.resolve(null)).then(r=>r||fetch(f,{cache:'reload'})).then(r=>{if(!r.ok)throw Error(f);return c.put(f,r);})))).then(()=>self.skipWaiting()));});
self.addEventListener('activate',e=>{e.waitUntil(caches.keys().then(keys=>Promise.all(keys.filter(k=>k!==CACHE&&k!==TILES).map(k=>caches.delete(k)))).then(()=>self.clients.claim()));});
self.addEventListener('fetch',e=>{const u=new URL(e.request.url);if(e.request.method!=='GET')return;
  if(u.hostname==='cyberjapandata.gsi.go.jp'){e.respondWith(caches.open(TILES).then(c=>c.match(u.href)).then(r=>r||fetch(e.request)));return;}
  if(u.origin!==location.origin)return;e.respondWith(caches.match(e.request,{ignoreSearch:e.request.mode==='navigate'}).then(r=>r||fetch(e.request)));});