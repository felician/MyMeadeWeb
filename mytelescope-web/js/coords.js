'use strict';

const Coords = (() => {
  function pad2(n) {
    return String(Math.floor(Math.abs(n))).padStart(2, '0');
  }

  function raToStr(ra) {
    if (ra == null || isNaN(ra)) return '--h--m--s';
    const h  = Math.floor(ra);
    const rm = 60 * (ra - h);
    const m  = Math.floor(rm);
    const s  = Math.floor(60 * (rm - m));
    return `${pad2(h)}h${pad2(m)}m${pad2(s)}s`;
  }

  function decToStr(dec) {
    if (dec == null || isNaN(dec)) return '---°--\'--"';
    const sign = dec >= 0 ? '+' : '−';
    const d    = Math.abs(dec);
    const deg  = Math.floor(d);
    const rm   = 60 * (d - deg);
    const m    = Math.floor(rm);
    const s    = Math.floor(60 * (rm - m));
    return `${sign}${pad2(deg)}°${pad2(m)}'${pad2(s)}"`;
  }

  function azToStr(az) {
    if (az == null || isNaN(az)) return '---°--\'--"';
    const deg = Math.floor(az);
    const rm  = 60 * (az - deg);
    const m   = Math.floor(rm);
    const s   = Math.floor(60 * (rm - m));
    return `${String(deg).padStart(3, '0')}°${pad2(m)}'${pad2(s)}"`;
  }

  // d carries the sign; m and s are always positive
  function dmsToDecimal(d, m, s) {
    const sign = parseInt(d) < 0 ? -1 : 1;
    return sign * (Math.abs(parseInt(d)) + parseInt(m) / 60 + parseInt(s) / 3600);
  }

  function hmsToDecimal(h, m, s) {
    return parseInt(h) + parseInt(m) / 60 + parseInt(s) / 3600;
  }

  function decToDMSParts(val) {
    const sign = val < 0 ? -1 : 1;
    const abs  = Math.abs(val);
    const d    = Math.trunc(abs);
    const rm   = 60 * (abs - d);
    const m    = Math.trunc(rm);
    const s    = Math.trunc(60 * (rm - m));
    return { d: sign * d, m, s };
  }

  function raToHMSParts(ra) {
    const h  = Math.trunc(ra);
    const rm = 60 * (ra - h);
    const m  = Math.trunc(rm);
    const s  = Math.trunc(60 * (rm - m));
    return { h, m, s };
  }

  return { raToStr, decToStr, azToStr, dmsToDecimal, hmsToDecimal, decToDMSParts, raToHMSParts };
})();
