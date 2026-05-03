unit uMain;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, Buttons,
  ComCtrls, ExtCtrls, math, uProperties, uGoto, uSettings,
  comobj,  // for ASCOM
  //hns_Upla, // astro and math functions  ... from hnsky
  LCLtype, StdCtrls, Menus, Variants;

type
  double33= array[1..3,1..3] of double;

type
  TTstatus= (connected,disconnected);

type
  TDirections = (Up, Down, Left, Right);

type

  { TfrmMain }

  TfrmMain = class(TForm)
    bitbtnService: TBitBtn;
    bitbtnStart: TBitBtn;
    bitbtnRight: TBitBtn;
    bitbtnDown: TBitBtn;
    bitbtnGoto: TBitBtn;
    bitbtnUp: TBitBtn;
    bitbtnLeft: TBitBtn;
    bitbtnAbort: TBitBtn;
    bitbtnPark: TBitBtn;
    bitbtnConnect: TBitBtn;
    ImageList1: TImageList;
    lblTracking: TLabel;
    lblRA: TLabel;
    lblDec: TLabel;
    lblAz: TLabel;
    lblAlt: TLabel;
    MainMenu1: TMainMenu;
    mnuGoto: TMenuItem;
    mnuSettings: TMenuItem;
    mnuAbout: TMenuItem;
    mnuHelp: TMenuItem;
    mnuProperties: TMenuItem;
    mnuView: TMenuItem;
    mnuExit: TMenuItem;
    mnuFile: TMenuItem;
    Separator1: TMenuItem;
    Separator2: TMenuItem;
    stBar: TStatusBar;
    tmrAscom: TTimer;
    toggScale: TToggleBox;
    trbarSlewVal: TTrackBar;
    procedure bitbtnServiceClick(Sender: TObject);
    procedure bitbtnGotoClick(Sender: TObject);
    procedure bitbtnStartClick(Sender: TObject);
    procedure btnDownClick(Sender: TObject);
    procedure btnDownMouseDown(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; X, Y: Integer);
    procedure btnDownMouseUp(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; X, Y: Integer);
    procedure btnLeftClick(Sender: TObject);
    procedure btnLeftMouseDown(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; X, Y: Integer);
    procedure btnLeftMouseUp(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; X, Y: Integer);
    procedure btnRightClick(Sender: TObject);
    procedure btnRightMouseDown(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; X, Y: Integer);
    procedure btnRightMouseUp(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; X, Y: Integer);
    procedure btnUpClick(Sender: TObject);
    procedure btnUpMouseDown(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; X, Y: Integer);
    procedure btnUpMouseUp(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; X, Y: Integer);
    procedure FormClose(Sender: TObject; var CloseAction: TCloseAction);
    procedure mnuAboutClick(Sender: TObject);
    procedure mnuExitClick(Sender: TObject);
    procedure mnuGotoClick(Sender: TObject);
    procedure mnuPropertiesClick(Sender: TObject);
    procedure mnuSettingsClick(Sender: TObject);
    procedure tmrAscomTimer(Sender: TObject);
    procedure bitbtnConnectClick(Sender: TObject);
    procedure bitbtnDownClick(Sender: TObject);
    procedure bitbtnLeftClick(Sender: TObject);
    procedure bitbtnParkClick(Sender: TObject);
    procedure bitbtnRightClick(Sender: TObject);
    procedure bitbtnUpClick(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    //procedure import_from_Ascom(Sender: TObject);
    procedure bitbtnAbortClick(Sender: TObject);
    procedure toggScaleChange(Sender: TObject);
    procedure trbarSlewValChange(Sender: TObject);
    //procedure telescope_synctomouse1Click(Sender: TObject);

    //function RAstringformat(RAdec:shortstring):shortstring;
    //function DECstringformat(DECdec:shortstring):shortstring;




  private

  public

  end;

const

  Minimum_Altitude: double = 0;
  Minimum_Declination: double = -22;
  Maximum_Declination: double = 72;
  {$ifdef mswindows}
  telescope_interface: string='A'; {A=Ascom or I for INDI}
  {$else} {unix}
  telescope_interface: string=' '; {A=Ascom or I for INDI, space for none}
  {$endif}
  version: shortstring = 'v0.9.1';
  dateversion: shortstring = '(2024 October 20)';
  author: shortstring = '©2024 Felician Ursache';
  equinox_telescope  : integer = 0;
  ascom_telescope_connected : boolean = false;
  //telescope_tracking : boolean = true;
  trackingmethod : integer=0;
  axis_RA:  integer = 0;
  axis_Dec: integer = 1;
  axis_Rate:double  = 0.03;
  //ascom_driver    : widestring ='ASCOM.Simulator.Telescope';
  ascom_driver    : widestring ='ASCOM.DeviceHub.Telescope';
  ascom_mount_capability:integer=0; {2= async slew, 1 slew, 0 no slew}
  longitude: double = 25.768879739;
  latitude: double = 45.865484225;
  timezone : double   =0;
  apparent_horizon : double= (- 34.5/60)*(pi/180);{34.5 minutes. this factor is used for exact horizon plotting}
  daylight_saving:integer=0;
  dst_auto: boolean=false;{day light saving on auto mode for USA and european timezones}
  Time_Reference : string='UTC';
  parallax2: integer=1; {correct parallax error ?}

  siderealtime2000=(280.46061837)*pi/180;{[radians], sidereal time at 2000 jan 1.5 UT (12 hours) =Jd 2451545 at meridian greenwich, see new meeus 11.4}
  earth_angular_velocity = pi*2*1.00273790935; {about(365.25+1)/365.25) or better (365.2421874+1)/365.2421874 velocity dailly. See new Meeus page 83}
  AE=149597870.700; {ae has been fixed to the value 149597870.700 km as adopted by the International Astronomical Union in 2012.  Note average earth distance is 149597870.662 * 1.000001018 see meeus new 379}
  days  : array[0..12] of integer=(31,31,28,31,30,31,30,31,31,30,31,30,31);{dec=0=special, jan=1, febr... dec}


var
  frmMain: TfrmMain;
  ascom_mount           : variant; {für ascom, telescope}
  telescopePt,oldtelescopePt,{ascom telescope_cursor}   oldframePt {measuring frame}  : tpoint;
  //telescope_connected, telescope_parked, telescope_tracking, telescope_athome:boolean;
  equinox_date, julian_UT, julian_ET, ecliptic2, TEQX:double;
  wtime2actual, old_julian_et, julian_local  : double; {julian day, julian day correct with delta_T to get dynamic time}

  telescope_status:TTstatus;
  telescope_tracking, telescope_athome:boolean;
  scara:integer;
  RA1, Dec1, Az1, Alt1:double;
  GotoAction:(RADec,AzAlt,None);

implementation

{$R *.lfm}
{$I tel_utils.inc}



procedure TfrmMain.bitbtnConnectClick(Sender: TObject);
var
  eqs:integer;
  str:string;
begin
 if telescope_status=disconnected then
   begin
     connect_telescope(Sender);
     //ShowMessage(Sender.ClassName);
     if ascom_mount.connected then
       begin
         //frmMain.Caption:='MyTelescope - status: CONNECTED';
         telescope_status:=connected;
         str:=ascom_mount.DriverVersion;
         bitbtnConnect.Caption:='Disconnect';
         stBar.Panels[0].Text:='Connected';
         stBar.Panels[2].Text:='';
         stBar.Panels[3].Text:=IntToStr(trbarSlewVal.Position)+'°';
         stBar.Panels[4].Text:=str;
         try
           if ascom_mount.AtPark then  {update menu telescope parked?}
             begin
               //telescope_status:=parked;
               telescope_tracking:=false;
               stBar.Panels[0].Text:='PARKED';
               stBar.Panels[1].Text:='';
               stBar.Panels[2].Text:='';
               lblTracking.Caption:='';
               //stBar.:=;
               exit;
             end;
           telescope_tracking:=ascom_mount.Tracking;{tracking ?}
           //chbTracking.Enabled:=true;
           //chbTracking.Checked:= telescope_tracking;
           if telescope_tracking then
             lblTracking.Caption:='Tracking'
           else
             lblTracking.Caption:='Stopped';

           //telescope_athome:=ascom_mount.AtHome;{home ?}
           UpdateLabels;

        except
        end;
        try    {check if ascom can specify equinox used}
         eqs:=ascom_mount.EquatorialSystem;
        except
         eqs:=0;
        end;
        case eqs of
         0 : equinox_telescope:=0;    {equOther	0	Custom or unknown equinox and/or reference frame.}
         1 : equinox_telescope:=1;    {equTopocentric	1	Local topocentric; True equinox of date about the same as "mean equinox of date". This is the most common for amateur telescopes.}
         2 : equinox_telescope:=2000; {equJ2000	2	J2000 equator/equinox, ICRS reference frame.}
         3 : equinox_telescope:=2050; {equJ2050	3	J2050 equator/equinox, ICRS reference frame.}
         4 : equinox_telescope:=1950; {equB1950	4	B1950 equinox, FK4 reference frame.}
        end;
        //frmMain.Caption:=frmMain.Caption+' Equinox: '+IntToStr(eqs);//equinox_telescope);
        //stBar.Panels[3].Text:='Equinox='+IntToStr(equinox_telescope);
        //process_telescope_position(RA_telesc,Dec_telesc,equinox_telescope);
       end;

   end
 else                         // foarte important, altfel se deconecteaza instantaneu
 if telescope_status=connected then
   begin
     ascom_mount.connected:=false;
     ascom_mount := Unassigned;
     //frmMain.Caption:='MyTelescope - status: NOT connected';
     telescope_status:=disconnected;
     stBar.Panels[0].Text:='DISCONNECTED';
     stBar.Panels[1].Text:='';
     stBar.Panels[2].Text:='';
     stBar.Panels[3].Text:='';
     stBar.Panels[4].Text:='';
     bitbtnConnect.Caption:='Connect';
     bitbtnUp.Enabled:=false;
     bitbtnDown.Enabled:=false;
     bitbtnLeft.Enabled:=false;
     bitbtnRight.Enabled:=false;
     bitbtnService.Enabled:=false;
     bitbtnStart.Enabled:=false;
     bitbtnPark.Enabled:=false;
     bitbtnAbort.Enabled:=false;
     bitbtnGoto.Enabled:=false;
     telescope_tracking:=false;{tracking ?}
     lblTracking.Caption:='';
     //chbTracking.Checked:= telescope_tracking;
     //chbTracking.Enabled:=false;
     //tmrAscom.Enabled:=false;
   end;
end;

procedure TfrmMain.tmrAscomTimer(Sender: TObject);
begin

 if telescope_status=connected then {ascom}
  //if telescope_parked=false then
   begin
    if ascom_mount.AtPark then  //telescope parked
    begin
      //telescope_status:=parked;
      telescope_tracking:=false;
      stBar.Panels[0].Text:='PARKED';
      stBar.Panels[1].Text:='';
      stBar.Panels[2].Text:='';
      bitbtnUp.Enabled:=false;
      bitbtnDown.Enabled:=false;
      bitbtnLeft.Enabled:=false;
      bitbtnRight.Enabled:=false;
      bitbtnService.Enabled:=false;
      bitbtnStart.Enabled:=false;
      bitbtnGoto.Enabled:=false;
      bitbtnPark.Enabled:=true;
      bitbtnPark.Caption:='Unpark';
      bitbtnAbort.Enabled:=true;

      exit;
    end;
    UpdateLabels;
    stBar.Panels[0].Text:='Connected';
    telescope_tracking:=ascom_mount.Tracking;
    //if telescope_tracking then
     //chbTracking.State:=cbChecked;
     if telescope_tracking then      //if ascom_mount.Tracking then
       //lblTracking.Caption:='Tracking'
       stBar.Panels[1].Text:='Tracking';
    if ascom_mount.Slewing then                      // or parking?
      begin
        //stBar.Panels[2].Text:='Slewing...';
        lblTracking.Color:=clRed;
        if lblTracking.Caption='Tracking' then
         lblTracking.Caption:='SLEWING.';
        if lblTracking.Caption='SLEWING.' then
         lblTracking.Caption:='SLEWING..';
        if lblTracking.Caption='SLEWING.' then
         lblTracking.Caption:='SLEWING...';
        if lblTracking.Caption='SLEWING...' then
         lblTracking.Caption:='SLEWING.';
        lblTracking.Color:=clBlack;
        stBar.Panels[1].Text:='SLEWING...';
        bitbtnUp.Enabled:=false;
        bitbtnDown.Enabled:=false;
        bitbtnLeft.Enabled:=false;
        bitbtnRight.Enabled:=false;
        bitbtnService.Enabled:=false;
        bitbtnStart.Enabled:=false;
        bitbtnGoto.Enabled:=false;
        bitbtnPark.Enabled:=false;
        bitbtnAbort.Enabled:=true;
        //btnUp.Enabled:=false;                    // daca e false nu mai reactioneaza la button Up
        //btnDown.Enabled:=false;
        //btnLeft.Enabled:=false;
        //btnRight.Enabled:=false;
        //chbTracking.Enabled:=false;
      end
    else
      begin
        stBar.Panels[2].Text:='';
        if not telescope_tracking then
         stBar.Panels[1].Text:='NOT Tracking';
        if telescope_tracking then
         stBar.Panels[1].Text:='Tracking';
        bitbtnAbort.Enabled:=true;
        bitbtnUp.Enabled:=true;
        bitbtnDown.Enabled:=true;
        bitbtnLeft.Enabled:=true;
        bitbtnRight.Enabled:=true;
        bitbtnService.Enabled:=true;
        bitbtnStart.Enabled:=true;
        bitbtnGoto.Enabled:=true;
        bitbtnPark.Enabled:=true;

        //chbTracking.Enabled:=true;
      end;
   end;
end;

procedure TfrmMain.bitbtnServiceClick(Sender: TObject);
begin
  telescope_gotoAzAlt(220, 15);

end;

procedure TfrmMain.bitbtnStartClick(Sender: TObject);
begin
  telescope_gotoAzAlt(160, 60);

end;

procedure TfrmMain.btnDownClick(Sender: TObject);
var
  new_RA, new_Dec:double;
begin
  new_RA:=ascom_mount.RightAscension;
  new_Dec:=ascom_mount.Declination-trbarSlewVal.Position/20;

  telescope_gotoRADec(new_RA, new_Dec);
end;

procedure TfrmMain.bitbtnGotoClick(Sender: TObject);
begin
  frmGoto.ShowModal;
  if frmGoto.ModalResult=mrOK then
   begin
     if GotoAction=AzAlt then
       telescope_gotoAzAlt(Az1,Alt1);
     if GotoAction=RADec then
       telescope_gotoRADec(RA1,Dec1);
   end;
end;

procedure TfrmMain.btnUpMouseDown(Sender: TObject; Button: TMouseButton;
  Shift: TShiftState; X, Y: Integer);
var
  new_Az, new_Alt:double;
begin
  // aici slew Up
   //telescope_moveAxis(Up);
  new_Az:=ascom_mount.Azimuth;
  new_Alt:=ascom_mount.Altitude+trbarSlewVal.Position;
  telescope_gotoAzAlt(new_Az,new_Alt);
end;

procedure TfrmMain.btnDownMouseDown(Sender: TObject; Button: TMouseButton;
  Shift: TShiftState; X, Y: Integer);
var
  new_Az, new_Alt:double;
begin
  // aici slew Down
  //telescope_moveAxis(Down);
  new_Az:=ascom_mount.Azimuth;
  new_Alt:=ascom_mount.Altitude-trbarSlewVal.Position;
  telescope_gotoAzAlt(new_Az,new_Alt);
end;

procedure TfrmMain.btnRightMouseDown(Sender: TObject; Button: TMouseButton;
  Shift: TShiftState; X, Y: Integer);
var
  new_Az, new_Alt:double;
begin
  // aici slew Right
  //telescope_moveAxis(Right);
  new_Az:=ascom_mount.Azimuth+trbarSlewVal.Position;
  new_Alt:=ascom_mount.Altitude;
  telescope_gotoAzAlt(new_Az,new_Alt);
end;

procedure TfrmMain.btnLeftMouseDown(Sender: TObject; Button: TMouseButton;
  Shift: TShiftState; X, Y: Integer);
var
  new_Az, new_Alt:double;
begin
  // aici slew Left
  //telescope_moveAxis(Left);
  new_Az:=ascom_mount.Azimuth-trbarSlewVal.Position/scara;
  new_Alt:=ascom_mount.Altitude;
  telescope_gotoAzAlt(new_Az,new_Alt);
end;

procedure TfrmMain.btnLeftMouseUp(Sender: TObject; Button: TMouseButton;
  Shift: TShiftState; X, Y: Integer);
begin
  if Button=mbLeft then
    Stop_Mount;
end;

procedure TfrmMain.btnRightClick(Sender: TObject);
var
  new_RA, new_Dec:double;
begin
  new_RA:=ascom_mount.RightAscension-trbarSlewVal.Position/15/20;
  if new_RA<0 then
    new_RA:=new_RA+24;
  new_Dec:=ascom_mount.Declination;

  telescope_gotoRADec(new_RA, new_Dec);
end;



procedure TfrmMain.btnRightMouseUp(Sender: TObject; Button: TMouseButton;
  Shift: TShiftState; X, Y: Integer);
begin
  if Button=mbLeft then
    Stop_Mount;
end;

procedure TfrmMain.btnUpClick(Sender: TObject);
var
  new_RA, new_Dec:double;
begin
  new_RA:=ascom_mount.RightAscension;
  new_Dec:=ascom_mount.Declination+trbarSlewVal.Position/20;

  telescope_gotoRADec(new_RA, new_Dec);
end;

procedure TfrmMain.btnDownMouseUp(Sender: TObject; Button: TMouseButton;
  Shift: TShiftState; X, Y: Integer);
begin
  if Button=mbLeft then
    Stop_Mount;
end;

procedure TfrmMain.btnLeftClick(Sender: TObject);
var
  new_RA, new_Dec:double;
begin
  new_RA:=ascom_mount.RightAscension+trbarSlewVal.Position/15/20;
  if new_RA>=24 then
     new_RA:=new_RA-24;
  new_Dec:=ascom_mount.Declination;

  telescope_gotoRADec(new_RA, new_Dec);
end;

procedure TfrmMain.btnUpMouseUp(Sender: TObject; Button: TMouseButton;
  Shift: TShiftState; X, Y: Integer);
begin
  if Button=mbLeft then
    Stop_Mount;
end;

procedure TfrmMain.FormClose(Sender: TObject; var CloseAction: TCloseAction);
begin
  if telescope_status=connected then
    begin
     Stop_Mount;
     ascom_mount.connected:=false;
    end;
end;

{
procedure TfrmMain.chbTrackingClick(Sender: TObject);
begin
  if telescope_status=connected then
  if chbTracking.State=cbChecked then
    begin
      chbTracking.State:=cbUnchecked;
      ascom_mount.Tracking:=false;
    end
  else
    begin
      chbTracking.State:=cbChecked;
      ascom_mount.Tracking:=true;
    end;

end;
}
procedure TfrmMain.mnuAboutClick(Sender: TObject);
begin
  ShowMessage(frmMain.Caption+' '+dateversion+#13+#13+author);
end;

procedure TfrmMain.mnuExitClick(Sender: TObject);
begin
  Application.Terminate;
end;

procedure TfrmMain.mnuGotoClick(Sender: TObject);
begin
  if telescope_status=connected then
     bitbtnGotoClick(Sender);
end;

procedure TfrmMain.mnuPropertiesClick(Sender: TObject);
begin
  frmProperties.Show;
end;

procedure TfrmMain.mnuSettingsClick(Sender: TObject);
begin
  frmSettings.ShowModal;
end;

procedure TfrmMain.bitbtnUpClick(Sender: TObject);
var
  new_RA, new_Dec:double;

begin
  //ascom_mount.Slew(Up)
  new_RA:=ascom_mount.RightAscension;

  new_Dec:=ascom_mount.Declination+trbarSlewVal.Position/scara;

  //ShowMessage(FloatToStr(ascom_mount.RightAscension)+ ' '+FloatToStr(ascom_mount.Declination)+#13+
  //                    FloatToStr(new_RA)+' '+FloatToStr(new_Dec));

  //ascom_mount.TargetRightAscension:=ascom_mount.RightAscension;
  //ascom_mount.TargetDeclination:=ascom_mount.Declination+trbarSlewVal.Position;

  //ShowMessage(FloatToStr(ascom_mount.TargetRightAscension)+ ' '+FloatToStr(ascom_mount.TargetDeclination));
  telescope_gotoRADec(new_RA, new_Dec);
end;

procedure TfrmMain.bitbtnDownClick(Sender: TObject);
var
  new_RA, new_Dec:double;
begin
  //ascom_mount.Slew(Down)
  new_RA:=ascom_mount.RightAscension;
  new_Dec:=ascom_mount.Declination-trbarSlewVal.Position/scara;

  //ShowMessage(FloatToStr(ascom_mount.RightAscension)+ ' Dec '+FloatToStr(ascom_mount.Declination)+#13+
  //                    FloatToStr(new_RA)+' '+FloatToStr(new_Dec));
  telescope_gotoRADec(new_RA, new_Dec);
end;

procedure TfrmMain.bitbtnLeftClick(Sender: TObject);
var
  new_RA, new_Dec:double;
begin
  //ascom_mount.Slew(Left)

  new_RA:=ascom_mount.RightAscension+trbarSlewVal.Position/15/scara;
  if new_RA>=24 then
     new_RA:=new_RA-24;
  new_Dec:=ascom_mount.Declination;

  //ShowMessage(FloatToStr(ascom_mount.RightAscension)+ ' Dec '+FloatToStr(ascom_mount.Declination)+#13+
  //                    FloatToStr(new_RA)+' '+FloatToStr(new_Dec));
  telescope_gotoRADec(new_RA, new_Dec);
end;

procedure TfrmMain.bitbtnRightClick(Sender: TObject);
var
  new_RA, new_Dec:double;
begin
  //ascom_mount.Slew(Right)
   new_RA:=ascom_mount.RightAscension-trbarSlewVal.Position/15/scara;
   if new_RA<0 then
     new_RA:=new_RA+24;
   new_Dec:=ascom_mount.Declination;

   //ShowMessage(FloatToStr(ascom_mount.RightAscension)+ ' Dec '+FloatToStr(ascom_mount.Declination)+#13+
   //                   FloatToStr(new_RA)+' '+FloatToStr(new_Dec));
   telescope_gotoRADec(new_RA, new_Dec);
end;

procedure TfrmMain.FormCreate(Sender: TObject);
begin
  frmMain.Caption:='My Telescope - '+version;
  telescope_status:=disconnected;
  stBar.Panels[0].Text:='DISCONNECTED';
  stBar.Panels[1].Text:='';
  stBar.Panels[2].Text:='';
  stBar.Panels[3].Text:=IntToStr(trbarSlewVal.Position)+'°';
  stBar.Panels[4].Text:='';
  lblTracking.Caption:='';
  scara:=1;
end;

procedure TfrmMain.bitbtnParkClick(Sender: TObject);
begin
    try
    // if ascom_mount.connected
    if ascom_mount.AtPark=false then
      begin
        ascom_mount.Park;
        stBar.Panels[2].Text:='Parking...';
        bitbtnPark.Caption:='Unpark';
        //telescope_status:=connected;
      end;
    if ascom_mount.AtPark=true then
     begin
       ascom_mount.UnPark;
       bitbtnPark.Caption:='Park';
       connect_telescope(Sender);

     end;
    except
       Showmessage('Error Unpark');
    end;


end;

procedure TfrmMain.bitbtnAbortClick(Sender: TObject);
begin
  Stop_Mount;

end;

procedure TfrmMain.toggScaleChange(Sender: TObject);
begin

 if toggScale.Checked then
   begin
     toggScale.Caption:='Scale: Fine';
     stBar.Panels[3].Text:=IntToStr(trbarSlewVal.Position)+'''';
     scara:=60
   end
  else
   begin
     toggScale.Caption:='Scale: Normal';
     stBar.Panels[3].Text:=IntToStr(trbarSlewVal.Position)+'°';
     scara:=1;
   end;
end;

procedure TfrmMain.trbarSlewValChange(Sender: TObject);
var
  ss:shortstring;
begin
  ss:='?';
  if scara=1 then
   ss:='°';
  if scara=60 then
   ss:='''';
  stBar.Panels[3].Text:=IntToStr(trbarSlewVal.Position)+ss;
end;

end.

