{
******************************************************
  Monkey Island Explorer
  Copyright (c) 2010 - 2011 Bgbennyboy
  Http://quick.mixnmojo.com
******************************************************
}

unit frmAbout;

interface

uses
  Windows, Forms, Controls, Classes, Graphics,
  ExtCtrls, JvExControls, JvScrollText,
  JCLShell,
  uMIExplorer_Const, pngimage;


type
  TAboutfrm = class(TForm)
    Image1: TImage;
    Image2: TImage;
    JvScrollText1: TJvScrollText;
    procedure FormCreate(Sender: TObject);
    procedure FormShow(Sender: TObject);
    procedure FormHide(Sender: TObject);
    procedure Image1Click(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  Aboutfrm: TAboutfrm;

implementation

{$R *.dfm}

procedure TAboutfrm.FormCreate(Sender: TObject);
begin
  //Add the version to the scrolling text
  JVScrollText1.Items.Strings[2]:='Version ' + strAppVersion;

  JVScrollText1.Font.Color:=clWhite;
  JVScrollText1.Font.Size:=14;

  Aboutfrm.Caption:='About ' + strAppName;
end;

procedure TAboutfrm.FormHide(Sender: TObject);
begin
  //JVScrollText1.Active:=false;
end;

procedure TAboutfrm.FormShow(Sender: TObject);
begin
  JVScrollText1.Active:=true;
end;

procedure TAboutfrm.Image1Click(Sender: TObject);
begin
  shellexec(0, 'open', 'Http://quick.mixnmojo.com','', '', SW_SHOWNORMAL);
end;

end.
