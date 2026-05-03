unit uProperties;

{$mode ObjFPC}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, StdCtrls;

type

  { TfrmProperties }

  TfrmProperties = class(TForm)
    memoProperties: TMemo;
    procedure FormShow(Sender: TObject);
  private

  public

  end;

var
  frmProperties: TfrmProperties;

implementation
uses
  uMain;
{$R *.lfm}

{ TfrmProperties }

procedure TfrmProperties.FormShow(Sender: TObject);
begin
  //
  memoProperties.Lines.Text:='';
  if  telescope_status=connected then {ascom}
    with memoProperties.Lines do
     begin
      Add('Ascom Telescope properties:');
      Add('Driver Info = '+ascom_mount.DriverInfo);
      Add('Driver Version = '+ascom_mount.DriverVersion);
      //Add('Interface Version = '+ascom_mount.InterfaceVersion);


      Add('Site Latitude = '+FloatToStr(ascom_mount.SiteLatitude));
      Add('Site Longitude = '+FloatToStr(ascom_mount.SiteLongitude));
      Add('Site Elevation = '+FloatToStr(ascom_mount.SiteElevation));



      if ascom_mount.AlignmentMode=0 then Add('Alignment Mode =  Altitude-Azimuth');
      if ascom_mount.AlignmentMode=1 then Add('Alignment Mode =  Polar (equatorial) mount other than German equatorial');
      if ascom_mount.AlignmentMode=2 then Add('Alignment Mode =  German equatorial mount');

      if ascom_mount.EquatorialSystem=0 then Add('Equatorial System = Custom or unknown equinox');
      if ascom_mount.EquatorialSystem=1 then Add('Equatorial System = Topocentric coordinates. Coordinates of the object at the current date having allowed for annual aberration, precession and nutation. This is the most common coordinate type for amateur telescopes.');
      if ascom_mount.EquatorialSystem=2 then Add('Equatorial System = J2000 equator/equinox. Coordinates of the object at mid-day on 1st January 2000, ICRS reference frame.');
      if ascom_mount.EquatorialSystem=3 then Add('Equatorial System = J2050 equator/equinox, ICRS reference frame.');
      if ascom_mount.EquatorialSystem=4 then Add('Equatorial System = B1950 equinox, FK4 reference frame.');

      Add('Aperture Area = '+FloatToStr(ascom_mount.ApertureArea)+' m2(sqm)');
      Add('Aperture Diameter = '+FloatToStr(ascom_mount.ApertureDiameter)+' meters');
      Add('Focal Length = '+FloatToStr(ascom_mount.FocalLength)+' meters');

      Add('Guide Rate Right Ascension = '+FloatToStr(ascom_mount.GuideRateRightAscension)+' °/s');
      Add('Guide Rate Declination = '+FloatToStr(ascom_mount.GuideRateDeclination)+' °/s');

      //Add('Tracking Rate = '+FloatToStr(ascom_mount.TrackingRate));
      if ascom_mount.TrackingRate=0 then Add('Tracking Rate = Sidereal tracking rate (15.041 arcseconds per second)');
      if ascom_mount.TrackingRate=1 then Add('Tracking Rate = Lunar tracking rate (14.685 arcseconds per second)');
      if ascom_mount.TrackingRate=2 then Add('Tracking Rate = Solar tracking rate (15.0 arcseconds per second)');
      if ascom_mount.TrackingRate=3 then Add('Tracking Rate = King tracking rate (15.0369 arcseconds per second)');

      Add('Slew Settle Time = '+FloatToStr(ascom_mount.SlewSettleTime)+' sec.');

      Add('Right Ascension Rate offset from sidereal = '+FloatToStr(ascom_mount.RightAscensionRate)+' sec/sid.sec');
      Add('Declination Rate offset from sidereal = '+FloatToStr(ascom_mount.DeclinationRate)+' arcsec/sid.sec');

      if ascom_mount.CanFindHome then
        Add('CanFindHome = YES') else Add('CanFindHome = NO');
      if ascom_mount.CanPark then
        Add('CanPark = YES') else Add('CanPark = NO');
      if ascom_mount.CanPulseGuide then
        Add('CanPulseGuide = YES') else Add('CanPulseGuide = NO');
      if ascom_mount.CanSetDeclinationRate then
        Add('CanSetDeclinationRate = YES') else Add('CanSetDeclinationRate = NO');
      if ascom_mount.CanSetGuideRates then
        Add('CanSetGuideRates = YES') else Add('CanSetGuideRates = NO');
      if ascom_mount.CanSetPark then
        Add('CanSetPark = YES') else Add('CanSetPark = NO');
      if ascom_mount.CanSetPierSide then
        Add('CanSetPierSide = YES') else Add('CanSetPierSide = NO');
      if ascom_mount.CanSetRightAscensionRate then
        Add('CanSetRightAscensionRate = YES') else Add('CanSetRightAscensionRate = NO');
      if ascom_mount.CanSetTracking then
        Add('CanSetTracking = YES') else Add('CanSetTracking = NO');
      if ascom_mount.CanSlew then
        Add('CanSlew = YES') else Add('CanSlew = NO');
      if ascom_mount.CanSlewAltAz then
        Add('CanSlewAltAz = YES') else Add('CanSlewAltAz = NO');
      if ascom_mount.CanSlewAltAzAsync then
        Add('CanSlewAltAzAsync = YES') else Add('CanSlewAltAzAsync = NO');
      if ascom_mount.CanSlewAsync then
        Add('CanSlewAsync = YES') else Add('CanSlewAsync = NO');
      if ascom_mount.CanSync then
        Add('CanSync = YES') else Add('CanSync = NO');
      if ascom_mount.CanSyncAltAz then
        Add('CanSyncAltAz = YES') else Add('CanSyncAltAz = NO');
      if ascom_mount.CanUnpark then
        Add('CanUnpark = YES') else Add('CanUnpark = NO');

     end;
end;

end.

