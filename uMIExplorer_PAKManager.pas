unit uMIExplorer_PAKManager;

interface

uses
  classes, sysutils, Contnrs, forms,
  uMIExplorer_BaseBundleManager, uFileReader, uMemReader, uMIExplorer_Types, uMIExplorer_Funcs;

type
  TPAKManager = class (TBundleManager)
  protected

    fBundle: TExplorerFileStream;
    fBundleFileName: string;
    function DetectBundle: boolean;  override;
    function GetFilesCount: integer; override;
    function GetFileName(Index: integer): string; override;
    function GetFileSize(Index: integer): integer; override;
    function GetFileOffset(Index: integer): integer; override;
    procedure Log(Text: string); override;
  public
    BundleFiles: TObjectList;
    constructor Create(ResourceFile: string); override;
    destructor Destroy; override;
    procedure ParseFiles; override;
    procedure SaveFile(FileNo: integer; DestDir, FileName: string); override;
    procedure SaveFileToStream(FileNo: integer; DestStream: TStream); override;
    procedure SaveFiles(DestDir: string); override;
    property Count: integer read GetFilesCount;
    property FileName[Index: integer]: string read GetFileName;
    property FileSize[Index: integer]: integer read GetFileSize;
    property FileOffset[Index: integer]: integer read GetFileOffset;
    property BigEndian: boolean read fBigEndian;
  end;

const
    strErrInvalidFile:          string  = 'Not a valid MI:SE bundle';

implementation

{ TBundleManager }


constructor TPAKManager.Create(ResourceFile: string);
begin
  try
    fBundle:=TExplorerFileStream.Create(ResourceFile);
  except on E: EInvalidFile do
    raise;
  end;

  fBundleFileName:=ExtractFileName(ResourceFile);
  BundleFiles:=TObjectList.Create(true);

  if DetectBundle = false then
    raise EInvalidFile.Create( strErrInvalidFile );
end;

destructor TPAKManager.Destroy;
begin
  if BundleFiles <> nil then
  begin
    BundleFiles.Free;
    BundleFiles:=nil;
  end;

  if fBundle <> nil then
    fBundle.free;

  inherited;
end;

function TPAKManager.DetectBundle: boolean;
var
  BlockName: string;
begin
  Result := false;
  BlockName := fBundle.ReadBlockName;

  if BlockName = 'KAPL' then
  begin
    Result := true;
    fBundle.BigEndian := false;
    fBigEndian := false;
  end
  else
  if BlockName = 'LPAK' then
  begin
    Result := true;
    fBundle.BigEndian := true;
    fBigEndian := true;
  end;
end;

function TPAKManager.GetFileName(Index: integer): string;
begin
  if (not assigned(BundleFiles)) or
     (index < 0) or
     (index > GetFilesCount) then
     result:= ''
  else
     result:=TMIFile(BundleFiles.Items[Index]).FileName;
end;

function TPAKManager.GetFileOffset(Index: integer): integer;
begin
  if (not assigned(BundleFiles)) or
     (index < 0) or
     (index > GetFilesCount) then
    result:=-1
  else
     result:=TMIFile(BundleFiles.Items[Index]).offset;
end;

function TPAKManager.GetFilesCount: integer;
begin
  if BundleFiles <> nil then
    result:=BundleFiles.Count
  else
    result:=0;
end;

function TPAKManager.GetFileSize(Index: integer): integer;
begin
  if (not assigned(BundleFiles)) or
     (index < 0) or
     (index > GetFilesCount) then
    result:=-1
  else
     result:=TMIFile(BundleFiles.Items[Index]).size;
end;

procedure TPAKManager.Log(Text: string);
begin
  if assigned(fOnDebug) then fOnDebug(Text);
end;

procedure TPAKManager.ParseFiles;
var
  startOfFileEntries, startOfFileNames, startOfData,
  sizeOfIndex, sizeOfFileEntries, sizeOfFileNames, sizeOfData: integer;

  numFiles, i, nameOffs, currNameOffset: integer;
  FileObject: TMIFile;
const
  sizeOfFileRecord: integer = 20;
begin
{	PakHeader	= record
    DWORD magic;                (* KAPL -> "LPAK" *)
    Single version;
    DWORD startOfIndex;         (* -> 1 DWORD per file *)
    DWORD startOfFileEntries;   (* -> 5 DWORD per file *)
    DWORD startOfFileNames;     (* zero-terminated string *)
    DWORD startOfData;
    DWORD sizeOfIndex;
    DWORD sizeOfFileEntries;
    DWORD sizeOfFileNames;
    DWORD sizeOfData;
 end;

	PakFileEntry	= record
    DWORD fileDataPos;          (* + startOfData *)
    DWORD fileNamePos;          (* + startOfFileNames *)
    DWORD dataSize;
    DWORD dataSize2;            (* real size? (always =dataSize) *)
    DWORD compressed;           (* compressed? (always 0) *)
 end;
 PakFileEntry	=	PakFileEntry;}

 if fBigEndian then
    Log('Detected as : XBOX360 version');


  //Read header
  fBundle.Position := 12;
  startOfFileEntries := fBundle.ReadDWord;
  startOfFileNames   := fBundle.ReadDWord;
  startOfData        := fBundle.ReadDWord;
  sizeOfIndex        := fBundle.ReadDWord;
  sizeOfFileEntries  := fBundle.ReadDWord;
  sizeOfFileNames    := fBundle.ReadDWord;
  sizeOfData         := fBundle.ReadDWord;

  numFiles :=  sizeOfFileEntries div sizeOfFileRecord;

  currNameOffset := 0;

  //Parse files
  for I := 0 to numFiles - 1 do
  begin
    fBundle.Position  := startOfFileEntries + (sizeOfFileRecord * i);
    FileObject        :=TMIFile.Create;
    FileObject.Offset := fBundle.ReadDWord + startOfData;
    nameOffs          := fBundle.ReadDWord;
    FileObject.Size   := fBundle.ReadDWord;

    //Get filename from filenames table
    //In MI2SE - nameOffs is broken - so just ignore it - luckily filenames are stored in the same order as the entries in the file records
    fBundle.Position    := startOfFileNames + currNameOffset;
    FileObject.FileName := PChar(fBundle.ReadString(255));
    inc(currNameOffset, length(FileObject.FileName) + 1); //+1 because each filename is null terminated

    BundleFiles.Add(FileObject);
  end;


  if (Assigned(FOnDoneLoading)) then
	  FOnDoneLoading(numFiles);
end;

procedure TPAKManager.SaveFile(FileNo: integer; DestDir, FileName: string);
var
  SaveFile: TFileStream;
begin
  if TMIFile(BundleFiles.Items[FileNo]).Size <= 0 then
  begin
    Log(strErrFileSize);
    exit;
  end;

  if (FileNo < 0) or (FileNo > BundleFiles.Count) then
  begin
    Log(strErrFileNo);
    exit;
  end;

  Log(strSavingFile + FileName);

  SaveFile:=tfilestream.Create(IncludeTrailingPathDelimiter(DestDir)  + FileName, fmOpenWrite or fmCreate);
  try
    SaveFileToStream(FileNo,SaveFile);
  finally
    SaveFile.Free;
  end;

end;

procedure TPAKManager.SaveFiles(DestDir: string);
var
  i: integer;
  SaveFile: TFileStream;
begin
  for I := 0 to BundleFiles.Count - 1 do
  begin
    ForceDirectories(extractfilepath(IncludeTrailingPathDelimiter(DestDir) + ExtractPartialPath( TMIFile(BundleFiles.Items[i]).FileName)));
    SaveFile:=TFileStream.Create(IncludeTrailingPathDelimiter(DestDir) +  TMIFile(BundleFiles.Items[i]).FileName , fmOpenWrite or fmCreate);
    try
      SaveFileToStream(i, SaveFile);
    finally
      SaveFile.free;
      if Assigned(FOnProgress) then FOnProgress(GetFilesCount -1, i);
      Application.Processmessages;
    end;
  end;

end;

procedure TPAKManager.SaveFileToStream(FileNo: integer; DestStream: TStream);
var
  Ext: string;
begin
  if TMIFile(BundleFiles.Items[FileNo]).Size <= 0 then
  begin
    Log(strErrFileSize);
    exit;
  end;

  if (FileNo < 0) or (FileNo > BundleFiles.Count) then
  begin
    Log(strErrFileNo);
    exit;
  end;

  Ext:=Uppercase(ExtractFileExt(TMIFile(BundleFiles.Items[FileNo]).FileName));

  fBundle.Seek(TMIFile(BundleFiles.Items[FileNo]).Offset, sofrombeginning);

  DestStream.CopyFrom(fBundle, TMIFile(BundleFiles.Items[FileNo]).Size);

  DestStream.Position:=0;
end;

end.
