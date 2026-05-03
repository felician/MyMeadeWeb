unit uSettings;

{$mode ObjFPC}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, StdCtrls, Buttons;

type

  { TfrmSettings }

  TfrmSettings = class(TForm)
    bitbtnSave: TBitBtn;
    bitbtnCancel: TBitBtn;
    Button1: TButton;
    Edit1: TEdit;
    Edit2: TEdit;
    GroupBox1: TGroupBox;
    GroupBox2: TGroupBox;
    Label1: TLabel;
    Label2: TLabel;
    Label3: TLabel;
    procedure bitbtnSaveClick(Sender: TObject);
  private

  public

  end;

var
  frmSettings: TfrmSettings;

implementation

uses
  uMain;
{$R *.lfm}

{ TfrmSettings }

procedure TfrmSettings.bitbtnSaveClick(Sender: TObject);
begin
  frmMain.bitbtnService.Caption:=Edit1.Text;
  frmMain.bitbtnStart.Caption:=Edit2.Text;
end;

end.

