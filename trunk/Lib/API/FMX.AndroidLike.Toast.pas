unit FMX.AndroidLike.Toast;

// FMX Cross Plattform Toast Component by Roland Kossow (https://www.cybertribe.de)
// How to use: Configure location via Objectinspector or at runtime and call
// NameOfToastcomponent.Now('Text to Toast');

interface

uses
  System.SysUtils,
  System.Classes,
  System.Types,
  FMX.Types,
  FMX.Controls,
  FMX.StdCtrls,
  FMX.Objects,
  System.UITypes,
  FMX.Graphics,
  System.Actions,
  System.Rtti,
  System.Generics.Collections,
  System.Generics.Defaults,
  FMX.Styles,
  FMX.TextLayout,
  FMX.Effects;

type

  TToast = class(TFMXObject)
  private
    FRectangle: TRectangle;
    FTextfield: TLabel;
    FTimer: TTimer;
    FTextColor: TAlphaColor;
    FToastBoxColor: TAlphaColor;
    FToastBoxStrokeDash: TStrokeDash;
    FDuration: Integer;
    FInfo: String;
    FOptimalWidth: Boolean;
    FTextAlign: TTextAlign;
    FTextFont: TFont;
    FToastBoxAlign: TAlignLayout;
    FToastBoxHeight: Single;
    FToastBoxMargin: TBounds;
    FToastBoxStrokeColor: TAlphaColor;
    FToastBoxStrokeThickness: Single;
    FToastboxPosition: TPosition;
    FToastBoxWidth: Single;
    FVersion: String;
    procedure SetDuration(const Value: Integer);
    procedure HideToast(Sender: TObject);
    procedure SetOptimalWidth(const Value: Boolean);
    procedure SetToastBoxColor(const Value: TAlphaColor);
    procedure SetToastBoxStrokeDash(const Value: TStrokeDash);
    procedure SetTextAlign(const Value: TTextAlign);
    procedure SetTextColor(const Value: TAlphaColor);
    procedure SetTextFont(const Value: TFont);
    procedure SetToastBoxAlign(const Value: TAlignLayout);
    procedure SetToastBoxMargin(const Value: TBounds);
    procedure SetToastBoxStrokeColor(const Value: TAlphaColor);
    procedure SetToastBoxStrokeThickness(const Value: Single);
    procedure SetToastboxPosition(const Value: TPosition);
  protected
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    procedure Now(aToastString: String);
  published
    property ToastBoxStrokeColor: TAlphaColor read FToastBoxStrokeColor
      write SetToastBoxStrokeColor;
    property TextColor: TAlphaColor read FTextColor write SetTextColor;
    property ToastBoxColor: TAlphaColor read FToastBoxColor
      write SetToastBoxColor;
    property ToastBoxStrokeDash: TStrokeDash read FToastBoxStrokeDash
      write SetToastBoxStrokeDash;
    property TextAlign: TTextAlign read FTextAlign write SetTextAlign;
    property Duration: Integer read FDuration write SetDuration;
    property Info: String read FInfo;
    property OptimalWidth: Boolean read FOptimalWidth write SetOptimalWidth;
    property TextFont: TFont read FTextFont write SetTextFont;
    property ToastBoxAlign: TAlignLayout read FToastBoxAlign
      write SetToastBoxAlign;
    property ToastBoxHeight: Single read FToastBoxHeight write FToastBoxHeight;
    property ToastBoxMargin: TBounds read FToastBoxMargin
      write SetToastBoxMargin;
    property ToastBoxStrokeThickness: Single read FToastBoxStrokeThickness
      write SetToastBoxStrokeThickness;
    property ToastboxPosition: TPosition read FToastboxPosition
      write SetToastboxPosition;
    property ToastBoxWidth: Single read FToastBoxWidth write FToastBoxWidth;
    property Version: String read FVersion;
  end;

procedure Register;

Const
 INFO_URL:string  = 'https://www.cybertribe.de/info/components/fmx/toast';
 COMPONENT_VERSION: string = '0.1 Alpha';

implementation

uses System.RTLConsts, FMX.Consts, FMX.Forms, FMX.Ani,
  FMX.Platform, FMX.Layouts;

procedure Register;
begin
  RegisterComponents('AndroidLike', [TToast]);
end;

constructor TToast.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FToastboxPosition := TPosition.Create(TPointF.Create(0, 0));
  FToastBoxMargin := TBounds.Create(TRectF.Create(100, 100, 100, 30));
  FToastBoxWidth := 100;
  FToastBoxHeight := 50;
  FTextFont := TFont.Create;
  FVersion := COMPONENT_VERSION;
  FInfo := INFO_URL;
  if not(csDesigning in ComponentState) then
  begin
    self.FRectangle := TRectangle.Create(AOwner);
    self.FRectangle.Parent := TFMXObject(self.Parent);
    self.FRectangle.Visible := false;
    self.FTextfield := TLabel.Create(AOwner);
    self.FTextfield.Visible := false;
    self.FTextfield.FontColor := TAlphaColorRec.Red;
    self.FTextfield.Stored := false;
    self.FTextfield.Name := self.Name + 'Textfield';
    self.FTextfield.Parent := self.FRectangle;
    self.FTextfield.Text := '';
    self.FTextfield.Align := TAlignLayout.alClient;
    self.FTextfield.StyledSettings := [];
    self.FTimer := TTimer.Create(AOwner);
    self.FTimer.Name := self.Name + 'Timer';
    self.FTimer.Enabled := false;
    self.FTimer.Interval := 1000;
    self.FTimer.OnTimer := self.HideToast;
  end;
end;

destructor TToast.Destroy;
begin
  FTextFont.Free;
  FToastboxPosition.Free;
  FToastBoxMargin.Free;
  inherited Destroy;
end;

procedure TToast.HideToast(Sender: TObject);
begin
  self.FTimer.Enabled := false;
  self.FRectangle.AnimateFloat('Opacity', 0, 0.3);
end;

procedure TToast.SetDuration(const Value: Integer);
begin
  FDuration := Value;
end;

procedure TToast.Now(aToastString: String);
var
  sidemargin: Single;
begin
  self.FRectangle.BeginUpdate;
  self.FTextfield.Font := FTextFont;
  self.FTextfield.FontColor := FTextColor;
  self.FTextfield.TextAlign := FTextAlign;
  self.FTextfield.Text := aToastString;
  self.FTextfield.Visible := true;
  self.FRectangle.Parent := self.Parent;
  self.FRectangle.Align := FToastBoxAlign;
  self.FRectangle.StrokeThickness := FToastBoxStrokeThickness;
  self.FRectangle.Fill.Color := FToastBoxColor;
  self.FRectangle.StrokeDash := FToastBoxStrokeDash;
  self.FRectangle.Stroke.Color := FToastBoxStrokeColor;
  self.FRectangle.Position := FToastboxPosition;
  self.FRectangle.Margins := FToastBoxMargin;
  self.FRectangle.Opacity := 0;
  self.FRectangle.Visible := true;
  self.FRectangle.BringToFront;
  self.FRectangle.Repaint;
  self.FRectangle.Width := FToastBoxWidth;
  self.FRectangle.Height := FToastBoxHeight;
  if FOptimalWidth then
  begin
    if FToastBoxAlign = TAlignLayout.alNone then
      self.FRectangle.Width := self.FTextfield.Canvas.TextWidth
        (aToastString) + 50
    else
    begin
      sidemargin := (self.FRectangle.ParentedRect.Width -
        self.FTextfield.Canvas.TextWidth(aToastString) + 50) / 2;
      self.FRectangle.Margins.Left := sidemargin;
      self.FRectangle.Margins.Right := sidemargin;
      self.FRectangle.Width := self.FRectangle.ParentedRect.Width -
        self.FTextfield.Canvas.TextWidth(aToastString) + 50;
    end;
  end;
  self.FRectangle.BringToFront;
  self.FRectangle.EndUpdate;
  self.FRectangle.Repaint;
  self.FRectangle.AnimateFloat('Opacity', 1, 0.3);
  self.FTimer.Interval := FDuration;
  self.FTimer.Enabled := true;
end;

procedure TToast.SetOptimalWidth(const Value: Boolean);
begin
  FOptimalWidth := Value;
end;

procedure TToast.SetTextColor(const Value: TAlphaColor);
begin
  FTextColor := Value;
end;

procedure TToast.SetToastBoxColor(const Value: TAlphaColor);
begin
  FToastBoxColor := Value;
end;

procedure TToast.SetToastBoxStrokeDash(const Value: TStrokeDash);
begin
  FToastBoxStrokeDash := Value;
end;

procedure TToast.SetTextAlign(const Value: TTextAlign);
begin
  FTextAlign := Value;
end;

procedure TToast.SetTextFont(const Value: TFont);
begin
  FTextFont.Assign(Value);
end;

procedure TToast.SetToastBoxAlign(const Value: TAlignLayout);
begin
  FToastBoxAlign := Value;
end;

procedure TToast.SetToastBoxMargin(const Value: TBounds);
begin
  FToastBoxMargin.Assign(Value);
end;

procedure TToast.SetToastBoxStrokeColor(const Value: TAlphaColor);
begin
  FToastBoxStrokeColor := Value;
end;

procedure TToast.SetToastBoxStrokeThickness(const Value: Single);
begin
  FToastBoxStrokeThickness := Value;
end;

procedure TToast.SetToastboxPosition(const Value: TPosition);
begin
  FToastboxPosition.Assign(Value);
end;

end.
