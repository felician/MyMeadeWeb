'use strict';

const App = (() => {
  // Limits ported from Pascal constants
  const MIN_DEC = -22;
  const MAX_DEC = 72;
  const MIN_ALT = 0;

  const state = {
    connected:    false,
    tracking:     false,
    slewing:      false,
    parked:       false,
    ra:  null, dec: null, az:  null, alt: null,
    slewRate:     parseInt(localStorage.getItem('mt_slewRate')  || '20'),
    fineMode:     localStorage.getItem('mt_fineMode') === 'true',
    serviceLabel: localStorage.getItem('mt_svcLabel')   || 'Service',
    startLabel:   localStorage.getItem('mt_startLabel') || 'Start',
    serviceAz:    220, serviceAlt: 15,
    startAz:      160, startAlt:   60,
    timer:        null
  };

  // ── DOM helpers ────────────────────────────────────────────────
  const el   = (id) => document.getElementById(id);
  const btn  = (id) => el(id);

  function showError(msg) {
    const bar = el('errorBar');
    bar.textContent = '⚠ ' + msg;
    bar.style.display = 'block';
    clearTimeout(bar._t);
    bar._t = setTimeout(() => { bar.style.display = 'none'; }, 5000);
  }

  // ── Display updates ────────────────────────────────────────────
  function updateCoords() {
    el('lblRA').textContent  = 'α  ' + Coords.raToStr(state.ra);
    el('lblDec').textContent = 'δ  ' + Coords.decToStr(state.dec);
    el('lblAz').textContent  = 'Az ' + Coords.azToStr(state.az);
    el('lblAlt').textContent = 'Alt' + Coords.decToStr(state.alt);
  }

  function updateStatus() {
    const dot = el('statusDot');
    const txt = el('statusText');
    const trkChk = el('trackingToggle');

    el('btnConnect').textContent = state.connected ? 'Disconnect' : 'Connect';
    el('btnPark').textContent    = state.parked     ? 'Unpark'     : 'Park';

    trkChk.disabled = !state.connected || state.parked || state.slewing;
    trkChk.checked  = state.tracking;

    if (!state.connected) {
      dot.className = 'dot disconnected'; txt.textContent = 'DISCONNECTED';
    } else if (state.parked) {
      dot.className = 'dot parked';       txt.textContent = 'PARKED';
    } else if (state.slewing) {
      dot.className = 'dot slewing';      txt.textContent = 'SLEWING…';
    } else {
      dot.className = 'dot connected';    txt.textContent = 'CONNECTED';
    }
  }

  function updateButtons() {
    const active = state.connected && !state.parked && !state.slewing;
    ['btnUp','btnDown','btnLeft','btnRight','btnGoto','btnService','btnStart']
      .forEach(id => { if (btn(id)) btn(id).disabled = !active; });
    if (btn('btnPark'))       btn('btnPark').disabled       = !state.connected;
    if (btn('btnAbort'))      btn('btnAbort').disabled      = !state.slewing;
    if (btn('btnProperties')) btn('btnProperties').disabled = !state.connected;
  }

  function updateSlewDisplay() {
    el('slewRateVal').textContent = state.slewRate + (state.fineMode ? "'" : '°');
    el('scaleLabel').textContent  = state.fineMode ? 'Slew Fine' : 'Slew Normal';
    el('scaleToggle').checked     = state.fineMode;
    el('slewRateSlider').value    = state.slewRate;
  }

  // ── Polling ────────────────────────────────────────────────────
  async function poll() {
    if (!state.connected) return;
    try {
      if (state.parked) {
        const parked = await Alpaca.getAtPark();
        if (!parked) {
          state.parked = false;
          updateStatus();
          updateButtons();
        }
        return;
      }
      const [ra, dec, az, alt, parked, tracking, slewing] = await Promise.all([
        Alpaca.getRa(), Alpaca.getDec(), Alpaca.getAz(), Alpaca.getAlt(),
        Alpaca.getAtPark(), Alpaca.getTracking(), Alpaca.getSlewing()
      ]);
      Object.assign(state, { ra, dec, az, alt, parked, tracking, slewing });
      updateCoords();
      updateStatus();
      updateButtons();
    } catch (e) {
      if (e.name !== 'AbortError' && e.name !== 'TimeoutError') {
        showError('Poll: ' + e.message);
      }
    }
  }

  function startTimer() {
    stopTimer();
    poll();
    state.timer = setInterval(poll, 1500);
  }

  function stopTimer() {
    if (state.timer) { clearInterval(state.timer); state.timer = null; }
  }

  // ── Connect / Disconnect ───────────────────────────────────────
  async function toggleConnect() {
    btn('btnConnect').disabled = true;
    try {
      if (!state.connected) {
        await Alpaca.connect();
        state.connected = true;
        startTimer();
      } else {
        stopTimer();
        try { await Alpaca.abortSlew(); } catch {}
        await Alpaca.disconnect();
        Object.assign(state, {
          connected: false, ra: null, dec: null, az: null, alt: null,
          tracking: false, slewing: false, parked: false
        });
        updateCoords();
        updateStatus();
        updateButtons();
      }
    } catch (e) {
      showError('Connect: ' + e.message);
    }
    btn('btnConnect').disabled = false;
  }

  // ── Slew helpers ───────────────────────────────────────────────
  async function slewStep(dra, ddec) {
    if (!state.connected || state.slewing || state.parked) return;
    if (state.ra == null) return;
    const step   = state.fineMode ? state.slewRate / 60 : state.slewRate;
    let   newRa  = state.ra  + dra  * step / 15;   // degrees → RA hours
    let   newDec = state.dec + ddec * step;
    if (newRa >= 24) newRa -= 24;
    if (newRa <  0)  newRa += 24;
    newDec = Math.max(MIN_DEC, Math.min(MAX_DEC, newDec));
    try { await Alpaca.slewToRaDec(newRa, newDec); } catch (e) { showError(e.message); }
  }

  async function doGoto(mode, vals) {
    if (!state.connected || state.parked) return;
    try {
      if (mode === 'radec') {
        const dec = Math.max(MIN_DEC, Math.min(MAX_DEC, vals.dec));
        await Alpaca.slewToRaDec(vals.ra, dec);
      } else {
        const alt = Math.max(MIN_ALT, Math.min(90, vals.alt));
        await Alpaca.slewToAzAlt(vals.az, alt);
      }
    } catch (e) { showError(e.message); }
  }

  async function doAbort() {
    try { await Alpaca.abortSlew(); } catch (e) { showError(e.message); }
  }

  async function doPark() {
    if (!state.connected) return;
    try {
      await Alpaca.park();
      stopTimer();
      try { await Alpaca.disconnect(); } catch {}
      Object.assign(state, {
        connected: false, ra: null, dec: null, az: null, alt: null,
        tracking: false, slewing: false, parked: false
      });
      updateCoords();
      updateStatus();
      updateButtons();
    } catch (e) { showError(e.message); }
  }

  // ── Panels ─────────────────────────────────────────────────────
  function showPanel(id) {
    document.querySelectorAll('.panel').forEach(p => p.classList.remove('active'));
    el(id).classList.add('active');
  }

  // ── GoTo panel ─────────────────────────────────────────────────
  function populateGotoFields() {
    if (state.ra != null) {
      const r = Coords.raToHMSParts(state.ra);
      el('RAh').value = r.h; el('RAm').value = r.m; el('RAs').value = r.s;
    }
    if (state.dec != null) {
      const d = Coords.decToDMSParts(state.dec);
      el('Decd').value = d.d; el('Decm').value = d.m; el('Decs').value = d.s;
    }
    if (state.az != null) {
      const a = Coords.decToDMSParts(state.az);
      el('Azd').value = a.d; el('Azm').value = a.m; el('Azs').value = a.s;
    }
    if (state.alt != null) {
      const a = Coords.decToDMSParts(state.alt);
      el('Altd').value = a.d; el('Altm').value = a.m; el('Alts').value = a.s;
    }
    refreshGotoDecimal();
    refreshAzAltDecimal();
  }

  function refreshGotoDecimal() {
    const ra  = Coords.hmsToDecimal(
      el('RAh').value, el('RAm').value, el('RAs').value);
    const dec = Coords.dmsToDecimal(
      el('Decd').value, el('Decm').value, el('Decs').value);
    el('displayRA').textContent  = ra.toFixed(6)  + ' h';
    el('displayDec').textContent = dec.toFixed(6) + ' °';
  }

  function refreshAzAltDecimal() {
    const az  = Coords.dmsToDecimal(
      el('Azd').value,  el('Azm').value,  el('Azs').value);
    const alt = Coords.dmsToDecimal(
      el('Altd').value, el('Altm').value, el('Alts').value);
    el('displayAz').textContent  = az.toFixed(6)  + ' °';
    el('displayAlt').textContent = alt.toFixed(6) + ' °';
  }

  function executeGotoRaDec() {
    const ra  = Coords.hmsToDecimal(
      el('RAh').value, el('RAm').value, el('RAs').value);
    const dec = Coords.dmsToDecimal(
      el('Decd').value, el('Decm').value, el('Decs').value);
    doGoto('radec', { ra, dec });
    showPanel('mainPanel');
  }

  function executeGotoAzAlt() {
    const az  = Coords.dmsToDecimal(
      el('Azd').value, el('Azm').value, el('Azs').value);
    const alt = Coords.dmsToDecimal(
      el('Altd').value, el('Altm').value, el('Alts').value);
    doGoto('azalt', { az, alt });
    showPanel('mainPanel');
  }

  // ── Properties panel ───────────────────────────────────────────
  async function openProperties() {
    showPanel('propPanel');
    el('propContent').textContent = 'Se încarcă…';
    try {
      const p = await Alpaca.getProperties();
      const alignModes   = ['Alt-Azimuth', 'Polar', 'German Equatorial'];
      const eqSystems    = ['Custom/Unknown', 'Topocentric', 'J2000', 'J2050', 'B1950'];
      const trackRates   = ['Sidereal (15.041"/s)', 'Lunar (14.685"/s)', 'Solar (15.0"/s)', 'King (15.037"/s)'];
      const bool = (v) => v === true || v === 'True' ? 'DA' : v === false || v === 'False' ? 'NU' : v;
      const lines = [
        'ASCOM Telescope Properties',
        '══════════════════════════',
        `Driver Info       : ${p.driverinfo}`,
        `Driver Version    : ${p.driverversion}`,
        `Site Latitude     : ${p.sitelatitude}°`,
        `Site Longitude    : ${p.sitelongitude}°`,
        `Site Elevation    : ${p.siteelevation} m`,
        `Alignment Mode    : ${alignModes[p.alignmentmode] ?? p.alignmentmode}`,
        `Equatorial System : ${eqSystems[p.equatorialsystem] ?? p.equatorialsystem}`,
        `Aperture Area     : ${p.aperturearea} m²`,
        `Aperture Diameter : ${p.aperturediameter} m`,
        `Focal Length      : ${p.focallength} m`,
        `Guide Rate RA     : ${p.guideraterightascension} °/s`,
        `Guide Rate Dec    : ${p.guideratedeclination} °/s`,
        `Tracking Rate     : ${trackRates[p.trackingrate] ?? p.trackingrate}`,
        `Slew Settle Time  : ${p.slewsettletime} s`,
        `RA Rate offset    : ${p.rightascensionrate} s/sid.s`,
        `Dec Rate offset   : ${p.declinationrate} "/sid.s`,
        '──────────────────────────',
        `CanFindHome       : ${bool(p.canfindhome)}`,
        `CanPark           : ${bool(p.canpark)}`,
        `CanPulseGuide     : ${bool(p.canpulseguide)}`,
        `CanSetDecRate     : ${bool(p.cansetdeclinationrate)}`,
        `CanSetGuideRates  : ${bool(p.cansetguiderates)}`,
        `CanSetPark        : ${bool(p.cansetpark)}`,
        `CanSetPierSide    : ${bool(p.cansetpierside)}`,
        `CanSetRARate      : ${bool(p.cansetrightascensionrate)}`,
        `CanSetTracking    : ${bool(p.cansettracking)}`,
        `CanSlew           : ${bool(p.canslew)}`,
        `CanSlewAltAz      : ${bool(p.canslewaltaz)}`,
        `CanSlewAltAzAsync : ${bool(p.canslewaltazasync)}`,
        `CanSlewAsync      : ${bool(p.canslewasync)}`,
        `CanSync           : ${bool(p.cansync)}`,
        `CanSyncAltAz      : ${bool(p.cansyncaltaz)}`,
        `CanUnpark         : ${bool(p.canunpark)}`,
      ];
      el('propContent').textContent = lines.join('\n');
    } catch (e) {
      el('propContent').textContent = 'Eroare: ' + e.message;
    }
  }

  // ── Settings ───────────────────────────────────────────────────
  function openSettings() {
    showPanel('settingsPanel');
    el('settingsUrl').value        = Alpaca.getBaseUrl();
    el('settingsSvcLabel').value   = state.serviceLabel;
    el('settingsStartLabel').value = state.startLabel;
    el('settingsSvcAz').value      = state.serviceAz;
    el('settingsSvcAlt').value     = state.serviceAlt;
    el('settingsStartAz').value    = state.startAz;
    el('settingsStartAlt').value   = state.startAlt;
  }

  function saveSettings() {
    const url = el('settingsUrl').value.trim();
    Alpaca.setBaseUrl(url);

    state.serviceLabel = el('settingsSvcLabel').value.trim()   || 'Service';
    state.startLabel   = el('settingsStartLabel').value.trim() || 'Start';
    state.serviceAz    = parseFloat(el('settingsSvcAz').value)  || 220;
    state.serviceAlt   = parseFloat(el('settingsSvcAlt').value) || 15;
    state.startAz      = parseFloat(el('settingsStartAz').value)  || 160;
    state.startAlt     = parseFloat(el('settingsStartAlt').value) || 60;

    localStorage.setItem('mt_svcLabel',   state.serviceLabel);
    localStorage.setItem('mt_startLabel', state.startLabel);
    localStorage.setItem('mt_serviceAz',  state.serviceAz);
    localStorage.setItem('mt_serviceAlt', state.serviceAlt);
    localStorage.setItem('mt_startAz',    state.startAz);
    localStorage.setItem('mt_startAlt',   state.startAlt);

    el('btnService').textContent = state.serviceLabel;
    el('btnStart').textContent   = state.startLabel;
    showPanel('mainPanel');
  }

  // ── Slew settings sync ────────────────────────────────────────
  async function syncSlewToServer() {
    try {
      await fetch('/slew-settings', {
        method: 'PUT',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ rate: state.slewRate, fine: state.fineMode }),
        signal: AbortSignal.timeout(2000)
      });
    } catch {}
  }

  async function fetchSlewFromServer() {
    try {
      const r = await fetch('/slew-settings', { signal: AbortSignal.timeout(2000) });
      const d = await r.json();
      const rate = typeof d.rate === 'number' ? Math.max(1, Math.min(30, d.rate)) : null;
      const fine = typeof d.fine === 'boolean' ? d.fine : null;
      let changed = false;
      if (rate !== null && rate !== state.slewRate) { state.slewRate = rate; changed = true; }
      if (fine !== null && fine !== state.fineMode) { state.fineMode = fine; changed = true; }
      if (changed) {
        localStorage.setItem('mt_slewRate', state.slewRate);
        localStorage.setItem('mt_fineMode', state.fineMode);
        updateSlewDisplay();
      }
    } catch {}
  }

  // ── Init ───────────────────────────────────────────────────────
  function init() {
    // Restore persisted special button config
    state.serviceAz  = parseFloat(localStorage.getItem('mt_serviceAz')  || '220');
    state.serviceAlt = parseFloat(localStorage.getItem('mt_serviceAlt') || '15');
    state.startAz    = parseFloat(localStorage.getItem('mt_startAz')    || '160');
    state.startAlt   = parseFloat(localStorage.getItem('mt_startAlt')   || '60');
    el('btnService').textContent = state.serviceLabel;
    el('btnStart').textContent   = state.startLabel;

    // Slew rate
    updateSlewDisplay();
    el('slewRateSlider').addEventListener('input', () => {
      state.slewRate = parseInt(el('slewRateSlider').value);
      localStorage.setItem('mt_slewRate', state.slewRate);
      updateSlewDisplay();
      syncSlewToServer();
    });

    // Scale toggle
    el('scaleToggle').addEventListener('change', () => {
      state.fineMode = el('scaleToggle').checked;
      localStorage.setItem('mt_fineMode', state.fineMode);
      updateSlewDisplay();
      syncSlewToServer();
    });

    // Sync slider with other devices every 3s
    fetchSlewFromServer();
    setInterval(fetchSlewFromServer, 60000);

    // Main buttons
    el('btnConnect').addEventListener('click', toggleConnect);
    el('btnAbort').addEventListener('click', doAbort);
    el('btnPark').addEventListener('click', doPark);
    el('trackingToggle').addEventListener('change', async () => {
      try { await Alpaca.setTracking(el('trackingToggle').checked); } catch (e) { showError(e.message); }
    });

    // Directional — +RA = west = "Left" (telescope convention)
    el('btnUp').addEventListener('click',    () => slewStep( 0, +1));
    el('btnDown').addEventListener('click',  () => slewStep( 0, -1));
    el('btnLeft').addEventListener('click',  () => slewStep(+1,  0));
    el('btnRight').addEventListener('click', () => slewStep(-1,  0));

    // Special buttons
    el('btnService').addEventListener('click', async () => {
      if (!state.connected || state.parked) return;
      try {
        if (state.tracking) await Alpaca.setTracking(false);
        const alt = Math.max(MIN_ALT, Math.min(90, state.serviceAlt));
        await Alpaca.slewToAzAlt(state.serviceAz, alt);
        await new Promise(r => setTimeout(r, 1500));
        while (await Alpaca.getSlewing()) {
          await new Promise(r => setTimeout(r, 500));
        }
        await Alpaca.setTracking(false);
      } catch (e) { showError(e.message); }
    });
    el('btnStart').addEventListener('click', async () => {
      if (!state.connected || state.parked) return;
      try {
        if (state.tracking) await Alpaca.setTracking(false);
        const alt = Math.max(MIN_ALT, Math.min(90, state.startAlt));
        await Alpaca.slewToAzAlt(state.startAz, alt);
        await new Promise(r => setTimeout(r, 1500));
        while (await Alpaca.getSlewing()) {
          await new Promise(r => setTimeout(r, 500));
        }
        await Alpaca.setTracking(true);
      } catch (e) { showError(e.message); }
    });

    // GoTo panel
    el('btnGoto').addEventListener('click', () => {
      showPanel('gotoPanel');
      populateGotoFields();
    });
    el('gotoBack').addEventListener('click', () => showPanel('mainPanel'));
    el('btnGotoRaDec').addEventListener('click', executeGotoRaDec);
    el('btnGotoAzAlt').addEventListener('click', executeGotoAzAlt);
    ['RAh','RAm','RAs','Decd','Decm','Decs']
      .forEach(id => el(id).addEventListener('input', refreshGotoDecimal));
    ['Azd','Azm','Azs','Altd','Altm','Alts']
      .forEach(id => el(id).addEventListener('input', refreshAzAltDecimal));

    // Properties panel
    el('btnProperties').addEventListener('click', openProperties);
    el('propBack').addEventListener('click', () => showPanel('mainPanel'));

    // Settings panel
    el('btnSettings').addEventListener('click', openSettings);
    el('settingsBack').addEventListener('click', () => showPanel('mainPanel'));
    el('btnSettingsSave').addEventListener('click', saveSettings);

    // Register service worker
    if ('serviceWorker' in navigator) {
      navigator.serviceWorker.register('/sw.js').catch(() => {});
    }

    updateStatus();
    updateButtons();
    updateCoords();
    showPanel('mainPanel');

    Alpaca.isConnected().then(already => {
      if (already) {
        state.connected = true;
        startTimer();
      }
    }).catch(() => {});
  }

  return { init };
})();

document.addEventListener('DOMContentLoaded', App.init);
