import { requireNativeView } from 'expo'

import { useCallback, useContext, useRef } from 'react'
import { Image } from 'react-native'
import type { SFSymbol } from 'sf-symbols-typescript'
import { GaleriaContext } from './context'
import {
  GaleriaIndexChangedEvent,
  GaleriaToolbarActionEvent,
  GaleriaToolbarItem,
  GaleriaViewProps,
} from './Galeria.types'

type NativeToolbarMenuItem = {
  id: string
  label: string
  icon?: string
  isDestructive: boolean
}

type NativeToolbarItem = {
  id: string
  icon: string
  label?: string
  isMenu: boolean
  menuItems?: NativeToolbarMenuItem[]
}

const NativeImage = requireNativeView<
  Omit<GaleriaViewProps, 'toolbar' | 'onToolbarAction'> & {
    urls?: string[]
    closeIconName?: SFSymbol
    theme: 'dark' | 'light'
    onIndexChange?: (event: GaleriaIndexChangedEvent) => void
    onToolbarAction?: (event: GaleriaToolbarActionEvent) => void
    hideBlurOverlay?: boolean
    hidePageIndicators?: boolean
    toolbar?: NativeToolbarItem[]
  }
>('Galeria')

const noop = () => {}

function stripCallbacks(toolbar: GaleriaToolbarItem[]): {
  nativeToolbar: NativeToolbarItem[]
  callbacks: Record<string, (currentIndex: number) => void>
} {
  const callbacks: Record<string, (currentIndex: number) => void> = {}
  const nativeToolbar: NativeToolbarItem[] = toolbar.map((item) => {
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
  return { nativeToolbar, callbacks }
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
    toolbar,
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
      | 'toolbar'
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
          toolbar,
        }}
      >
        {children}
      </GaleriaContext.Provider>
    )
  },
  {
    Image({
      toolbar: _toolbarProp,
      onToolbarAction: _onToolbarActionProp,
      ...props
    }: GaleriaViewProps) {
      const {
        theme,
        urls,
        initialIndex,
        closeIconName,
        hideBlurOverlay,
        hidePageIndicators,
        toolbar,
      } = useContext(GaleriaContext)

      const callbacksRef = useRef<Record<string, (currentIndex: number) => void>>({})

      const nativeToolbar = toolbar
        ? (() => {
            const { nativeToolbar: nt, callbacks } = stripCallbacks(toolbar)
            callbacksRef.current = callbacks
            return nt
          })()
        : undefined

      const handleToolbarAction = useCallback(
        (event: GaleriaToolbarActionEvent) => {
          const key =
            event.nativeEvent.menuItemId ?? event.nativeEvent.buttonId
          callbacksRef.current[key]?.(event.nativeEvent.currentIndex)
          _onToolbarActionProp?.(event)
        },
        [_onToolbarActionProp],
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
          toolbar={nativeToolbar}
          onToolbarAction={handleToolbarAction}
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
