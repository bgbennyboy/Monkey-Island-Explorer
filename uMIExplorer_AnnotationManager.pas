{
******************************************************
  Monkey Island Explorer
  Copyright (c) 2010 - 2011 Bgbennyboy
  Http://quick.mixnmojo.com
******************************************************
}

unit uMIExplorer_AnnotationManager;

interface

uses
  Classes, Sysutils, Inifiles ,jclfileutils, Contnrs, uMIExplorer_Types {,dialogs};

type
  EInvalidIniFile = class (exception);

  TAnnotationManager = class

  private
    FSoundTrackIni: TMemIniFile;
    FBundleFiles: TObjectList;
    FOriginalFileNames: TStringList;
    FSoundTrackDir: string;
    FNoSoundTracks: boolean;
    function FindMatchingIniFile: string;
    procedure ListFileDir(Path: string; FileList: TStrings);
    function CheckForUniqueFiles(UniqueFile1, UniqueFile2: string): boolean;
    function GetGameTitle: string;
    function GetCount: integer;
    function GetOriginalFileNames(Index: integer): string;
    function GetAnnotation(OriginalName: string): string;
  public
    constructor Create(AnnotationDir: String; ObjectList: TObjectList);
    destructor Destroy; override;
    property GameTitle: string read GetGameTitle;
    property Title[OriginalName: string]: string read GetAnnotation;
    property Annotation[OriginalName: string]: string read GetAnnotation;
    property Count: integer read GetCount;
    property OriginalFileNames[Index: integer]: string read GetOriginalFileNames;
end;

implementation

function IsValidFileName( const FileName: string ): boolean;
begin
  Result := (LastDelimiter('\/:*?"<>|',FileName ) =0 );
end;


{
  CleanFileName
  ---------------------------------------------------------------------------

  Given an input string strip any chars that would result
  in an invalid file name.  This should just be passed the
  filename not the entire path because the slashes will be
  stripped.  The function ensures that the resulting string
  does not hae multiple spaces together and does not start
  or end with a space.  If the entire string is removed the
  result would not be a valid file name so an error is raised.

}

function CleanFileName(const InputString: string): string;
var
  i: integer;
  ResultWithSpaces: string;
begin
  if InputString = '' then
  begin
    Result := InputString;
    exit;
  end;

  ResultWithSpaces := InputString;

  for i := 1 to Length(ResultWithSpaces) do
  begin
    // These chars are invalid in file names.
    case ResultWithSpaces[i] of
      '/', '\', ':', '*', '?', '"', '|', ' ', #$D, #$A, #9:
        // Use chr(161) to indicate a duplicate space so we can remove
        // them at the end.
        {$WARNINGS OFF} // W1047 Unsafe code 'String index to var param'
        if (i > 1) and
          ((ResultWithSpaces[i - 1] = ' ') or (ResultWithSpaces[i - 1] = chr(161))) then
          ResultWithSpaces[i] := chr(161)
        else
          ResultWithSpaces[i] := ' ';

        {$WARNINGS ON}
    end;
  end;

  // A * indicates duplicate spaces.  Remove them.
  result := StringReplace(ResultWithSpaces, chr(161), '', [rfReplaceAll]);  //ReplaceStr(ResultWithSpaces, '*', '');

  // Also trim any leading or trailing spaces
  result := Trim(Result);
end;


procedure TAnnotationManager.ListFileDir(Path: string; FileList: TStrings);
var
  SR: TSearchRec;
begin
  if FindFirst(Path + '*.*', faAnyFile, SR) = 0 then
  begin
    repeat
      begin
        if sr.Attr and faDirectory = faDirectory then
        else
        if sr.Attr and faSysFile = faSysFile then
        else
        begin
          if extractfileext(sr.Name)='.annot' then
            filelist.Add(sr.Name);
        end;
      end;
    until FindNext(SR) <> 0;
    FindClose(SR);
  end;
end;

function TAnnotationManager.FindMatchingIniFile: string;
var
  AnnotationFiles: TstringList;
  i: integer;
  StrUnique1, StrUnique2: string;
  FileCheck: boolean;
begin
  AnnotationFiles:=TStringList.Create;
  try
    ListFileDir(FSoundTrackDir, AnnotationFiles);

    result:='';
    if AnnotationFiles.Count=0 then exit;

    for I := 0 to AnnotationFiles.Count - 1 do
    begin
      FSoundTrackIni:=TMemIniFile.Create(FSoundTrackDir + AnnotationFiles[i]);
      try
        StrUnique1:=FSoundTrackIni.ReadString('Info Header', 'UniqueFile1', '');
        StrUnique2:=FSoundTrackIni.ReadString('Info Header', 'UniqueFile2', '');

        FileCheck:=CheckForUniqueFiles(StrUnique1, StrUnique2);
        if FileCheck = true then
        begin
          if FSoundTrackIni.ReadInteger('Info Header', 'NoFiles', 0) = fBundleFiles.Count then
          begin
            result:=FSoundTrackDir + AnnotationFiles[i];
            break;
          end;
        end;

      finally
        FSoundTrackIni.Free;
      end;
    end;

  finally
    AnnotationFiles.Free;
  end;
end;

function TAnnotationManager.CheckForUniqueFiles(UniqueFile1,
  UniqueFile2: string): boolean;
var
  FoundCount, i: integer;
begin
  if UniqueFile1='' then //They are all unique but if this is blank then
  begin                  //the others probably will be
    result:=false;
    exit;
  end;

  FoundCount:=0;

  for i := 0 to FBundleFiles.Count - 1 do
  begin
    if (PathRemoveExtension(TWaveBankFile(FBundleFiles[i]).FileName) = UniqueFile1) or
       (PathRemoveExtension(TWaveBankFile(FBundleFiles[i]).FileName) = UniqueFile2) then
        inc(FoundCount);
  end;

  if FoundCount=2 then
    result:=true
  else
    result:=false;
end;

constructor TAnnotationManager.Create(AnnotationDir: String; ObjectList: TObjectList);
var
  Ini: string;
begin
  FBundleFiles := ObjectList;
  FOriginalFileNames := TStringList.Create;

  FSoundTrackDir:=IncludeTrailingPathDelimiter(AnnotationDir);

  Ini:=FindMatchingIniFile;

  if ini= '' then
  begin
    FNoSoundTracks:=true;
    raise EInvalidIniFile.Create('No valid SoundTrack ini file found!');
  end
  else
  begin
    FSoundTrackIni:=TMemIniFile.Create(Ini);
    FNoSoundTracks:=false;
    FSoundTrackIni.ReadSections(FOriginalFileNames);
    if FOriginalFileNames.Count > 0 then
      if FOriginalFileNames[0] = 'Info Header' then
        FOriginalFileNames.Delete(0);

  end;
end;

destructor TAnnotationManager.Destroy;
begin
  if FNoSoundTracks=false then
    FSoundTrackIni.Free;

  FOriginalFileNames.Free;

  inherited;
end;


function TAnnotationManager.GetOriginalFileNames(Index: integer): string;
begin
  if (Index < 0) or (Index > FOriginalFileNames.Count) then
  begin
    Result:='';
    Exit;
  end;

  Result := FOriginalFileNames[Index];
end;


function TAnnotationManager.GetAnnotation(OriginalName: string): string;
begin
  if FNoSoundTracks then
  begin
    Result:='';
    Exit;
  end;

  OriginalName := PathRemoveExtension(OriginalName);

  if OriginalName = '' then
  begin
    Result:='';
    Exit;
  end;

  Result := FSoundTrackIni.ReadString( OriginalName, 'Annotation', '');

  //Strip any invalid characters
  Result := StringReplace(Result, '/', '-', [rfReplaceAll, rfIgnoreCase]);
  Result := StringReplace(Result, ':', ' -', [rfReplaceAll, rfIgnoreCase]);

  if IsValidFileName(Result) = false then
    Result := CleanFileName(Result);

end;

function TAnnotationManager.GetCount: integer;
begin
  result := FOriginalFileNames.count;
end;

function TAnnotationManager.GetGameTitle: string;
begin
  result := FSoundTrackIni.ReadString('Info Header', 'Title', '');
end;

end.
