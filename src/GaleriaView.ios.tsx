import { requireNativeView } from 'expo'

import { useCallback, useContext, useRef } from 'react'
import { Image } from 'react-native'
import type { SFSymbol } from 'sf-symbols-typescript'
import { GaleriaContext } from './context'
import {
  GaleriaIndexChangedEvent,
  GaleriaHeaderActionEvent,
  GaleriaHeaderItem,
  GaleriaViewProps,
} from './Galeria.types'

type NativeHeaderMenuItem = {
  id: string
  label: string
  icon?: string
  isDestructive: boolean
}

type NativeHeaderItem = {
  id: string
  icon: string
  label?: string
  isMenu: boolean
  menuItems?: NativeHeaderMenuItem[]
}

const NativeImage = requireNativeView<
  Omit<GaleriaViewProps, 'headerItems' | 'onHeaderAction'> & {
    urls?: string[]
    closeIconName?: SFSymbol
    theme: 'dark' | 'light'
    onIndexChange?: (event: GaleriaIndexChangedEvent) => void
    onHeaderAction?: (event: GaleriaHeaderActionEvent) => void
    hideBlurOverlay?: boolean
    hidePageIndicators?: boolean
    headerItems?: NativeHeaderItem[]
  }
>('Galeria')

const noop = () => {}

function stripCallbacks(headerItems: GaleriaHeaderItem[]): {
  nativeItems: NativeHeaderItem[]
  callbacks: Record<string, (currentIndex: number) => void>
} {
  const callbacks: Record<string, (currentIndex: number) => void> = {}
  const nativeItems: NativeHeaderItem[] = headerItems.map((item) => {
    if (item.action) callbacks[item.id] = item.action
    return {
      id: item.id,
      icon: item.icon,
      label: item.label,
      isMenu: item.isMenu ?? false,
      menuItems: item.menuItems?.map((m) => {
        if (m.action) callbacks[m.id] = m.action
        return {
          id: m.id,
          label: m.label,
          icon: m.icon,
          isDestructive: m.isDestructive ?? false,
        }
      }),
    }
  })
  return { nativeItems, callbacks }
}

const Galeria = Object.assign(
  function Galeria({
    children,
    closeIconName,
    urls,
    theme = 'dark',
    ids,
    hideBlurOverlay = false,
    hidePageIndicators = false,
    headerItems,
  }: {
    children: React.ReactNode
  } & Partial<
    Pick<
      GaleriaContext,
      | 'theme'
      | 'ids'
      | 'urls'
      | 'closeIconName'
      | 'hideBlurOverlay'
      | 'hidePageIndicators'
      | 'headerItems'
    >
  >) {
    return (
      <GaleriaContext.Provider
        value={{
          closeIconName,
          urls,
          theme,
          initialIndex: 0,
          open: false,
          src: '',
          setOpen: noop,
          ids,
          hideBlurOverlay,
          hidePageIndicators,
          headerItems,
        }}
      >
        {children}
      </GaleriaContext.Provider>
    )
  },
  {
    Image({
      headerItems: _headerItemsProp,
      onHeaderAction: _onHeaderActionProp,
      ...props
    }: GaleriaViewProps) {
      const {
        theme,
        urls,
        initialIndex,
        closeIconName,
        hideBlurOverlay,
        hidePageIndicators,
        headerItems,
      } = useContext(GaleriaContext)

      const callbacksRef = useRef<Record<string, (currentIndex: number) => void>>({})

      const nativeItems = headerItems
        ? (() => {
            const { nativeItems: ni, callbacks } = stripCallbacks(headerItems)
            callbacksRef.current = callbacks
            return ni
          })()
        : undefined

      const handleHeaderAction = useCallback(
        (event: GaleriaHeaderActionEvent) => {
          const key =
            event.nativeEvent.menuItemId ?? event.nativeEvent.buttonId
          callbacksRef.current[key]?.(event.nativeEvent.currentIndex)
          _onHeaderActionProp?.(event)
        },
        [_onHeaderActionProp],
      )

      return (
        <NativeImage
          onIndexChange={props.onIndexChange}
          closeIconName={closeIconName}
          theme={theme}
          hideBlurOverlay={props.hideBlurOverlay ?? hideBlurOverlay}
          hidePageIndicators={props.hidePageIndicators ?? hidePageIndicators}
          urls={urls?.map((url) => {
            if (typeof url === 'string') {
              return url
            }
            return Image.resolveAssetSource(url).uri
          })}
          index={initialIndex}
          headerItems={nativeItems}
          onHeaderAction={handleHeaderAction}
          {...props}
        />
      )
    },
    Popup: (() => null) as React.FC<{
      disableTransition?: 'web'
    }>,
  },
)

export default Galeria
