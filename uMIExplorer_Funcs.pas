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
  Sysutils, Windows, JCLRegistry;

  function GetMI1SEPath: string;
  function GetMI2SEPath: string;
  function SanitiseFileName(FileName: string): string;
  function ExtractPartialPath(FileName: string): string;
  function SwapEndianDWord(Value: integer): integer; register;
implementation

function GetMI1SEPath: string;
const
  ExtraPath: string = 'steamapps\common\the secret of monkey island special edition\';
var
  Temp: string;
begin
  Result := '';
  try
    Temp:= IncludeTrailingPathDelimiter(RegReadString(HKEY_CURRENT_USER, 'SOFTWARE\Valve\Steam', 'SteamPath'));
    result:=Temp + ExtraPath;
    Result := StringReplace(Result, '/', '\', [rfReplaceAll, rfIgnoreCase ]);
  except on EJCLRegistryError do
    result:='';
  end;
end;

function GetMI2SEPath: string;
const
  ExtraPath: string = 'steamapps\common\monkey2\';
var
  Temp: string;
begin
  Result := '';
  try
    Temp:= IncludeTrailingPathDelimiter(RegReadString(HKEY_CURRENT_USER, 'SOFTWARE\Valve\Steam', 'SteamPath'));
    result:=Temp + ExtraPath;
    Result := StringReplace(Result, '/', '\', [rfReplaceAll, rfIgnoreCase ]);
  except on EJCLRegistryError do
    result:='';
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
