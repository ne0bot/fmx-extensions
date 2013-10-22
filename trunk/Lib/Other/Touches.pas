unit Touches;

//****************************************************************************
//* Thouches classes by David Nottage & Martin Searancke
//****************************************************************************
// Please email all changes or suggestions to martin@dreamsolutions.biz
//

interface

{$IFDEF IOS}
uses
  Macapi.ObjectiveC, Macapi.ObjCRuntime, iOSApi.UIKit, iOSApi.Foundation, TypInfo,
  FMX.Forms;

type
  UIViewTouches = interface(UIView)
    ['{513042E9-7B3A-43F6-BC0B-C33AF1B07E2B}']
    procedure touchesBegan(touches: NSSet; withEvent: UIEvent); cdecl;
    procedure touchesCancelled(touches: NSSet; withEvent: UIEvent); cdecl;
    procedure touchesEnded(touches: NSSet; withEvent: UIEvent); cdecl;
    procedure touchesMoved(touches: NSSet; withEvent: UIEvent); cdecl;
  end;

  TUIViewTouches = class(TOCLocal)
  private
    FForm: TCommonCustomForm;
    procedure DoLMouseDown(const X, Y: Single);
    procedure DoLMouseUp(const X, Y: Single);
    procedure DoLMouseMove(const X, Y: Single);
    procedure GetSingleTouchCoord(const touch: UITouch; const Window: UIView; var x, y: single);
  public
    constructor Create(const AOwner: TCommonCustomForm; AFRameRect: NSRect);
    destructor Destroy; override;
    function GetObjectiveCClass: PTypeInfo; override;
    // UIView
    procedure touchesBegan(touches: NSSet; withEvent: UIEvent); cdecl;
    procedure touchesCancelled(touches: NSSet; withEvent: UIEvent); cdecl;
    procedure touchesEnded(touches: NSSet; withEvent: UIEvent); cdecl;
    procedure touchesMoved(touches: NSSet; withEvent: UIEvent); cdecl;
    property Form: TCommonCustomForm read FForm;
  end;

{$ENDIF}
implementation
{$IFDEF IOS}

uses
  FMX.Controls, FMX.Platform.iOS, Classes, System.Generics.Collections, System.UITypes, iOSapi.CoreGraphics;

{ TUIViewTouches }

constructor TUIViewTouches.Create(const AOwner: TCommonCustomForm; AFRameRect: NSRect);
var
  V: Pointer;
  View: UIView;
begin
  inherited Create;
  V := UIView(Super).initWithFrame(AFrameRect);
  if V <> GetObjectID then
    UpdateObjectID(V);
  UIView(Super).setMultipleTouchEnabled(True);
  UIView(Super).setAutoresizesSubviews(True);
  FForm := AOwner;
  if Assigned(FForm) then
  begin
    View := WindowHandleToPlatform(Form.Handle).View;
    View.setMultipleTouchEnabled(True);
    View.addSubview(UIView(Super));
  end;
end;

function TUIViewTouches.GetObjectiveCClass: PTypeInfo;
begin
  Result := TypeInfo(UIViewTouches);
end;

destructor TUIViewTouches.Destroy;
var
  View: UIView;
begin
  UIView(Super).setMultipleTouchEnabled(false);
  if Assigned(FForm) then
  begin
    View := WindowHandleToPlatform(Form.Handle).View;
    View.setMultipleTouchEnabled(false);
    UIView(Super).removeFromSuperview;
  end;
  inherited;
end;

procedure TUIViewTouches.DoLMouseDown(const X, Y: Single);
var
  PopupList: TList<TPopup>;
  I: Integer;
begin
  try
    // Store all opened popup
    PopupList := TList<TPopup>.Create;
    try
      // Save all current opened TPopup Forms
      for I := 0 to GetPopupCount - 1 do
        PopupList.Add(GetPopup(I) as TPopup);

      if Assigned(Form) and (not Form.Released) then
      begin
//        Form.MouseMove([ssTouch], X, Y);
//        Application.ProcessMessages;
        Form.MouseDown(TMouseButton.mbLeft, [ssLeft, ssTouch], X, Y);
//        Application.ProcessMessages;
      end;

      // Close only all old opened popup
      if not (Form.Owner is TPopup) then
      begin
        for I := 0 to PopupList.Count - 1 do
          ClosePopup(PopupList[I]);
        PopupList.Clear;
      end;
    finally
      PopupList.DisposeOf;
    end;
  except
    Application.HandleException(Form);
  end;
end;

procedure TUIViewTouches.DoLMouseMove(const X, Y: Single);
var
  PopupList: TList<TPopup>;
  I: Integer;
begin
  try
    // Store all opened popup
    PopupList := TList<TPopup>.Create;
    try
      // Save all current opened TPopup Forms
      for I := 0 to GetPopupCount - 1 do
        PopupList.Add(GetPopup(I) as TPopup);

      if Assigned(Form) and (not Form.Released) then
      begin
        Form.MouseMove([ssTouch], X, Y);
//        Application.ProcessMessages;
      end;

      // Close only all old opened popup
      if not (Form.Owner is TPopup) then
      begin
        for I := 0 to PopupList.Count - 1 do
          ClosePopup(PopupList[I]);
        PopupList.Clear;
      end;
    finally
      PopupList.DisposeOf;
    end;
  except
    Application.HandleException(Form);
  end;
end;

procedure TUIViewTouches.DoLMouseUp(const X, Y: Single);
//var
  //PopupList: TList<TPopup>;
  //I: Integer;
begin
  try
    if Assigned(Form) and (not Form.Released) then
      Form.MouseUp(TMouseButton.mbLeft, [ssLeft, ssTouch], X, Y);
  except
    Application.HandleException(Form);
  end;
end;

procedure TUIViewTouches.GetSingleTouchCoord(const touch: UITouch; const Window: UIView; var x, y: single);
var
  p: CGPoint;
begin
  p := touch.locationInView(Window);
  x := p.x;
  y := p.y;
end;

procedure TUIViewTouches.touchesBegan(touches: NSSet; withEvent: UIEvent);
var
  Touch: UITouch;
  ViewTouches: NSSet;
  i, Count: Integer;
  X, Y: single;
begin
  ViewTouches := withEvent.touchesForView(UIView(Super));
  Count := ViewTouches.count;
  for i := 0 to Count - 1 do
  begin
    Touch := TUITouch.Wrap(ViewTouches.allObjects.objectAtIndex(i));
    GetSingleTouchCoord(Touch, UIView(Super), X, Y);
    DoLMouseDown(X, Y);
  end;
end;

procedure TUIViewTouches.touchesCancelled(touches: NSSet; withEvent: UIEvent);
begin
  //
end;

procedure TUIViewTouches.touchesEnded(touches: NSSet; withEvent: UIEvent);
var
  Touch: UITouch;
  ViewTouches: NSSet;
  i, Count: Integer;
  X, Y: single;
begin
  ViewTouches := withEvent.touchesForView(UIView(Super));
  Count := ViewTouches.count;
  for i := 0 to Count - 1 do
  begin
    Touch := TUITouch.Wrap(ViewTouches.allObjects.objectAtIndex(i));
    GetSingleTouchCoord(Touch, UIView(Super), X, Y);
    DoLMouseUp(X, Y);
  end;
end;

procedure TUIViewTouches.touchesMoved(touches: NSSet; withEvent: UIEvent);
var
  Touch: UITouch;
  ViewTouches: NSSet;
  i, Count: Integer;
  X, Y: single;
begin
  ViewTouches := withEvent.touchesForView(UIView(Super));
  Count := ViewTouches.count;
  for i := 0 to Count - 1 do
  begin
    Touch := TUITouch.Wrap(ViewTouches.allObjects.objectAtIndex(i));
    GetSingleTouchCoord(Touch, UIView(Super), X, Y);
    DoLMouseMove(X, Y);
  end;
end;
{$ENDIF}
end.
