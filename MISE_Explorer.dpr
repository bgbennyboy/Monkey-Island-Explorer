{
******************************************************
  Monkey Island Explorer
  Copyright (c) 2010 - 2011 Bgbennyboy
  Http://quick.mixnmojo.com
******************************************************
}

program MISE_Explorer;

uses
  Forms,
  frmMain in 'frmMain.pas' {formMain},
  uMIExplorer_Const in 'uMIExplorer_Const.pas',
  uMIExplorer_PAKManager in 'uMIExplorer_PAKManager.pas',
  uMIExplorer_Types in 'uMIExplorer_Types.pas',
  uMIExplorer_Base in 'uMIExplorer_Base.pas',
  uMIExplorer_Funcs in 'uMIExplorer_Funcs.pas',
  uMIExplorer_XWBManager in 'uMIExplorer_XWBManager.pas',
  frmAbout in 'frmAbout.pas' {Aboutfrm},
  uMIExplorer_BaseBundleManager in 'uMIExplorer_BaseBundleManager.pas',
  uMIExplorer_AnnotationManager in 'uMIExplorer_AnnotationManager.pas';

{$R *.res}

begin
  Application.Initialize;
  Application.MainFormOnTaskbar := True;
  Application.Title := 'Monkey Island SE Explorer';
  Application.CreateForm(TformMain, formMain);
  Application.CreateForm(TAboutfrm, Aboutfrm);
  Application.Run;
end.
