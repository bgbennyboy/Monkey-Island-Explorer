{
******************************************************
  Monkey Island Explorer
  Copyright (c) 2010 - 2018 Bennyboy
  Http://quickandeasysoftware.net
******************************************************
}

unit uMIExplorer_Funcs;

interface

uses
  Sysutils, Windows, Classes, StrUtils, JCLStrings, JCLRegistry;

  function GetMI1SEPath: string;
  function GetMI2SEPath: string;
  function SanitiseFileName(FileName: string): string;
  function ExtractPartialPath(FileName: string): string;
  function SwapEndianDWord(Value: integer): integer; register;
  procedure GetSteamLibraryPaths(LibraryPaths: TStringList);
implementation

procedure GetSteamLibraryPaths(LibraryPaths: TStringList);
var
  SteamPath, VDFfile, CurrLine, NewPath: string;
  Reader: TStreamReader;
begin
  try
    SteamPath := IncludeTrailingPathDelimiter(
      RegReadString(HKEY_CURRENT_USER, 'SOFTWARE\Valve\Steam', 'SteamPath'));
    SteamPath := StringReplace(SteamPath, '/', '\', [rfReplaceAll, rfIgnoreCase]);
  except on EJCLRegistryError do
    exit;
  end;

  LibraryPaths.Add(SteamPath);

  VDFfile := SteamPath + 'config\libraryfolders.vdf';
  if FileExists(VDFfile) = false then exit;


  Reader := TStreamReader.Create(TFileStream.Create(VDFfile, fmOpenRead), TEncoding.UTF8);
  try
    while not Reader.EndOfStream do
    begin
      CurrLine := Reader.ReadLine;
      if AnsiContainsStr(CurrLine, '"path"') then //BaseInstallFolder is the extra library
      begin
        NewPath := StrAfter('"path"', CurrLine);
        NewPath := StrRemoveChars(NewPath, [#34]); //Remove the surrounding double quotes
        NewPath := StrRemoveChars(NewPath, [#9]); //Remove any tab characters before the string
        NewPath := IncludeTrailingPathDelimiter(NewPath); //Add the backslash to the path
        StrReplace(NewPath, '\\', '\', [rfReplaceAll]); //Remove the \\ and replace with \
        LibraryPaths.Add(NewPath);
        //ShowMessage(NewPath);
      end;
    end;
  finally
    Reader.Close();
    Reader.BaseStream.Free;
    Reader.Free();
  end;
end;


function GetMI1SEPath: string;
const
  ExtraPath: string = 'steamapps\common\the secret of monkey island special edition\';
var
  Paths: TStringList;
  i: integer;
begin
  Result := '';
  Paths := TStringList.Create;
  try
    GetSteamLibraryPaths(Paths);
    if Paths.Count > 0 then
      for I := 0 to Paths.Count -1 do
      begin
        if DirectoryExists(Paths[i] + ExtraPath) then
        begin
          result:=Paths[i] + ExtraPath;
          break;
        end;
      end;
  finally
    Paths.free;
  end;
end;


function GetMI2SEPath: string;
const
  ExtraPath: string = 'steamapps\common\monkey2\';
var
  Paths: TStringList;
  i: integer;
begin
  Result := '';
  Paths := TStringList.Create;
  try
    GetSteamLibraryPaths(Paths);
    if Paths.Count > 0 then
      for I := 0 to Paths.Count -1 do
      begin
        if DirectoryExists(Paths[i] + ExtraPath) then
        begin
          result:=Paths[i] + ExtraPath;
          break;
        end;
      end;
  finally
    Paths.free;
  end;
end;

function SanitiseFileName(FileName: string): string;
var
  DelimiterPos: integer;
begin
  DelimiterPos := LastDelimiter('/', FileName );
  if DelimiterPos = 0 then
    result := FileName
  else
    Result := Copy( FileName, DelimiterPos + 1, Length(FileName) - DelimiterPos + 1);
end;

function ExtractPartialPath(FileName: string): string;
var
  DelimiterPos: integer;
begin
  DelimiterPos := LastDelimiter('/', FileName );
  if DelimiterPos = 0 then
    result := ''
  else
  begin
    Result := Copy( FileName, 1,  DelimiterPos);
    Result := StringReplace(Result, '/', '\', [rfReplaceAll, rfIgnoreCase ]);
  end;
end;

function SwapEndianDWord(Value: integer): integer; register;
asm
  bswap eax
end;



end.
