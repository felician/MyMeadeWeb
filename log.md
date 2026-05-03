# Log de Proiect

| Data/Ora        | Activitate | Rezultat/Blocaj | Next Step   |
| --------------- | ---------- | --------------- | ----------- |
| 2026-04-26      | Init       | Proiect creat   | Analiza cod Pascal sursă |
| 2026-04-26      | Analiză sursă Pascal | 4 forms, 7 fișiere .pas analizate; funcționalitate complet documentată | Decizie stack web |
| 2026-04-26      | Propuneri web | 3 opțiuni documentate; recomandare: Vanilla JS PWA + ASCOM Alpaca | Review și decizie finală |
| 2026-04-26      | Decizie stack | Opțiunea A confirmată: Vanilla JS PWA + ASCOM Alpaca | Implementare |
| 2026-04-26      | Implementare v1 | 7 fișiere create în mytelescope-web/; UI complet, PWA ready | Test pe teren cu telescop |
| 2026-04-26      | Activare ASCOM Alpaca | ASCOM Remote Server pornit; ascultă pe http://127.0.0.1:11111 | Rezolvare CORS |
| 2026-04-26      | Rezolvare CORS + proxy | Creat `server.py` — proxy Python care servește static files și forwadează `/api/*` → portul 11111; eliminat CORS complet | Rezolvare cache Service Worker |
| 2026-04-26      | Fix Service Worker cache | Versiune cache incrementată `v1→v2`; fix `alpaca.js` detectează automat URL vechi `:11111` | Test conexiune |
| 2026-04-26      | Test conexiune reușit | Connect funcțional; aplicația comunică cu ASCOM Remote prin proxy | Test pe teren cu telescop real |
| 2026-04-26      | Logică butoane Service/Start | Service: tracking off → slew → tracking rămâne off; Start: tracking off → slew → tracking on; delay 1.5s înainte de poll slewing (fix timing WiFi) | UI tracking |
| 2026-04-26      | Auto-connect la pornire | Aplicația verifică automat starea ASCOM la încărcare; dacă telescopul e deja conectat intră direct în stare activă (util pentru acces multi-dispozitiv) | Design UI |
| 2026-04-26      | Checkbox Tracking + redesign UI | Adăugat toggle Tracking în rândul de slew (dreapta sliderului); Normal/Fine mutat în stânga sliderului cu text Slew Normal/Slew Fine; valoare slider afișată deasupra | Design final |
| 2026-04-26      | Design header și culori v1.0.14 | Titlu: Meade 16 (verde, bold) + v1.0.* (verde) + Felician Ursache ©2026 (estompat); Tracking mereu verde; butoane Service/Start/Properties/Settings font mai mare; Settings mereu activ | Testare pe teren |
