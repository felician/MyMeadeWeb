unit uGoto;

{$mode ObjFPC}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, StdCtrls, Spin,
  Buttons;

type

  { TfrmGoto }

  TfrmGoto = class(TForm)
    bitbtnEphem: TBitBtn;
    bitbtnRaDec: TBitBtn;
    bitbtnCancel: TBitBtn;
    bitbtnAzAlt: TBitBtn;
    edtRA: TEdit;
    edtDec: TEdit;
    edtAz: TEdit;
    edtAlt: TEdit;
    grpRADec1: TGroupBox;
    grpAzAlt: TGroupBox;
    lblDec2: TLabel;
    lblDecdeg1: TLabel;
    lblDecdeg2: TLabel;
    lblDecdeg3: TLabel;
    lblDecm1: TLabel;
    lblDecs1: TLabel;
    lblRA2: TLabel;
    lblRAh: TLabel;
    lblRA1: TLabel;
    lblDec1: TLabel;
    lblDecdeg: TLabel;
    lblRAh1: TLabel;
    lblRAh2: TLabel;
    lblRAh3: TLabel;
    lblRAm: TLabel;
    lblDecm: TLabel;
    lblRAm1: TLabel;
    lblRAs: TLabel;
    lblDecs: TLabel;
    lblRAs1: TLabel;
    spedRAh: TSpinEdit;
    spedDecd: TSpinEdit;
    spedAzd: TSpinEdit;
    spedAltd: TSpinEdit;
    spedRAm: TSpinEdit;
    spedDecm: TSpinEdit;
    spedAzm: TSpinEdit;
    spedAltm: TSpinEdit;
    spedRAs: TSpinEdit;
    spedDecs: TSpinEdit;
    spedAzs: TSpinEdit;
    spedAlts: TSpinEdit;
    procedure bitbtnAzAltClick(Sender: TObject);
    procedure bitbtnCancelClick(Sender: TObject);
    procedure bitbtnRaDecClick(Sender: TObject);
    procedure edtAltClick(Sender: TObject);
    procedure edtAzClick(Sender: TObject);
    procedure edtDecClick(Sender: TObject);
    procedure edtRAClick(Sender: TObject);
    procedure FormShow(Sender: TObject);
    procedure spedAltdChange(Sender: TObject);
    procedure spedAltmChange(Sender: TObject);
    procedure spedAltsChange(Sender: TObject);
    procedure spedAzdChange(Sender: TObject);
    procedure spedAzmChange(Sender: TObject);
    procedure spedAzsChange(Sender: TObject);
    procedure spedDecdChange(Sender: TObject);
    procedure spedDecmChange(Sender: TObject);
    procedure spedDecsChange(Sender: TObject);
    procedure spedRAhChange(Sender: TObject);
    procedure spedRAmChange(Sender: TObject);
    procedure spedRAsChange(Sender: TObject);
  private

  public

  end;

var
  frmGoto: TfrmGoto;

implementation
uses
  uMain;
{$R *.lfm}

{ TfrmGoto }

procedure TfrmGoto.FormShow(Sender: TObject);
var
  RA0, Dec0, Az0, Alt0:double;
begin
  RA0:=ascom_mount.RightAscension;
  Dec0:=ascom_mount.Declination;
  Az0:=ascom_mount.Azimuth;
  Alt0:=ascom_mount.Altitude;

  edtRA.Text:=FormatFloat('0.000000',RA0);
  edtDec.Text:=FormatFloat('0.000000',Dec0);

  spedRAh.Value:=trunc(RA0);
  spedRAm.Value:=trunc(60*(RA0-spedRAh.Value));
  spedRAs.Value:=trunc(60*(60*(RA0-spedRAh.Value)-spedRAm.Value));
  spedDecd.Value:=trunc(Dec0);
  spedDecm.Value:=trunc(60*(Dec0-spedDecd.Value));;
  spedDecs.Value:=trunc(60*(60*(Dec0-spedDecd.Value)-spedDecm.Value));

  edtAz.Text:=FormatFloat('0.000000',Az0);
  edtAlt.Text:=FormatFloat('0.000000',Alt0);

  spedAzd.Value:=trunc(Az0);
  spedAzm.Value:=trunc(60*(Az0-spedAzd.Value));
  spedAzs.Value:=trunc(60*(60*(Az0-spedAzd.Value)-spedAzm.Value));
  spedAltd.Value:=trunc(Alt0);
  spedAltm.Value:=trunc(60*(Alt0-spedAltd.Value));;
  spedAlts.Value:=trunc(60*(60*(Alt0-spedAltd.Value)-spedAltm.Value));

  GotoAction:=None;
end;

procedure TfrmGoto.spedAltdChange(Sender: TObject);
begin
  edtAlt.Text:=FormatFloat('0.000000',spedAltd.Value+spedAltm.Value/60+spedAlts.Value/3600);
end;

procedure TfrmGoto.spedAltmChange(Sender: TObject);
begin
  edtAlt.Text:=FormatFloat('0.000000',spedAltd.Value+spedAltm.Value/60+spedAlts.Value/3600);
end;

procedure TfrmGoto.spedAltsChange(Sender: TObject);
begin
  edtAlt.Text:=FormatFloat('0.000000',spedAltd.Value+spedAltm.Value/60+spedAlts.Value/3600);
end;

procedure TfrmGoto.spedAzdChange(Sender: TObject);
begin
  edtAz.Text:=FormatFloat('0.000000',spedAzd.Value+spedAzm.Value/60+spedAzs.Value/3600);
end;

procedure TfrmGoto.spedAzmChange(Sender: TObject);
begin
  edtAz.Text:=FormatFloat('0.000000',spedAzd.Value+spedAzm.Value/60+spedAzs.Value/3600);
end;

procedure TfrmGoto.spedAzsChange(Sender: TObject);
begin
  edtAz.Text:=FormatFloat('0.000000',spedAzd.Value+spedAzm.Value/60+spedAzs.Value/3600);
end;

procedure TfrmGoto.spedDecdChange(Sender: TObject);
begin
  edtDec.Text:=FormatFloat('0.000000',spedDecd.Value+spedDecm.Value/60+spedDecs.Value/3600);
end;

procedure TfrmGoto.spedDecmChange(Sender: TObject);
begin
  edtDec.Text:=FormatFloat('0.000000',spedDecd.Value+spedDecm.Value/60+spedDecs.Value/3600);
end;

procedure TfrmGoto.spedDecsChange(Sender: TObject);
begin
  edtDec.Text:=FormatFloat('0.000000',spedDecd.Value+spedDecm.Value/60+spedDecs.Value/3600);
end;

procedure TfrmGoto.spedRAhChange(Sender: TObject);
begin
  edtRA.Text:=FormatFloat('0.000000',spedRAh.Value+spedRAm.Value/60+spedRAs.Value/3600);
end;

procedure TfrmGoto.spedRAmChange(Sender: TObject);
begin
  edtRA.Text:=FormatFloat('0.000000',spedRAh.Value+spedRAm.Value/60+spedRAs.Value/3600);
end;

procedure TfrmGoto.spedRAsChange(Sender: TObject);
begin
  edtRA.Text:=FormatFloat('0.000000',spedRAh.Value+spedRAm.Value/60+spedRAs.Value/3600);
end;

procedure TfrmGoto.bitbtnRaDecClick(Sender: TObject);
begin
  GotoAction:=RADec;
  RA1:=StrToFloat(edtRA.Text);
  Dec1:=StrToFloat(edtDec.Text);
  //telescope_gotoAzAlt(StrToFloat(edtAz.Text), StrToFloat(edtAlt.Text));
end;

procedure TfrmGoto.bitbtnAzAltClick(Sender: TObject);
begin
  GotoAction:=AzAlt;
  Az1:=StrToFloat(edtAz.Text);
  Alt1:=StrToFloat(edtAlt.Text);
end;

procedure TfrmGoto.bitbtnCancelClick(Sender: TObject);
begin
  GotoAction:=None;
end;

procedure TfrmGoto.edtAltClick(Sender: TObject);
begin
  edtAlt.SelectAll;
end;

procedure TfrmGoto.edtAzClick(Sender: TObject);
begin
  edtAz.SelectAll;
end;

procedure TfrmGoto.edtDecClick(Sender: TObject);
begin
  edtDec.SelectAll;
end;

procedure TfrmGoto.edtRAClick(Sender: TObject);
begin
  edtRA.SelectAll;
end;

end.

