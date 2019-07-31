unit ColorBtn;

interface

uses
   Windows, Messages, SysUtils, Classes, Graphics, Controls, Forms, Dialogs,
   StdCtrls, Buttons;

type
   TColorBtn = class(TBitBtn)
   private
      FOldColor: TColor;
   private
      IsFocused: boolean;
      FCanvas: TCanvas;
      FColor: TColor;
      FRound: Integer;
      FDisableColor: TColor;
      FHoverColor: TColor;
      FParentColor: Boolean;
      procedure SetColor(Value: TColor);
      procedure CNDrawItem(var Message: TWMDrawItem); message CN_DRAWITEM;
      procedure WMLButtonDblClk(var Message: TWMLButtonDblClk); message WM_LBUTTONDBLCLK;
      procedure DrawButtonText(const Caption: string; TRC: TRect; IsDisable: Boolean; BiDiFlags: Longint);
      procedure CalcuateTextPosition(const Caption: string; var TRC: TRect; BiDiFlags: Longint; IsDisable: Boolean);
      procedure SetRound(const Value: Integer);
      procedure SetDisableColor(const Value: TColor);
      procedure SetHoverColor(const Value: TColor);
      procedure SetParentColor(const Value: Boolean);
      function GetIcon(IsDisable: Boolean): TBitmap;
   protected
      procedure CreateParams(var Params: TCreateParams); override;
      procedure WndProc(var Message: TMessage); override;
      procedure SetButtonStyle(ADefault: boolean); override;
      procedure DrawButton(Rect: TRect; State: UINT);
   public
      constructor Create(AOwner: TComponent); override;
      destructor Destroy; override;
   published
      property Color: TColor read FColor write SetColor default clBtnFace;
      property Round: Integer read FRound write SetRound default 0;
      property DisableColor: TColor read FDisableColor write SetDisableColor default clBtnShadow;
      property HoverColor: TColor read FHoverColor write SetHoverColor default clBtnHighlight;
      property ParentColor: Boolean read FParentColor write SetParentColor default True;
   end;

procedure Register;

implementation

{ TColorBtn }

constructor TColorBtn.Create(AOwner: TComponent);
begin
   inherited Create(AOwner);
   FCanvas := TCanvas.Create;
   FColor := clBtnFace;
   FDisableColor := clBtnShadow;
   FParentColor := True;
   FHoverColor := clBtnHighlight;
end;

destructor TColorBtn.Destroy;
begin
   FCanvas.Free;
   inherited Destroy;
end;

procedure TColorBtn.CreateParams(var Params: TCreateParams);
begin
   inherited CreateParams(Params);
   with Params do
      Style := Style or BS_OWNERDRAW;
end;

procedure TColorBtn.SetColor(Value: TColor);
begin
   if FColor <> Value then
   begin
      FColor := Value;
      FParentColor := False;
      Invalidate;
   end;
end;

procedure TColorBtn.WMLButtonDblClk(var Message: TWMLButtonDblClk);
begin
   Perform(WM_LBUTTONDOWN, Message.Keys, Longint(Message.Pos));
end;

procedure TColorBtn.SetButtonStyle(ADefault: Boolean);
begin
   if IsFocused <> ADefault then
      IsFocused := ADefault;
end;

procedure TColorBtn.SetRound(const Value: Integer);
var
   rgn: hrgn;
begin
   FRound := Value;
   rgn := CreateRoundRectRgn(0, 0, Width, Height, FRound, FRound);
   SetWindowRgn(Handle, rgn, True);
end;

procedure TColorBtn.CNDrawItem(var Message: TWMDrawItem);
var
   RC: TRect;
   Flags: Longint;
   State: TButtonState;
   IsDown, IsDefault: Boolean;
   DrawItemStruct: TDrawItemStruct;
   SaveIndex: Integer;
begin
   with Message.DrawItemStruct^ do
   begin
      SaveIndex := SaveDC(hDC);
      FCanvas.Lock;
      try
         FCanvas.Handle := hDC;
         FCanvas.Font := Font;
         FCanvas.Brush := Brush;
         DrawButton(rcItem, itemState);
      finally
         FCanvas.Handle := 0;
         FCanvas.Unlock;
         RestoreDC(hDC, SaveIndex);
      end;
   end;

   Message.Result := 1;
end;

procedure TColorBtn.CalcuateTextPosition(const Caption: string; var TRC: TRect;
   BiDiFlags: Integer; IsDisable: Boolean);
var
   TB: TRect;
   xGlyph: TBitmap;
   xLeft, xRight, xTop, xBottom: Integer;
begin
   with FCanvas do
   begin
      TB := Rect(0, 0, TRC.Right + TRC.Left, TRC.Top + TRC.Bottom);
      DrawText(Handle, PChar(Caption), Length(Caption), TB, DT_CALCRECT or BiDiFlags);

      xLeft := 0;
      xRight := 0;
      xTop := 0;
      xBottom := 0;

      xGlyph := GetIcon(IsDisable);

      if (xGlyph.Width > 0) or
         (xGlyph.Height > 0) then
      begin
         xGlyph.Transparent := True;

         case Layout of
            blGlyphLeft:
               begin
                  xLeft := xGlyph.Width + TB.Right + 3;
                  xTop  := ((TRC.Bottom - TRC.Top) - xGlyph.Height) div 2;

                  if Margin = -1 then
                     xLeft := ((TRC.Right - TRC.Left) - xLeft) div 2
                  else
                     xLeft := Margin + 3;

                  FCanvas.Draw(xLeft, xTop, xGlyph);
                  xLeft := xLeft + 4 + xGlyph.Width;
                  xTop  := ((TRC.Bottom - TRC.Top) - TB.Bottom) div 2;
               end;
            blGlyphRight:
               begin
                  xRight  := xGlyph.Width + TB.Right + 3;
                  xBottom := ((TRC.Bottom - TRC.Top) - xGlyph.Height) div 2;

                  if Margin = -1 then
                  begin
                     xRight := ((TRC.Right - TRC.Left) - xRight) div 2;
                     xRight := TRC.Right - (xRight + xGlyph.Width);
                  end
                  else
                     xRight := TRC.Right - (Margin + xGlyph.Width);

                  FCanvas.Draw(xRight, xBottom, xGlyph);
                  xRight  := xRight - 4 - TB.Right;
                  xBottom := ((TRC.Bottom - TRC.Top) - TB.Bottom) div 2;
               end;
            blGlyphTop:
               begin
                  xTop := xGlyph.Height + TB.Bottom + 3;

                  if Margin = -1 then
                     xTop := ((TRC.Bottom - TRC.Top) - xTop) div 2
                  else
                     xTop := Margin + 3;

                  xLeft := ((TRC.Right - TRC.Left) - xGlyph.Width) div 2;

                  FCanvas.Draw(xLeft, xTop, xGlyph);
                  xTop := xTop + 4 + xGlyph.Height;
                  xLeft := ((TRC.Right - TRC.Left) - TB.Right) div 2;
               end;
            blGlyphBottom:
               begin
                  xBottom := xGlyph.Height + TB.Bottom + 3;

                  if Margin = -1 then
                  begin
                     xBottom := ((TRC.Bottom - TRC.Top) - xBottom) div 2;
                     xBottom := TRC.Bottom - (xBottom + xGlyph.Height);
                  end
                  else
                     xBottom := TRC.Bottom - (Margin + xGlyph.Height);

                  xRight := ((TRC.Right - TRC.Left) - xGlyph.Width) div 2;

                  FCanvas.Draw(xRight, xBottom, xGlyph);
                  xBottom := xBottom - 4 - TB.Bottom;
                  xRight := ((TRC.Right - TRC.Left) - TB.Right) div 2;
               end;
         end;
      end
      else
      begin
         xLeft := ((TRC.Right - TRC.Left) - TB.Right) div 2;
         xTop  := ((TRC.Bottom - TRC.Top) - TB.Bottom) div 2;
      end;

      OffsetRect(TB, xLeft + xRight + 1, xTop + xBottom);
      TRC := TB;
   end;
end;

procedure TColorBtn.DrawButtonText(const Caption: string; TRC: TRect; IsDisable: Boolean; BiDiFlags: Integer);
begin
   with FCanvas do
   begin
      CalcuateTextPosition(Caption, TRC, BiDiFlags, IsDisable);
      Brush.Style := bsClear;

      if IsDisable then
         Font.Color := FDisableColor;

      DrawText(Handle, PChar(Caption), Length(Caption), TRC, DT_CENTER or DT_VCENTER or BiDiFlags);
   end;
end;

function TColorBtn.GetIcon(IsDisable: Boolean): TBitmap;
var
   xRect,
   xCutRect: TRect;
begin
   Result := TBitmap.Create;
   Result.Height := Glyph.Height;
   Result.Width  := Trunc(Glyph.Width / NumGlyphs);

   if IsDisable then
      xRect := Bounds(Result.Width, 0, Result.Width, Result.Height)
   else
      xRect := Bounds(0, 0, Result.Width, Result.Height);

   xCutRect := Bounds(0, 0, Result.Width, Result.Height);
   Result.Canvas.CopyRect(xCutRect, Glyph.Canvas, xRect);
end;

procedure Register;
begin
   RegisterComponents('Samples', [TColorBtn]);
end;

procedure TColorBtn.WndProc(var Message: TMessage);
begin
   if (Message.Msg = CM_MOUSELEAVE) then
   begin
      FColor := FOldColor;
      invalidate;
   end;
   if (Message.Msg = CM_MOUSEENTER) then
   begin
      FOldColor := FColor;
      FColor := FHoverColor;
      invalidate;
   end;

   inherited;
end;

procedure TColorBtn.SetDisableColor(const Value: TColor);
begin
   if FDisableColor <> Value then
   begin
      FDisableColor := Value;
      Invalidate;
   end;
end;

procedure TColorBtn.SetHoverColor(const Value: TColor);
begin
   if FHoverColor <> Value then
   begin
      FHoverColor := Value;
      Invalidate;
   end;
end;

procedure TColorBtn.SetParentColor(const Value: Boolean);
begin
   if FParentColor <> Value then
   begin
      FParentColor := Value;

      if FParentColor and (Parent <> Nil) then
         FColor := Parent.Brush.Color;

      Invalidate;
   end;
end;

procedure TColorBtn.DrawButton(Rect: TRect; State: UINT);
var
   Flags, OldMode: Longint;
   IsDown, IsDefault, IsDisabled: Boolean;
   OldColor: TColor;
   OrgRect: TRect;
begin
   OrgRect := Rect;
   Flags := DFCS_BUTTONPUSH or DFCS_ADJUSTRECT;
   IsDown := State and ODS_SELECTED <> 0;
   IsDisabled := State and ODS_DISABLED <> 0;
   IsDefault := State and ODS_FOCUS <> 0;

   if IsDown then
      Flags := Flags or DFCS_PUSHED;
   if IsDisabled then
      Flags := Flags or DFCS_INACTIVE;

   if IsDown then
   begin
      FCanvas.Pen.Color := clBtnShadow;
      FCanvas.Pen.Width := 1;
      FCanvas.Brush.Color := clBtnFace;
      FCanvas.Rectangle(Rect.Left, Rect.Top, Rect.Right, Rect.Bottom);
      InflateRect(Rect, -1, -1);
   end;

   if IsDown then
      OffsetRect(Rect, 1, 1);

   OldColor := FCanvas.Brush.Color;

   if IsDisabled then
   begin
      FCanvas.Brush.Color := Parent.Brush.Color;
      FCanvas.Pen.Color := FDisableColor;
   end
   else
   begin
      if FParentColor and (FColor <> FHoverColor) then
      begin
         FCanvas.Brush.Color := Parent.Brush.Color;
         FCanvas.Pen.Color := Parent.Brush.Color;
      end
      else
      begin
         FCanvas.Brush.Color := FColor;
         FCanvas.Pen.Color := FColor;
      end;
   end;

   FCanvas.FillRect(Rect);
   FCanvas.Brush.Color := OldColor;
   OldMode := SetBkMode(FCanvas.Handle, TRANSPARENT);

   FCanvas.Font := Self.Font;

   DrawButtonText(Caption, OrgRect, IsDisabled, 0);

   SetBkMode(FCanvas.Handle, OldMode);

   if (IsFocused and IsDefault) then
   begin
      Rect := OrgRect;
      InflateRect(Rect, -1, -1);
      FCanvas.Pen.Color := clWindowFrame;
      FCanvas.Brush.Style := bsClear;
      FCanvas.RoundRect(Rect.Left, Rect.Top, Rect.Right, Rect.Bottom, FRound, FRound);
      InflateRect(Rect, 0, 0);
   end
   else if IsDisabled then
   begin
      Rect := OrgRect;
      InflateRect(Rect, -1, -1);
      FCanvas.Pen.Color := clSilver;
      FCanvas.Brush.Style := bsClear;
      FCanvas.RoundRect(Rect.Left, Rect.Top, Rect.Right, Rect.Bottom, FRound, FRound);
      InflateRect(Rect, 0, 0);
   end;
end;

end.
