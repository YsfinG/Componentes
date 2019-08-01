unit HSLColor;

interface

uses
   Graphics, Windows, Math;

type
   THSL = record
      Hue: Integer;
      Saturation: Integer;  //fade a color to gray
      Lightness: Integer;   //make a color darker
   end;

function ColorToHSLDegree(Color: TColor): THSL;
function ColorToHSLWindow(Color: TColor): THSL;
function HSLDegreeToColor(HSL: THSL): TColor;
function HSLWindowToColor(HSL: THSL): TColor;

implementation
// Returns the HSL (0..1) value of an RGB (0..255) color

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
