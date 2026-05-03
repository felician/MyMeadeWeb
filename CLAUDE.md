# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.
Always respond in romanian language

## Project Overview

MyTelescope is a **Progressive Web App** (PWA) for controlling motorized telescope mounts over WiFi via the [ASCOM Alpaca REST API](https://ascom-standards.org/api/). It ports a Free Pascal/Lazarus desktop app to a mobile-friendly web app. Documentation files (README.md, decizii.md, log.md, tasks.md) are in Romanian.

## Running Locally

No build step — serve `mytelescope-web/` as static files:

```bash
cd mytelescope-web
python -m http.server 8000
# or: npx http-server -p 8000
```

Then open `http://localhost:8000`. The app connects to an ASCOM Alpaca server (default `http://localhost:11111`), configurable in the Settings panel (persisted via `localStorage`).

**CORS:** The Alpaca server (ASCOM DeviceHub) must allow the web app's origin. Configure this in DeviceHub → Settings → Enable Alpaca Remote Server.

## Architecture

All production code lives in `mytelescope-web/`:

```
index.html          — UI: 4 panels (Main, GoTo, Properties, Settings)
style.css           — Mobile dark theme (dark red/orange astronomy palette)
manifest.json       — PWA metadata
sw.js               — Service Worker: cache-first for UI assets, network-only for /api/*
js/
  app.js            — Application state, polling loop, slew/goto commands, event wiring
  alpaca.js         — Thin ASCOM Alpaca REST wrapper (all fetch calls live here)
  coords.js         — Coordinate conversions: RA/Dec/Az/Alt ↔ HMS/DMS strings
```

### Data flow

1. `app.js` calls `alpaca.js` functions → HTTP GET/PUT to Alpaca server at `http://<host>:11111/api/v1/telescope/0/<property>`
2. A 1.5-second polling loop in `app.js` refreshes RA, Dec, Az, Alt, tracking state, and slew state
3. `coords.js` formats raw decimal degrees / decimal hours into display strings (e.g. `12h 34m 56.7s`)
4. All persistent user settings (server URL, slew rate, button labels/targets, scale) are stored in `localStorage` with the `mt_` prefix

### Key state object (`app.js`)

```js
const state = {
  connected, tracking, slewing, parked,
  ra, dec, az, alt,          // current telescope coordinates (decimals)
  slewRate,                  // degrees, 1–10
  scara,                     // 1 = normal (1°), 60 = fine (1′)
  serviceLabel, startLabel,  // quick-goto button labels
  serviceAz, serviceAlt,     // quick-goto button targets (degrees)
  startAz, startAlt,
  timer                      // setInterval handle for polling
};
```

### Alpaca API conventions (`alpaca.js`)

- All endpoints: `/api/v1/telescope/0/<property>`
- GET properties return `{ Value: ..., ErrorNumber: 0 }`
- PUT actions send form-encoded body with `ClientID=1&ClientTransactionID=<n>&<params>`
- `alpaca.js` exports named async functions; `app.js` imports them via ES module `import`

## Reference Material

`resurse/` contains the original Pascal source (`src-pascal/`) and analysis docs:
- `analiza_pascal.md` — maps Pascal forms/units to web equivalents
- `propuneri_web.md` — 3 evaluated architecture options (Vanilla PWA chosen)
