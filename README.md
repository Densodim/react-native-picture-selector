# react-native-picture-selector

High-performance photo and video picker for React Native, built on **Nitro Modules** (JSI, zero bridge overhead).

| Platform | Native library | Min OS |
|----------|---------------|--------|
| Android  | LuckSiege/PictureSelector v3.11.2 | Android 7.0 (API 24) |
| iOS      | SilenceLove/HXPhotoPicker v5.0.5  | iOS 13.0 |

---

## Features

- **Photos and videos** — single or multi-selection, mixed media
- **Camera capture** — photo and video directly from the picker
- **Cropping** — fixed ratio, free-style, circular (iOS)
- **Compression** — JPEG quality + max dimensions
- **Video duration limits** — min / max in seconds
- **Pre-selected assets** — restore a previous selection (Android only)
- **Themes** — WeChat / White / Dark (Android), hex accent color (iOS)
- **Strict TypeScript** — fully typed API and result objects
- **Promise-based** — async/await friendly, cancel → rejection
- **React hook** — `usePictureSelector` manages loading / error state

---

## Installation

```sh
npm install react-native-picture-selector react-native-nitro-modules
# or
yarn add react-native-picture-selector react-native-nitro-modules
```

### iOS — CocoaPods

```sh
cd ios && pod install
```

Add required keys to **`ios/YourApp/Info.plist`**:

```xml
<key>NSPhotoLibraryUsageDescription</key>
<string>Used to select photos and videos</string>

<key>NSPhotoLibraryAddUsageDescription</key>
<string>Used to save photos to your library</string>

<key>NSCameraUsageDescription</key>
<string>Used to capture photos and videos</string>

<key>NSMicrophoneUsageDescription</key>
<string>Used to record video with audio</string>
```

### Android — Gradle

Permissions are declared in the library manifest and merged automatically. If you target **Android 13+ (API 33)** and also support older versions you need no extra steps — the manifest already uses `maxSdkVersion` to apply the right permission per API level.

For apps that don't use autolinking, register the package manually:

```kotlin
// android/app/src/main/java/.../MainApplication.kt
override fun getPackages() =
  PackageList(this).packages + NitroPictureSelectorPackage()
```

---

## Quick start

```tsx
import { PictureSelector, MediaType } from 'react-native-picture-selector'

const assets = await PictureSelector.openPicker({
  mediaType: MediaType.IMAGE,
  maxCount: 1,
})

console.log(assets[0].uri)      // file:///data/user/0/.../image.jpg
console.log(assets[0].width)    // 4032
console.log(assets[0].fileSize) // 2457600
```

---

## API Reference

### `PictureSelector.openPicker(options?)`

Opens the native gallery picker. Returns `Promise<MediaAsset[]>`.

The promise rejects with `PickerError` when the user dismisses the picker without making a selection.

```ts
import { PictureSelector, MediaType, toPickerError } from 'react-native-picture-selector'

// Basic usage
const assets = await PictureSelector.openPicker()

// With options
const assets = await PictureSelector.openPicker({
  mediaType: MediaType.ALL,
  maxCount: 9,
  compress: { enabled: true, quality: 0.7 },
})

// Handle cancel
try {
  const assets = await PictureSelector.openPicker()
} catch (err) {
  const e = toPickerError(err)
  if (e.code === 'CANCELLED') {
    // user tapped back — not an error
  }
}
```

---

### `PictureSelector.openCamera(options?)`

Opens the device camera. Returns `Promise<MediaAsset[]>` (always one item).

```ts
// Take a photo
const [photo] = await PictureSelector.openCamera({
  mediaType: MediaType.IMAGE,
})

// Record a short video
const [video] = await PictureSelector.openCamera({
  mediaType: MediaType.VIDEO,
  maxVideoDuration: 30,
})

// Take a photo and crop it immediately
const [photo] = await PictureSelector.openCamera({
  mediaType: MediaType.IMAGE,
  crop: { enabled: true, ratioX: 1, ratioY: 1 },
})
```

---

### `usePictureSelector(defaultOptions?)`

React hook that wraps the picker with loading, error, and asset state.

```tsx
import { usePictureSelector, MediaType } from 'react-native-picture-selector'

function PhotoPicker() {
  const { assets, loading, error, pick, shoot, clear } = usePictureSelector({
    mediaType: MediaType.IMAGE,
    maxCount: 9,
  })

  return (
    <>
      <Button onPress={() => pick()} title="Gallery" disabled={loading} />
      <Button onPress={() => shoot()} title="Camera"  disabled={loading} />
      <Button onPress={clear}         title="Clear" />

      {error && <Text style={{ color: 'red' }}>Error: {error.message}</Text>}

      {assets.map((a, i) => (
        <Image key={i} source={{ uri: a.uri }} style={{ width: 80, height: 80 }} />
      ))}
    </>
  )
}
```

You can also override options per call:

```ts
// use hook defaults
await pick()

// override for this call only
await pick({ maxCount: 1, crop: { enabled: true, ratioX: 16, ratioY: 9 } })
await shoot({ mediaType: MediaType.VIDEO, maxVideoDuration: 15 })
```

#### Hook state

| Property | Type | Description |
|----------|------|-------------|
| `assets` | `MediaAsset[]` | Currently selected assets |
| `loading` | `boolean` | `true` while the picker is open |
| `error` | `PickerError \| null` | Last non-cancel error, `null` otherwise |

#### Hook actions

| Method | Signature | Description |
|--------|-----------|-------------|
| `pick` | `(options?) => Promise<MediaAsset[]>` | Open gallery picker |
| `shoot` | `(options?) => Promise<MediaAsset[]>` | Open camera |
| `clear` | `() => void` | Reset `assets` and `error` to initial state |

> **Cancellation** — `CANCELLED` errors are silently swallowed by the hook. `pick()` and `shoot()` return `[]` on cancel instead of throwing.

---

## Configuration (`PictureSelectorOptions`)

All fields are optional. Omitting an option uses the native library default.

---

### Media type

| Field | Type | Default | Description |
|-------|------|---------|-------------|
| `mediaType` | `MediaType` | `IMAGE` | `IMAGE`, `VIDEO`, or `ALL` |
| `maxCount` | `number` | `1` | Maximum selectable items (gallery picker only) |
| `enableCamera` | `boolean` | `true` | Show camera shortcut inside gallery grid |

```ts
import { MediaType } from 'react-native-picture-selector'

// Images only, single selection
openPicker({ mediaType: MediaType.IMAGE })

// Videos only, up to 3
openPicker({ mediaType: MediaType.VIDEO, maxCount: 3 })

// Mixed photo + video, up to 9
openPicker({ mediaType: MediaType.ALL, maxCount: 9 })

// Gallery without in-picker camera button
openPicker({ enableCamera: false })
```

---

### Cropping (`crop`)

Crop is applied automatically **after** the user selects a photo. It activates only when `maxCount === 1`.

| Field | Type | Default | Description |
|-------|------|---------|-------------|
| `crop.enabled` | `boolean` | `false` | Enable the crop editor |
| `crop.ratioX` | `number` | `1` | Crop width part of the ratio |
| `crop.ratioY` | `number` | `1` | Crop height part of the ratio |
| `crop.freeStyle` | `boolean` | `false` | Let the user freely resize the crop frame |
| `crop.circular` | `boolean` | `false` | Circular crop mask **(iOS only)** |

```ts
// Square crop (avatar)
openPicker({ crop: { enabled: true, ratioX: 1, ratioY: 1 } })

// Widescreen banner 16:9
openPicker({ crop: { enabled: true, ratioX: 16, ratioY: 9 } })

// Portrait 3:4
openPicker({ crop: { enabled: true, ratioX: 3, ratioY: 4 } })

// Free-form — user defines any size
openPicker({ crop: { enabled: true, freeStyle: true } })

// Circular (iOS only — falls back to 1:1 on Android)
openPicker({ crop: { enabled: true, circular: true } })
```

> **Android** uses the uCrop library for cropping.
> **iOS** uses the built-in HXPhotoPicker photo editor.

The cropped file path is available at `asset.editedUri`. The original (un-cropped) file is at `asset.uri`.

---

### Compression (`compress`)

Compression runs **after** crop (if enabled). The original file is never modified — a new compressed copy is returned.

| Field | Type | Default | Description |
|-------|------|---------|-------------|
| `compress.enabled` | `boolean` | `false` | Enable compression |
| `compress.quality` | `number` | `0.8` | JPEG quality `0.0` (smallest) – `1.0` (lossless) |
| `compress.maxWidth` | `number` | `1920` | Max output width in pixels (aspect preserved) |
| `compress.maxHeight` | `number` | `1920` | Max output height in pixels (aspect preserved) |

```ts
// Light compression for fast upload
openPicker({
  compress: { enabled: true, quality: 0.8, maxWidth: 1920, maxHeight: 1920 },
})

// Heavy compression for thumbnails
openPicker({
  compress: { enabled: true, quality: 0.5, maxWidth: 640, maxHeight: 640 },
})

// Compress but keep original dimensions
openPicker({
  compress: { enabled: true, quality: 0.7 },
})
```

> **Android** uses the Luban library. Files under 100 KB are passed through without compression.
> **iOS** uses HXPhotoPicker's native compression pipeline.

---

### Video limits

| Field | Type | Unit | Description |
|-------|------|------|-------------|
| `maxVideoDuration` | `number` | seconds | Reject (hide) videos longer than this |
| `minVideoDuration` | `number` | seconds | Reject (hide) videos shorter than this |

```ts
// Only show videos between 3 and 60 seconds
openPicker({
  mediaType: MediaType.VIDEO,
  minVideoDuration: 3,
  maxVideoDuration: 60,
})

// Camera: stop recording automatically at 15 s
openCamera({
  mediaType: MediaType.VIDEO,
  maxVideoDuration: 15,
})
```

---

### Themes

| Field | Type | Description |
|-------|------|-------------|
| `theme` | `PickerTheme` | Preset theme for the picker UI (Android only) |
| `themeColor` | `string` | Hex accent color, e.g. `"#007AFF"` (both platforms) |

```ts
import { PickerTheme } from 'react-native-picture-selector'

// Android — WeChat-style dark green theme
openPicker({ theme: PickerTheme.WECHAT })

// Android — clean white theme
openPicker({ theme: PickerTheme.WHITE })

// Android — dark / night theme
openPicker({ theme: PickerTheme.DARK })

// Both platforms — custom accent colour
openPicker({ themeColor: '#1DB954' })  // Spotify green
openPicker({ themeColor: '#007AFF' })  // iOS blue
openPicker({ themeColor: '#E91E63' })  // Pink
```

> `theme` enum values (`WECHAT`, `WHITE`, `DARK`) are ignored on iOS. Use `themeColor` for cross-platform tinting.

---

### Pre-selected assets

> **iOS limitation**: `selectedAssets` is not yet implemented on iOS. The option is accepted but has no effect. See Android usage below.

Pass `file://` URIs of previously selected files to pre-check them in the gallery grid.

```ts
// Store selection
const [selectedAssets, setSelectedAssets] = useState<MediaAsset[]>([])

// First open — nothing pre-selected
const assets = await PictureSelector.openPicker({ maxCount: 9 })
setSelectedAssets(assets)

// Re-open — restore previous selection
const updated = await PictureSelector.openPicker({
  maxCount: 9,
  selectedAssets: selectedAssets.map((a) => a.uri),
})
setSelectedAssets(updated)
```

---

## Result (`MediaAsset`)

Every item in the returned array has this shape:

| Field | Type | Description |
|-------|------|-------------|
| `uri` | `string` | `file://` path of the final file (compressed / cropped if applicable) |
| `type` | `"image" \| "video"` | Media kind |
| `mimeType` | `string` | e.g. `"image/jpeg"`, `"video/mp4"` |
| `width` | `number` | Width in pixels |
| `height` | `number` | Height in pixels |
| `duration` | `number` | Duration in **milliseconds** (`0` for images) |
| `fileName` | `string` | File name with extension, e.g. `"photo.jpg"` |
| `fileSize` | `number` | Size in **bytes** |
| `editedUri?` | `string` | Path of the edited file after crop (if crop was applied) |
| `isOriginal?` | `boolean` | iOS only: `true` if the user tapped "Original" in the picker |
| `bucketName?` | `string` | Android only: album / folder name the file came from |

```ts
const [asset] = await PictureSelector.openPicker()

asset.uri       // "file:///data/user/0/com.myapp/cache/image.jpg"
asset.type      // "image"
asset.mimeType  // "image/jpeg"
asset.width     // 4032
asset.height    // 3024
asset.fileSize  // 2457600  (bytes ≈ 2.4 MB)
asset.duration  // 0        (image has no duration)
asset.fileName  // "IMG_20240101_120000.jpg"
asset.editedUri // "file:///...cropped.jpg" or undefined
```

Video example:

```ts
const [video] = await PictureSelector.openPicker({ mediaType: MediaType.VIDEO })

video.type      // "video"
video.mimeType  // "video/mp4"
video.duration  // 12500  (12.5 seconds in ms)
video.fileSize  // 8388608  (≈ 8 MB)
```

---

## Error handling

Wrap picker calls in try/catch and use `toPickerError` to normalise any error into a typed `PickerError`:

```ts
import { PictureSelector, toPickerError } from 'react-native-picture-selector'
import type { PickerError } from 'react-native-picture-selector'

async function pickPhoto() {
  try {
    const assets = await PictureSelector.openPicker()
    return assets
  } catch (err) {
    const e = toPickerError(err)

    switch (e.code) {
      case 'CANCELLED':
        // User dismissed — not an error, just return empty
        return []

      case 'PERMISSION_DENIED':
        // Show a settings prompt
        Alert.alert(
          'Permission required',
          'Please allow photo access in Settings.',
          [{ text: 'Open Settings', onPress: () => Linking.openSettings() }]
        )
        return []

      case 'UNKNOWN':
      default:
        console.error('[Picker]', e.message)
        return []
    }
  }
}
```

### Error codes

| Code | When |
|------|------|
| `CANCELLED` | User tapped Back or Cancel without selecting |
| `PERMISSION_DENIED` | Runtime permission was not granted |
| `UNKNOWN` | Any unexpected native error |

### `toPickerError(err)`

Normalises an unknown thrown value into a `PickerError` object:

```ts
interface PickerError {
  code: 'CANCELLED' | 'PERMISSION_DENIED' | 'UNKNOWN'
  message: string
}
```

---

## TypeScript enums

```ts
import { MediaType, PickerTheme } from 'react-native-picture-selector'

// MediaType
MediaType.IMAGE   // photos only
MediaType.VIDEO   // videos only
MediaType.ALL     // photos + videos

// PickerTheme (Android only)
PickerTheme.DEFAULT  // system default
PickerTheme.WECHAT   // WeChat green style
PickerTheme.WHITE    // light / white style
PickerTheme.DARK     // dark / night style
```

---

## Common recipes

### Avatar picker — square crop + resize

```ts
async function pickAvatar(): Promise<string | null> {
  try {
    const [asset] = await PictureSelector.openPicker({
      mediaType: MediaType.IMAGE,
      maxCount: 1,
      crop: { enabled: true, ratioX: 1, ratioY: 1 },
      compress: { enabled: true, quality: 0.85, maxWidth: 512, maxHeight: 512 },
    })
    return asset.uri
  } catch {
    return null
  }
}
```

### Multi-photo for a post

```ts
const photos = await PictureSelector.openPicker({
  mediaType: MediaType.IMAGE,
  maxCount: 9,
  compress: { enabled: true, quality: 0.7, maxWidth: 1920, maxHeight: 1920 },
})
// photos[0].uri … photos[8].uri
```

### Short video clip picker

```ts
const [clip] = await PictureSelector.openPicker({
  mediaType: MediaType.VIDEO,
  maxCount: 1,
  minVideoDuration: 1,
  maxVideoDuration: 30,
})

console.log(`${clip.duration / 1000}s, ${clip.fileSize} bytes`)
```

### Banner / cover image — 16:9 crop

```ts
const [banner] = await PictureSelector.openPicker({
  mediaType: MediaType.IMAGE,
  maxCount: 1,
  crop: { enabled: true, ratioX: 16, ratioY: 9 },
  compress: { enabled: true, quality: 0.8, maxWidth: 1280, maxHeight: 720 },
})
```

### Camera capture → instant upload

```ts
async function captureAndUpload() {
  const [photo] = await PictureSelector.openCamera({
    mediaType: MediaType.IMAGE,
    compress: { enabled: true, quality: 0.8, maxWidth: 1920, maxHeight: 1920 },
  })

  const form = new FormData()
  form.append('file', {
    uri:  photo.uri,
    type: photo.mimeType,
    name: photo.fileName,
  } as any)

  const res = await fetch('https://your-api.com/upload', {
    method: 'POST',
    body: form,
  })

  return res.json()
}
```

### Chat input — hook version

```tsx
import React from 'react'
import { View, Pressable, Text, Image, ScrollView } from 'react-native'
import { usePictureSelector, MediaType } from 'react-native-picture-selector'

function ChatInput({ onSend }: { onSend: (uris: string[]) => void }) {
  const { assets, loading, pick, clear } = usePictureSelector({
    mediaType: MediaType.ALL,
    maxCount: 9,
    compress: { enabled: true, quality: 0.7 },
  })

  const handleSend = () => {
    onSend(assets.map((a) => a.uri))
    clear()
  }

  return (
    <View>
      <Pressable onPress={() => pick()} disabled={loading}>
        <Text>{loading ? 'Opening…' : '📎 Attach'}</Text>
      </Pressable>

      {assets.length > 0 && (
        <>
          <ScrollView horizontal>
            {assets.map((a, i) => (
              <Image
                key={i}
                source={{ uri: a.uri }}
                style={{ width: 64, height: 64, marginRight: 4, borderRadius: 8 }}
              />
            ))}
          </ScrollView>

          <Pressable onPress={handleSend}>
            <Text>Send {assets.length} file{assets.length > 1 ? 's' : ''}</Text>
          </Pressable>

          <Pressable onPress={clear}>
            <Text>✕ Cancel</Text>
          </Pressable>
        </>
      )}
    </View>
  )
}

export default ChatInput
```

### Profile settings — restore previous selection

> **Note**: `selectedAssets` pre-selection works on Android only. On iOS the picker opens without any pre-checked items.

```tsx
function ProfilePhotoScreen() {
  const [photo, setPhoto] = useState<MediaAsset | null>(null)

  const changePhoto = async () => {
    try {
      const [asset] = await PictureSelector.openPicker({
        mediaType: MediaType.IMAGE,
        maxCount: 1,
        crop: { enabled: true, ratioX: 1, ratioY: 1 },
        compress: { enabled: true, quality: 0.9, maxWidth: 512, maxHeight: 512 },
        // restore the current photo if user re-opens
        selectedAssets: photo ? [photo.uri] : [],
      })
      setPhoto(asset)
    } catch {
      // cancelled — do nothing
    }
  }

  return (
    <Pressable onPress={changePhoto}>
      {photo
        ? <Image source={{ uri: photo.uri }} style={{ width: 100, height: 100, borderRadius: 50 }} />
        : <Text>Tap to set photo</Text>
      }
    </Pressable>
  )
}
```

---

## Platform-specific notes

### Android

- Minimum SDK: **24** (Android 7.0)
- PictureSelector v3 handles runtime permissions internally. On Android 13+ it requests `READ_MEDIA_IMAGES` / `READ_MEDIA_VIDEO`; on older versions it requests `READ_EXTERNAL_STORAGE`.
- The `theme` option maps to PictureSelector's built-in style presets. `PickerTheme.WECHAT` is the most polished preset.
- Video files captured by camera are placed in the app cache directory.
- Glide is used for thumbnail rendering inside the gallery grid.
- uCrop handles all cropping; circular crop falls back to a 1:1 fixed-ratio crop.
- Luban handles JPEG compression; files under 100 KB bypass compression unchanged.

### iOS

- Minimum deployment target: **iOS 13.0**
- Swift 5.9 is required for the C++ interop used by Nitro Modules.
- HXPhotoPicker requests permissions automatically the first time the picker is opened. The `Info.plist` keys **must** be present or the app will crash on first use.
- The `circular` crop option is iOS-only; it renders a circular preview mask but saves a square file.
- `isOriginal` in `MediaAsset` is only populated on iOS (when the user taps the "Original" toggle).
- `bucketName` is only populated on Android.
- `themeColor` sets HXPhotoPicker's global `themeColor` property (navigation bar, selection indicators).
- `theme` enum values (`WECHAT`, `WHITE`, `DARK`) are ignored on iOS — use `themeColor` instead.
- `selectedAssets` pre-selection is **not yet implemented** on iOS — the option is accepted but has no effect. Resolving `file://` URIs back to `PHAsset` objects is required for this feature.

---

## Permissions summary

### Android — declared automatically

| Permission | API level |
|-----------|-----------|
| `CAMERA` | All |
| `READ_EXTERNAL_STORAGE` | ≤ API 32 (Android 12) |
| `READ_MEDIA_IMAGES` | ≥ API 33 (Android 13) |
| `READ_MEDIA_VIDEO` | ≥ API 33 (Android 13) |
| `WRITE_EXTERNAL_STORAGE` | ≤ API 28 (Android 9) |

### iOS — `Info.plist` keys required

| Key | Purpose |
|-----|---------|
| `NSPhotoLibraryUsageDescription` | Read photos and videos from the library |
| `NSPhotoLibraryAddUsageDescription` | Save captured media to the library |
| `NSCameraUsageDescription` | Access the camera for capture |
| `NSMicrophoneUsageDescription` | Record audio with video |

---

## Known limitations (v1.0)

| Feature | Status |
|---------|--------|
| `selectedAssets` pre-selection (iOS) | Not yet implemented — Android only |
| Audio file selection | Not supported |
| iCloud Photos (iOS) | Partial — depends on HXPhotoPicker internals |
| Live Photos | Not exposed |
| Animated GIF selection | Not exposed |
| Background upload / processing | Out of scope |
| Save to gallery | Out of scope |
| Document picker (PDF, etc.) | Out of scope |

---

## Architecture

```
JavaScript / TypeScript
  PictureSelector.openPicker()
  PictureSelector.openCamera()
  usePictureSelector()
        │
        │  JSI — zero serialization, zero bridge queue
        │  react-native-nitro-modules
        ▼
  HybridPictureSelector
  ┌──────────────────────┬────────────────────────┐
  │ Android (Kotlin)     │ iOS (Swift 5.9)        │
  │                      │                        │
  │ PictureSelector v3   │ HXPhotoPicker v5       │
  │  ├─ GlideEngine      │  ├─ PickerConfiguration│
  │  ├─ UCropEngine      │  ├─ PhotoPickerController│
  │  └─ LubanCompress    │  └─ async result map   │
  └──────────────────────┴────────────────────────┘
```

Results travel from native to JavaScript through a **statically compiled JSI binding** — no JSON serialisation, no async bridge queue, no reflection. Native promises resolve directly on the JS thread.

---

## License

MIT

Native dependencies:
- LuckSiege/PictureSelector — Apache 2.0
- SilenceLove/HXPhotoPicker — MIT
- mrousavy/nitro — MIT
