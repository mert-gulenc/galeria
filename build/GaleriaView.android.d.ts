import { GaleriaContext } from './context';
import { GaleriaViewProps } from './Galeria.types';
declare const Galeria: (({ children, urls, theme, ids, }: {
    children: React.ReactNode;
} & Partial<Pick<GaleriaContext, "theme" | "ids" | "urls">>) => import("react").JSX.Element) & {
    Image({ edgeToEdge, ...props }: GaleriaViewProps): import("react").JSX.Element;
    Popup: React.FC<{
        disableTransition?: "web";
    }>;
};
export default Galeria;
//# sourceMappingURL=GaleriaView.android.d.ts.map