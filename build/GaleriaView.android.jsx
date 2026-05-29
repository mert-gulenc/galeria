import { requireNativeView } from 'expo';
import { useCallback, useContext, useRef } from 'react';
import { Image } from 'react-native';
import { controlEdgeToEdgeValues, isEdgeToEdge, } from 'react-native-is-edge-to-edge';
import { GaleriaContext } from './context';
const EDGE_TO_EDGE = isEdgeToEdge();
const NativeImage = requireNativeView('Galeria');
const noop = () => { };
function stripCallbacks(headerItems) {
    const callbacks = {};
    const nativeItems = headerItems.map((item) => {
        if (item.action)
            callbacks[item.id] = item.action;
        return {
            id: item.id,
            icon: item.icon,
            label: item.label,
            isMenu: item.isMenu ?? false,
            menuItems: item.menuItems?.map((m) => {
                if (m.action)
                    callbacks[m.id] = m.action;
                return {
                    id: m.id,
                    label: m.label,
                    icon: m.icon,
                    isDestructive: m.isDestructive ?? false,
                };
            }),
        };
    });
    return { nativeItems, callbacks };
}
const Galeria = Object.assign(function Galeria({ children, closeIconName, urls, theme = 'dark', ids, hideBlurOverlay = false, hidePageIndicators = false, headerItems, }) {
    return (<GaleriaContext.Provider value={{
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
        }}>
        {children}
      </GaleriaContext.Provider>);
}, {
    Image({ headerItems: _headerItemsProp, onHeaderAction: _onHeaderActionProp, edgeToEdge, ...props }) {
        const { theme, urls, initialIndex, hideBlurOverlay, hidePageIndicators, headerItems, } = useContext(GaleriaContext);
        const callbacksRef = useRef({});
        const nativeItems = headerItems
            ? (() => {
                const { nativeItems: ni, callbacks } = stripCallbacks(headerItems);
                callbacksRef.current = callbacks;
                return ni;
            })()
            : undefined;
        const handleHeaderAction = useCallback((event) => {
            const menuItemId = event.nativeEvent.menuItemId;
            const key = menuItemId && menuItemId !== ''
                ? menuItemId
                : event.nativeEvent.buttonId;
            callbacksRef.current[key]?.(event.nativeEvent.currentIndex);
            _onHeaderActionProp?.(event);
        }, [_onHeaderActionProp]);
        if (__DEV__) {
            // warn the user once about unnecessary defined prop
            controlEdgeToEdgeValues({ edgeToEdge });
        }
        return (<NativeImage onIndexChange={props.onIndexChange} edgeToEdge={EDGE_TO_EDGE || (edgeToEdge ?? false)} theme={theme} hideBlurOverlay={props.hideBlurOverlay ?? hideBlurOverlay} hidePageIndicators={props.hidePageIndicators ?? hidePageIndicators} urls={urls?.map((url) => {
                if (typeof url === 'string') {
                    return url;
                }
                return Image.resolveAssetSource(url).uri;
            })} index={props.index ?? initialIndex} headerItems={nativeItems} onHeaderAction={handleHeaderAction} {...props}/>);
    },
    Popup: (() => null),
});
export default Galeria;
//# sourceMappingURL=GaleriaView.android.jsx.map