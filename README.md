
# Galeria 📷

An image viewer for React (+ Native). **It works with any image component - bring your own image component (BYOIC™)**

> This is a fork of [@nandorojo/galeria](https://github.com/nandorojo/galeria) with native header action buttons for the image viewer.

https://github.com/user-attachments/assets/5062e949-b205-4260-830c-38041cec26db

## Features

- Shared element transitions
- Pinch to zoom
- Double tap to zoom
- Pan to close
- Multi-image support
- React Native Modal support
- FlashList support
- Clean API
- Web support
- Remote URLs & local images
- New Architecture (Fabric) – required
- Supports different images when collapsed and expanded
- Works with _any image component_
- **Native header action buttons** — Share, context menu, and more *(new)*
- **iOS 26 liquid glass** — nav bar and buttons get the glass material automatically *(new)*

For iOS and Android, the implementation uses Swift (`ImageViewer.swift`) and Kotlin (`imageviewer`) respectively.

Web support is a simplified version of the native experience powered by Framer Motion.

---

## Header Items (new)

The `headerItems` prop adds native action buttons to the top-right of the full-screen image viewer on iOS. The viewer's navigation bar automatically adopts the iOS 26 liquid glass material. A close button (×) is always shown on the left.

Plain buttons fire an `action` callback immediately on tap. Menu buttons (`isMenu: true`) open a native action sheet with their `menuItems`.

### Props

```ts
interface GaleriaHeaderItem {
  id: string
  icon: string              // SF Symbol name (e.g. "square.and.arrow.up")
  label?: string
  isMenu?: boolean          // true → tap opens an action sheet with menuItems
  menuItems?: GaleriaHeaderMenuItem[]
  action?: (currentIndex: number) => void
}

interface GaleriaHeaderMenuItem {
  id: string
  label: string
  icon?: string             // SF Symbol name
  isDestructive?: boolean   // renders the item in red
  action?: (currentIndex: number) => void
}
```

Action callbacks receive the **current image index** — no need to track it yourself.

### Basic example

```tsx
import { Galeria } from '@mert-gulenc/galeria'

<Galeria
  urls={urls}
  headerItems={[
    {
      id: 'share',
      icon: 'square.and.arrow.up',
      action: (index) => shareImage(urls[index]),
    },
    {
      id: 'more',
      icon: 'ellipsis',
      isMenu: true,
      menuItems: [
        {
          id: 'save',
          label: 'Save to Photos',
          icon: 'square.and.arrow.down',
          action: (index) => saveToLibrary(urls[index]),
        },
        {
          id: 'delete',
          label: 'Delete',
          icon: 'trash',
          isDestructive: true,
          action: (index) => deleteImage(index),
        },
      ],
    },
  ]}
>
  {urls.map((url, index) => (
    <Galeria.Image index={index} key={url}>
      <Image source={{ uri: url }} style={{ width: 100, height: 100 }} />
    </Galeria.Image>
  ))}
</Galeria>
```

### Full example (Share + context menu with Save / Delete)

```tsx
import { Galeria } from '@mert-gulenc/galeria'
import { File, Paths } from 'expo-file-system/next'
import * as Haptics from 'expo-haptics'
import * as MediaLibrary from 'expo-media-library'
import * as Sharing from 'expo-sharing'

export default function Gallery({ images }) {
  const urls = images.map((img) => img.url)

  async function handleShare(index: number) {
    const file = new File(Paths.cache, `img_${index}.jpg`)
    if (!file.exists) await File.downloadFileAsync(urls[index], file)
    await Sharing.shareAsync(file.uri, { mimeType: 'image/jpeg' })
  }

  async function handleSave(index: number) {
    const { status } = await MediaLibrary.requestPermissionsAsync()
    if (status !== 'granted') return
    const file = new File(Paths.cache, `img_${index}.jpg`)
    if (!file.exists) await File.downloadFileAsync(urls[index], file)
    await MediaLibrary.saveToLibraryAsync(file.uri)
    await Haptics.notificationAsync(Haptics.NotificationFeedbackType.Success)
  }

  async function handleDelete(index: number) {
    // your delete logic
  }

  return (
    <Galeria
      urls={urls}
      headerItems={[
        { id: 'share', icon: 'square.and.arrow.up', action: handleShare },
        {
          id: 'more',
          icon: 'ellipsis',
          isMenu: true,
          menuItems: [
            { id: 'save',   label: 'Save to Photos', icon: 'square.and.arrow.down', action: handleSave },
            { id: 'delete', label: 'Delete',          icon: 'trash', isDestructive: true, action: handleDelete },
          ],
        },
      ]}
    >
      {urls.map((url, index) => (
        <Galeria.Image index={index} key={url}>
          <Image source={{ uri: url }} style={{ width: 100, height: 100 }} />
        </Galeria.Image>
      ))}
    </Galeria>
  )
}
```

### Header item behaviour

| Behaviour | Detail |
|---|---|
| Layout | Buttons appear right-to-left in the order you pass them (first item is leftmost) |
| Close button | Always present on the left — no configuration needed |
| Plain button | Tap fires `action(currentIndex)` immediately |
| Menu button | Tap opens a native action sheet with the `menuItems` listed |
| Destructive items | `isDestructive: true` renders the action sheet item in red |
| Visibility | Shown when viewer opens; single-tap on the image toggles hide/show |
| Liquid glass | Automatic on iOS 26+ via the navigation bar material |
| Current index | Passed to every `action` callback — no ref tracking needed |

---

## Usage

### One Image

```tsx
import { Galeria } from '@mert-gulenc/galeria'
import { Image } from 'react-native'

const url = 'https://my-image.com/image.jpg'

export const SingleImage = ({ style }) => (
  <Galeria urls={[url]}>
    <Galeria.Image>
      <Image source={{ uri: url }} style={style} />
    </Galeria.Image>
  </Galeria>
)
```

### Multiple Images

```tsx
import { Galeria } from '@mert-gulenc/galeria'
import { Image } from 'react-native'

const urls = ['https://my-image.com/image.jpg', 'https://my-image.com/image2.jpg']

export const MultiImage = ({ style }) => (
  <Galeria urls={urls}>
    {urls.map((url, index) => (
      <Galeria.Image index={index} key={url}>
        <Image source={{ uri: url }} style={style} />
      </Galeria.Image>
    ))}
  </Galeria>
)
```

### FlashList

```tsx
import { Galeria } from '@mert-gulenc/galeria'
import { Image } from 'react-native'
import { FlashList } from '@shopify/flash-list'

const urls = ['https://my-image.com/image.jpg', 'https://my-image.com/image2.jpg']
const size = 100

export const FlashListSupport = () => (
  <Galeria urls={urls}>
    <FlashList
      data={urls}
      renderItem={({ item, index }) => (
        <Galeria.Image index={index}>
          <Image source={{ uri: item }} style={{ width: size, height: size }} />
        </Galeria.Image>
      )}
      numColumns={3}
      estimatedItemSize={size}
      keyExtractor={(item, i) => item + i}
    />
  </Galeria>
)
```

### Dark Mode

```tsx
<Galeria urls={urls} theme="dark">
  ...
</Galeria>
```

### Get Index of Currently Shown Image

```tsx
<Galeria.Image
  index={index}
  onIndexChange={(e) => setCurrentIndex(e.nativeEvent.currentIndex)}
>
  <Image source={{ uri: url }} style={style} />
</Galeria.Image>
```

### Hide Blur Overlay *(iOS)*

```tsx
<Galeria.Image hideBlurOverlay>
  <Image source={{ uri: url }} style={style} />
</Galeria.Image>
```

### Hide Page Indicators *(iOS)*

```tsx
<Galeria.Image hidePageIndicators>
  <Image source={{ uri: url }} style={style} />
</Galeria.Image>
```

---

## Installation

### Requirements

- **New Architecture (Fabric)** – requires Expo SDK 54+ or React Native 0.79+
- **iOS 16+**

```bash
npm install github:mert-gulenc/galeria
# or
bun add git+ssh://git@github.com:mert-gulenc/galeria.git
```

### Expo

Galeria uses native libraries, so it does not work with Expo Go. Use a dev client.

```bash
npx expo prebuild
npx expo run:ios
```

---

## Credits

- Fork of [@nandorojo/galeria](https://github.com/nandorojo/galeria) by [Fernando Rojo](https://github.com/nandorojo)
- Header action buttons & iOS 26 liquid glass by [mert-gulenc](https://github.com/mert-gulenc)
- iOS image viewer: [Michael Henry – ImageViewer.swift](https://github.com/michaelhenry/ImageViewer.swift)
- iOS transitions: [Luke Zhao – DynamicTransition](https://github.com/lkzhao/DynamicTransition)
- Android image viewer: [iielse](https://github.com/iielse/imageviewer)
- Android integration: [Alan](https://github.com/alantoa)
- Web animations: [Framer Motion](https://www.framer.com/motion/)
