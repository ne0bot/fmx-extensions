unit FMX.Extensions.UX.TabControl;

// Version 0.1
//
// FMX Tab Control Extension
//
//----------------------------------------------------------------------------------------------------------------------
//
// The contents of this file are subject to the Mozilla Public License
// Version 1.1 (the "License"); you may not use this file except in compliance
// with the License. You may obtain a copy of the License at http://www.mozilla.org/MPL/
//
// Alternatively, you may redistribute this library, use and/or modify it under the terms of the
// GNU Lesser General Public License as published by the Free Software Foundation;
// either version 2.1 of the License, or (at your option) any later version.
// You may obtain a copy of the LGPL at http://www.gnu.org/copyleft/.
//
// Software distributed under the License is distributed on an "AS IS" basis,
// WITHOUT WARRANTY OF ANY KIND, either express or implied. See the License for the
// specific language governing rights and limitations under the License.
//
// The original code is ChromeTabs.pas, released December 2012.
//
// The initial developer of the original code is Easy-IP AS (Oslo, Norway, www.easy-ip.net),
// written by Paul Spencer Thornton (paul.thornton@easy-ip.net, www.easy-ip.net).
//
//----------------------------------------------------------------------------------------------------------------------
// Features:
//
// SetActiveTabWithTransitionEx - Faster tab transistion with addtional options.

interface

uses
  System.SysUtils, System.Classes, System.Types, System.UITypes,

  FMX.Controls, FMX.TabControl, FMX.Types, FMX.Ani, FMX.Platform, FMX.WebBrowser,
  FMX.Forms, FMX.TextLayout.GPU, FMX.Graphics, FMX.Objects, FMX.Layouts;

type
  TTabItemHelper = class helper for TTabItem
  private
    function GetContent: TContent;
  public
    property Content: TContent read GetContent;
  end;

  TTabControlEx = class(TTabControl)
  private
    FTransistionLayout: TLayout;
    FCurrentTab: TTabItem;
    FTransitionTab: TTabItem;
    FCurrentTabAnimation: TIntAnimation;
    FTransitionTabAnimation: TIntAnimation;

    procedure AnimationFinished(Sender: TObject);
    procedure WebBrowserReallign(Sender: TObject);
  public
    procedure SetActiveTabWithTransitionEx(const ATab: TTabItem;
      const ADirection: TTabTransitionDirection = TTabTransitionDirection.tdNormal;
      AInterpolationType: TInterpolationType = TInterpolationType.itLinear; ADuration: Single = 0.2;
      AExitDistanceRatio: Single = 1; AAnimationType: TAnimationType = TAnimationType.atIn);
  end;

implementation

procedure TTabControlEx.AnimationFinished(Sender: TObject);
begin
  WebBrowserReallign(Sender);

  // Free the current tab animation
  if Sender = FCurrentTabAnimation then
  begin
    FCurrentTabAnimation.Release;
    FCurrentTabAnimation := nil;
  end else

  // Free the transition tab animation
  if Sender = FTransitionTabAnimation then
  begin
    FTransitionTabAnimation.Release;
    FTransitionTabAnimation := nil;
  end;

  // Have both animations finished?
  if (FCurrentTabAnimation = nil) and
     (FTransitionTabAnimation = nil) then
  begin
    // Make the tab contents visible again
    FCurrentTab.Content.Visible := TRUE;
    FTransitionTab.Content.Visible := TRUE;

    // Set the active tab
    ActiveTab := FTransitionTab;

    // Free the transition layout (and images)
    FTransistionLayout.DisposeOf;
    FTransistionLayout := nil;
  end;
end;

procedure TTabControlEx.WebBrowserReallign(Sender: TObject);
var
  BrowserManager : IFMXWBService;
begin

  if TPlatformServices.Current.SupportsPlatformService(IFMXWBService, IInterface(BrowserManager)) then
    BrowserManager.RealignBrowsers;
end;

procedure TTabControlEx.SetActiveTabWithTransitionEx(const ATab: TTabItem;
      const ADirection: TTabTransitionDirection; AInterpolationType: TInterpolationType; ADuration: Single;
      AExitDistanceRatio: Single; AAnimationType: TAnimationType);

  function CreateAnimation(AParent: TFmxObject; const APropertyName: string; const NewValue: Integer): TIntAnimation;
  begin
    // Create the animation
    Result := TIntAnimation.Create(AParent);

    // Set the animation properties
    Result.Parent := AParent;
    Result.AnimationType := AAnimationType;
    Result.Interpolation := AInterpolationType;
    Result.OnFinish := AnimationFinished;
    Result.OnProcess := WebBrowserReallign;
    Result.Duration := ADuration;
    Result.PropertyName := APropertyName;
    Result.StartFromCurrent := True;
    Result.StopValue := NewValue;
    Result.Start;
  end;

  function GetTabBitmap(Tab: TTabItem): TBitmap;
  var
    TempBitmap: TBitmap;
    BmpRect: TRectF;
    B: TFMXObject;
  begin
    // Paint the tab control to a bitmap
    TempBitmap := Tab.Content.MakeScreenshot;
    try
      // Create a new bitmap that we will use to overlay the
      // control image with the form background
      Result := TBitmap.Create;
      Result.Width := TempBitmap.Width;
      Result.Height := TempBitmap.Height;

      BmpRect := RectF(0, 0, TempBitmap.Width, TempBitmap.Height);

      Result.Canvas.BeginScene;
      try
        // Find the parent form
        if Root.GetObject is TCustomForm then
        begin
          // Find the background style
          B := TCustomForm(Root.GetObject).FindStyleResource('backgroundstyle');

          if (B <> nil) and
             (B is TRectangle) then
          begin
            // If we found a style, assign it to the canvas
            Result.Canvas.Fill.Assign((B as TRectangle).Fill);

            // Fill the backgrounf
            Result.Canvas.FillRect(BmpRect, 0, 0, [], 1);
          end;
        end;

        // Draw the control bitmap on the result bitmap
        Result.Canvas.DrawBitmap(TempBitmap, BmpRect, BmpRect, 1);
      finally
        Result.Canvas.EndScene;
      end;
    finally
      FreeAndNil(TempBitmap);
    end;
  end;

  function NewTabImage: TImage;
  begin
    Result := TImage.Create(FTransistionLayout);
    Result.WrapMode := TImageWrapMode.iwOriginal;
    Result.Parent := FTransistionLayout;
  end;

var
  CurrentTabImage, TransitionTabImage: TImage;
  LayoutRect: TRectF;
  LayoutPos: TPointF;
  XPosOffset: Integer;
begin
  if FTransistionLayout = nil then
  begin
    // Calculate the position of the images
    LayoutPos := ActiveTab.Content.LocalToAbsolute(PointF(0, 0));
    LayoutRect := ActiveTab.Content.BoundsRect;

    // Create a parent layout control so that the transition images
    // are clipped correctly.
    FTransistionLayout := TLayout.Create(Root.GetObject);
    FTransistionLayout.Parent := Root.GetObject;
    FTransistionLayout.ClipChildren := TRUE;
    FTransistionLayout.SetBounds(LayoutPos.X, LayoutPos.Y, LayoutRect.Width, LayoutRect.Height);

    // Create the images that will contain the tab views
    CurrentTabImage := NewTabImage;
    TransitionTabImage := NewTabImage;

    // Set the X position offset
    XPosOffset := Round(LayoutRect.Width);

    // Negate the offset if we are moving the tabs to the right
    if ADirection = TTabTransitionDirection.tdReversed then
      XPosOffset := -XPosOffset;

    // Set the image position.
    CurrentTabImage.SetBounds(LayoutPos.X, LayoutPos.Y, LayoutRect.Width, LayoutRect.Height);
    TransitionTabImage.SetBounds(LayoutPos.X + XPosOffset, LayoutPos.Y, LayoutRect.Width, LayoutRect.Height);

    { TODO : Why is the image half the size it should be on mobile platforms? }
    {$IFNDEF WIN32}
      CurrentTabImage.Scale.X := 2;
      CurrentTabImage.Scale.Y := 2;
      TransitionTabImage.Scale.X := 2;
      TransitionTabImage.Scale.Y := 2;
    {$ENDIF}

    // Generate the image of the active tab
    FCurrentTab := ActiveTab;
    CurrentTabImage.Bitmap := GetTabBitmap(FCurrentTab);
    CurrentTabImage.Visible := TRUE;

    // Set the active tab to the transisiton tab. If we don't do this the
    // screenshot will be blank.
    FTransitionTab := ATab;
    ActiveTab := FTransitionTab;

    // Force the active tab to be repainted
    { TODO : Is there an alternative to "ProcessMessages"?
      None of the following commands work!! http://qc.embarcadero.com/wc/qcmain.aspx?d=119083
        ActiveTab.InvalidateRect(LayoutRect);
        InvalidateRect(LayoutRect);
        Repaint; }
    Application.ProcessMessages;

    // Generate the bitmap of the transition tab
    TransitionTabImage.Bitmap := GetTabBitmap(FTransitionTab);

    // Switch the active tab back to the original active tab
    ActiveTab := FCurrentTab;

    // Hide the contents of the tabs
    FCurrentTab.Content.Visible := FALSE;
    FTransitionTab.Content.Visible := FALSE;

    // Create the current tab image animation
    FCurrentTabAnimation := CreateAnimation(CurrentTabImage, 'Position.X', Round(LayoutPos.X - (XPosOffset * AExitDistanceRatio)));

    // Create the transition tab image animation
    FTransitionTabAnimation := CreateAnimation(TransitionTabImage, 'Position.X', Round(LayoutPos.X));
  end;
end;

{ TTabItemHelper }

function TTabItemHelper.GetContent: TContent;
begin
  Result := Self.FContent;
end;

end.
