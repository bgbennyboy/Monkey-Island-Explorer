{
******************************************************
  Monkey Island Explorer
  Copyright (c) 2010 - 2011 Bgbennyboy
  Http://quick.mixnmojo.com
******************************************************
}

unit uMIExplorer_Types;

interface

uses
  SysUtils, Xact;

type
  TProgressEvent = procedure(ProgressMax: integer; ProgressPos: integer) of object;
  TDebugEvent = procedure(DebugText: string) of object;
  TOnDoneLoading = procedure(FileNamesCount: integer) of object;
  EInvalidFile = class (exception);

  TMIFile = class
    FileName: string;
    Size:     integer;
    Offset:   integer;
  end;

  TWaveBankFile = class
    FileName: string;
    Size:     integer;
    Offset:   integer;
    BankEntry: TWAVEBANKENTRY
  end;

implementation

end.
