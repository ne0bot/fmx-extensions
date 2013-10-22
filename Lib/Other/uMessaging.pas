unit uMessaging;

//****************************************************************************
//* Threadsafe Messaging classes by Martin Searancke
// This class is designed for threadsafe messaging between any thread and the main thread
//****************************************************************************
// Please email all changes or suggestions to martin@dreamsolutions.biz
//


interface

uses
  System.Classes, Generics.collections, System.SyncObjs;

Type
  TLFMessageEvent = procedure(ID, Val1, Val2, Val3: Integer; msg: string) of object;
  TLFMessageTarget = procedure(Val1, Val2, Val3: Integer; msg: string) of object;

  TMessageClients = class
  public
    ID: integer;
    evt: TLFMessageTarget;
  end;

  TMessages = class
  public
    ID: integer;
    val1, val2, val3: integer;
    msg: string;
    constructor Create(iID, iVal1, iVal2, iVal3: integer; iMsg: string);
  end;

  TLFMessages = class(TThread)
  private
    ClientList: TList<TMessageClients>;
    MessageQueue: TThreadedQueue<TMessages>;
    procedure SendMessageToClients(id, v1, v2, v3: integer; m: string);
    //cs: TCriticalSection;
  protected
    procedure Execute; override;
  public
    procedure RegisterForMessages(RegID: integer; func: TLFMessageTarget);
    procedure SendLFMessage(ID, Val1, Val2, Val3: Integer; msg: string = '');

    procedure Shutdown;

    constructor Create;
  end;

  function LFMsg: TLFMessages;

implementation

var
  aLFMsg: TLFMessages = NIL;

function LFMsg: TLFMessages;
begin
  if not assigned(aLFMsg) then
    aLFMsg := TLFMessages.Create;
  result := aLFMsg;
end;

{ TLFMessages }

constructor TLFMessages.Create;
begin
  inherited Create(False);
  ClientList := TList<TMessageClients>.Create;
  MessageQueue := TThreadedQueue<TMessages>.Create;
  //cs := TCriticalSection.Create;
end;

procedure TLFMessages.Execute;
var
  I: Integer;
  procedure InnerFunc;
  var
    tmpMsg: TMessages;
  begin
    tmpMsg := MessageQueue.PopItem;
    Queue(   // NOTE: using "Synchronize" here causes a deadlock on the mobile compiler
        procedure
        begin
          SendMessageToClients(tmpMsg.ID, tmpMsg.val1, tmpMsg.val2, tmpMsg.val3, tmpMsg.msg);
        end);
  end;
begin
  inherited;
  while not Terminated do
  begin
    while MessageQueue.QueueSize > 0 do
      InnerFunc;
    Sleep(10);
  end;
end;

procedure TLFMessages.SendMessageToClients(id, v1, v2, v3: integer; m: string);
var
  i: integer;
begin
  for i := 0 to ClientList.Count-1 do
  begin
    if ClientList[i].ID = id then
      ClientList[i].evt(v1, v2, v3, m);
  end;
end;

procedure TLFMessages.RegisterForMessages(RegID: integer; func: TLFMessageTarget);
var
  tmp: TMessageClients;
begin
  //cs.Enter;
  //try
    tmp := TMessageClients.Create;
    tmp.ID := RegID;
    tmp.evt := func;
    ClientList.Add(tmp);
  //finally
  //  cs.Leave;
  //end;
end;

procedure TLFMessages.SendLFMessage(ID, Val1, Val2, Val3: Integer; msg: string);
begin
  MessageQueue.PushItem(TMessages.Create(ID, Val1, Val2, Val3, msg));
end;

procedure TLFMessages.Shutdown;
begin
  Terminate;
end;

{ TMessages }

constructor TMessages.Create(iID, iVal1, iVal2, iVal3: integer; iMsg: string);
begin
  ID := iID;
  val1 := iVal1;
  val2 := iVal2;
  val3 := iVal3;
  msg := iMsg;
end;

end.
