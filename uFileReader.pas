{
******************************************************
  Monkey Island Explorer
  Copyright (c) 2010 - 2011 Bgbennyboy
  Http://quick.mixnmojo.com
******************************************************
}

unit uFileReader;

interface

uses
	Classes, SysUtils;

type
  TExplorerFileStream = class (TFileStream)

  private
    fBigEndian: boolean;
    procedure setBigEndian(const Value: boolean);
  public
    function ReadByte: byte; inline;
    function ReadWord: word; inline;
    function ReadWordBE: word; inline;
    function ReadDWord: longword; inline;
    function ReadDWordBE: longword; inline;
    function ReadBlockName: string; inline;
    function ReadString(Length: integer): string;
    function ReadStringAlt(Length: integer): string;
    constructor Create(FileName: string);
    destructor Destroy; override;
    property BigEndian: boolean read fBigEndian write setBigEndian;

end;

implementation

function TExplorerFileStream.ReadByte: byte;
begin
	Read(result,1);
end;

function TExplorerFileStream.ReadWord: word;
begin
  if fBigEndian then
    result :=ReadWordBE
  else
    Read(result,2);
end;

function TExplorerFileStream.ReadWordBE: word;
begin
	result:=ReadByte shl 8
   		    +ReadByte;
end;

function TExplorerFileStream.ReadDWord: longword;
begin
  if fBigEndian then
    result :=ReadDWordBE
  else
    Read(result,4);
end;

function TExplorerFileStream.ReadDWordBE: longword;
begin
	result:=ReadByte shl 24
          +ReadByte shl 16
   		    +ReadByte shl 8
          +ReadByte;
end;

function TExplorerFileStream.ReadBlockName: string;
begin
   result:=chr(ReadByte)+chr(ReadByte)+chr(ReadByte)+chr(ReadByte);
end;

function TExplorerFileStream.ReadString(Length: integer): string;
var
  n: longword;
begin
  SetLength(result,length);
  for n:=1 to length do
  begin
    result[n]:=Chr(ReadByte);
  end;
end;

function TExplorerFileStream.ReadStringAlt(Length: integer): string;
var //Replaces #0 chars with character
  n: longword;
  Rchar: char;
begin
  SetLength(result,length);
  for n:=0 to length -1 do
  begin
    RChar:=Chr(ReadByte);
    if RChar=#0 then
      result[n]:='x'
    else
    result[n]:=rchar;
  end;
end;

procedure TExplorerFileStream.setBigEndian(const Value: boolean);
begin
  fBigEndian := Value;
end;

constructor TExplorerFileStream.Create(FileName: string);
begin
  inherited Create(Filename, fmopenread);
  fBigEndian := false;
end;

destructor TExplorerFileStream.Destroy;
begin
  inherited;
end;

end.
