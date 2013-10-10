unit fServerDataModule;

{$I RemObjects.inc}

interface

uses
  SysUtils, Classes, uROClient, uROServer, uROIndyTCPServer,
  uROPoweredByRemObjectsButton, uROClientIntf, uROClasses,
  uROBinMessage, uROIndyHTTPServer,

  RemObjects.RestServer;

type
  TServerDataModule = class(TDataModule)
    procedure DataModuleCreate(Sender: TObject);
  private
    FRORestServer: TRORestServer;
  end;

var
  ServerDataModule: TServerDataModule;

implementation

{$IFDEF DELPHIXE2UP}
{%CLASSGROUP 'System.Classes.TPersistent'}
{$ENDIF}

{$R *.dfm}

procedure TServerDataModule.DataModuleCreate(Sender: TObject);
begin
  FRORestServer := TRORestServer.Create(Self);
  FRORestServer.Port := 8181;

  FRORestServer.Active := TRUE;
end;

end.
