unit fServerForm;

interface

uses
  Windows, Messages, SysUtils, Classes, Graphics, Controls, Forms, Dialogs, StdCtrls,
  uROClient, uROPoweredByRemObjectsButton, uROClientIntf, uROServer, uROClasses;

type
  TServerForm = class(TForm)
    RoPoweredByRemObjectsButton1: TRoPoweredByRemObjectsButton;
  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  ServerForm: TServerForm;

implementation


{$R *.dfm}

end.
