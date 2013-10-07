unit FMX.Extensions.UX.Register;

interface

uses
  Classes,

  FMX.Extensions.UX.TabControl;

procedure Register;

implementation

procedure Register;
begin
  RegisterComponents('FMX Extensions', [TTabControlEx]);
end;

end.
