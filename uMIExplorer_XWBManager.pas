unit uMIExplorer_XWBManager;

interface

uses
  classes, sysutils, Contnrs, forms,
  uFileReader, uMemReader, uMIExplorer_BaseBundleManager, uMIExplorer_Types, uMIExplorer_Funcs,
  XACT, JCLSysInfo, JCLShell, Windows, uMIExplorer_AnnotationManager;

type
  TXWBManager = class (TBundleManager)
  protected
    fBundle: TExplorerFileStream;
    fBundleFileName: string;
    function DetectBundle: boolean; override;
    function GetFilesCount: integer; override;
    function GetFileName(Index: integer): string; override;
    function GetFileSize(Index: integer): integer;  override;
    function GetFileOffset(Index: integer): integer; override;
    procedure Log(Text: string); override;
    procedure ExtractInfoFromEntryFormat(var Codec, Bitrate, Channels, Bits, Align: integer; Format: TWavebankMiniWaveFormat);
    procedure WriteWav(Codec, Bitrate, Channels, Bits, Align: integer; Source: TStream; DataSize: Cardinal; var Dest: TStream);
    procedure ConvertxWMAStreamIntoPcm(XwmaStream: TStream);
    procedure LoadAnnotationFileNames;
  public
    BundleFiles: TObjectList;
    constructor Create(ResourceFile: string); override;
    destructor Destroy; override;
    procedure ParseFiles; override;
    procedure SaveFile(FileNo: integer; DestDir, FileName: string); override;
    procedure SaveFileToStream(FileNo: integer; DestStream: TStream); override;
    procedure SaveWavToStream(FileNo: integer; DestStream: TStream);
    procedure SaveFiles(DestDir: string); override;
    property Count: integer read GetFilesCount;
    property FileName[Index: integer]: string read GetFileName;
    property FileSize[Index: integer]: integer read GetFileSize;
    property FileOffset[Index: integer]: integer read GetFileOffset;
  end;

const
    strErrInvalidFile:  string  = 'Not a valid XWB file';
    strEncodeTool:      string  = 'xWMAEncode.exe';
    strTempWavName:     string  = 'tempWav_MI';
    strTempxWMAName:    string  = 'tempWMA_MI';
    strAnnotationDir:   string  = 'Annotations';
    WAVEBANK_HEADER_SIGNATURE_LE: Cardinal  = 1145979479; //'WBND'
    WAVEBANK_HEADER_SIGNATURE_BE: Cardinal  = 1463963204; //'DNBW'
    ADPCM_MINIWAVEFORMAT_BLOCKALIGN_CONVERSION_OFFSET = 22;
var
    WaveBankVersion: integer;

implementation

{ TXWBManager }

constructor TXWBManager.Create(ResourceFile: string);
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

destructor TXWBManager.Destroy;
begin
  SysUtils.DeleteFile(IncludeTrailingPathDelimiter( GetWindowsTempFolder) + strTempxWMAName);
  SysUtils.DeleteFile(IncludeTrailingPathDelimiter( GetWindowsTempFolder) + strTempWAVName);

  if BundleFiles <> nil then
  begin
    BundleFiles.Free;
    BundleFiles:=nil;
  end;

  if fBundle <> nil then
    fBundle.free;

  inherited;
end;

function TXWBManager.DetectBundle: boolean;
var
  Temp: Cardinal;
begin
  Result := false;
  Temp := fBundle.ReadDWord;
  if (Temp = WAVEBANK_HEADER_SIGNATURE_LE) or
     (Temp = WAVEBANK_HEADER_SIGNATURE_BE) then
     Result := true;
end;

function TXWBManager.GetFileName(Index: integer): string;
begin
  if (not assigned(BundleFiles)) or
     (index < 0) or
     (index > GetFilesCount) then
     result:= ''
  else
     result:=TWaveBankFile(BundleFiles.Items[Index]).FileName;
end;

function TXWBManager.GetFileOffset(Index: integer): integer;
begin
  if (not assigned(BundleFiles)) or
     (index < 0) or
     (index > GetFilesCount) then
    result:=-1
  else
     result:=TWaveBankFile(BundleFiles.Items[Index]).offset;
end;

function TXWBManager.GetFilesCount: integer;
begin
  if BundleFiles <> nil then
    result:=BundleFiles.Count
  else
    result:=0;
end;

function TXWBManager.GetFileSize(Index: integer): integer;
begin
  if (not assigned(BundleFiles)) or
     (index < 0) or
     (index > GetFilesCount) then
    result:=-1
  else
     result:=TWaveBankFile(BundleFiles.Items[Index]).size;
end;

procedure TXWBManager.Log(Text: string);
begin
  if assigned(fOnDebug) then fOnDebug(Text);
end;

procedure TXWBManager.ParseFiles;
var
  i: integer;
  BankHeader: TWAVEBANKHEADER;
  BankData:   TWAVEBANKDATA;
  BankEntry:  TWAVEBANKENTRY;
  DataOffset, EntryOffset, NameOffset, ChunkOffset, ChunkSize: Cardinal;
  FileObject: TWaveBankFile;
  HasFileNames: boolean;
begin
  HasFileNames := false;
  WaveBankVersion := -1;
  fBundle.Position :=0;

  fBundle.Read(BankHeader, SizeOf(TWAVEBANKHEADER));

  ////Checks
  if (BankHeader.dwSignature <> WAVEBANK_HEADER_SIGNATURE_BE) and
     (BankHeader.dwSignature <> WAVEBANK_HEADER_SIGNATURE_LE)
  then
  begin
    Log('Wavebank header invalid!');
    raise EInvalidFile.Create( strErrInvalidFile );
  end;

  if BankHeader.dwVersion <42 then
    Log('Unexpected XWB version ' + inttostr(BankHeader.dwVersion) + ' attempting to continue...');
  ////

  //Need this for extracting later
  WaveBankVersion := BankHeader.dwVersion;

  fBundle.Seek( BankHeader.Segments[WAVEBANK_SEGIDX_BANKDATA].dwOffset, soFromBeginning );
  fBundle.Read( BankData, SizeOf(TWAVEBANKDATA) );

  //log(inttostr(bankdata.dwEntryCount));
  if (BankData.dwFlags and cardinal(WAVEBANK_FLAGS_ENTRYNAMES)) > 0 then
  begin
    //log('Has filenames!');
    HasFileNames := true;
  end;



  Log('Wavebank name is: ' + string(Copy(BankData.szBankName,0,BankData.dwEntryMetaDataElementSize)));


  DataOffset:=BankHeader.Segments[WAVEBANK_SEGIDX_ENTRYWAVEDATA].dwOffset;
  EntryOffset:=BankHeader.Segments[WAVEBANK_SEGIDX_ENTRYMETADATA].dwOffset;
  NameOffset:=BankHeader.Segments[WAVEBANK_SEGIDX_ENTRYNAMES].dwOffset;
  for I := 0 to BankData.dwEntryCount- 1 do
  begin
    fBundle.Seek(EntryOffset, soFromBeginning);
    Inc(EntryOffset,SizeOf(TWAVEBANKENTRY));

    fBundle.Read(BankEntry,SizeOf(TWAVEBANKENTRY));


    ChunkOffset:= DataOffset + BankEntry.PlayRegion.dwOffset;
    ChunkSize:= BankEntry.PlayRegion.dwLength;
    //fBundle.Seek(ChunkOffset, soFromBeginning);

    FileObject := TWaveBankFile.Create;
    if HasFileNames then
    begin
      fBundle.Seek(NameOffset, sofromBeginning);
      inc(NameOffset, WAVEBANK_ENTRYNAME_LENGTH);

      FileObject.FileName := PChar(fBundle.ReadString(WAVEBANK_ENTRYNAME_LENGTH)) + '.wav';
    end
    else
      FileObject.FileName := inttostr(i) + '.wav';

    FileObject.Size := ChunkSize;
    FileObject.Offset := ChunkOffset;
    FileObject.BankEntry := BankEntry;

    BundleFiles.Add(FileObject);
  end;

  LoadAnnotationFileNames;

  if (Assigned(FOnDoneLoading)) then
	  FOnDoneLoading(BankData.dwEntryCount);
end;

procedure TXWBManager.SaveFile(FileNo: integer; DestDir, FileName: string);
var
  SaveFile: TFileStream;
begin
  if TWaveBankFile(BundleFiles.Items[FileNo]).Size <= 0 then
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

procedure TXWBManager.SaveFiles(DestDir: string);
var
  i: integer;
  SaveFile: TFileStream;
begin
  for I := 0 to BundleFiles.Count - 1 do
  begin
    ForceDirectories(extractfilepath(IncludeTrailingPathDelimiter(DestDir) + ExtractPartialPath( TWaveBankFile(BundleFiles.Items[i]).FileName)));
    SaveFile:=TFileStream.Create(IncludeTrailingPathDelimiter(DestDir) +  TWaveBankFile(BundleFiles.Items[i]).FileName , fmOpenWrite or fmCreate);
    try
      SaveFileToStream(i, SaveFile);
    finally
      SaveFile.free;
      if Assigned(FOnProgress) then FOnProgress(GetFilesCount -1, i);
      Application.Processmessages;
    end;
  end;

end;

procedure TXWBManager.SaveFileToStream(FileNo: integer; DestStream: TStream);
var
  Ext: string;
begin
  if TWaveBankFile(BundleFiles.Items[FileNo]).Size <= 0 then
  begin
    Log(strErrFileSize);
    exit;
  end;

  if (FileNo < 0) or (FileNo > BundleFiles.Count) then
  begin
    Log(strErrFileNo);
    exit;
  end;

  Ext:=Uppercase(ExtractFileExt(TWaveBankFile(BundleFiles.Items[FileNo]).FileName));

  fBundle.Seek(TWaveBankFile(BundleFiles.Items[FileNo]).Offset, sofrombeginning);

  DestStream.CopyFrom(fBundle, TWaveBankFile(BundleFiles.Items[FileNo]).Size);

  DestStream.Position:=0;
end;

procedure TXWBManager.SaveWavToStream(FileNo: integer; DestStream: TStream);
var
  Ext: string;
  Codec, Bitrate, Channels, Bits, Align: integer;
begin
  if TWaveBankFile(BundleFiles.Items[FileNo]).Size <= 0 then
  begin
    Log(strErrFileSize);
    exit;
  end;

  if (FileNo < 0) or (FileNo > BundleFiles.Count) then
  begin
    Log(strErrFileNo);
    exit;
  end;

  Ext:=Uppercase(ExtractFileExt(TWaveBankFile(BundleFiles.Items[FileNo]).FileName));

  fBundle.Seek(TWaveBankFile(BundleFiles.Items[FileNo]).Offset, sofrombeginning);


  ExtractInfoFromEntryFormat(Codec, Bitrate, Channels, Bits, Align, TWaveBankFile(BundleFiles.Items[FileNo]).BankEntry.Format);
  WriteWav(Codec, Bitrate, Channels, Bits, Align, fBundle, TWaveBankFile(BundleFiles.Items[FileNo]).Size, DestStream);

  if Codec = WAVEBANKMINIFORMAT_TAG_WMA then
    ConvertxWMAStreamIntoPcm(DestStream);


  DestStream.Position:=0;

end;

procedure TXWBManager.ExtractInfoFromEntryFormat(var Codec, Bitrate, Channels,
  Bits, Align: integer; Format: TWavebankMiniWaveFormat);
begin
  if WaveBankVersion = 1 then
  begin
    Codec :=    (Format.dwValue                          ) and ((1 shl  1) - 1);
    Channels := (Format.dwValue  shr (1)                 ) and ((1 shl  3) - 1);
    Bitrate  := (Format.dwValue  shr (1 + 3 + 1)         ) and ((1 shl 18) - 1);
    Align :=    (Format.dwValue  shr (1 + 3 + 1 + 18)    ) and ((1 shl  8) - 1);
    Bits  :=    (Format.dwValue  shr (1 + 3 + 1 + 18 + 8)) and ((1 shl  1) - 1);
  end
  else
  begin
    Codec :=    (Format.dwValue                     ) and ((1 shl  2) - 1);
    Channels := (Format.dwValue shr (2)             ) and ((1 shl  3) - 1);
    Bitrate  := (Format.dwValue shr (2 + 3)         ) and ((1 shl 18) - 1);
    Align :=    (Format.dwValue shr (2 + 3 + 18)    ) and ((1 shl  8) - 1);
    Bits  :=    (Format.dwValue shr (2 + 3 + 18 + 8)) and ((1 shl  1) - 1);
  end;
end;

procedure TXWBManager.WriteWav(Codec, Bitrate, Channels, Bits,
  Align: integer; Source: TStream; DataSize: Cardinal; var Dest: TStream);
type
  TWaveHeader = record
    riff,
    totallen,
    wave,
    fmt,
    wavelen: cardinal;
    wFormatTag,
    wChannels: word;
    dwSamplesPerSec,
    dwAvgBytesPerSec: cardinal;
    wBlockAlign,
    wBitsPerSample: word;
    data: cardinal;
  end;
  TADPCMHeader =  packed Record
    riff,
    totallen,
    wave,
    fmt,
    wavelen: cardinal;
    wFormatTag: Word;
    wChannels: Word;
    dwSamplesPerSec: cardinal;
    dwAvgBytesPerSec: cardinal;
    wBlockAlign: Word;
    wBitsPerSample: Word;
    wSize: Word;
    wSamplesPerBlock:Word;
    nNumCoef: word;
    Coef1_0: smallint;
    Coef1_1: smallint;
    Coef1_2: smallint;
    Coef1_3: smallint;
    Coef1_4: smallint;
    Coef1_5: smallint;
    Coef1_6: smallint;
    Coef2_0: smallint;
    Coef2_1: smallint;
    Coef2_2: smallint;
    Coef2_3: smallint;
    Coef2_4: smallint;
    Coef2_5: smallint;
    Coef2_6: smallint;
    data: cardinal;
  end;
  TXWMAHeader = packed record
    riff,
    totallen,
    xwma,
    fmt,
    wavelen: cardinal;
    wFormatTag,
    wChannels: word;
    dwSamplesPerSec,
    dwAvgBytesPerSec: cardinal;
    wBlockAlign,
    wBitsPerSample: word;

    wSize: Word;
    wExtra: Word;

    dpds: cardinal;
    dpdsChunkSize: cardinal;
    dpdsExtra: longint;
    data: cardinal;
  end;
var
  FWaveHeader: TWaveHeader;
  FADPCMHeader: TADPCMHeader;
  fXWMAHeader: TXWMAHeader;
begin
  case Codec of
    WAVEBANKMINIFORMAT_TAG_PCM:
    begin
      with FWaveHeader do
      begin
        riff:= 1179011410; //RIFF
        totallen:= (SizeOf(TWaveHeader) - 8) + DataSize;
        wave:= 1163280727; //WAVE
        fmt:= 544501094; //'fmt '
        wavelen:= 16;
        wFormatTag:= $01;
        wChannels:= Channels;
        dwSamplesPerSec:= Bitrate;
        wBitsPerSample:= 8 shl Bits;//Bits;
        wBlockAlign:= wChannels * (wBitsPerSample div 8);
        dwAvgBytesPerSec:= wBlockAlign * dwSamplesPerSec;
        data:= 1635017060; //data
      end;

      Dest.Write(FWaveHeader, SizeOf(TWaveHeader));
    end;

    WAVEBANKMINIFORMAT_TAG_ADPCM:
    begin
    with FADPCMHeader do
      begin
        riff:= 1179011410; //RIFF
        totallen:= (SizeOf(TADPCMHeader) - 8) + DataSize;
        wave:= 1163280727; //WAVE
        fmt:= 544501094; //'fmt '
        wavelen:= 50;
        wFormatTag:= $02;
        wChannels:= Channels;
        dwSamplesPerSec:= Bitrate;
        wBitsPerSample:= 4;
        wBlockAlign:= (Align + ADPCM_MINIWAVEFORMAT_BLOCKALIGN_CONVERSION_OFFSET) * wChannels;
        dwAvgBytesPerSec:= 21 * wBlockAlign;

        wSize :=  32;
        wSamplesPerBlock :=   (((wBlockAlign - (7 * wChannels)) * 8) div (wBitsPerSample * wChannels)) + 2; //wfx.nBlockAlign * 2 / wfx.nChannels - 12 

        nNumCoef := 7;
        Coef1_0:= 256;
        Coef1_1:= 0;
        Coef1_2:= 512;
        Coef1_3:= -256;
        Coef1_4:=  0;
        Coef1_5:=  0;
        Coef1_6:=  192;
        Coef2_0:=  64;
        Coef2_1:=  240;
        Coef2_2:=  0;
        Coef2_3:=  460;
        Coef2_4:=  -208;
        Coef2_5:=  392;
        Coef2_6:=  -232;

        data:= 1635017060; //data
      end;

      Dest.Write(FADPCMHeader, SizeOf(TADPCMHeader));
    end;

    WAVEBANKMINIFORMAT_TAG_WMA:
    begin
      with fXWMAHeader do
      begin
        riff:= 1179011410; //RIFF
        totallen:= (SizeOf(TXWMAHeader) - 8) + DataSize;
        xwma:= 1095587672; //XWMA
        fmt:= 544501094; //'fmt '
        wavelen:= 20;
        wFormatTag:= $0161;
        wChannels:= Channels;
        dwSamplesPerSec:= Bitrate;
        wBitsPerSample := 16;
        wBlockAlign:= 1;
        dwAvgBytesPerSec:= 12000;

        wSize := 2;
        wExtra := 0;

        dpds := 1935962212; //dpds
        dpdschunksize := 4;
        dpdsExtra := -1;

        data:= 1635017060; //data
      end;

      Dest.Write(fXWMAHeader, SizeOf(TXWMAHeader));
    end

    else
      Log('Unknown codec tag! ' + inttostr(codec) );
  end;


  Dest.Write(DataSize, SizeOf(DataSize));
  Dest.CopyFrom(Source, DataSize);

end;

procedure TXWBManager.ConvertxWMAStreamIntoPcm(xWMAStream: TStream);
var
  TempFile: TFileStream;
begin
  if xWMAStream.Size = 0 then
  begin
    Log('xWMA stream size is 0 !');
    Exit;
  end;

  if FileExists( ExtractFilePath(Application.ExeName) + strEncodeTool ) = false then
  begin
    Log('Couldnt find ' + strEncodeTool + ' in program folder! Cant decode xWMA audio without this!');
    Exit;
  end;

  //Delete any existing files
  SysUtils.DeleteFile(IncludeTrailingPathDelimiter( GetWindowsTempFolder) + strTempxWMAName);
  SysUtils.DeleteFile(IncludeTrailingPathDelimiter( GetWindowsTempFolder) + strTempWAVName);


  try
    TempFile := TFileStream.Create( IncludeTrailingPathDelimiter( GetWindowsTempFolder) + strTempxWMAName, fmCreate );
    try
      xWMAStream.Position := 0;
      TempFile.CopyFrom(xWMAStream, xWMAStream.Size);
    finally
      TempFile.Free;
    end;

  except on EFCreateError do
    begin
      Log('Too many clicks! Ignoring this playback request');
      exit;
    end;
  end;


  if ShellExecAndWait( ExtractFilePath(Application.ExeName) + strEncodeTool, IncludeTrailingPathDelimiter( GetWindowsTempFolder) + strTempxWMAName + ' ' + IncludeTrailingPathDelimiter( GetWindowsTempFolder) + strTempWAVName, '', SW_HIDE) then
  begin
    if FileExists(IncludeTrailingPathDelimiter( GetWindowsTempFolder) + strTempWAVName) = false then
    begin
      Log('xWMA decode failed!');
      Exit;
    end;

    //Now load the data back from the decoded file
    xWMAStream.Size := 0;
    TempFile := TFileStream.Create( IncludeTrailingPathDelimiter( GetWindowsTempFolder) + strTempWAVName, fmOpenRead );
    try
      xWMAStream.CopyFrom(TempFile, TempFile.Size);
      xWMAStream.Position := 0;
    finally
      TempFile.Free;
    end;

  end;
end;



procedure TXWBManager.LoadAnnotationFileNames;
var
  AnnotationManager: TAnnotationManager;
  I: Integer;
  strTemp: string;
begin
  if BundleFiles = nil then exit;
  if BundleFiles.Count = 0 then exit;

  try
     AnnotationManager := TAnnotationManager.Create(ExtractFilePath(Application.ExeName) + strAnnotationDir, BundleFiles);
     try
        Log('Matching annotation file found! Using new filenames.');
        for I := 0 to BundleFiles.Count - 1 do
        begin
          strTemp := AnnotationManager.Annotation[TWaveBankFile(BundleFiles.Items[i]).FileName];
          if strTemp <> '' then
            TWaveBankFile(BundleFiles.Items[i]).FileName := strTemp + '.wav';
        end;

     finally
        AnnotationManager.Free;
     end;
  Except on EInvalidIniFile do

  end;

end;

end.
