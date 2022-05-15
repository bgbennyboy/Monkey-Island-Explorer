{
******************************************************
  Monkey Island Explorer
  Copyright (c) 2010 - 2018 Bennyboy
  Http://quickandeasysoftware.net
******************************************************
}

unit uMIExplorer_Base;

interface

uses
  Classes, sysutils, windows, graphics,

  GR32, ImagingComponents, ZlibExGz,

  uMIExplorer_Types, uMIExplorer_BaseBundleManager, uMemReader, uMIExplorer_Funcs,
  uMIExplorer_XWBManager, uMIExplorer_PAKManager;

type
  TMIExplorerBase = class
private
  fOnDebug: TDebugEvent;
  fOnProgress: TProgressEvent;
  fOnDoneLoading: TOnDoneLoading;
  fBundle: TBundleManager;
  fBundleFilename: string;
  function GetFileName(Index: integer): string;
  function GetFileSize(Index: integer): integer;
  function GetFileOffset(Index: integer): integer;
  function DrawImage(MemStream: TMemoryStream; OutImage: TBitmap32): boolean;
  procedure Log(Text: string);
  procedure WriteDDSToStream(SourceStream, DestStream: TStream);
public
  constructor Create(BundleFile: string; Debug: TDebugEvent);
  destructor Destroy; override;
  function DrawImageGeneric(FileIndex: integer; DestBitmap: TBitmap32): boolean;
  function DrawImageDDS(FileIndex: integer; DestBitmap: TBitmap32): boolean;
  function SaveImageGenericAsPNG(FileIndex: integer; DestDir, FileName: string): Boolean; //Stop the save image being impossibly slow with the drawing to multiple bitmaps
  function SaveImageDDSAsPNG(FileIndex: integer; DestDir, FileName: string): Boolean;
  function SaveDDSToFile(FileIndex: integer; DestDir, FileName: string): boolean;
  procedure Initialise;
  procedure SaveFile(FileNo: integer; DestDir, FileName: string);
  procedure SaveFiles(DestDir: string);
  procedure ReadText(FileIndex: integer; DestStrings: TStrings);
  function SaveWavToStream(FileIndex: integer; DestStream: Tstream): boolean;
  function SaveWavToFile(FileIndex: integer; DestDir, FileName: string): boolean;
  property OnDebug: TDebugEvent read FOnDebug write FOnDebug;
  property OnDoneLoading: TOnDoneLoading read FOnDoneLoading write FOnDoneLoading;
  property OnProgress: TProgressEvent read FOnProgress write FOnProgress;
  property FileName[Index: integer]: string read GetFileName;
  property FileSize[Index: integer]: integer read GetFileSize;
  property FileOffset[Index: integer]: integer read GetFileOffset;
end;

implementation


constructor TMIExplorerBase.Create(BundleFile: string; Debug: TDebugEvent);
begin
  OnDebug:=Debug;
  fBundleFilename:=BundleFile;

  try
    if Uppercase( ExtractFileExt(BundleFile) ) = '.XWB' then
      fBundle:=TXWBManager.Create(BundleFile)
    else
      fBundle:=TPAKManager.Create(BundleFile);
  except on E: EInvalidFile do
    raise;
  end;

end;

destructor TMIExplorerBase.Destroy;
begin
  if fBundle <> nil then
    FreeandNil(fBundle);

  inherited;
end;

function TMIExplorerBase.DrawImage(MemStream: TMemoryStream;
  OutImage: TBitmap32): boolean;
var
  ImgBitmap : TImagingBitmap;
begin
  Result := false;
  MemStream.Position:=0;

  ImgBitmap := TImagingBitmap.Create;
  try
    ImgBitmap.LoadFromStream(MemStream);
    if ImgBitmap.Empty then
      Exit;

    OutImage.Assign(ImgBitmap);
    Result := true;
  finally
    ImgBitmap.Free;
  end;
end;

function TMIExplorerBase.DrawImageDDS(FileIndex: integer;
  DestBitmap: TBitmap32): boolean;
var
  TempStream, DDSStream: TExplorerMemoryStream;
begin
  Result:=false;

  TempStream:=TExplorerMemoryStream.Create;
  try
    fBundle.SaveFileToStream(FileIndex, TempStream);
    TempStream.Position:=0;

    DDSStream:=TExplorerMemoryStream.Create;
    try
      WriteDDSToStream(Tempstream, DDSStream);

      DestBitmap.Clear();
      destbitmap.CombineMode:=cmMerge ;
      destBitmap.DrawMode:=dmBlend ;
      if DrawImage(DDSStream, DestBitmap)=false then
      begin
        Log('DDS Decode failed! ' + fBundle.FileName[FileIndex]);
        Exit;
      end;

      Result:=true;
    finally
      DDSStream.Free;
    end;
  finally
    TempStream.Free;
  end;
end;

procedure TMIExplorerBase.WriteDDSToStream(SourceStream, DestStream: TStream);
const
  DDSD_CAPS =                       $00000001;
  DDSD_HEIGHT =                     $00000002;
  DDSD_WIDTH =                      $00000004;
  DDSD_PITCH =                      $00000008;
  DDSD_PIXELFORMAT =                $00001000;
  DDSD_MIPMAPCOUNT =                $00020000;
  DDSD_LINEARSIZE =                 $00080000;
  DDSD_DEPTH =                      $00800000;
  DDPF_ALPHAPIXELS =                $00000001;
  DDPF_FOURCC =                     $00000004;
  DDPF_RGB =                        $00000040;
  DDSCAPS_COMPLEX =                 $00000008;
  DDSCAPS_TEXTURE =                 $00001000;
  DDSCAPS_MIPMAP =                  $00400000;
  DDSCAPS2_CUBEMAP =                $00000200;
  DDSCAPS2_CUBEMAP_POSITIVEX =      $00000400;
  DDSCAPS2_CUBEMAP_NEGATIVEX =      $00000800;
  DDSCAPS2_CUBEMAP_POSITIVEY =      $00001000;
  DDSCAPS2_CUBEMAP_NEGATIVEY =      $00002000;
  DDSCAPS2_CUBEMAP_POSITIVEZ =      $00004000;
  DDSCAPS2_CUBEMAP_NEGATIVEZ =      $00008000;
  DDSCAPS2_VOLUME =                 $00200000;
  DDSMAGIC = 542327876; //'DDS '
type
  TDDPIXELFORMAT = record
    dwSize,
    dwFlags,
    dwFourCC,
    dwRGBBitCount,
    dwRBitMask,
    dwGBitMask,
    dwBBitMask,
    dwRGBAlphaBitMask : Cardinal;
  end;

  TDDCAPS2 = record
    dwCaps1,
    dwCaps2 : Cardinal;
    Reserved : array[0..1] of Cardinal;
  end;

  TDDSURFACEDESC2 = record
    dwSize,
    dwFlags,
    dwHeight,
    dwWidth,
    dwPitchOrLinearSize,
    dwDepth,
    dwMipMapCount : Cardinal;
    dwReserved1 : array[0..10] of Cardinal;
    ddpfPixelFormat : TDDPIXELFORMAT;
    ddsCaps : TDDCAPS2;
    dwReserved2 : Cardinal;
  end;

  TDDSHeader = record
    Magic : Cardinal;
    SurfaceFormat : TDDSURFACEDESC2;
  end;

var
  Header : TDDSHeader;
  Height, Width, Datasize, Dataoffset: integer;
  TempFourCC: Cardinal;
  Temp: word;
  TempStream: TMemoryStream;
begin
  //First get the width and height and data size
  SourceStream.Position := 4;
  Sourcestream.Read(Width, 4);
  if fBundle.BigEndian then Width := SwapEndianDWord(Width);

  Sourcestream.Read(Height, 4);
  if fBundle.BigEndian then Height := SwapEndianDWord(Height);

  //Check here if gzipped
  //MI2:SE has gzipped dxt files after the 12 byte header
  SourceStream.Read(Temp, 2);
  SourceStream.Seek(-2, soFromCurrent);
  if Temp = 35615 {1F8B} then
  begin
    TempStream := tmemorystream.Create;
    try
      TempStream.CopyFrom(SourceStream, SourceStream.Size - 12);
      Tempstream.Position := 0;
      SourceStream.Size := 12;
      GZDecompressStream(tempstream, sourcestream);
    finally
      TempStream.Free;
    end;

  end;




  Datasize := Sourcestream.Size - 12; //The header on the dxt files is only 12 bytes long and is not a DDPIXELFORMAT structure
  Dataoffset := 12;

  FillChar(header, SizeOf(TDDSHeader), 0);
  Header.magic := DDSMAGIC;

  Header.SurfaceFormat.dwSize := 124;
  Header.SurfaceFormat.dwFlags := DDSD_CAPS or DDSD_HEIGHT or DDSD_WIDTH or DDSD_PIXELFORMAT or DDSD_LINEARSIZE;
  Header.SurfaceFormat.dwHeight := Height;
  Header.SurfaceFormat.dwWidth := Width;
  Header.SurfaceFormat.dwPitchOrLinearSize := Datasize;

  Header.SurfaceFormat.ddpfPixelFormat.dwSize := 32;
  Header.SurfaceFormat.ddpfPixelFormat.dwFlags := DDPF_FOURCC; //or DDPF_ALPHAPIXELS;
  //Header.SurfaceFormat.ddpfPixelFormat.dwRGBAlphaBitMask := $FF000000;

  SourceStream.Position := 0;
  SourceStream.Read(TempFourCC, 4);
  Header.SurfaceFormat.ddpfPixelFormat.dwFourCC :=  TempFourCC;

  Header.SurfaceFormat.ddsCaps.dwCaps1 := DDSCAPS_TEXTURE;

  DestStream.Position := 0;
  DestStream.Write(header, SizeOf(TDDSHeader));

  SourceStream.Position := Dataoffset;
  DestStream.CopyFrom(SourceStream, DataSize);


  //DestStream.SaveToFile('C:\Users\Ben\Desktop\test.dds');
end;

function TMIExplorerBase.DrawImageGeneric(FileIndex: integer;
  DestBitmap: TBitmap32): boolean;
var
  TempStream: TExplorerMemoryStream;
begin
  result:=true;

  TempStream:=TExplorerMemoryStream.Create;
  try
    DestBitmap.Clear();
    destbitmap.CombineMode:=cmBlend;
    destBitmap.DrawMode:=dmOpaque;
    fBundle.SaveFileToStream(FileIndex, TempStream);
    if DrawImage(TempStream, DestBitmap) = false then
    begin
      Log('Image decode failed! ' + fBundle.FileName[FileIndex]);
      result:=false;
    end;
  finally
    TempStream.Free;
  end;
end;

function TMIExplorerBase.GetFileName(Index: integer): string;
begin
  result:=fBundle.FileName[Index];
end;

function TMIExplorerBase.GetFileOffset(Index: integer): integer;
begin
  result:=fBundle.FileOffset[Index];
end;

function TMIExplorerBase.GetFileSize(Index: integer): integer;
begin
  result:=fBundle.FileSize[Index];
end;

procedure TMIExplorerBase.Initialise;
begin
  if assigned(FOnDoneLoading) then
    fBundle.OnDoneLoading:=FOnDoneLoading;
  if assigned(FOnDebug) then
    fBundle.OnDebug:=FOnDebug;

  fBundle.ParseFiles;
end;

procedure TMIExplorerBase.Log(Text: string);
begin
  if assigned(fOnDebug) then fOnDebug(Text);
end;

procedure TMIExplorerBase.ReadText(FileIndex: integer; DestStrings: TStrings);
var
  TempStream: TExplorerMemoryStream;
begin
  TempStream:=TExplorerMemoryStream.Create;
  try
    fBundle.SaveFileToStream(Fileindex, TempStream);
    DestStrings.LoadFromStream(TempStream);
  finally
    TempStream.Free;
  end;
end;

function TMIExplorerBase.SaveDDSToFile(FileIndex: integer; DestDir,
  FileName: string): boolean;
var
  TempStream: TExplorerMemoryStream;
  SaveFile: TFileStream;
begin
  result:=false;

  if (FileIndex < 0) or (FileIndex > fBundle.Count) then
  begin
    Log('Invalid file number! Save cancelled.');
    exit;
  end;


  TempStream:=TExplorerMemoryStream.Create;
  try
    fBundle.SaveFileToStream(FileIndex, TempStream);
    TempStream.Position:=0;

    SaveFile:=tfilestream.Create(IncludeTrailingPathDelimiter(DestDir)  + FileName, fmOpenWrite or fmCreate);
    try
      WriteDDSToStream(Tempstream, SaveFile);
      Result:=true;
    finally
      SaveFile.Free;
    end;
  finally
    TempStream.Free;
  end;
end;

procedure TMIExplorerBase.SaveFile(FileNo: integer; DestDir, FileName: string);
begin
  fBundle.SaveFile(FileNo, DestDir, Filename);
end;

procedure TMIExplorerBase.SaveFiles(DestDir: string);
begin
  fBundle.SaveFiles(DestDir);
end;



function TMIExplorerBase.SaveImageDDSAsPNG(FileIndex: integer; DestDir,
  FileName: string): Boolean;
var
  TempStream, DDSStream: TExplorerMemoryStream;
  ImgPNG: TImagingPNG;
begin
  Result:=false;

  TempStream:=TExplorerMemoryStream.Create;
  try
    fBundle.SaveFileToStream(FileIndex, TempStream);
    TempStream.Position:=0;

    DDSStream:=TExplorerMemoryStream.Create;
    try
      WriteDDSToStream(Tempstream, DDSStream);
      DDSStream.Position :=0;

      ImgPNG := TImagingPNG.Create;
      try
        ImgPNG.LoadFromStream(DDSStream);
        if ImgPNG.Empty then
        begin
          Result := false;
          Log('Image decode failed! ' + fBundle.FileName[FileIndex]);
          Exit;
        end;

        ImgPNG.SaveToFile( IncludeTrailingPathDelimiter(DestDir)  + FileName );
        Result := true;
      finally
        ImgPNG.Free;
      end;

      Result:=true;
    finally
      DDSStream.Free;
    end;
  finally
    TempStream.Free;
  end;

end;

function TMIExplorerBase.SaveImageGenericAsPNG(FileIndex: integer; DestDir,
  FileName: string): Boolean;
var
  TempStream: TExplorerMemoryStream;
  ImgPNG: TImagingPNG;
begin
  result:=true;

  TempStream:=TExplorerMemoryStream.Create;
  try
    fBundle.SaveFileToStream(FileIndex, TempStream);

    TempStream.Position:=0;
    ImgPNG := TImagingPNG.Create;
    try
      ImgPNG.LoadFromStream(TempStream);
      if ImgPNG.Empty then
      begin
        Result := false;
        Log('Image decode failed! ' + fBundle.FileName[FileIndex]);
        Exit;
      end;

      ImgPNG.SaveToFile( IncludeTrailingPathDelimiter(DestDir)  + FileName );
      Result := true;
    finally
      ImgPNG.Free;
    end;
  finally
    TempStream.Free;
  end;

end;

function TMIExplorerBase.SaveWavToFile(FileIndex: integer; DestDir,
  FileName: string): boolean;
var
  SaveFile: TFileStream;
begin
  result:=false;

  if (FileIndex < 0) or (FileIndex > fBundle.Count) then
  begin
    Log('Invalid file number! Save cancelled.');
    exit;
  end;

  SaveFile:=tfilestream.Create(IncludeTrailingPathDelimiter(DestDir)  + FileName, fmOpenWrite or fmCreate);
  try
    SaveFile.Position:=0;
    SaveWavToStream(FileIndex, SaveFile);
  finally
    SaveFile.Free;
  end;

end;

function TMIExplorerBase.SaveWavToStream(FileIndex: integer;
  DestStream: Tstream): boolean;
begin
  result:=false;

  if (FileIndex < 0) or (FileIndex > fBundle.Count) then
  begin
    Log('Invalid file number! Save cancelled.');
    exit;
  end;

  TXWBManager(fBundle).SaveWavToStream(FileIndex, DestStream);
  Result := true;
end;

end.
