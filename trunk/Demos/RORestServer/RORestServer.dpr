program RORestServer;

{#ROGEN:DemoLibrary.rodl} // RemObjects: Careful, do not remove!

uses
  uROComInit,
  uROComboService,
  Forms,
  fServerDataModule in 'fServerDataModule.pas' {ServerDataModule: TDataModule},
  fServerForm in 'fServerForm.pas' {ServerForm},
  RemObjects.RestServer in '..\..\Lib\Other\RemObjects.RestServer.pas',
  DemoLibrary_Intf in 'DemoLibrary_Intf.pas',
  DemoLibrary_Invk in 'DemoLibrary_Invk.pas',
  DemoService_Impl in 'DemoService_Impl.pas' {DemoService: TRORemoteDataModule};

{$R *.res}
{$R RODLFile.res}

begin
  if ROStartService('RORestServer', 'RORestServer') then begin
    ROService.CreateForm(TServerDataModule, ServerDataModule);
    ROService.Run;
    Exit;
  end;

  Application.Initialize;
  Application.CreateForm(TServerDataModule, ServerDataModule);
  Application.CreateForm(TServerForm, ServerForm);
  Application.Run;
end.
