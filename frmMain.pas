{
******************************************************
  Monkey Island Explorer
  Copyright (c) 2010 - 2018 Bennyboy
  Http://quickandeasysoftware.net
******************************************************
}

unit frmMain;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls, Menus, ImgList, Buttons, ExtCtrls,
  JvBaseDlg, JvBrowseFolder, JvExStdCtrls, JvRichEdit, JvEdit, JvExControls,
  JvTracker, JvExExtCtrls, JvExtComponent, JvSplit, JvAnimatedImage, JvGIFCtrl,

  GR32_Image, pngimage, gr32, VirtualTrees,

  AdvMenus, AdvMenuStylers, AdvGlowButton,

  JCLSysInfo, JCLStrings, JCLShell, bass,

  uMIExplorer_Const, uMIExplorer_Base, uMIExplorer_Types, uMIExplorer_Funcs,
  System.ImageList;

type
  TformMain = class(TForm)
    OpenDialog1: TOpenDialog;
    panelButtons: TPanel;
    btnAbout: TAdvGlowButton;
    btnFilterView: TAdvGlowButton;
    btnSaveAllFiles: TAdvGlowButton;
    btnSaveFile: TAdvGlowButton;
    btnOpen: TAdvGlowButton;
    editFind: TJvEdit;
    panelPreviewContainer: TPanel;
    PanelPreviewAudio: TPanel;
    btnPlay: TSpeedButton;
    btnPause: TSpeedButton;
    btnStop: TSpeedButton;
    lblTime: TLabel;
    TrackBarAudio: TJvTracker;
    panelPreviewImage: TPanel;
    imagePreview: TImage32;
    panelPreviewText: TPanel;
    memoPreview: TMemo;
    panelBlank: TPanel;
    Image1: TImage;
    Tree: TVirtualStringTree;
    panelBottom: TPanel;
    memoLog: TJvRichEdit;
    SaveDialog1: TSaveDialog;
    dlgBrowseForSaveFolder: TJvBrowseForFolderDialog;
    AdvMenuOfficeStyler1: TAdvMenuOfficeStyler;
    PopupFileTypes: TAdvPopupMenu;
    popupOpen: TAdvPopupMenu;
    MenuItemOpenFolder: TMenuItem;
    N2: TMenuItem;
    MenuItemOpenMI1: TMenuItem;
    popupSave: TAdvPopupMenu;
    menuItemDumpFile: TMenuItem;
    menuItemDumpImage: TMenuItem;
    menuItemDumpDDSImage: TMenuItem;
    menuItemDumpText: TMenuItem;
    menuItemDumpWav: TMenuItem;
    popupSaveAll: TAdvPopupMenu;
    menuItemSaveAllRaw: TMenuItem;
    menuItemSaveAllImages: TMenuItem;
    menuItemSaveAllDDSImages: TMenuItem;
    menuItemSaveAllText: TMenuItem;
    menuItemSaveAllAudio: TMenuItem;
    MenuItemOpenMI2: TMenuItem;
    JvxSplitter1: TJvxSplitter;
    ImageList1: TImageList;
    panelProgress: TPanel;
    Image2: TImage;
    JvGIFAnimator1: TJvGIFAnimator;
    Timer1: TTimer;
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure editFindChange(Sender: TObject);
    procedure memoLogURLClick(Sender: TObject; const URLText: string;
      Button: TMouseButton);
    procedure OpenPopupMenuHandler(Sender: TObject);
    procedure TreeGetText(Sender: TBaseVirtualTree; Node: PVirtualNode;
      Column: TColumnIndex; TextType: TVSTTextType; var CellText: string);
    procedure TreeChange(Sender: TBaseVirtualTree; Node: PVirtualNode);
    procedure menuItemDumpFileClick(Sender: TObject);
    procedure btnSaveFileClick(Sender: TObject);
    procedure menuItemDumpImageClick(Sender: TObject);
    procedure menuItemDumpDDSImageClick(Sender: TObject);
    procedure menuItemDumpTextClick(Sender: TObject);
    procedure menuItemSaveAllRawClick(Sender: TObject);
    procedure btnSaveAllFilesClick(Sender: TObject);
    procedure menuItemSaveAllImagesClick(Sender: TObject);
    procedure btnAboutClick(Sender: TObject);
    procedure menuItemSaveAllDDSImagesClick(Sender: TObject);
    procedure menuItemSaveAllTextClick(Sender: TObject);
    procedure btnPauseClick(Sender: TObject);
    procedure btnPlayClick(Sender: TObject);
    procedure btnStopClick(Sender: TObject);
    procedure TrackBarAudioChangedValue(Sender: TObject; NewValue: Integer);
    procedure Timer1Timer(Sender: TObject);
    procedure TreeDblClick(Sender: TObject);
    procedure menuItemDumpWavClick(Sender: TObject);
    procedure menuItemSaveAllAudioClick(Sender: TObject);
    procedure TreeGetImageIndex(Sender: TBaseVirtualTree; Node: PVirtualNode;
      Kind: TVTImageKind; Column: TColumnIndex; var Ghosted: Boolean;
      var ImageIndex: TImageIndex);
  private
    fExplorer: TMIExplorerBase;
    fAudioStream: TMemoryStream;
    fAudioHandle: HSTREAM;
    fTotalTime: string;
    fTrackBarChanging: boolean;
    function IsViewFilteredByCategory: boolean;
    procedure OnDoneLoading(Count: integer);
    procedure DoLog(Text: string);
    procedure FreeResources;
    procedure StopAndFreeAudio;
    procedure ShowProgress(Running: boolean);
    procedure EnableDisableButtonsGlobal(Value: boolean);
    procedure EnableDisableButtons_TreeDependant;
    procedure AddFiletypePopupItems;
    procedure FilterNodesByFileExt(FileExt: string);
    procedure FilterNodesByFileExtArray(Extensions: array of string);
    procedure FileTypePopupMenuHandler(Sender: TObject);
    procedure OpenFile;
    procedure UpdateSaveAllMenu;
    procedure OnDebug(DebugText: string);
  public
    { Public declarations }
  end;

var
  formMain: TformMain;
  MyPopUpItems: array of TMenuItem;

const
  arrImageTypes: array[0..4] of string =(
   '.TGA',
   '.PNG',
   '.JPG',
   '.JPEG',
   '.GIF');

  arrDDSImageTypes: array[0..1] of string =(
   '.DDS',
   '.DXT');

  arrTextTypes: array[0..2] of string =(
   '.TXT',
   '.FX',
   '.CSV');

  arrAudioTypes: array[0..1] of string =(
   '.WAV',
   '.WMA');

  arrBundleTypes: array[0..1] of string =(
   '.000',
   '.001');

   arrSavedGameTypes: array[0..98] of string =(
   '.101', '.102', '.103', '.104', '.105', '.106', '.107', '.108',
   '.109', '.110', '.111', '.112', '.113', '.114', '.115', '.116',
   '.117', '.118', '.119', '.120', '.121', '.122', '.123', '.124',
   '.125', '.126', '.127', '.128', '.129', '.130', '.131', '.132',
   '.133', '.134', '.135', '.136', '.137', '.138', '.139', '.140',
   '.141', '.142', '.143', '.144', '.145', '.146', '.147', '.148',
   '.149', '.150', '.151', '.152', '.153', '.154', '.155', '.156',
   '.157', '.158', '.159', '.160', '.161', '.162', '.163', '.164',
   '.165', '.166', '.167', '.168', '.169', '.170', '.171', '.172',
   '.173', '.174', '.175', '.176', '.177', '.178', '.179', '.180',
   '.181', '.182', '.183', '.184', '.185', '.186', '.187', '.188',
   '.189', '.190', '.191', '.192', '.193', '.194', '.195', '.196',
   '.197', '.198', '.199');


  strWAVExt: string     = '.WAV';
  strLangDBExt: string    = '.LANGDB';
  strFontExt: string      = '.FONT';

implementation

uses frmAbout;

{$R *.dfm}


procedure TformMain.FormCreate(Sender: TObject);
begin
  formMain.Caption := strAppName + ' ' + strAppVersion;

  EditFind.Font.Size:=20;

  dlgBrowseforSavefolder.RootDirectory:=fdDesktopDirectory;
  dlgBrowseforSavefolder.RootDirectoryPath:=GetDesktopDirectoryFolder;

  SaveDialog1.InitialDir:=GetDesktopDirectoryFolder;
  JvxSplitter1.TopLeftLimit:=Tree.Constraints.MinWidth;

  lblTime.Font.Size := lblTime.Font.Size + 4;

  MemoLog.Clear;
  DoLog(strAppName + ' ' + strAppVersion);
  DoLog(strAppURL);

  {$IFDEF DebugMode}
    DoLog('Debug mode ON');
  {$ENDIF}

	// check the correct BASS dll was loaded
	if (HIWORD(BASS_GetVersion) <> BASSVERSION) then
	begin
		MessageBox(0, 'An incorrect version of BASS.DLL was loaded', nil, MB_ICONERROR);
		Halt;
	end;

	// Initialize audio - default device, 44100hz, stereo, 16 bits
	if not BASS_Init(-1, 44100, 0, Handle, nil) then
		MessageBox(0, 'Error initializing audio!', nil, MB_ICONERROR);

end;

procedure TformMain.FormDestroy(Sender: TObject);
begin
  FreeResources;
  BASS_Free;
end;

procedure TformMain.OpenFile;
begin
  FreeResources;
  try
    fExplorer:=TMIExplorerBase.Create(OpenDialog1.FileName, OnDebug);
    try
      EnableDisableButtonsGlobal(false);
      memoLog.Clear;
      Tree.Clear;
      fExplorer.OnDoneLoading:=OnDoneLoading;
      fExplorer.OnDebug:=OnDebug;
      Tree.Header.AutoFitColumns(true);

      fExplorer.Initialise;
      UpdateSaveAllMenu;
      DoLog('Opened file: ' + ExtractFileName( OpenDialog1.FileName ) );
    finally
      EnableDisableButtonsGlobal(true);
    end;
  except on E: EInvalidFile do
  begin
    DoLog(E.Message);
    FreeResources;
    EnableDisableButtonsGlobal(true);
  end;
  end;
end;

procedure TformMain.FreeResources;
var
  i: integer;
begin
  editFind.Text:='';
  tree.Clear;

  StopAndFreeAudio;

  //In case invalid files are opened twice in succession
  if fExplorer <> nil then
    FreeAndNil(FExplorer);

  if MyPopUpItems <> nil then
  begin
    for i:=low(mypopupitems) to high(mypopupitems) do
      mypopupitems[i].Free;

    MyPopUpItems:=nil;
  end;
end;










{******************   Custom Events   ******************}

procedure TformMain.DoLog(Text: string);
begin
  memoLog.Lines.Add(Text);
end;

procedure TformMain.OnDoneLoading(Count: integer);
begin
  Tree.RootNodeCount := Count;
  AddFileTypePopupItems;
end;

procedure TformMain.OnDebug(DebugText: string);
begin
  memoLog.Lines.Add(DebugText);
end;

procedure TformMain.ShowProgress(Running: boolean);
begin
  case Running of
    True:
    begin
      jvgifanimator1.Animate := true;
      panelProgress.Visible:=true;
      panelProgress.BringToFront;
    end;

    False:
    begin
      jvgifanimator1.Animate := false;
      panelProgress.Visible:=false;
    end;
  end;
end;







{******************   Form update stuff Stuff   ******************}
procedure TformMain.editFindChange(Sender: TObject);
var
  i, FoundPos: integer;
  TempNode: pVirtualNode;
begin
  //sometimes it still has focus when view is filtered by category
  if (editFind.Focused = false) then exit;

  if EditFind.Text = '' then
  begin
    // If view is filtered and someone clicks in the search box and out again without typing
    // anything , we dont want the view to change to show all nodes
    if IsViewFilteredByCategory = false then
      FilterNodesByFileExt('');

    exit;
  end;

  //Remove tick from all items
  for I := 0 to PopupFileTypes.Items.Count -1 do
  begin
    PopupFileTypes.Items[i].Checked:=false;
  end;

  tree.BeginUpdate;
  //Make them all visible again
  FilterNodesByFileExt('');

  TempNode:=Tree.GetFirst;
  while (tempNode <> nil) do
  begin
    FoundPos:=pos(uppercase(EditFind.Text), uppercase(fExplorer.FileName[TempNode.index]));

    if FoundPos > 0 then
    begin
      tree.IsVisible[TempNode]:=true;
    end
    else
      tree.IsVisible[TempNode]:=false;

    TempNode:=Tree.GetNext(TempNode);
  end;

  tree.EndUpdate;
end;

procedure TformMain.EnableDisableButtonsGlobal(Value: boolean);
begin
  btnOpen.Enabled:=Value;
  btnSaveFile.Enabled:=Value;
  btnSaveAllFiles.Enabled:=Value;
  tree.Enabled:=Value;
  btnFilterView.Enabled:=Value;
  btnAbout.Enabled:=Value;
  editFind.Enabled:=Value;

  btnPlay.Enabled:=Value;
  btnPause.Enabled:=Value;
  btnStop.Enabled:=Value;
  TrackBarAudio.Enabled:=Value;

  if Value then EnableDisableButtons_TreeDependant;
end;

procedure TformMain.EnableDisableButtons_TreeDependant;
var
  NodeIsSelected: boolean;
  Ext: string;
begin
  if Tree.RootNodeCount > 0 then
    btnSaveAllFiles.Enabled:=true
  else
    btnSaveAllFiles.Enabled:=false;

  NodeIsSelected := Tree.SelectedCount > 0;
  btnSaveFile.Enabled:=NodeIsSelected;

  if NodeIsSelected then
  begin
    ext:=Uppercase(extractfileext(fExplorer.FileName[Tree.focusednode.Index]));
    menuItemDumpImage.Visible:= (StrIndex(Ext, arrImageTypes) > -1) or (StrIndex(Ext, arrDDSImageTypes) > -1);
    menuItemDumpDDSImage.Visible:=StrIndex(Ext, arrDDSImageTypes) > -1;
    menuItemDumpText.Visible:= (StrIndex(Ext, arrTextTypes) > -1);
    //menuItemDumpOgg.Visible:= Ext = strOggExt;
    menuItemDumpWav.Visible:= Ext = strWAVExt;
  end;
end;

procedure TformMain.memoLogURLClick(Sender: TObject; const URLText: string;
  Button: TMouseButton);
begin
  shellexec(0, 'open', URLText,'', '', SW_SHOWNORMAL);
end;


procedure TformMain.UpdateSaveAllMenu;
var
  i: integer;
  Ext: string;
begin
  {Parse through all files and enable the appropriate menu if it finds
  corresponding file type}

  if Tree.RootNodeCount = 0 then exit;


  menuItemSaveAllImages.Visible:=false;
  menuItemSaveAllText.Visible:=false;
  menuItemSaveAllDDSImages.Visible:=false;
  menuItemSaveAllAudio.Visible:=false;


  for i:=0 to tree.RootNodeCount -1 do
  begin
    ext:=Uppercase(extractfileext(extractfileext(fExplorer.FileName[i])));
    if StrIndex(Ext, arrImageTypes) > -1 then
      menuItemSaveAllImages.Visible:=true;
    if StrIndex(Ext, arrDDSImageTypes) > -1 then
    begin
      menuItemSaveAllImages.Visible:=true;
      menuItemSaveAllDDSImages.Visible:=true;
    end;
    if (StrIndex(Ext, arrTextTypes) > -1) or (ext = strLangDBExt) then
      menuItemSaveAllText.Visible:=true;
    if (StrIndex(Ext, arrAudioTypes) > -1) then
      menuItemSaveAllAudio.Visible:=true;
  end;
end;








{******************   Tree Stuff   ******************}

procedure TformMain.TreeChange(Sender: TBaseVirtualTree; Node: PVirtualNode);
var
  ext: string;
begin
  EnableDisableButtons_TreeDependant;

  if Tree.RootNodeCount=0 then exit;
  if Tree.SelectedCount=0 then exit;

  panelBlank.BringToFront;
  //Clear resources here just to save memory ie not leaving a big image hanging around
  imagePreview.Bitmap.Clear;
  memoPreview.Clear;

  ext:=Uppercase(extractfileext(fExplorer.FileName[Tree.focusednode.Index]));

  //Other images
  if StrIndex(Ext, arrImageTypes) > -1 then
  begin
    panelPreviewImage.BringToFront;
    fExplorer.DrawImageGeneric(Tree.focusednode.Index, imagePreview.Bitmap);
  end;

  //Text types
  if StrIndex(Ext, arrTextTypes) > -1 then
  begin
    panelPreviewText.BringToFront;
    memoPreview.Clear;
    fExplorer.ReadText(Tree.focusednode.Index, memoPreview.Lines);
  end;

  //DDS Images
  if StrIndex(Ext, arrDDSImageTypes) > -1 then
  begin
    panelPreviewImage.BringToFront;
    fExplorer.DrawImageDDS(Tree.focusednode.Index, imagePreview.Bitmap);
  end;



  {
  //Text types
  if StrIndex(Ext, arrTextTypes) > -1 then
  begin
    AddTextToPreviewMemo(Tree.focusednode.Index);
  end;}

  //Audio types
  if StrIndex(Ext, arrAudioTypes) > -1 then
  begin
    panelPreviewAudio.BringToFront;
  end;
end;

procedure TformMain.TreeDblClick(Sender: TObject);
var
  ext: string;
begin
  ext:=Uppercase(extractfileext(fExplorer.FileName[Tree.focusednode.Index]));

  //Audio types
  if StrIndex(Ext, arrAudioTypes) > -1 then
  begin
    panelPreviewAudio.BringToFront;
    StopAndFreeAudio;
    btnPlay.Click;
  end;


end;

procedure TformMain.TreeGetImageIndex(Sender: TBaseVirtualTree;
  Node: PVirtualNode; Kind: TVTImageKind; Column: TColumnIndex;
  var Ghosted: Boolean; var ImageIndex: TImageIndex);
var
  Ext: string;
begin
  if column <> 0 then exit;
  if Kind = ikOverlay then exit;

  Ext:=Uppercase(extractfileext(fExplorer.FileName[node.index]));
  if StrIndex(Ext, arrImageTypes) > -1 then
    ImageIndex:= 8
  else
  if StrIndex(Ext, arrDDSImageTypes) > -1 then
    ImageIndex:= 8
  else
  if StrIndex(Ext, arrTextTypes) > -1 then
    ImageIndex:=9
  else
  if StrIndex(Ext, arrAudioTypes) > -1 then
    ImageIndex:=12
  else
  if StrIndex(Ext, arrBundleTypes) > -1 then
    ImageIndex:=13
  else
    ImageIndex:=5;

end;

procedure TformMain.TreeGetText(Sender: TBaseVirtualTree; Node: PVirtualNode;
  Column: TColumnIndex; TextType: TVSTTextType; var CellText: string);
begin
  case Column of
    0: Celltext := fExplorer.FileName[node.index];
    1: Celltext := inttostr(fExplorer.FileSize[node.index] );
    2: Celltext := inttostr (fExplorer.FileOffset[node.index] );
  end;
end;










{******************   Category Filtering Stuff   ******************}

function TformMain.IsViewFilteredByCategory: boolean;
var
  i: integer;
begin
  result:=false;
  for I := 0 to PopupFileTypes.Items.Count -1 do
  begin
    if PopupFileTypes.Items[i].Checked then
      result:=true;
  end;
end;

procedure TformMain.AddFiletypePopupItems;
var
  FileTypes: TStringList;
  tempStr: string;
  i: integer;
begin
  Filetypes:=tstringlist.Create;
  try
    for i:=0 to tree.RootNodeCount -1 do
    begin
      tempStr:=copy(extractfileext(fExplorer.FileName[i]),
               1, length(extractfileext(fExplorer.FileName[i])));

      if (FileTypes.IndexOf(tempStr)=-1) and (tempStr > '' ) then
      begin
        if StrIndex(tempStr, arrSavedGameTypes) > -1 then //Its a saved game filetype
        begin
          if FileTypes.IndexOf(strViewSavedGameFiles) = -1 then //If doesnt already exist
            FileTypes.Add(strViewSavedGameFiles) //Add the saved games menu item
        end

        else //Just add the file extension
          FileTypes.Add(tempStr);
      end;
    end;
    FileTypes.Sort;

    SetLength(MyPopupItems, Filetypes.Count + 2); //+2 for 'all files' and line break
    for i:=low(mypopupitems) to high(mypopupitems) -2 do
    begin
      MyPopUpItems[i]:=TMenuItem.Create(Self);
      MyPopUpItems[i].Caption:=FileTypes[i];
      MyPopUpItems[i].tag:=i + 2;
      PopupFileTypes.Items.add(MyPopupItems[i]);
      MyPopUpItems[i].OnClick:=FileTypePopupMenuHandler;

      //icons
      tempStr:=Uppercase(FileTypes[i]);
      if StrIndex(tempStr, arrImageTypes) > -1 then
        MyPopupItems[i].ImageIndex:=8
      else
      if StrIndex(tempStr, arrDDSImageTypes) > -1 then
        MyPopupItems[i].ImageIndex:=8
      else
      if StrIndex(tempStr, arrTextTypes) > -1 then
        MyPopupItems[i].ImageIndex:=9
      else
      if StrIndex(tempStr, arrAudioTypes) > -1 then
        MyPopupItems[i].ImageIndex:=12
      else
      if StrIndex(tempStr, arrBundleTypes) > -1 then
        MyPopupItems[i].ImageIndex:=13
      else
        MyPopupItems[i].ImageIndex:=5
      //MyPopUpItems[i].ImageIndex:=GetImageIndex(FileTypes[i]);
    end;

    //Add 'all files' menu item
    i:=high(mypopupitems);
    MyPopUpItems[i]:=TMenuItem.Create(Self);
    MyPopUpItems[i].Caption:=strViewAllFiles;
    MyPopUpItems[i].tag:=0;
    MyPopUpItems[i].Checked:=true;
    //MyPopUpItems[i].ImageIndex:=5;
    popupFileTypes.Items.Insert(0, MyPopUpItems[i]);
    MyPopUpItems[i].OnClick:=FileTypePopupMenuHandler;

    //Add line break menu item
    i:=high(mypopupitems)-1;
    MyPopUpItems[i]:=TMenuItem.Create(Self);
    MyPopUpItems[i].Caption:='-';
    MyPopUpItems[i].tag:=1;
    MyPopUpItems[i].Checked:=true;
    //MyPopUpItems[i].ImageIndex:=5;
    popupFileTypes.Items.Insert(1, MyPopUpItems[i]);
  finally
    Filetypes.Free;
  end;
end;

procedure TformMain.FilterNodesByFileExt(FileExt: string);
var
  TempNode: PVirtualNode;
begin
  if Tree.RootNodeCount=0 then exit;

  Tree.BeginUpdate;
  try
    TempNode:=Tree.GetFirst;
    while (tempNode <> nil) do
    begin
      if FileExt = '' then //Show all nodes
        Tree.IsVisible[TempNode]:=true
      else
      if extractfileext( fExplorer.FileName[TempNode.Index] )=FileExt then
       Tree.IsVisible[TempNode]:=true
      else
        Tree.IsVisible[TempNode]:=false;

      TempNode:=Tree.GetNext(TempNode);
    end;
  finally
    Tree.EndUpdate;
  end;
end;

procedure TformMain.FilterNodesByFileExtArray(Extensions: array of string);
var
  TempNode: PVirtualNode;
begin
  if Tree.RootNodeCount=0 then exit;

  Tree.BeginUpdate;
  try
    TempNode:=Tree.GetFirst;
    while (tempNode <> nil) do
    begin
      if StrIndex(extractfileext( fExplorer.FileName[TempNode.Index] ), Extensions) > -1 then
       Tree.IsVisible[TempNode]:=true
      else
        Tree.IsVisible[TempNode]:=false;

      TempNode:=Tree.GetNext(TempNode);
    end;
  finally
    Tree.EndUpdate;
  end;
end;







{******************     Popup Handlers     ******************}

procedure TformMain.OpenPopupMenuHandler(Sender: TObject);
var
  SenderName: string;
begin
  SenderName := tmenuitem(sender).Name;

  if SenderName = 'MenuItemOpenFolder' then
    OpenDialog1.InitialDir:=''
  else
  if SenderName = 'MenuItemOpenMI1' then
    OpenDialog1.InitialDir:=GetMI1SEPath
  else
  if SenderName = 'MenuItemOpenMI2' then
    OpenDialog1.InitialDir:=GetMI2SEPath;



  if OpenDialog1.Execute then
    OpenFile;
end;

procedure TformMain.FileTypePopupMenuHandler(Sender: TObject);
var
  tempStr: string;
  i: integer;
begin
  if Tree.RootNodeCount=0 then exit;

  editFind.Text:=''; //doing editFind.clear doesnt show the 'search' default text
  tree.SetFocus; //take the focus away from the search editbox if it has it

  with Sender as TMenuItem do
  begin
    tempStr:=caption;
    StrReplace(tempStr, '&', '',[rfIgnoreCase, rfReplaceAll]);
    if tempStr = strViewAllFiles then
      FilterNodesByFileExt('')
    else
    if tempStr = strViewSavedGameFiles then
      FilterNodesByFileExtArray(arrSavedGameTypes)
    else
      FilterNodesByFileExt(tempStr);

    //DoLog('Filtered view by category: ' + temp);
  end;

  //Remove tick from all items
  for I := 0 to PopupFileTypes.Items.Count -1 do
  begin
    PopupFileTypes.Items[i].Checked:=false;
  end;

  //Add tick to the item
  with Sender as TMenuItem do
  begin
    PopupFileTypes.Items[tag].Checked:=true;
  end;
end;






{******************   Save Stuff   ******************}

procedure TformMain.menuItemDumpFileClick(Sender: TObject);
begin
  btnSaveFile.OnClick(formMain);
end;

procedure TformMain.menuItemDumpImageClick(Sender: TObject);
var
  TempPng: TPngImage;
  TempBmp: TBitmap;
  TempBmp32: TBitmap32;
  Ext: string;
  DecodeResult: boolean;
begin
  if Tree.RootNodeCount=0 then exit;
  if Tree.SelectedCount=0 then exit;

  SaveDialog1.Filter:='Png files|*.png';
  SaveDialog1.DefaultExt:='.png';
  SaveDialog1.FileName:= SanitiseFileName( ChangeFileExt(fExplorer.FileName[Tree.focusednode.Index], '' ) );
  if SaveDialog1.Execute = false then exit;

  DecodeResult:=false;
  ext:=Uppercase(extractfileext(fExplorer.FileName[Tree.focusednode.Index]));

  TempPng:=TPngImage.Create;
  try
    EnableDisableButtonsGlobal(false);
    DoLog(strSavingFile + SaveDialog1.FileName);

    TempBmp32:=TBitmap32.Create;
    try
      if StrIndex(Ext, arrDDSImageTypes) > -1 then
      begin
        DecodeResult:=fExplorer.DrawImageDDS(Tree.focusednode.Index, TempBmp32)
      end
      else
        DecodeResult:=fExplorer.DrawImageGeneric(Tree.focusednode.Index, TempBmp32) ;

      if DecodeResult = false then
      begin
        DoLog('Image decode failed! Save cancelled.');
        exit;
      end;

      TempBmp:=TBitmap.Create;
      try
        TempBmp.Assign(TempBmp32);
        TempPng.Assign(TempBmp);
      finally
        TempBmp.Free;
      end;
      TempPng.SaveToFile(SaveDialog1.FileName);
    finally
      TempBmp32.Free;
    end;
  finally
    TempPng.Free;
    if DecodeResult = true then DoLog(strDone);
    EnableDisableButtonsGlobal(true);
  end;

end;

procedure TformMain.menuItemDumpTextClick(Sender: TObject);
var
  TempStrings: TStringList;
begin
  if Tree.RootNodeCount=0 then exit;
  if Tree.SelectedCount=0 then exit;

  SaveDialog1.Filter:='Text files|*.txt';
  SaveDialog1.DefaultExt:='.txt';
  SaveDialog1.FileName:= SanitiseFileName( ChangeFileExt(fExplorer.FileName[Tree.focusednode.Index], '' ) );
  if SaveDialog1.Execute = false then exit;

  TempStrings:=TStringList.Create;
  try
    EnableDisableButtonsGlobal(false);
    DoLog(strSavingFile + SaveDialog1.FileName);

    fExplorer.ReadText(Tree.focusednode.Index, TempStrings);

    TempStrings.SaveToFile( SaveDialog1.FileName );
  finally
    TempStrings.Free;
    DoLog(strDone);
    EnableDisableButtonsGlobal(true);
  end;

end;

procedure TformMain.menuItemDumpWavClick(Sender: TObject);
var
  Ext: string;
  DecodeResult: boolean;
begin
  if Tree.RootNodeCount=0 then exit;
  if Tree.SelectedCount=0 then exit;

  SaveDialog1.Filter:='WAV files|*.wav';
  SaveDialog1.DefaultExt:='.wav';
  SaveDialog1.FileName:=ChangeFileExt(fExplorer.FileName[Tree.focusednode.Index], '' );
  if SaveDialog1.Execute = false then exit;

  DecodeResult:=false;
  ext:=Uppercase(extractfileext(fExplorer.FileName[Tree.focusednode.Index]));
  EnableDisableButtonsGlobal(false);
  try
    DoLog(strSavingFile + SaveDialog1.FileName);

    if StrIndex(Ext, arrAudioTypes) > -1 then
    if Ext = strWavExt then
      DecodeResult:=fExplorer.SaveWavToFile(Tree.focusednode.Index, ExtractFilePath(SaveDialog1.FileName), ExtractFileName(SaveDialog1.FileName))
    else
    begin
      DoLog('Not a recognised audio type file extension! Save cancelled.');
      DecodeResult:=false;
    end;
  finally
    if DecodeResult = true then DoLog(strDone);
    EnableDisableButtonsGlobal(true);
  end;


end;

procedure TformMain.menuItemSaveAllAudioClick(Sender: TObject);
var
  TempNode: pVirtualNode;
  Ext: string;
  DecodeResult: boolean;
begin
  if Tree.RootNodeCount=0 then exit;
  if dlgBrowseforSaveFolder.Execute = false then exit;

  EnableDisableButtonsGlobal(false);
  try
    DoLog(strDumpingAllAudio);
    ShowProgress(True);

    TempNode:=Tree.GetFirst;
    while (tempNode <> nil) do
    begin
      Ext:=Uppercase(extractfileext( fExplorer.FileName[TempNode.Index] ));
      if StrIndex(Ext, arrAudioTypes) = -1 then //not an audio file
      begin
        TempNode:=Tree.GetNext(TempNode);
        continue;
      end;

      DecodeResult:=false;
      if Ext = strWavExt then
        DecodeResult:=fExplorer.SaveWavToFile(TempNode.Index, IncludeTrailingPathDelimiter(dlgBrowseForSaveFolder.Directory), ChangeFileExt(fExplorer.FileName[TempNode.Index], '.wav'));

      if DecodeResult = false then
      begin
        TempNode:=Tree.GetNext(TempNode);
        Application.ProcessMessages;
        continue;
      end;

      Application.ProcessMessages;
      TempNode:=Tree.GetNext(TempNode);
    end;

  finally
    EnableDisableButtonsGlobal(true);
    ShowProgress(False);
    DoLog(strDone);
  end;

end;

procedure TformMain.menuItemSaveAllDDSImagesClick(Sender: TObject);
var
  TempNode: pVirtualNode;
  Ext: string;
  DecodeResult: boolean;
begin
  if Tree.RootNodeCount=0 then exit;
  if dlgBrowseforSaveFolder.Execute = false then exit;

  EnableDisableButtonsGlobal(false);
  try
    DoLog(strDumpingAllDDSImages);
    ShowProgress(True);

    TempNode:=Tree.GetFirst;
    while (tempNode <> nil) do
    begin
      Ext:=Uppercase(extractfileext( fExplorer.FileName[TempNode.Index] ));
      if StrIndex(Ext, arrDDSImageTypes) = -1 then //not DDS image
      begin
        TempNode:=Tree.GetNext(TempNode);
        continue;
      end;

      DecodeResult:=false;
      if StrIndex(Ext, arrDDSImageTypes) > -1 then
      begin
        ForceDirectories(extractfilepath(IncludeTrailingPathDelimiter(dlgBrowseForSaveFolder.Directory) + ExtractPartialPath( fExplorer.FileName[TempNode.Index])));
        DecodeResult:=fExplorer.SaveDDSToFile(TempNode.Index, IncludeTrailingPathDelimiter(dlgBrowseForSaveFolder.Directory), ChangeFileExt(fExplorer.FileName[TempNode.Index], '.dds'))
      end;

      if DecodeResult = false then
      begin
        TempNode:=Tree.GetNext(TempNode);
        Application.ProcessMessages;
        continue;
      end;

      Application.ProcessMessages;
      TempNode:=Tree.GetNext(TempNode);
    end;

  finally
    EnableDisableButtonsGlobal(true);
    ShowProgress(False);
    DoLog(strDone);
  end;

end;

procedure TformMain.menuItemSaveAllImagesClick(Sender: TObject);
var
  TempPng: TPngImage;
  TempBmp: TBitmap;
  TempBmp32: TBitmap32;
  TempNode: pVirtualNode;
  Ext: string;
  DecodeResult: boolean;
begin
  if Tree.RootNodeCount=0 then exit;
  if dlgBrowseforSaveFolder.Execute = false then exit;

  TempPng:=TPngImage.Create;
  TempBmp32:=TBitmap32.Create;
  TempBmp:=TBitmap.Create;
  try
    EnableDisableButtonsGlobal(false);
    ShowProgress(True);
    DoLog(strDumpingAllImages);

    TempNode:=Tree.GetFirst;
    while (tempNode <> nil) do
    begin
      Ext:=Uppercase(ExtractFileExt( fExplorer.FileName[TempNode.Index] ));
      if (StrIndex(Ext, arrImageTypes) = -1) and (StrIndex(Ext, arrDDSImageTypes) = -1) then //not an image
      begin
        TempNode:=Tree.GetNext(TempNode);
        continue;
      end;

      TempBmp32.Clear;
      TempBmp.Assign(nil);

      if StrIndex(Ext, arrDDSImageTypes) > -1 then
      begin
        DecodeResult:=fExplorer.DrawImageDDS(TempNode.Index, TempBmp32)
      end
      else
        DecodeResult:=fExplorer.DrawImageGeneric(TempNode.Index, TempBmp32);

      if DecodeResult = false then
      begin
        TempNode:=Tree.GetNext(TempNode);
        continue;
      end;

      TempBmp.Assign(TempBmp32);
      TempPng.Assign(TempBmp);
      ForceDirectories(extractfilepath(IncludeTrailingPathDelimiter(dlgBrowseForSaveFolder.Directory) + ExtractPartialPath( fExplorer.FileName[TempNode.Index])));
      TempPng.SaveToFile(IncludeTrailingPathDelimiter(dlgBrowseForSaveFolder.Directory) +  ChangeFileExt(fExplorer.FileName[TempNode.Index], '.png'));

      Application.ProcessMessages;
      TempNode:=Tree.GetNext(TempNode);
    end;

  finally
    TempPng.Free;
    TempBmp32.Free;
    TempBmp.Free;
    EnableDisableButtonsGlobal(true);
    ShowProgress(False);
    DoLog(strDone);
  end;

end;

procedure TformMain.menuItemSaveAllRawClick(Sender: TObject);
begin
  btnSaveAllFiles.OnClick(formMain);
end;

procedure TformMain.menuItemSaveAllTextClick(Sender: TObject);
var
  TempStrings: TStringList;
  TempNode: pVirtualNode;
  Ext: string;
begin
  if Tree.RootNodeCount=0 then exit;
  if dlgBrowseforSaveFolder.Execute = false then exit;

  TempStrings:=TStringList.Create;
  try
    EnableDisableButtonsGlobal(false);
    ShowProgress(True);
    DoLog(strDumpingAllText);

    TempNode:=Tree.GetFirst;
    while (tempNode <> nil) do
    begin
      Ext:=Uppercase( extractfileext( fExplorer.FileName[TempNode.Index] ));
      if (StrIndex(Ext, arrTextTypes) = -1) and (Ext <> strLangDBExt) then //not text
      begin
        TempNode:=Tree.GetNext(TempNode);
        continue;
      end;

      TempStrings.Clear;
      fExplorer.ReadText(TempNode.Index, TempStrings);

      ForceDirectories(extractfilepath(IncludeTrailingPathDelimiter(dlgBrowseForSaveFolder.Directory) + ExtractPartialPath( fExplorer.FileName[TempNode.Index])));
      TempStrings.SaveToFile( IncludeTrailingPathDelimiter(dlgBrowseForSaveFolder.Directory) + ChangeFileExt(fExplorer.FileName[TempNode.Index], '.txt') );
      TempNode:=Tree.GetNext(TempNode);
      Application.ProcessMessages;
    end;

  finally
    TempStrings.Free;
    EnableDisableButtonsGlobal(true);
    ShowProgress(False);
    DoLog(strDone);
  end;

end;

procedure TformMain.menuItemDumpDDSImageClick(Sender: TObject);
var
  Ext: string;
  DecodeResult: boolean;
begin
  if Tree.RootNodeCount=0 then exit;
  if Tree.SelectedCount=0 then exit;

  SaveDialog1.Filter:='DDS files|*.dds';
  SaveDialog1.DefaultExt:='.dds';
  SaveDialog1.FileName:= SanitiseFileName (ChangeFileExt(fExplorer.FileName[Tree.focusednode.Index], '' ) );
  if SaveDialog1.Execute = false then exit;

  DecodeResult:=false;
  ext:=Uppercase(extractfileext(fExplorer.FileName[Tree.focusednode.Index]));
  EnableDisableButtonsGlobal(false);
  try
    DoLog(strSavingFile + SaveDialog1.FileName);

    if StrIndex(Ext, arrDDSImageTypes) > -1 then
    begin
      DecodeResult:=fExplorer.SaveDDSToFile(Tree.focusednode.Index,ExtractFilePath(SaveDialog1.FileName), ExtractFileName(SaveDialog1.FileName))
    end
    else
    begin
      DoLog('Not a recognised dds type file extension! Save cancelled.');
      DecodeResult:=false;
    end;
  finally
    if DecodeResult = true then DoLog(strDone);
    EnableDisableButtonsGlobal(true);
  end;

end;

procedure TformMain.btnSaveAllFilesClick(Sender: TObject);
begin
  if Tree.RootNodeCount=0 then exit;
  if dlgBrowseforSaveFolder.Execute = false then exit;

  ShowProgress(true);
  EnableDisableButtonsGlobal(false);
  try
    DoLog(strDumpingAllFiles);
    fExplorer.SaveFiles(dlgBrowseForSaveFolder.Directory);
  finally
    EnableDisableButtonsGlobal(true);
    ShowProgress(False);
    DoLog(strDone);
  end;
end;

procedure TformMain.btnSaveFileClick(Sender: TObject);
begin
  if Tree.RootNodeCount=0 then exit;
  if Tree.SelectedCount=0 then exit;

  SaveDialog1.Filter:='All Files|*.*';
  SaveDialog1.DefaultExt:='';

  SaveDialog1.FileName := SanitiseFileName( fExplorer.FileName[Tree.focusednode.Index] );

  if SaveDialog1.Execute = false then exit;

  DoLog(strSavingFile + SaveDialog1.FileName);
  EnableDisableButtonsGlobal(false);
  try
    fExplorer.SaveFile(Tree.focusednode.Index, ExtractFilePath(SaveDialog1.FileName), ExtractFileName(SaveDialog1.FileName));
  finally
    DoLog(strDone);
    EnableDisableButtonsGlobal(true);
    //Progressbar1.Position:=0;
  end;
end;










{***********************   Audio Playback Stuff   ***********************}
procedure TformMain.StopAndFreeAudio;
begin
  BASS_ChannelSlideAttribute(fAudioHandle, BASS_ATTRIB_VOL, 0, 500);
  Sleep(500);
  BASS_ChannelStop(fAudioHandle);
  BASS_StreamFree(fAudioHandle);
  TrackBarAudio.Value := 0;
  lblTime.Caption := '';
  fTotalTime := '';

  if fAudioStream <> nil then
    FreeAndNil(fAudioStream);
end;

procedure TformMain.btnAboutClick(Sender: TObject);
begin
  AboutFrm.ShowModal;
end;

procedure TformMain.btnPauseClick(Sender: TObject);
begin
  if BASS_ChannelPause(fAudioHandle) = false then
    if BASS_ErrorGetCode = BASS_ERROR_ALREADY then //Already paused
      BASS_ChannelPlay(fAudioHandle, False)
end;

procedure TformMain.btnPlayClick(Sender: TObject);
var
  DecodeResult: boolean;
  Ext, strSecs: string;
  ByteLength: QWord;
  SecsLength: Double;
  Seconds: Integer;
begin
  if Tree.RootNodeCount=0 then exit;
  if Tree.SelectedCount=0 then exit;

  ext := Uppercase(extractfileext(fExplorer.FileName[Tree.focusednode.Index]));

  if StrIndex(Ext, arrAudioTypes) = -1 then
  begin
    DoLog('File not recognised audio type');
    exit;
  end;

  BASS_StreamFree(fAudioHandle);
  if fAudioStream <> nil then
    FreeAndNil(fAudioStream);

  fAudioStream := TMemoryStream.Create;
  try
    DecodeResult:=false;

    if ext = strWAVExt then
      DecodeResult:=fExplorer.SaveWavToStream(Tree.focusednode.Index, fAudioStream);

    if DecodeResult = false then exit;

    //fAudioStream.SaveToFile('c:\users\ben\desktop\musictest.wav');

    fAudioStream.Position:=0;
    fAudioHandle := BASS_StreamCreateFile(True, fAudioStream.Memory, 0, fAudioStream.Size, BASS_UNICODE);

    //if fAudioHandle = 0 then exit;


	if not BASS_ChannelPlay(fAudioHandle, True) then
    begin
		DoLog('Error playing stream! Error code:' + inttostr(BASS_ErrorGetCode));
		Exit;
    end;


    ByteLength := BASS_ChannelGetLength(fAudioHandle, BASS_POS_BYTE);
    SecsLength := BASS_ChannelBytes2Seconds(fAudioHandle, ByteLength);
    Seconds := Trunc(SecsLength);

    strSecs := IntToStr(Seconds mod 60);
    if Seconds mod 60 < 10 then
      strSecs := '0' + strSecs;
    fTotalTime:= ' / ' + Format('%d:%s', [Seconds div 60, strSecs]);
    //lblCurrentlyPlaying.Caption :=fExplorer.FileName[Tree.focusednode.Index];

    TrackBarAudio.Value := 0;
    TrackBarAudio.Maximum:= round(BASS_ChannelBytes2Seconds(fAudioHandle, BASS_ChannelGetLength(fAudioHandle, BASS_POS_BYTE)));
    fTrackBarChanging := false;

    Timer1.Enabled := true;
  finally
    //fAudioStream.Free;
  end;

end;

function SecToTime(Sec: Integer): string;
var
  H, M, S: string;
  ZH, ZM, ZS: Integer;
begin
  ZH := Sec div 3600;
  ZM := Sec div 60 - ZH * 60;
  ZS := Sec - (ZH * 3600 + ZM * 60) ;
  H := IntToStr(ZH) ;

  if ZM mod 60 < 10 then
    M := '0' + IntToStr(ZM)
  else
    M := IntToStr(ZM) ;
  if ZS mod 60 < 10 then
    S := '0' + IntToStr(ZS)
  else
    S := IntToStr(ZS) ;

  Result := {H + ':' +} M + ':' + S;
end;

procedure TformMain.Timer1Timer(Sender: TObject);
var
  Seconds: integer;
begin
  Seconds :=  round(BASS_ChannelBytes2Seconds(fAudioHandle, BASS_ChannelGetPosition(fAudioHandle, BASS_POS_BYTE)));
  if Seconds < 0 then
    lblTime.caption := '00:00' + fTotalTime
  else
    lblTime.caption := SecToTime(Seconds) + fTotalTime;

  if fTrackBarChanging = false then
    TrackBarAudio.Value:= Seconds;

end;

procedure TformMain.TrackBarAudioChangedValue(Sender: TObject;
  NewValue: Integer);
begin
  fTrackBarChanging:=true;
  BASS_ChannelSetPosition(fAudioHandle, BASS_ChannelSeconds2Bytes(fAudioHandle, TrackBarAudio.Value)  , BASS_POS_BYTE);
  fTrackBarChanging:=false;
end;

procedure TformMain.btnStopClick(Sender: TObject);
begin
  StopAndFreeAudio;
end;

end.
