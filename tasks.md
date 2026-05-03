# Task Management

## Backlog
- [ ] Activare ASCOM Alpaca în DeviceHub (Settings → Enable Alpaca)
- [ ] Creare `alpaca.js` — wrapper fetch pentru endpoint-urile Alpaca
- [ ] Creare `index.html` — layout mobil responsive (butoane direcționale, status, labels)
- [ ] Creare `app.js` — timer refresh 1-2s + event handlers butoane
- [ ] Creare `coords.js` — port funcții RAstringformat, DECstringformat, julian_calc, delta_T
- [ ] Dialog Go-To (RA/Dec + Az/Alt cu input DMS)
- [ ] Pagina Properties (afișare info driver ASCOM)
- [ ] Pagina Settings (redenumire butoane, slew rate)
- [ ] Creare `manifest.json` + `sw.js` → PWA instalabil
- [ ] Testare pe telefon/tabletă în WiFi local
- [ ] Deploy / hosting local sau GitHub Pages

## Next
- [ ] Adăugare icoane PWA reale (192x192, 512x512 .png)
- [ ] Test complet pe teren cu telescopul real

## Doing
- [ ]

## Done
- [x] Inițiere proiect 2026-04-26
- [x] Analiză cod sursă Pascal (2026-04-26) → resurse/analiza_pascal.md
- [x] Creare propuneri soluție web (2026-04-26) → resurse/propuneri_web.md
- [x] Decizie stack confirmată: Vanilla JS PWA + ASCOM Alpaca (2026-04-26)
- [x] Implementare completă aplicație web (2026-04-26)
  - [x] js/alpaca.js — wrapper ASCOM Alpaca REST API
  - [x] js/coords.js — formatare RA/Dec/Az/Alt, conversii DMS
  - [x] js/app.js — logică principală + polling 1.5s
  - [x] index.html — UI mobil complet (4 panouri)
  - [x] style.css — dark astronomy theme, touch-friendly
  - [x] manifest.json + sw.js — PWA instalabil
- [x] Activare ASCOM Remote Server (2026-04-26) — ascultă pe http://127.0.0.1:11111
- [x] Rezolvare CORS (2026-04-26)
  - [x] Creat server.py — proxy Python (static files + /api/* → port 11111)
  - [x] Adăugat handler OPTIONS preflight în proxy
  - [x] Fix alpaca.js — detectează automat URL vechi :11111, folosește same-origin
  - [x] Fix app.js — saveSettings salvează corect și URL gol
  - [x] Fix sw.js — cache v1→v2, forțează reload fișiere JS actualizate
- [x] Test conexiune reușit (2026-04-26) — Connect funcțional prin proxy
- [x] Logică avansată butoane Service/Start (2026-04-26)
  - [x] Service: oprește tracking → slew AzAlt → așteaptă finalul → tracking rămâne OFF
  - [x] Start: oprește tracking → slew AzAlt → așteaptă finalul → repornește tracking ON
  - [x] Delay 1.5s post-slew înainte de poll (fix race condition WiFi)
  - [x] Poll silențios la AbortError/TimeoutError (fără notificare utilizator)
- [x] Auto-connect la pornire (2026-04-26) — detectează dacă telescopul e deja conectat în ASCOM
- [x] Checkbox Tracking + redesign rând slew (2026-04-26)
  - [x] Toggle Tracking în dreapta sliderului (verde permanent)
  - [x] Toggle Slew Normal/Fine mutat în stânga sliderului
  - [x] Valoare slider (°/') afișată deasupra sliderului
- [x] Design v1.0.14 (2026-04-26)
  - [x] Titlu: Meade 16 bold verde + versiune verde + copyright estompat
  - [x] Tracking label mereu verde
  - [x] Slew Normal/Fine text vizibil (ne-estompat)
  - [x] Font mai mare pentru Service, Start, Properties, Settings
  - [x] Properties dezactivat la disconnect; Settings mereu activ
