import { createContext } from 'react';
export const GaleriaContext = createContext({
    initialIndex: 0,
    open: false,
    urls: [],
    closeIconName: undefined,
    /**
     * @deprecated
     */
    ids: undefined,
    setOpen: (info) => { },
    theme: 'dark',
    src: '',
    hideBlurOverlay: false,
    hidePageIndicators: false,
    headerItems: undefined,
});
//# sourceMappingURL=context.jsx.map