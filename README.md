
# Galeria 📷

An image viewer for React (+ Native). **It works with any image component - bring your own image component (BYOIC™)**

> This is a fork of [@nandorojo/galeria](https://github.com/nandorojo/galeria) with an added native bottom toolbar for the image viewer.

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
- **Native bottom toolbar** with action buttons *(new)*
- **Context menu support** via native `UIMenu` *(new)*

For iOS and Android, the implementation uses Swift (`ImageViewer.swift`) and Kotlin (`imageviewer`) respectively.

Web support is a simplified version of the native experience powered by Framer Motion.

---

## Toolbar (new)

The `toolbar` prop adds a native `UIToolbar` at the bottom of the full-screen image viewer on iOS. On iOS 26 it automatically picks up the liquid glass material.

### Props

```ts
interface GaleriaToolbarItem {
  id: string
  icon: string           // SF Symbol name (e.g. "square.and.arrow.up")
  label?: string
  isMenu?: boolean       // renders as a context menu button
  menuItems?: GaleriaToolbarMenuItem[]
  action?: (currentIndex: number) => void
}

interface GaleriaToolbarMenuItem {
  id: string
  label: string
  icon?: string          // SF Symbol name
  isDestructive?: boolean
  action?: (currentIndex: number) => void
}
```

Action callbacks receive the **current image index** automatically — no need to track it yourself.

### Basic example

```tsx
import { Galeria } from '@mert-gulenc/galeria'

<Galeria
  urls={urls}
  toolbar={[
    {
      id: 'share',
      icon: 'square.and.arrow.up',
      action: (index) => shareImage(urls[index]),
    },
    {
      id: 'more',
      icon: 'ellipsis.circle',
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

### Full example (Share, Crop, Edit, context menu)

```tsx
import { Galeria } from '@mert-gulenc/galeria'
import { File, Paths } from 'expo-file-system'
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

  return (
    <Galeria
      urls={urls}
      toolbar={[
        { id: 'share', icon: 'square.and.arrow.up', action: handleShare },
        { id: 'crop',  icon: 'crop',                action: (i) => openEditor(i) },
        { id: 'edit',  icon: 'pencil',              action: (i) => openEditor(i) },
        {
          id: 'more',
          icon: 'ellipsis.circle',
          isMenu: true,
          menuItems: [
            { id: 'save',   label: 'Save to Photos', icon: 'square.and.arrow.down', action: handleSave },
            { id: 'delete', label: 'Delete', icon: 'trash', isDestructive: true, action: (i) => deleteImage(i) },
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

### Toolbar behaviour

| Behaviour | Detail |
|---|---|
| Visibility | Shown when viewer opens, hidden on swipe-dismiss start |
| Toggle | Single tap anywhere on the image shows/hides both toolbar and nav bar |
| Menu button | Long-press not required — tap shows the `UIMenu` immediately |
| Destructive items | Rendered in red automatically |
| Liquid glass | Automatic on iOS 26+ via `UIToolbar` |
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
- Native toolbar additions by [mert-gulenc](https://github.com/mert-gulenc)
- iOS image viewer: [Michael Henry – ImageViewer.swift](https://github.com/michaelhenry/ImageViewer.swift)
- iOS transitions: [Luke Zhao – DynamicTransition](https://github.com/lkzhao/DynamicTransition)
- Android image viewer: [iielse](https://github.com/iielse/imageviewer)
- Android integration: [Alan](https://github.com/alantoa)
- Web animations: [Framer Motion](https://www.framer.com/motion/)
