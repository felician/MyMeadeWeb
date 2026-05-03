# Jurnal de Decizii (ADR Simplificat)

## [2026-04-26] Propunere soluție web: Vanilla JS PWA + ASCOM Alpaca
* **Context:** ASCOM (COM/OLE) este Windows-only și inaccesibil direct din browser. Trebuie ales un protocol de comunicare și un stack web.
* **Opțiuni:** A) Vanilla JS PWA + ASCOM Alpaca | B) React + Node.js backend | C) Vue 3 + ASCOM Alpaca
* **Decizie:** CONFIRMATĂ — Opțiunea A (Vanilla JS PWA + ASCOM Alpaca). Confirmată de utilizator pe 2026-04-26.
* **Motiv:** ASCOM Alpaca există deja în DeviceHub (zero backend de scris), nu necesită build tools, se instalează ca PWA nativ pe telefon, funcționalitatea Pascal se mapează 1:1 pe REST API.

## [2026-04-26] Comportament tracking la butoanele Service și Start
* **Context:** Montura nu poate executa SlewToAltAzAsync cu tracking activ. După slew, montura repornește automat tracking-ul.
* **Decizie:** Service oprește tracking înainte de slew și îl lasă OFF după. Start oprește tracking înainte de slew și îl repornește ON după finalizare. Ambele așteaptă finalizarea slew-ului (poll `getSlewing()` cu delay inițial de 1.5s pentru a evita race condition pe WiFi).
* **Motiv:** Service = poziție de parcare/service → tracking inutil. Start = poziție de observație → tracking necesar pentru urmărirea obiectului.

## [2026-04-26] Proxy local pentru eliminarea CORS
* **Context:** Browserul blochează cererile fetch de la `http://localhost:8000` (server static) către `http://localhost:11111` (ASCOM Alpaca) — origini diferite (porturi diferite = CORS). ASCOM Remote Server nu acceptă cereri OPTIONS (preflight), returnând eroare de protocol.
* **Opțiuni:** A) Configura CORS în ASCOM Remote Server | B) Proxy Python local care servește și fișierele statice și forwadează `/api/*` | C) Servi aplicația direct de pe portul 11111
* **Decizie:** Opțiunea B — `server.py` proxy Python pe portul 8000.
* **Motiv:** ASCOM Remote Server nu expune configurare CORS accesibilă; proxy-ul elimină problema complet fără modificări la ASCOM; zero dependențe externe (Python standard library). Cererile `/api/*` sunt interceptate de proxy și redirecționate la `http://127.0.0.1:11111` înainte să ajungă la browser — CORS nu se mai aplică.
* **Detalii implementare:** `server.py` răspunde la OPTIONS preflight local (204 + CORS headers), forwadează GET/PUT la Alpaca. `alpaca.js` detectează automat URL-ul vechi `:11111` și folosește same-origin în loc. Service Worker cache versionat (`v1→v2`) pentru a forța reload JS după modificări.

## [2026-04-26] Inițiere proiect MyTelescope
* **Context:** Aplicația Free Pascal existentă nu este accesibilă pe dispozitive mobile; se dorește portarea în web.
* **Opțiuni:** Portare completă vs wrapper/emulator Pascal în browser.
* **Decizie:** Portare completă în tehnologii web native.
* **Motiv:** Maintainability pe termen lung, performanță nativă pe mobil, fără dependențe de toolchain Pascal.
