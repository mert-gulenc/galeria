import { ContextType } from 'react';
import type { Image } from 'react-native';
import type { SFSymbol } from 'sf-symbols-typescript';
import type { GaleriaHeaderItem } from './Galeria.types';
type ImageSource = string | Parameters<typeof Image.resolveAssetSource>[0];
export declare const GaleriaContext: import("react").Context<{
    initialIndex: number;
    open: boolean;
    urls: undefined | ImageSource[];
    closeIconName: undefined | SFSymbol;
    /**
     * @deprecated
     */
    ids: string[] | undefined;
    setOpen: (info: {
        open: true;
        src: string;
        initialIndex: number;
        id?: string;
    } | {
        open: false;
    }) => void;
    theme: "dark" | "light";
    src: string;
    hideBlurOverlay: boolean;
    hidePageIndicators: boolean;
    headerItems: GaleriaHeaderItem[] | undefined;
}>;
export type GaleriaContext = ContextType<typeof GaleriaContext>;
export {};
//# sourceMappingURL=context.d.ts.map