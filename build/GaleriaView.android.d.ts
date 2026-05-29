import { GaleriaContext } from './context';
import { GaleriaViewProps } from './Galeria.types';
declare const Galeria: (({ children, closeIconName, urls, theme, ids, hideBlurOverlay, hidePageIndicators, headerItems, }: {
    children: React.ReactNode;
} & Partial<Pick<GaleriaContext, "theme" | "ids" | "urls" | "closeIconName" | "hideBlurOverlay" | "hidePageIndicators" | "headerItems">>) => import("react").JSX.Element) & {
    Image({ headerItems: _headerItemsProp, onHeaderAction: _onHeaderActionProp, edgeToEdge, ...props }: GaleriaViewProps): import("react").JSX.Element;
    Popup: React.FC<{
        disableTransition?: "web";
    }>;
};
export default Galeria;
//# sourceMappingURL=GaleriaView.android.d.ts.map