# Propuneri Soluție Web — MyTelescope

**Data:** 2026-04-26
**Bazat pe:** analiza_pascal.md

---

## Problema centrală: ASCOM → Web

ASCOM folosește COM/OLE (Windows). O aplicație web **nu poate apela direct ASCOM**.

**Soluție standard în industrie:** **ASCOM Alpaca** — extensia REST/HTTP a ASCOM, disponibilă în ASCOM 6.5+ și în ASCOM DeviceHub. Expune același API al telescopului prin HTTP local:

```
GET  http://localhost:11111/api/v1/telescope/0/rightascension
PUT  http://localhost:11111/api/v1/telescope/0/slewtocoordinatesasync
```

Alpaca este deja instalat dacă există ASCOM DeviceHub pe PC → **zero effort** pe backend.

---

## Opțiunea A — PWA + ASCOM Alpaca (RECOMANDAT)

### Arhitectură
```
[Telefon/Tabletă] ←WiFi→ [PC observator]
     |                          |
  Web App (HTML/JS)      ASCOM DeviceHub
  (PWA, instalabil)      + Alpaca Server
                               |
                         Telescope Driver
                               |
                           Montura
```

### Stack tehnic
- **Frontend:** HTML5 + CSS3 + Vanilla JavaScript (ES2022)
- **Nicio dependență npm**, niciun build tool, niciun framework
- **PWA** cu `manifest.json` + Service Worker → instalabil pe home screen iOS/Android
- **Comunicare:** `fetch()` → ASCOM Alpaca REST API (localhost sau IP local)
- **Polling:** `setInterval` la 1-2s pentru refresh coordonate (identic cu `tmrAscomTimer`)

### Structura fișierelor
```
mytelescope-web/
├── index.html          — UI principal
├── app.js              — logica principală
├── alpaca.js           — wrapper ASCOM Alpaca API
├── coords.js           — formatare RA/Dec/Az/Alt, julian date
├── style.css           — UI mobil responsive
├── manifest.json       — PWA manifest
└── sw.js               — service worker (offline support)
```

### Pro
✅ Zero backend de scris — Alpaca există deja  
✅ Niciun framework, niciun build tool, niciun npm  
✅ Funcționează pe orice browser modern (iOS Safari, Android Chrome)  
✅ Instalabil ca PWA direct pe home screen  
✅ Portare 1:1 a funcționalității Pascal  
✅ Ușor de întreținut și extins  
✅ Offline-capable pentru UI (fără date live)  

### Contra
⚠️ Necesită activare Alpaca în ASCOM DeviceHub (1 click în settings)  
⚠️ CORS: Alpaca trebuie configurat să permită originea web app-ului  
⚠️ Nu funcționează fără conexiune WiFi la PC-ul cu telescopul  

---

## Opțiunea B — React SPA + Node.js backend

### Arhitectură
```
[Telefon] ←WiFi→ [Node.js server pe PC] ←COM→ [ASCOM]
```

### Stack tehnic
- Frontend: React + Tailwind CSS
- Backend: Node.js + Express + `node-ascom` sau apel shell la PowerShell

### Pro
✅ Structură modernă, bine-known  
✅ Componentizare bună pentru UI complex  

### Contra
❌ Necesită backend custom scris și întreținut  
❌ node-ascom nu este oficial, puțin documentat  
❌ Build step (npm run build) — overhead pentru un proiect personal  
❌ Over-engineering pentru funcționalitatea existentă  

---

## Opțiunea C — Vue 3 + ASCOM Alpaca

### Stack tehnic
- Frontend: Vue 3 (Composition API) + Vite
- Backend: ASCOM Alpaca (identic cu Opțiunea A)

### Pro
✅ Reactivity nativă pentru coordonate în timp real  
✅ Sintaxă clară, template-uri curate  

### Contra
⚠️ Necesită npm + Vite (build tool)  
⚠️ Overkill pentru complexitatea actuală a UI-ului  
⚠️ Bundle size mai mare față de Vanilla JS  

---

## Comparație finală

| Criteriu | A: Vanilla PWA + Alpaca | B: React + Node.js | C: Vue + Alpaca |
|----------|------------------------|-------------------|-----------------|
| Backend de scris | ❌ Zero | ✅ Da | ❌ Zero |
| Build tools | ❌ Nu | ✅ npm/webpack | ✅ npm/Vite |
| Ușurință portare | ⭐⭐⭐ | ⭐⭐ | ⭐⭐ |
| Mentenanță | ⭐⭐⭐ | ⭐ | ⭐⭐ |
| Instalabil mobil | ⭐⭐⭐ PWA | ⭐ Nu nativ | ⭐⭐ PWA posibil |
| Performanță mobil | ⭐⭐⭐ | ⭐⭐ | ⭐⭐ |
| Complexitate setup | ⭐⭐⭐ Minim | ⭐ Mare | ⭐⭐ Mediu |

---

## Recomandare finală: **Opțiunea A**

**Vanilla JS PWA + ASCOM Alpaca** este soluția optimă pentru că:

1. **ASCOM Alpaca este deja disponibil** pe PC-ul cu DeviceHub — zero efort de backend
2. **Funcționalitatea Pascal se mapează 1:1** pe Alpaca REST API — aceleași proprietăți, același model de date
3. **Fără build tools** — editezi un fișier `.js` și reîmprospătezi browserul, util pe teren
4. **PWA** = funcționează exact ca o aplicație nativă pe telefon/tabletă, instalabilă pe home screen
5. Codul Pascal este simplu (~700 linii logică reală) — nu justifică un framework

### Pași de implementare propuși (după decizie)
1. Activare ASCOM Alpaca în DeviceHub (Settings → Enable Alpaca)
2. Creare `alpaca.js` — wrapper fetch pentru toate endpoint-urile folosite
3. Creare `index.html` — layout mobil cu butoanele din frmMain
4. Creare `app.js` — timer refresh + event handlers
5. Creare `coords.js` — port funcții RAstringformat, DECstringformat, julian_calc
6. Creare `manifest.json` + `sw.js` → PWA
7. Testare pe telefon în WiFi local
