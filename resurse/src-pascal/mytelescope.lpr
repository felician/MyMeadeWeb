program mytelescope;

{$mode objfpc}{$H+}

uses
  {$IFDEF UNIX}
  cthreads,
  {$ENDIF}
  {$IFDEF HASAMIGA}
  athreads,
  {$ENDIF}
  Interfaces, // this includes the LCL widgetset
  Forms, uMain, uProperties, uGoto, uSettings
  { you can add units after this };

{$R *.res}

begin
  RequireDerivedFormResource:=True;
  Application.Title:='MyTelescope';
  Application.Scaled:=True;
  Application.Initialize;
  Application.CreateForm(TfrmMain, frmMain);
  Application.CreateForm(TfrmProperties, frmProperties);
  Application.CreateForm(TfrmGoto, frmGoto);
  Application.CreateForm(TfrmSettings, frmSettings);
  Application.Run;

end.

