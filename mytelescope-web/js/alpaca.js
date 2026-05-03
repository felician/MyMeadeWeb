'use strict';

const Alpaca = (() => {
  const _stored = localStorage.getItem('mt_alpacaUrl') || '';
  let _base = (_stored === 'http://localhost:11111' || _stored === 'http://127.0.0.1:11111') ? '' : _stored;
  let _txId = 0;
  const _cid = 1;

  const ep = (p) => `${_base}/api/v1/telescope/0/${p}`;

  async function get(prop) {
    const r = await fetch(
      `${ep(prop)}?ClientID=${_cid}&ClientTransactionID=${++_txId}`,
      { signal: AbortSignal.timeout(3000) }
    );
    if (!r.ok) throw new Error(`HTTP ${r.status}`);
    const d = await r.json();
    if (d.ErrorNumber !== 0) throw new Error(d.ErrorMessage || `Alpaca error ${d.ErrorNumber}`);
    return d.Value;
  }

  async function put(action, params = {}) {
    const body = new URLSearchParams({
      ClientID: _cid,
      ClientTransactionID: ++_txId,
      ...params
    });
    const r = await fetch(ep(action), {
      method: 'PUT',
      headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
      body: body.toString(),
      signal: AbortSignal.timeout(15000)
    });
    if (!r.ok) throw new Error(`HTTP ${r.status}`);
    const d = await r.json();
    if (d.ErrorNumber !== 0) throw new Error(d.ErrorMessage || `Alpaca error ${d.ErrorNumber}`);
    return d;
  }

  return {
    getBaseUrl: () => _base,
    setBaseUrl(url) {
      _base = url.replace(/\/$/, '');
      localStorage.setItem('mt_alpacaUrl', _base);
    },

    // Connection
    isConnected:  () => get('connected'),
    connect:      () => put('connected', { Connected: 'True' }),
    disconnect:   () => put('connected', { Connected: 'False' }),

    // Position
    getRa:        () => get('rightascension'),
    getDec:       () => get('declination'),
    getAz:        () => get('azimuth'),
    getAlt:       () => get('altitude'),

    // Status
    getAtPark:    () => get('atpark'),
    getTracking:  () => get('tracking'),
    getSlewing:   () => get('slewing'),
    setTracking:  (on) => put('tracking', { Tracking: on ? 'True' : 'False' }),

    // Movement
    slewToRaDec: (ra, dec) => put('slewtocoordinatesasync', {
      RightAscension: ra,
      Declination: dec
    }),
    slewToAzAlt: (az, alt) => put('slewtoaltazasync', {
      Azimuth: az,
      Altitude: alt
    }),
    abortSlew: () => put('abortslew'),

    // Park
    park:   () => put('park'),
    unpark: () => put('unpark'),

    // Driver properties (for Properties panel)
    async getProperties() {
      const props = [
        'driverinfo', 'driverversion', 'sitelatitude', 'sitelongitude',
        'siteelevation', 'alignmentmode', 'equatorialsystem',
        'aperturearea', 'aperturediameter', 'focallength',
        'guideraterightascension', 'guideratedeclination', 'trackingrate',
        'slewsettletime', 'rightascensionrate', 'declinationrate',
        'canfindhome', 'canpark', 'canpulseguide', 'cansetdeclinationrate',
        'cansetguiderates', 'cansetpark', 'cansetpierside',
        'cansetrightascensionrate', 'cansettracking', 'canslew',
        'canslewaltaz', 'canslewaltazasync', 'canslewasync',
        'cansync', 'cansyncaltaz', 'canunpark'
      ];
      const result = {};
      for (const p of props) {
        try { result[p] = await get(p); } catch { result[p] = 'N/A'; }
      }
      return result;
    }
  };
})();
