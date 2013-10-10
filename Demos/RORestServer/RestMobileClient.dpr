program RestMobileClient;

uses
  System.StartUpCopy,
  FMX.Forms,
  frmRestClientU in 'frmRestClientU.pas' {frmRestClient};

{$R *.res}

begin
  Application.Initialize;
  Application.CreateForm(TfrmRestClient, frmRestClient);
  Application.Run;
end.
