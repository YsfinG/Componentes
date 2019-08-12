unit HSLColor;

interface

uses
   Graphics, Windows, Math,
   {$IFDEF VER150}pngimage{$ELSE}Vcl.Imaging.pngimage{$ENDIF};

type
   THSL = record
      Hue: Integer;
      Saturation: Integer;  //fade a color to gray
      Lightness: Integer;   //make a color darker
   end;

function GrayScale(Color: TColor): TColor; overload;
procedure GrayScale(Image: Graphics.TBitmap); overload;
procedure GrayScale({$IFDEF VER150}Image: TPNGObject;{$ELSE}Image: TPngImage;{$ENDIF} Amount: Byte = 255); overload;
function ColorToHSLDegree(Color: TColor): THSL;
function ColorToHSLWindow(Color: TColor): THSL;
function HSLDegreeToColor(HSL: THSL): TColor;
function HSLWindowToColor(HSL: THSL): TColor;

implementation
// Returns the HSL (0..1) value of an RGB (0..255) color

function GrayScale(Color: TColor): TColor;
var
  Gray : byte;
begin
  Gray := Round((0.30 * GetRValue(Color)) +
                (0.59 * GetGValue(Color)) +
                (0.11 * GetBValue(Color )));
  Result := RGB(Gray, Gray, Gray);
end;

procedure GrayScale(Image: Graphics.TBitmap);
var
   I, J: Integer;
begin
   for I := 0 to Pred(Image.Height) do
      for J := 0 to Pred(Image.Width) do
         Image.Canvas.Pixels[I,J] := GrayScale(Image.Canvas.Pixels[I,J]);
end;

procedure GrayScale(
   {$IFDEF VER150}
   Image: TPNGObject;
   {$ELSE}
   Image: TPngImage;
   {$ENDIF}
   Amount: Byte = 255);

   procedure GrayscaleRGB(var R, G, B: Byte);
  { Performance optimized version without floating point operations by Christian Budde }
   var
      X: Byte;
   begin
      X := (R * 77 + G * 150 + B * 29) shr 8;
      R := ((R * (255 - Amount)) + (X * Amount) + 128) shr 8;
      G := ((G * (255 - Amount)) + (X * Amount) + 128) shr 8;
      B := ((B * (255 - Amount)) + (X * Amount) + 128) shr 8;
    (* original code
    X := Round(R * 0.30 + G * 0.59 + B * 0.11);
    R := Round(R / 256 * (256 - Amount - 1)) + Round(X / 256 * (Amount + 1));
    G := Round(G / 256 * (256 - Amount - 1)) + Round(X / 256 * (Amount + 1));
    B := Round(B / 256 * (256 - Amount - 1)) + Round(X / 256 * (Amount + 1));
    *)
   end;

var
   X, Y, PalCount: Integer;
   Line: PRGBLine;
   PaletteHandle: HPalette;
   Palette: array[Byte] of TPaletteEntry;
begin
  //Don't do anything if the image is already a grayscaled one
   if not (Image.Header.ColorType in [COLOR_GRAYSCALE, COLOR_GRAYSCALEALPHA]) then
   begin
      if Image.Header.ColorType = COLOR_PALETTE then
      begin
      //Grayscale every palette entry
         PaletteHandle := Image.Palette;
         PalCount := GetPaletteEntries(PaletteHandle, 0, 256, Palette);
         for X := 0 to PalCount - 1 do
            GrayscaleRGB(Palette[X].peRed, Palette[X].peGreen, Palette[X].peBlue);
         SetPaletteEntries(PaletteHandle, 0, PalCount, Palette);
         Image.Palette := PaletteHandle;
      end
      else
      begin
      //Grayscale every pixel
         for Y := 0 to Image.Height - 1 do
         begin
            Line := Image.Scanline[Y];
            for X := 0 to Image.Width - 1 do
               GrayscaleRGB(Line[X].rgbtRed, Line[X].rgbtGreen, Line[X].rgbtBlue);
         end;
      end;
   end;
end;

procedure ColorToHSL(Color: TColor; var h, s, l: Real);
var
   r, g, b, delta, minValue, maxValue: Real;
begin
   r := GetRValue(ColorToRGB(Color)) / 255;
   g := GetGValue(ColorToRGB(Color)) / 255;
   b := GetBValue(ColorToRGB(Color)) / 255;
   minValue := Min(Min(r, g), b);
   maxValue := Max(Max(r, g), b);
  // Calculate luminosity
   l := (maxValue + minValue) / 2;
   if maxValue = minValue then   //it's gray
   begin
      h := 0;                     //it's actually undefined
      s := 0;
   end
   else
   begin
      delta := maxValue - minValue;
    // Calculate saturation
      if l < 0.5 then
         s := delta / (maxValue + minValue)
      else
         s := delta / (2 - maxValue - minValue);
    // Calculate hue
      if r = maxValue then
         h := (g - b) / delta
      else if g = maxValue then
         h := 2 + (b - r) / delta
      else
         h := 4 + (r - g) / delta;
      h := h / 6;
      if h < 0 then
         h := h + 1;
   end;
end;
// Returns the RGB (0..255) color of an HSL (0..1) value

function HSLToColor(h, s, l: Real): TColor;
var
   m1, m2: Real;

   function HueToColorValue(Hue: Real): Byte;
   var
      v: Real;
   begin
      if Hue < 0 then
         Hue := Hue + 1
      else if Hue > 1 then
         Hue := Hue - 1;
      if 6 * Hue < 1 then
         v := m1 + (m2 - m1) * Hue * 6
      else if 2 * Hue < 1 then
         v := m2
      else if 3 * Hue < 2 then
         v := m1 + (m2 - m1) * (2 / 3 - Hue) * 6
      else
         v := m1;
      Result := Round(255 * v);
   end;

var
   r, g, b: Byte;
begin
   if s = 0 then
   begin
      r := Round(255 * l);
      g := r;
      b := r;
   end
   else
   begin
      if l <= 0.5 then
         m2 := l * (1 + s)
      else
         m2 := l + s - l * s;
      m1 := 2 * l - m2;
      r := HueToColorValue(h + 1 / 3);
      g := HueToColorValue(h);
      b := HueToColorValue(h - 1 / 3);
   end;
   Result := RGB(r, g, b);
end;
// Returns the HSL value of an RGB color (0..255)
//   H = 0 to 239 (corresponding to windows color dialog)
//   S = 0 (shade of gray) to 240 (pure color)
//   L = 0 (black) to 240 (white)

function ColorToHSLWindow(Color: TColor): THSL;
var
   h, s, l: Real;
begin
   ColorToHSL(Color, h, s, l);
   Result.Hue := Round(h * 240);
   Result.Saturation := Round(s * 240);
   Result.Lightness := Round(l * 240);
   if Result.Hue = 240 then
      Result.Hue := 0;
end;
// Returns the HSL value (in degrees) of an RGB color (0..255)
//   H = 0 to 360 (corresponding to 0..360 degrees around the hexcone)
//   S = 0% (shade of gray) to 100% (pure color)
//   L = 0% (black) to 100% (white)

function ColorToHSLDegree(Color: TColor): THSL;
var
   h, s, l: Real;
begin
   ColorToHSL(Color, h, s, l);
   Result.Hue := Round(h * 360);
   Result.Saturation := Round(s * 100);
   Result.Lightness := Round(l * 100);
end;
// Returns the RGB color of an HSL Windows value

function HSLWindowToColor(HSL: THSL): TColor;
var
   h, s, l: Real;
begin
   h := HSL.Hue / 240;
   s := HSL.Saturation / 240;
   l := HSL.Lightness / 240;
   Result := HSLToColor(h, s, l);
end;
// Returns the RGB color of an HSL degrees value

function HSLDegreeToColor(HSL: THSL): TColor;
var
   h, s, l: Real;
begin
   h := HSL.Hue / 360;
   s := HSL.Saturation / 100;
   l := HSL.Lightness / 100;
   Result := HSLToColor(h, s, l);
end;

end.
