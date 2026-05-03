# Analiză Cod Sursă Pascal — MyTelescope

**Data analizei:** 2026-04-26
**Versiune aplicație:** v0.9.1 (2024 October 20)
**Autor original:** ©2024 Felician Ursache
**Framework:** Free Pascal / Lazarus LCL 3.2.0

---

## 1. Structura aplicației

4 formulare (ferestre) Lazarus:

| Fișier | Formular | Rol |
|--------|----------|-----|
| `umain.pas` / `umain.lfm` | `TfrmMain` | Panoul principal de control al telescopului |
| `ugoto.pas` / `ugoto.lfm` | `TfrmGoto` | Dialog Go-To: input coordonate RA/Dec sau Az/Alt |
| `uproperties.pas` / `uproperties.lfm` | `TfrmProperties` | Afișare proprietăți driver ASCOM |
| `usettings.pas` / `usettings.lfm` | `TfrmSettings` | Setări: denumiri butoane, scară |

Fișier auxiliar: `tel_utils.inc` — inclus în `umain.pas`, conține toată logica de comunicare cu telescopul și calculele astronomice de bază.

---

## 2. Funcționalități identificate

### 2.1 Control telescop
- **Connect / Disconnect** — conectare la driver ASCOM (Windows OLE/COM)
- **Park / Unpark** — parcare și deparcare montură
- **Abort** — oprire imediată slew
- **Tracking** — afișare status tracking (On/Off/Slewing)

### 2.2 Mișcare (Slewing)
- **4 butoane direcționale** (Sus/Jos/Stânga/Dreapta) — slew în RA/Dec
- **MouseDown/MouseUp** — slew continuu pe Az/Alt cât ține apăsat
- **Click simplu** — slew cu pas în RA/Dec
- **Slew rate** — TrackBar 1-10°, cu toggle Normal (grade °) / Fine (minute ')
- **Scară** (`scara = 1` sau `60`) — comutare între grade și minute arcminute

### 2.3 Go-To
- Input coordonate în format HMS/DMS (ore-minute-secunde / grade-minute-secunde)
- Suport **RA/Dec** și **Az/Alt**
- Afișare valoare decimală calculată în timp real
- Butoane speciale programabile: **Service** (Az=220°, Alt=15°) și **Start** (Az=160°, Alt=60°)

### 2.4 Afișare date în timp real
- **RA** (α) în format HH:MM:SS
- **Dec** (δ) în format ±DD°MM'SS"
- **Az** și **Alt** în format ±DD°MM'SS"
- StatusBar cu 5 panouri: status conexiune, tracking, slewing, slew rate, driver version
- Timer (`tmrAscomTimer`) pentru actualizare continuă

### 2.5 Proprietăți driver ASCOM (frmProperties)
- Info driver, versiune
- Coordonate site (lat/lon/alt)
- Mod aliniere (AltAz / Polar / German Equatorial)
- Sistem ecuatorial (Topocentric / J2000 / J2050 / B1950)
- Apertura, focal length
- Guide rates, tracking rate
- Capabilități (CanSlew, CanPark, CanSync, etc.)

### 2.6 Setări (frmSettings)
- Redenumire butoane speciale "Service" și "Start"
- Scală nivel (1x)

---

## 3. Interfața cu telescopul — ASCOM

Aplicația folosește **ASCOM** (Astronomy Common Object Model) prin **OLE Automation** (COM/Windows):

```pascal
ascom_mount := CreateOleObject('ASCOM.DeviceHub.Telescope');
ascom_mount.connected := true;
```

**Proprietăți ASCOM folosite:**
- `RightAscension`, `Declination`, `Azimuth`, `Altitude` — coordonate curente
- `AtPark`, `Tracking`, `Slewing` — stări
- `SlewToCoordinatesAsync`, `SlewToCoordinates` — goto RA/Dec
- `SlewToAltAzAsync`, `SlewToAltAz` — goto Az/Alt
- `AbortSlew` — oprire
- `Park`, `UnPark`
- `MoveAxis` — control axe continue
- `RightAscensionRate`, `DeclinationRate` — rate tracking

**Limitare critică:** ASCOM OLE funcționează **doar pe Windows**. Nu este accesibil direct dintr-o aplicație web.

---

## 4. Biblioteci astronomice (hns_*)

| Fișier | Conținut |
|--------|----------|
| `hns_uDE.pas` | Reader binar JPL DE405/DE406 ephemeris — poziții planete |
| `hns_Upla.pas` | Calcule poziții planete (algoritmi Meeus) |
| `hns_Uast.pas` | Funcții astronomice generale (coordonate, conversii) |
| `tel_utils.inc` | Julian date, Delta-T, precesie, sidereal time, conversii RA/Dec |

**Funcții cheie în `tel_utils.inc`:**
- `julian_calc` — calcul dată Juliană
- `delta_T` — diferența UTC-TT (1680-2150), algoritm complet Espenak/Meeus
- `calculate_julian` — actualizare JD + timp sideral local
- `PMATEQU` / `PRECART` / `EP` — matrice de precesie ecuatorială
- `RAstringformat` / `DECstringformat` — formatare coordonate

**Notă:** Bibliotecile hns_* nu sunt active în versiunea curentă (`//hns_Upla` este comentat în umain.pas). Aplicația actuală folosește direct ASCOM pentru toate coordonatele.

---

## 5. Constante importante

```
Locație: 45.865484225°N, 25.768879739°E  (zona Brașov)
Altitudine minimă: 0°
Declinație: -22° ... +72°
AE = 149597870.700 km
Sidereal time 2000: 280.46061837°
```

---

## 6. Dependențe externe

| Dependență | Tip | Portabilitate web |
|------------|-----|-------------------|
| ASCOM OLE (COM) | Protocol telescop | ❌ Windows-only → înlocuit cu ASCOM Alpaca |
| Lazarus LCL | GUI framework | ❌ Desktop → înlocuit cu HTML/CSS/JS |
| TFileStream (DE405) | Fișiere binare efemeride | ❌ Filesystem → optional, API extern |
| comobj (OLE) | COM automation | ❌ Windows-only |

---

## 7. Complexitate portare (estimare)

| Componentă | Efort | Note |
|------------|-------|------|
| UI principal (butoane, labels, status) | Mic | HTML/CSS pur |
| Dialog Go-To (spinners DMS) | Mic-Mediu | Component custom JS |
| Logica ASCOM → Alpaca REST | Mediu | API swap, același model |
| Formatare coordonate RA/Dec/Az/Alt | Mic | ~30 linii JS |
| Julian date, Delta-T, precesie | Mediu | Port direct sau lib existentă |
| Timer refresh afișaj | Mic | setInterval JS |
| Biblioteca DE405 ephemeris | Mare | Nu este activă azi, poate fi omisă v1 |
| Settings persistente | Mic | localStorage |
