unit frmRestClientU;

interface

{.$DEFINE USE_XSUPEROBJECT}

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes, System.Variants,
  FMX.Types, FMX.Controls, FMX.Forms, FMX.Dialogs, FMX.Layouts, FMX.Memo,
  System.Actions, FMX.ActnList, FMX.StdCtrls,

  {$IFDEF USE_XSUPEROBJECT}
  XSuperObject,
  {$ENDIF}

  IdHTTP, FMX.Edit, FMX.ListView.Types, FMX.ListView, FMX.TabControl;

type
  TRestThread = class(TThread)
  protected
    FURL: String;
    FParams: String;
    FError: String;
    FReply: String;
  public
    constructor Create(const URL, Params: String);

    property Error: String read FError;
    property Reply: String read FReply;

    procedure Execute; override;
  end;

  TfrmRestClient = class(TForm)
    Button1: TButton;
    actStruct: TButton;
    Button3: TButton;
    ActionList1: TActionList;
    actGetServerTime: TAction;
    actGetSum: TAction;
    actGetStruct: TAction;
    edtURL: TEdit;
    tcResults: TTabControl;
    tabText: TTabItem;
    tabListView: TTabItem;
    memResult: TMemo;
    vtStruct: TListView;
    procedure actGetServerTimeExecute(Sender: TObject);
    procedure ActionList1Update(Action: TBasicAction; var Handled: Boolean);
    procedure actGetSumExecute(Sender: TObject);
    procedure actGetStructExecute(Sender: TObject);
    procedure FormCreate(Sender: TObject);
  protected
    FRestThread: TRestThread;
    FLoadingStruct: Boolean;
  private
    procedure LoadData(const MethodName: String; const ParamNames: array of String; const ParamValues: array of Variant);
    procedure OnRestThreadTerminate(Sender: TObject);
    procedure UpdateStructListView(const JSON: String);
  public
  end;

var
  frmRestClient: TfrmRestClient;

implementation

const
  URL = 'http://127.0.0.1:8181/json/DemoService/';

{$R *.fmx}

procedure TfrmRestClient.actGetServerTimeExecute(Sender: TObject);
begin
  LoadData('GetServerTime', [], []);
end;

procedure TfrmRestClient.actGetStructExecute(Sender: TObject);
begin
  FLoadingStruct := TRUE;

  LoadData('GetDemoStruct', ['Count'], [10]);
end;

procedure TfrmRestClient.actGetSumExecute(Sender: TObject);
begin
  LoadData('GetSum', ['A', 'B'], [5, 5]);
end;

procedure TfrmRestClient.ActionList1Update(Action: TBasicAction;
  var Handled: Boolean);
begin
  actGetServerTime.Enabled := FRestThread = nil;
  actGetSum.Enabled := FRestThread = nil;
  actGetStruct.Enabled := FRestThread = nil;

  Handled := TRUE;
end;

procedure TfrmRestClient.FormCreate(Sender: TObject);
begin
  tcResults.ActiveTab := tabText;
end;

procedure TfrmRestClient.LoadData(const MethodName: String; const ParamNames: Array of String; const ParamValues: Array of Variant);
var
  FullURL, ParamString: String;
  i: Integer;
begin
  Assert(length(ParamNames) = length(ParamValues));

  FullURL := URL + MethodName;
  ParamString := '';

  for i := Low(ParamNames) to High(ParamNames) do
  begin
    if i = low(ParamNames) then
      ParamString := ParamString + '?'
    else
      ParamString := ParamString + '&';

    ParamString := format('%s%s=%s', [ParamString, ParamNames[i], VarToStr(ParamValues[i])]);
  end;

  edtURL.Text := FullURL + ParamString;

  FRestThread := TRestThread.Create(FullURL, ParamString);
  FRestThread.OnTerminate := OnRestThreadTerminate;
  FRestThread.Start;
end;

procedure TfrmRestClient.OnRestThreadTerminate(Sender: TObject);
begin
  try
    if FRestThread.Error <> '' then
    begin
      ShowMessage(FRestThread.Error);
    end
    else
    begin
      memResult.Text := FRestThread.Reply;

      if FLoadingStruct then
      begin
        UpdateStructListView(FRestThread.Reply);

        tcResults.ActiveTab := tabListView;
      end
      else
      begin
        tcResults.ActiveTab := tabText;
      end;
    end;
  finally
    FRestThread := nil;
    FLoadingStruct := FALSE;
  end;
end;

procedure TfrmRestClient.UpdateStructListView(const JSON: String);
var
  Item: TListViewItem;
  {$IFDEF USE_XSUPEROBJECT}
  i: Integer;
  SuperObject: ISuperObject;
  {$ENDIF}
begin
  vtStruct.BeginUpdate;
  try
    vtStruct.ClearItems;

   {$IFDEF USE_XSUPEROBJECT}
    SuperObject := SO(JSON);

    for i := 0 to pred(SuperObject.A['result'].Length) do
    begin
      Item := vtStruct.Items.Add;

      Item.Text := format('Field1: %s - Field2: %d - Field3 - %s',
                          [SuperObject.A['result'].O[i].S['Field1'],
                           SuperObject.A['result'].O[i].I['Field2'],
                           FloatToStr(SuperObject.A['result'].O[i].F['Field3'])]);
    end;
    {$ELSE}
    Item := vtStruct.Items.Add;
    Item.Text := 'Download XSuperObject (https://code.google.com/p/x-superobject/)';
    Item := vtStruct.Items.Add;
    Item.Text := 'then define {USE_XSUPEROBJECT}';
    {$ENDIF}
  finally
    vtStruct.EndUpdate;
  end;
end;

{ TRestThread }

constructor TRestThread.Create(const URL, Params: String);
begin
  inherited Create(TRUE);

  FURL := URL;
  FParams := Params;

  FreeOnTerminate := TRUE;
end;

procedure TRestThread.Execute;
var
  IdHTTP: TIdHTTP;
  StringStream: TStringStream;
begin
  try
    StringStream := TStringStream.Create;
    IdHTTP := TIdHTTP.Create(nil);
    try
      IdHTTP.ConnectTimeout := 10000;

      IdHTTP.Get(FURL + FParams, StringStream);

      FReply := StringStream.DataString;
    finally
      FreeAndNil(StringStream);
      FreeAndNil(IdHTTP);
    end;
  except
    on e: Exception do
    begin
      FError := e.Message;
    end;
  end;
end;

end.
