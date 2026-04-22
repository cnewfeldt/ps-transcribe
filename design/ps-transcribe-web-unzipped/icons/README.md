# PS Transcribe — App Icon assets

Everything you need to ship a macOS app icon, generated from **Concept 14
(Bot on Laptop)**. All PNGs use the paper / navy editorial palette from
`tokens.css`.

## What's here

| Path | What it is |
|---|---|
| `AppIcon.appiconset/` | **Xcode asset catalog.** Drop inside `Assets.xcassets/`. |
| `iconset-preview/` | The 10 PNG sizes under "safe" filenames (no `@`). Used to build the iconset below. |
| `AppIcon-1024.png` → `AppIcon-64.png` | Marketing exports (App Store, web, README). |
| `favicon-16.png`, `favicon-32.png` | For the website. |
| `preview.html` | Side-by-side view of every size. |

## Using the Xcode asset catalog (easiest)

1. Open your Xcode project.
2. Drag `AppIcon.appiconset` into `Assets.xcassets`.
3. In the target's **General → App Icons and Launch Images**, set
   **App Icon Source** = `AppIcon`.
4. Build.

## Building a standalone `.icns` (command line)

If you want a raw `.icns` file (e.g. for an Electron / Tauri app, or a
hand-rolled `.app` bundle):

```bash
# 1. Duplicate iconset-preview with the filenames macOS's iconutil expects
mkdir -p AppIcon.iconset
cp iconset-preview/icon_16.png      AppIcon.iconset/icon_16x16.png
cp iconset-preview/icon_16_2x.png   AppIcon.iconset/icon_16x16@2x.png
cp iconset-preview/icon_32.png      AppIcon.iconset/icon_32x32.png
cp iconset-preview/icon_32_2x.png   AppIcon.iconset/icon_32x32@2x.png
cp iconset-preview/icon_128.png     AppIcon.iconset/icon_128x128.png
cp iconset-preview/icon_128_2x.png  AppIcon.iconset/icon_128x128@2x.png
cp iconset-preview/icon_256.png     AppIcon.iconset/icon_256x256.png
cp iconset-preview/icon_256_2x.png  AppIcon.iconset/icon_256x256@2x.png
cp iconset-preview/icon_512.png     AppIcon.iconset/icon_512x512.png
cp iconset-preview/icon_512_2x.png  AppIcon.iconset/icon_512x512@2x.png

# 2. Compile
iconutil -c icns AppIcon.iconset
# → AppIcon.icns
```

Drop `AppIcon.icns` into `YourApp.app/Contents/Resources/` and add to
`Info.plist`:

```xml
<key>CFBundleIconFile</key>
<string>AppIcon</string>
```

## Web / favicon

In the `<head>` of your site:

```html
<link rel="icon" type="image/png" sizes="32x32" href="/icons/favicon-32.png">
<link rel="icon" type="image/png" sizes="16x16" href="/icons/favicon-16.png">
<link rel="apple-touch-icon" sizes="180x180" href="/icons/AppIcon-256.png">
```
