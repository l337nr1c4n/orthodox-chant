# App Icon Specification

Two PNG files are required here. Once they exist, run:

```
flutter pub run flutter_launcher_icons
```

## app_icon.png (full icon with background)
- Size: 1024×1024 px
- Background: `#1A1A1A` (solid fill)
- Foreground: Orthodox 3-bar Byzantine cross (centered-left) + quarter note (bottom-right), both in gold `#CFB53B`
- Cross: ~320px tall, ~10px stroke weight
- Quarter note: ~160px, same gold
- Subtle outer glow on cross: gold at 30% opacity, ~20px spread
- No text, no rounded corners (the OS applies them)

## app_icon_foreground.png (adaptive icon layer)
- Size: 1024×1024 px
- Background: transparent
- Same artwork as above, scaled to fit within the inner 768×768 safe zone (centered in canvas)
- Used on Android 8+ adaptive icons; the background color is set to `#1A1A1A` in pubspec.yaml

## Tools
Canva, Figma, or Inkscape all work. Export as PNG (not JPEG).
