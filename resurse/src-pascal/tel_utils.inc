

function fnmodulo(x,range: double):double;
begin
  {range should be 2*pi or 24 hours or 0 .. 360}
  result:=range*frac(x/range);
  if result<0 then result:=result+range;   {do not like negative numbers}
end;

procedure connect_telescope(Sender: TObject);{connect to telescope driver}
var
  V: variant;
begin

  if telescope_interface='A' then {=Ascom or I for INDI}
  begin
    {$ifdef mswindows}
    try
    if not VarIsEmpty(ascom_mount) then  {ascom alive?}
    begin
      //frmMain.tmrAscom.enabled:=false;
      ascom_mount.connected:=false;
      frmMain.stBar.Panels[0].Text:='NOT connected';
      ascom_mount := Unassigned;
      //update_telescope_menu(false);
      ascom_telescope_connected:=false;
      {canslew and canslewasync will be asked later. Here to early}
    end
    else
    begin
      {
      if sender<>nil then {send from popup menu}
      begin {show this only when called from popup menu}
        try
          V := CreateOleObject('ASCOM.Utilities.Chooser'); {for 64 bit applications as suggested in http://www.ap-i.net/mantis/view.php?id=778#bugnotes, "ASCOM." is required!!}
          except
          V := CreateOleObject('DriverHelper.Chooser');{This will work for old Ascom and 32 bit windows only. Note this give an error when run in the Delphi environment}
        end;
        V.devicetype:=widestring('Telescope');
        ascom_driver:=(V.Choose(ascom_driver));
        //ShowMessage('ascom_driver: '+ascom_driver);
        //frmMain.stBar.Panels[5].Text:=ascom_driver;
        V:=Unassigned;
      end;{end send from popup menu}

      if ascom_driver='' then exit; {e.g. 'ScopeSim.Telescope'}
      }
      {setup Ascom}
      try
        ascom_mount := CreateOleObject(ascom_driver); {See at the end of this file the ASCOM fix 2018, """"SetExceptionMask([exInvalidOp, exDenormalized, exZeroDivide,exOverflow, exUnderflow, exPrecision]); """"}
        ascom_mount.connected:=true;
        if ascom_mount.CanSlewAsync then
          Ascom_mount_capability:=2
           else {async slew possible, live feed back Ra/DEC}
            if ascom_mount.CanSlew      then
              Ascom_mount_capability:=1
               else {slew possible but not feedback of position at the same time}
                 Ascom_mount_capability:=0;{no slew possible}

        frmMain.tmrAscom.enabled:=true;
        //Showmessage(ascom_mount.Description+#13+#10+#13+#10+ascom_mount.DriverInfo);{show this only when called from popup menu}

        ascom_mount.Tracking:=true;{set tracking on}
        ascom_telescope_connected:=true;
        //update_telescope_menu(true);
      except
        on E: EOleException do ShowMessage('ASCOM error : ' + E.Message) {e.g. wrong com port}
        else
        begin {other errors}
         // mainwindow.connect_telescope1.checked:=false; {diable if default.hns is loaded and ASCOM driver is not there}
          //update_telescope_menu(false);
          Showmessage({error_string+}', ASCOM driver "'+ascom_driver+'" not_found');
        end;
      end; {end setup ascom}
    end;
    except {ascom alive}
      Showmessage({error_string+}', No ASCOM detected. Install from http://ascom-standards.org');
    end;
    {$else}
      {Not available in Linux}
    {$endif}
  end;

end;

procedure Stop_Mount;
begin
  if (ascom_mount.connected) then {allow export}
     begin
      try
        ascom_mount.AbortSlew;
        frmMain.stBar.Panels[2].Text:='';
      except
         on E: Exception do
         begin
           beep;
           application.messagebox(pchar(E.Message),'ASCOM returns following error:',MB_ICONWARNING+MB_OK); {show error from driver error, for example below horizon}
         end;
      end;
     end;
end;

procedure telescope_gotoRADec(Target_ra,Target_dec :double);
var
    //Target_ra, Target_dec        : double;
    s1,s2                        : string;
begin
  DefaultFormatSettings.DecimalSeparator := '.';
  if telescope_status=disconnected then
   begin
     ShowMessage('Telescope not connected!');
     exit;
   end;
  ascom_mount.tracking:=true;

  if Target_dec>Maximum_Declination then
    Target_dec:=Maximum_Declination
  else
     if Target_dec<Minimum_Declination then
       Target_dec:=Minimum_Declination;{exceptions above 90 will occur}


  if (ascom_mount.connected) then {allow goto}
    begin
      try {parked ?}
        if ascom_mount.AtPark then
        begin
           Showmessage('Telescope parked !');
           exit;
        end;
        except
          on E: Exception do
          begin
            application.messagebox(pchar(E.Message),'ASCOM returns following error:',MB_ICONWARNING+MB_OK); {show error from driver error, for example below horizon}
          end;
      end;{park test}
      try {export}
      if Ascom_mount_capability=2 then  ascom_mount.SlewToCoordinatesAsync(Target_ra, Target_dec)
      else
      if Ascom_mount_capability=1 then  ascom_mount.SlewToCoordinates(Target_ra, Target_dec)
      else;
      {nothing}
      except
        on E: Exception do
        begin
          beep;
          application.messagebox(pchar(E.Message),'ASCOM returns following error:',MB_ICONWARNING+MB_OK); {show error from driver error, for example below horizon}
        end;
     end;
   end;


end;

procedure telescope_gotoAzAlt(Target_Az,Target_Alt :double);
var
    //Target_Az, Target_Alt        : double;
    //s1,s2                        : string;
    tracking_status              :boolean;
begin
  DefaultFormatSettings.DecimalSeparator := '.';
  if telescope_status=disconnected then
   begin
     ShowMessage('Telescope not connected!');
     exit;
   end;
  tracking_status:=ascom_mount.tracking;
  ascom_mount.tracking:=false;
  //frmMain.stBar.Panels[1].Text:='NOT tracking';

  if Target_Alt>90 then
    Target_Alt:=90
  else
    if Target_Alt<Minimum_Altitude then
      Target_Alt:=Minimum_Altitude;                 {exceptions above 90 will occur}


  if (ascom_mount.connected) then {allow goto}
    begin
      try {parked ?}
        if ascom_mount.AtPark then
        begin
           Showmessage('Telescope parked !');
           exit;
        end;
        except
          on E: Exception do
          begin
            application.messagebox(pchar(E.Message),'ASCOM returns following error:',MB_ICONWARNING+MB_OK); {show error from driver error, for example below horizon}
          end;
      end;{park test}
      try {export}
      //frmMain.stBar.Panels[2].Text:='Slewing...';

      if Ascom_mount_capability=2 then  ascom_mount.SlewToAltAzAsync(Target_Az, Target_Alt)
      else
      if Ascom_mount_capability=1 then  ascom_mount.SlewToAltAz(Target_Az, Target_Alt)
      else;
      {nothing}
      except
        on E: Exception do
        begin
          beep;
          application.messagebox(pchar(E.Message),'ASCOM returns following error:',MB_ICONWARNING+MB_OK); {show error from driver error, for example below horizon}
        end;
     end;
   end;

   ascom_mount.tracking:=tracking_status;

end;

procedure telescope_moveAxis(dir:TDirections);
var
    tracking_status              :boolean;
begin

  if telescope_status=disconnected then
   begin
     ShowMessage('Telescope not connected!');
     exit;
   end;
  tracking_status:=ascom_mount.tracking;
  ascom_mount.tracking:=false;
  frmMain.stBar.Panels[1].Text:='NOT tracking';

  if (ascom_mount.connected) then {allow goto}
    begin
      try {parked ?}
        if ascom_mount.AtPark then
        begin
           Showmessage('Telescope parked !');
           exit;
        end;
        except
          on E: Exception do
          begin
            application.messagebox(pchar(E.Message),'ASCOM returns following error:',MB_ICONWARNING+MB_OK); {show error from driver error, for example below horizon}
          end;
      end;{park test}
      try {export}
      frmMain.stBar.Panels[2].Text:='Slewing...';

      if dir=Up then
        ascom_mount.MoveAxis(axis_Dec,ascom_mount.DeclinationRate);   //axis_Rate);
      if dir=Down then
        ascom_mount.MoveAxis(axis_Dec,-ascom_mount.DeclinationRate);
      if dir=Left then
        ascom_mount.MoveAxis(axis_RA,ascom_mount.RightAscensionRate);
      if dir=Right then
        ascom_mount.MoveAxis(axis_RA,-ascom_mount.RightAscensionRate);

      {nothing}
      except
        on E: Exception do
        begin
          beep;
          application.messagebox(pchar(E.Message),'ASCOM returns following error:',MB_ICONWARNING+MB_OK); {show error from driver error, for example below horizon}
        end;
     end;
   end;

   ascom_mount.tracking:=tracking_status;
   if tracking_status then
     frmMain.stBar.Panels[1].Text:='Tracking';
end;

function RAstringformat(RAdec:shortstring):shortstring;
var
  ra, mm, ss:double;
  h, m, s:shortstring;
begin
  DefaultFormatSettings.DecimalSeparator := '.';
  Result:='';
  ra:=StrToFloat(Trim(RAdec));

  if Trunc(ra)>9 then
    h := IntToStr(Trunc(ra))
  else
    h := '0' + IntToStr(Trunc(ra));
  mm := 60*(ra-Trunc(ra));
  if Trunc(mm)>9 then
    m := IntToStr(Trunc(mm))
  else
    m := '0' + IntToStr(Trunc(mm));
  ss := 60*(mm-Trunc(mm));
  if Trunc(ss)>9 then
    s := IntToStr(Trunc(ss))
  else
    s := '0' + IntToStr(Trunc(ss));

  Result:= h+'h'+m+'m'+s+'s';

end;

function DECstringformat(DECdec:shortstring):shortstring;
var
  dec, mm, ss:ValReal;
  g, m, s:shortstring;
begin
  DefaultFormatSettings.DecimalSeparator := '.';
  Result:='';
  dec:=StrToFloat(Trim(DECdec));
  if dec>0 then
    Result:='+'
  else
    begin
      Result:='-';
      dec := -1*dec;
    end;

  if Trunc(dec)>9 then
    g := IntToStr(Trunc(dec))
  else
    g := '0' + IntToStr(Trunc(dec));

  mm := 60*(dec-Trunc(dec));
  if Trunc(mm)>9 then
    m := IntToStr(Trunc(mm))
  else
    m := '0' + IntToStr(Trunc(mm));

  ss := 60*(mm-Trunc(mm));
  if Trunc(ss)>9 then
    s := IntToStr(Trunc(ss))
  else
    s := '0' + IntToStr(Trunc(ss));

  Result:= Result+g+'°'+m+''''+s+'"';

end;

procedure UpdateLabels;
begin
  DefaultFormatSettings.DecimalSeparator := '.';
  with frmMain do
  begin
    lblRA.Caption:='α= '+RAstringformat(FloatToStr(ascom_mount.RightAscension));
    lblDec.Caption:='δ= '+DECstringformat(FloatToStr(ascom_mount.Declination));

    lblAz.Caption:='Az='+Decstringformat(FloatToStr(ascom_mount.Azimuth));
    lblAlt.Caption:='Alt='+DECstringformat(FloatToStr(ascom_mount.Altitude));

  end;
end;

function delta_T(jd:double) : double; {calculates difference dynamic time and UT in days. Max error about 10 seconds. Range 1680 - 2150plus}
var y,u,t : double;
    year: integer;
const
  minyeardt = -99999999;{no limit}
  maxyeardt = +99999999;
begin
  { Reference  :
  NASA TP-2006-214141
  Five Millennium Canon of Solar Eclipses: -1999 to +3000 (2000 BCE to 3000 CE)
  Fred Espenak and see new meeus page 72 }
  y:=(2000 +(JD-2451544.5)/365.25);
  year:=round(y);

  {most lines taken from CdC 2016}
  if ((year>=minyeardt) and (year<=-2000)) then { minyeardt..-2000:}
                begin    // use JPL Horizon value
                  u:=(y-1820)/100;
                  result:=(32*u*u);{seconds}
                end
                else
  if ((year>=-1999) and (year<=-501)) then
  begin         // Use Espenak value
    u:=(y-1820)/100;
    result:=(-20+32*u*u);{seconds}
  end
  else
  if ((year>=-500) and (year<=499)) then
  begin
    u:=y/100;
    result:=(10583.6+u*(-1014.41+u*(33.78311+u*(-5.952053+u*(-0.1798452+u*(0.022174192+u*(0.0090316521)))))));{seconds}
  end
  else
  if ((year>=500) and (year<=1599)) then
  begin
    u:=(y-1000)/100;
    result:=(1574.2+u*(-556.01+u*(71.23472+u*(0.319781+u*(-0.8503463+u*(-0.005050998+u*(0.0083572073)))))));{seconds}
  end
  else
  if ((year>=1600) and (year<=1699)) then
  begin
    t:=y-1600;
    result:=(120+t*(-0.9808+t*(-0.01532+t*(1/7129))));{seconds}
  end
  else
  if ((year>=1700) and (year<=1799)) then
  begin
    t:=y-1700;
    result:=(8.83+t*(0.1603+t*(-0.0059285+t*(0.00013336+t*(-1/1174000)))));{seconds}
  end
  else
  if ((year>=1800) and (year<=1859)) then
  begin
    t:=y-1800;
    result:=(13.72+t*(-0.332447+t*(0.0068612+t*(0.0041116+t*(-0.00037436+t*(0.0000121272+t*(-0.0000001699+t*(0.000000000875))))))));{seconds}
  end
  else
  if ((year>=1860) and (year<=1899)) then
  begin
    t:=y-1860;
    result:=(7.62+t*(0.5737+t*(-0.251754+t*(0.01680668+t*(-0.0004473624+t*(1/233174))))));{seconds}
  end
  else
  if ((year>=1900) and (year<=1919)) then
  begin
     t:=y-1900;
     result:=(-2.79+t*(1.494119+t*(-0.0598939+t*(0.0061966+t*(-0.000197)))));{seconds}
  end
  else
  if ((year>=1920) and (year<=1940)) then
  begin
    t:=y-1920;
    result:=(21.20+t*(0.84493+t*(-0.076100+t*(0.0020936))));{seconds}
    end
  else
  if ((year>=1941) and (year<=1960)) then
  begin
    t:=y-1950;
    result:=(29.07+t*(0.407+t*(-1/233+t*(1/2547))));{seconds}
  end
  else
  if ((year>=1961) and (year<=1985)) then
  begin
    t:=y-1975;
    result:=(45.45+t*(1.067+t*(-1/260+t*(-1/718))));{seconds}
  end
  else
  if ((year>=1986) and (year<=2004)) then
  begin
    t:=y-2000;
    result:=(63.86+t*(0.3345+t*(-0.060374+t*(0.0017275+t*(0.000651814+t*(0.00002373599))))));{seconds}
  end
  else
  if ((year>=2005) and (year<=2012)) then
  // adjustement for measured values after 2005 :
  // linear adjustement from 2005.0 value to 66.9 sec. reached by 2013.0
  // factor up to 2150 are adjusted to avoid a discontinuity.
  begin
    t:=y-2005;
    result:=(64.69+t*0.27625);{seconds}  // (66.9-64.69)/8 = 0.27625
  end
  else
  if ((year>=2013) and (year<=2015)) then
  begin
    t:=y-2013;
    result:=(66.9+t*0.4667);{seconds}  // (68.3-66.9)/3 = 0.4667
  end
  else
  if ((year>=2016) and (year<=2020)) then
  begin
    t:=y-2016;
    result:=(68.3+t*0.54);{seconds}  // (71-68.3)/5 = 0.54
  end
  else
  if ((year>=2021) and (year<=2024)) then
  begin
    t:=y-2021;
    result:=(71+t*0.5);{seconds}  // (73-71)/4 = 0.5
  end
  else
  if ((year>=2025) and (year<=2049)) then
  begin
    t:=y-2000;
          //2005-2050: result:=(62.92+t*(0.32217+t*(0.005589)));{seconds}
          // > 2025 : 62.92+(0.32217*25)+(0.005589*25^2)=74.46
          // 62.92-74.46+73 = 61.46
    result:=(61.46+t*(0.32217+t*(0.005589)));{seconds}
  end
  else
  if ((year>=2050) and (year<=2149)) then
  begin
    u:=(y-1820)/100;
    t:=2150-y;
    result:=(-20+32*u*u-0.5788*t);{seconds}
    //result:=(-20+32*u*u-0.5628*t);{seconds}
  end
  else
  if ((year>=2150) and (year<=2999)) then
  begin        // End of Espenak range
    u:=(y-1820)/100;
    result:=(-20+32*u*u);{seconds}
  end
  else
  if ((year>=3000) and (year<=maxyeardt)) then
  begin    // use JPL Horizon value
    u:=(y-1820)/100;
    result:=(32*u*u);{seconds}{https://eclipse.gsfc.nasa.gov/SEhelp/deltatpoly2004.html}
  end
  else  result:=0; // unknown
  result:=result/(24*3600);{convert results to days}
end;


FUNCTION julian_calc(yyyy,mm:integer;dd,hours,minutes,seconds:double):double; {##### calculate julian day, revised 2017}
var
   Y,M   : integer;
   A, B , T ,XX : double;
begin
  IF MM>2 THEN  begin Y:=YYYY; M:=MM;end
  else {MM=1 OR MM=2}
    begin Y:=YYYY-1; M:=MM+12;end;

  DD:=DD+HOURS/24+MINUTES/(24*60)+SECONDS/(24*60*60);

  if ((YYYY+MM/100+DD/10000)<1582.10149999) then B:=0 {year 1582 October, 15, 00:00 reform Gregorian to julian, 1582.10149999=1582.1015 for rounding errors}
  else                                                {test year 837 april 10, 0 hours is Jd 2026871.5}
  begin
    A:=INT(Y/100);
    B:=+ 2 - A + INT(A/4)
  end;

  if Y<0 then XX:=0.75 else xx:=0;{correction for negative years}
    result:=INT(365.25*Y-XX)+INT(30.6001*(M+1))
         + DD
         + B
         + 1720994.5;

  {update the obliquity of ecliptic }
  T:=(result- 2451545)/36525;
  ecliptic2:=23.439291111  - T*46.8150/(60*60) - T*T*0.00059/(60*60); //M&P page 15
  {obliquity of ecliptic }
end;

procedure calculate_julian(year2,month2,day2,hour2,min2,sec:integer);{update julian_UT and julian_ET}
begin
  julian_UT:=julian_calc(year2,month2,day2,hour2-(timezone+daylight_saving),min2,sec);{julian time with delta T}

  if Time_Reference='UTC' then julian_ET:=julian_UT+delta_T(julian_UT) {calculates difference dynamic time and UT between 1700 and 2250 in days. new meeus page 74}
  else julian_ET:=julian_UT;
  equinox_date:=2000+(julian_ET-2451545.0)/365.25;

   wtime2actual:=fnmodulo((-longitude*pi/180)+siderealtime2000 +(julian_UT-2451545 )* earth_angular_velocity,2*pi); {longitude is positive towards west so has to be subtracted from time.} //In HNSKY the site longitude is negative if east and has to be subtracted from the time
         {change by time & longitude in 0 ..pi*2, local siderial time}
end;
(*-----------------------------------------------------------------------*)
(* SN: sine function (degrees)                                           *)
(*-----------------------------------------------------------------------*)
FUNCTION SN(X:double):double;
  BEGIN
    SN:=SIN(X*pi/180)
  END;
(*-----------------------------------------------------------------------*)
(* CS: cosine function (degrees)                                         *)
(*-----------------------------------------------------------------------*)
FUNCTION CS(X:double):double;
  BEGIN
    CS:=COS(X*pi/180)
  END;
(*-----------------------------------------------------------------------*)
(* TN: tangent function (degrees)                                        *)
(*-----------------------------------------------------------------------*)
FUNCTION TN(X:double):double;
  VAR XX: double;
  BEGIN
    XX:=X*pi/180; TN:=SIN(XX)/COS(XX);
  END;
(*-----------------------------------------------------------------------*)
(* ATN: arctangent function (degrees)                                    *)
(*-----------------------------------------------------------------------*)
FUNCTION ATN(X:double):double;
  BEGIN
    ATN:=ARCTAN(X)*180/pi
  END;
(*-----------------------------------------------------------------------*)
(* ATN2: arctangent of y/x for two arguments                             *)
(*       (correct quadrant; -180 deg <= ATN2 <= +180 deg)                *)
(*-----------------------------------------------------------------------*)
FUNCTION ATN2(Y,X:double):double;
  VAR   AX,AY,PHI: double;
  BEGIN
    IF (X=0.0) AND (Y=0.0)
      THEN ATN2:=0.0
      ELSE
        BEGIN
          AX:=ABS(X); AY:=ABS(Y);
          IF (AX>AY)
            THEN PHI:=ARCTAN(AY/AX)*180/pi
            ELSE PHI:=90.0-ARCTAN(AX/AY)*180/pi;
          IF (X<0.0) THEN PHI:=180.0-PHI;
          IF (Y<0.0) THEN PHI:=-PHI;
          ATN2:=PHI;
        END;
  END;

(*-----------------------------------------------------------------------*)
(* POLAR2: conversion of cartesian coordinates (x,y,z)                    *)
(*        into polar coordinates (r,theta,phi)                           *)
(*        (theta in [-pi/2 deg,+pi/2]; phi in [0 ,+ 2*pi radians]        *)
(*-----------------------------------------------------------------------*)

procedure polar2(x,y,z:double;out r,theta,phi:double);
var rho: double;
begin
  rho:=x*x+y*y;  r:=sqrt(rho+z*z);
  phi:=arctan2(y,x);
  if phi<0 then phi:=phi+2*pi;
  rho:=sqrt(rho);
  theta:=arctan2(z,rho);
end;


(*---------------------------------------------------------------------------*)
(* PMATEQU: Calculation precession matrix A[i,j] for                         *)
(*          equatorial coordinates from equinox T1 to T2                     *)
(*          ( T=(JD-2451545.0)/36525 )                                       *)
(*---------------------------------------------------------------------------*)
procedure PMATEQU(t1,t2:double; out a:double33);{Springer}
var dt,zeta,z,theta: double;
    c1,s1,c2,s2,c3,s3: double;
begin
 dt:=t2-t1;
  zeta  :=  ( (2306.2181+(1.39656-0.000139*t1)*t1)+
              ((0.30188-0.000345*t1)+0.017998*dt)*dt )*dt/3600;
  z     :=  zeta + ( (0.79280+0.000411*t1)+0.000205*dt)*dt*dt/3600;
  theta :=  ( (2004.3109-(0.85330+0.000217*t1)*t1)-
              ((0.42665+0.000217*t1)+0.041833*dt)*dt )*dt/3600;
  sincos(z*pi/180,s1,c1);
  sincos(theta*pi/180,s2,c2);
  sincos(zeta*pi/180,s3,c3);
  a[1,1]:=-s1*s3+c1*c2*c3; a[1,2]:=-s1*c3-c1*c2*s3; a[1,3]:=-c1*s2;
  a[2,1]:=+c1*s3+s1*c2*c3; a[2,2]:=+c1*c3-s1*c2*s3; a[2,3]:=-s1*s2;
  a[3,1]:=+s2*c3;          a[3,2]:=-s2*s3;          a[3,3]:=+c2;
end;


(*-----------------------------------------------------------------------*)
(* PRECART: calculate change of coordinates due to precession            *)
(*          for given transformation matrix A[i,j]                       *)
(*          (to be used with PMATECL und PMATEQU)                        *)
(*-----------------------------------------------------------------------*)
procedure PRECART(a:double33;var x,y,z:double);
var u,v,w: double;
begin
  u := a[1,1]*x+a[1,2]*y+a[1,3]*z;
  v := a[2,1]*x+a[2,2]*y+a[2,3]*z;
  w := a[3,1]*x+a[3,2]*y+a[3,3]*z;
  x:=u; y:=v; z:=w;
end;


(*-----------------------------------------------------------------------*)
(* CART: conversion of polar coordinates (r,theta,phi)                   *)
(*       into cartesian coordinates (x,y,z)                              *)
(*       (theta in [-90 deg,+90 deg]; phi in [-360 deg,+360 deg])        *)
(*-----------------------------------------------------------------------*)
PROCEDURE CART(R,THETA,PHI: double; out X,Y,Z: double);
  VAR RCST : double;
  BEGIN
    RCST := R*CS(THETA);
    X    := RCST*CS(PHI); Y := RCST*SN(PHI); Z := R*SN(THETA)
  END;

PROCEDURE EP(yearold,yearnew,raOLD,decold:double;out ranew,decnew:double);{correct precession for equatorial coordinates}
var teqxn,R : double;
    A       : double33;
    x,y,z : double;
begin
  CART(1,decold*180/pi,raold*180/pi,X,Y,Z);
  TEQX := (yearold-2000.0)/100.0;
  TEQXn := (yearnew-2000.0)/100.0;

  PMATEQU(TEQX,TEQXN,a);

  PRECART(A,X,Y,Z);

  TEQX := TEQXN;
  POLAR2(X,Y,Z ,R,DECnew,RAnew);
end;
{
procedure process_telescope_position(ra_telesc,dec_telesc,equinox_tel:double);
var
  dec_map,ra_map, RA_display,DEC_display,orientation_t,xxxx : double;
  ra5_text,dec5_text                                        : string;{telescope values}
  telescope_boundary : integer;
  telescope_connected : boolean;
begin
  if equinox_tel<=1 then ep(equinox_date,  2000,RA_telesc,DEC_telesc,ra_map,dec_map) {convert telescope astrometric to 2000 for map}
  else
  if equinox_tel=2000 then begin ra_map:=RA_telesc; dec_map:=DEC_telesc; end
  else
  ep(equinox_tel,  2000,RA_telesc,DEC_telesc,ra_map,dec_map);{1950,2050}


  if equinox=2000 then begin ra_display:=RA_map;  Dec_display:=dec_map; end{no conversion required}
  else
  if equinox<=1 then begin ra_display:=RA_telesc;  Dec_display:=dec_telesc; end{no conversion required}
  else
  if equinox=1950 then{conversion required}
  begin
    ep(equinox_date,  1950,RA_telesc,DEC_telesc,ra_display,dec_display); {convert telescope astrometric to 2000 for map}
  end;
  ra5_text:=prepare_ra(ra_display);{for display telescope position at mainwindow.caption}
  dec5_text:=prepare_dec(dec_display);

  if equinox>1 then {1950, 2000, 2050}
     telescope_position:='       '+Telescopetekst+'_'+inttostr(equinox)+': '+ra5_text+', '+dec5_text
     else
     telescope_position:='       '+Telescopetekst+'_'+mean_string     + ' '+ra5_text+', '+dec5_text;

  plot_pixel_sphere(mainwindow.image1.canvas,ra_map,dec_map,-99,$0,0,0);{find x and y coordinate based on image1.canvas. Note based on mainwindow.canvas is possible but cause a repaint.}


  telescopePt.x:=x9;{Store ascom pointer position for telescope_cursor}
  telescopePt.y:=y9;

  plot_pixel_sphere(mainwindow.image1.canvas,ra_map,dec_map+0.5/zoom,-99,$0,0,0); { find orientation by moving to }
  xxxx:=telescopePt.x-x9; if abs(xxxx)<0.000001 then xxxx:=0.000001; {prevent divide zero}
  orientation_t:=+arctan((telescopePt.y-y9)/xxxx)+(90-frame_angle)*pi/180;{frame_angle is extra rotation from ctrl + mouse wheel}

  telescope_connected:=((ascom_telescope_connected) or (indi_telescope_connected) or (alpaca_connected)) ;
  if ((zc>=0) and (mainwindow.boxshape1.height<4) and (telescope_connected)) then {blink telescope cursor}
    telescope_cursor(orientation_t);{plot telescope cursor & rectangle}

  if mainwindow.tracktelescope1.checked=true then {follow telescope and update screen}
  begin
    telescope_boundary:=round((rrw.bottom-rrw.top)*0.2);{keep telescope within this from canvas corners}
    if ((telescopePt.x+mainwindow.image1.left<rrw.left+telescope_boundary) or (telescopePt.x+mainwindow.image1.left>rrw.right-telescope_boundary) or
        (telescopePt.y+mainwindow.image1.top<rrw.top+telescope_boundary) or (telescopePt.y+mainwindow.image1.top>(rrw.bottom)-telescope_boundary)) then {use image1.top and image1.left since image1 can be moved without repaint}
    begin
      ra_az(ra_map,dec_map,latitude,0,wtime2,{var} viewx,viewy); {move sphere to center object}
      found:=0; {prevent a second and other writeinfo if quick a repaint is give by e.g. dde interface}
      missedupdate:=2; {rewrite window}
      paint_sky;{rewrite window}
    end;
  end;
end;
}



procedure sync_telescope(Target_ra, Target_dec:double);
begin
{
  Target_RA :=mouse_RA;{mouse position is target}
  Target_Dec:=mouse_Dec;

  if equinox_telescope=0 then ep(2000,equinox_date, Target_ra, Target_dec,Target_ra, Target_dec) {convert equinox2000 map to astrometric/date}
  else
  if equinox_telescope<>2000 then ep(2000,equinox_telescope, Target_ra, Target_dec,Target_ra, Target_dec); {convert equinox2000 map to telescope equinox}
 }
  Target_ra :=(Target_ra)*12/pi;
  Target_dec:=(Target_dec)*180/pi;
  if Target_dec>90 then
    Target_dec:=90
  else
    if Target_dec<-90 then Target_dec:=-90;{exceptions above 90 will occur}
{$ifdef mswindows}
  if telescope_interface='A' then
  begin {ascom telescope connection}
    if (ascom_mount.connected) then {allow sync}
    begin

     try
      ascom_mount.SyncToCoordinates(Target_ra, Target_dec);
      except
         on E: Exception do
         begin
           beep;
           application.messagebox(pchar(E.Message),'ASCOM returns following error:',MB_ICONWARNING+MB_OK); {show error from driver error, for example below horizon}
           exit;
         end
      end;
    end;
  end;
  {$else} {unix}
  {$endif}
end;

procedure set_telescope_movement_rates(ra_rate {rotation in seconds of degrees/hour},vdec_rate {"/hour}: double);
var
  rate0,rate1 : double;
  s0,s1 : string;
  p :integer;
const
  siderealrate=360.98564736629*3600/(24*60*60); {15.041...}
begin
  //if (mainwindow.connect_telescope1.Checked)=false then exit;

  //mainwindow.statusbar1.caption:='Mount motion: '+found_velocity_str;

  rate0:= ra_rate/3600;//ra rotation rate not velocity so without cos() correction, 1 ra_sec/s RA rate is not required}
  rate1:= vdec_rate/3600; {from "/hour to  "/sec}

  {$ifdef mswindows}
  if telescope_interface='A' then
  begin
    if ascom_mount.connected then
    begin
      try
        case trackingmethod of 0,3:if ascom_mount.sideofpier=1 then rate1:=-rate1;//looking east, inverse declination, 0 = pierEast(pointing west), 1 = pierWest(pointing east), -1= pierUnknown          //altaz mount is always 0
                               2,5:if ascom_mount.sideofpier=0 then rate1:=-rate1;//looking west, inverse declination, 0 = pierEast(pointing west), 1 = pierWest(pointing east), -1= pierUnknown          //altaz mount is always 0
                            end; //case
        if trackingmethod<=2 then //adjust tracking rate
        begin
          ascom_mount.RightAscensionRate:=rate0*(24/360)/0.9972695677;//ra [ra seconds/sec.] Note 23:56/24:00 hours=0.9972
          //The units of this property are seconds of right ascension per sidereal second. Please note that for historic reasons the units of the DeclinationRate property are arcseconds per SI second.
          //To convert a given rate in (the more common) units of sidereal seconds per UTC (clock) second, multiply the value by 0.9972695677 (the number of UTC seconds in a sidereal second) then set the property
          ascom_mount.DeclinationRate:=rate1;//declination
        end
        else
        begin // method moveaxis
          ascom_mount.moveAxis(0,(siderealrate-rate0)/3600);//ra [deg/sec]
          ascom_mount.moveAxis(1,rate1/3600);//declination [deg/sec]
        end;
      except
         on E: Exception do
         begin
           beep;
           application.messagebox(pchar(E.Message),'ASCOM returns following error:',MB_ICONWARNING+MB_OK); {show error from driver error, for example below horizon}
         end;
      end;
    end;
    exit;
  end; {ascom}
  {$else} {unix}
  {$endif}

end;




