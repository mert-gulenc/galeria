import UIKit

class ImageViewerRootView: UIView, RootViewType {
    let transition = MatchTransition()

    weak var imageDatasource: ImageDataSource?
    let imageLoader: ImageLoader
    var initialIndex: Int = 0
    var theme: ImageViewerTheme = .dark
    var options: [ImageViewerOption] = []
    var onIndexChange: ((Int) -> Void)?
    var onDismiss: (() -> Void)?
    var sourceImage: UIImage?
    var hideBlurOverlay: Bool = false
    var hidePageIndicators: Bool = false

    private var headerItemsConfig: [[String: Any]] = []
    private var onHeaderActionCallback: ((String, String?, Int) -> Void)?

    private var pageViewController: UIPageViewController!
    private(set) lazy var backgroundView: UIView = {
        let view = UIView()
        view.backgroundColor = theme.color
        return view
    }()

    private(set) lazy var navBar: UINavigationBar = {
        let navBar = UINavigationBar(frame: .zero)
        navBar.isTranslucent = true
        navBar.setBackgroundImage(UIImage(), for: .default)
        navBar.shadowImage = UIImage()
        return navBar
    }()

    private lazy var navItem = UINavigationItem()
    private var onRightNavBarTapped: ((Int) -> Void)?

    private(set) var currentIndex: Int = 0
    private var initialViewController: ImageViewerController?

    var currentImageView: UIImageView? {
        if let vc = pageViewController?.viewControllers?.first as? ImageViewerController {
            return vc.imageView
        }
        if let vc = initialViewController {
            return vc.imageView
        }
        return nil
    }

    var currentScrollView: UIScrollView? {
        if let vc = pageViewController?.viewControllers?.first as? ImageViewerController {
            return vc.scrollView
        }
        return initialViewController?.scrollView
    }

    var preferredStatusBarStyle: UIStatusBarStyle {
        theme == .dark ? .lightContent : .default
    }

    var prefersStatusBarHidden: Bool { false }
    var prefersHomeIndicatorAutoHidden: Bool { false }

    func willAppear(animated: Bool) {
        navBar.alpha = 0
    }

    func didAppear(animated: Bool) {
        UIView.animate(withDuration: 0.25) {
            self.navBar.alpha = 1.0
        }
    }

    func willDisappear(animated: Bool) {
        UIView.animate(withDuration: 0.25) {
            self.navBar.alpha = 0
        }
    }

    func didDisappear(animated: Bool) {
        onDismiss?()
    }

    init(
        imageDataSource: ImageDataSource?,
        imageLoader: ImageLoader,
        options: [ImageViewerOption] = [],
        initialIndex: Int = 0,
        sourceImage: UIImage? = nil
    ) {
        self.imageDatasource = imageDataSource
        self.imageLoader = imageLoader
        self.options = options
        self.initialIndex = initialIndex
        self.currentIndex = initialIndex
        self.sourceImage = sourceImage

        for option in options {
            if case .hidePageIndicators(let hide) = option {
                self.hidePageIndicators = hide
            }
        }

        super.init(frame: .zero)
        setupViews()
        applyOptions()
        setupGestures()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupViews() {
        addSubview(backgroundView)

        let pageOptions = [UIPageViewController.OptionsKey.interPageSpacing: 20]
        pageViewController = UIPageViewController(
            transitionStyle: .scroll,
            navigationOrientation: .horizontal,
            options: pageOptions
        )
        pageViewController.dataSource = self
        pageViewController.delegate = self
        pageViewController.view.backgroundColor = .clear

        addSubview(pageViewController.view)

        if let datasource = imageDatasource {
            let initialVC = ImageViewerController(
                index: initialIndex,
                imageItem: datasource.imageItem(at: initialIndex),
                imageLoader: imageLoader
            )
            self.initialViewController = initialVC

            if let sourceImage = self.sourceImage {
                initialVC.initialPlaceholder = sourceImage
            }

            initialVC.view.gestureRecognizers?.removeAll(where: { $0 is UIPanGestureRecognizer })
            pageViewController.setViewControllers([initialVC], direction: .forward, animated: false)

            initialVC.view.setNeedsLayout()
            initialVC.view.layoutIfNeeded()

            onIndexChange?(initialIndex)
        }

        // Close button: xmark icon on the LEFT
        let closeBarButton = UIBarButtonItem(
            image: UIImage(systemName: "xmark"),
            style: .plain,
            target: self,
            action: #selector(dismissViewer)
        )
        closeBarButton.tintColor = theme.tintColor
        navItem.leftBarButtonItem = closeBarButton

        navBar.items = [navItem]
        addSubview(navBar)
    }

    private func applyOptions() {
        let closeButton = navItem.leftBarButtonItem

        options.forEach { option in
            switch option {
            case .theme(let newTheme):
                self.theme = newTheme
                backgroundView.backgroundColor = newTheme.color
                closeButton?.tintColor = newTheme.tintColor
            case .closeIcon(let icon):
                closeButton?.image = icon
            case .rightNavItemTitle(let title, let onTap):
                let customButton = UIBarButtonItem(
                    title: title,
                    style: .plain,
                    target: self,
                    action: #selector(didTapRightNavItem)
                )
                navItem.rightBarButtonItem = customButton
                onRightNavBarTapped = onTap
            case .rightNavItemIcon(let icon, let onTap):
                let customButton = UIBarButtonItem(
                    image: icon,
                    style: .plain,
                    target: self,
                    action: #selector(didTapRightNavItem)
                )
                navItem.rightBarButtonItem = customButton
                onRightNavBarTapped = onTap
            case .onIndexChange(let callback):
                self.onIndexChange = callback
            case .onDismiss(let callback):
                self.onDismiss = callback
            case .contentMode:
                break
            case .hideBlurOverlay(let hide):
                self.hideBlurOverlay = hide
            case .hidePageIndicators(let hide):
                self.hidePageIndicators = hide
            case .headerItems(let items, let onTap):
                headerItemsConfig = items
                onHeaderActionCallback = onTap
                buildNavBarRightItems()
            }
        }
    }

    // Builds rightBarButtonItems from the headerItems config.
    // Items appear left→right on screen; UIKit rightBarButtonItems are stored right→left,
    // so we reverse the built array before assigning.
    private func buildNavBarRightItems() {
        NSLog("[Galeria] buildNavBarRightItems called with %d items", headerItemsConfig.count)
        var buttons: [UIBarButtonItem] = []

        for item in headerItemsConfig {
            guard let id = item["id"] as? String,
                  let iconName = item["icon"] as? String else {
                NSLog("[Galeria] buildNavBarRightItems: skipping item missing id or icon: %@", item.description)
                continue
            }

            let isMenu = item["isMenu"] as? Bool ?? false
            let image = UIImage(systemName: iconName)
            NSLog("[Galeria] buildNavBarRightItems: id=%@ icon=%@ isMenu=%d imageFound=%d", id, iconName, isMenu ? 1 : 0, image != nil ? 1 : 0)

            if isMenu, let rawMenuItems = item["menuItems"] as? [[String: Any]] {
                NSLog("[Galeria] buildNavBarRightItems: building menu with %d items for id=%@", rawMenuItems.count, id)
                let actions: [UIAction] = rawMenuItems.compactMap { m in
                    guard let mid = m["id"] as? String,
                          let label = m["label"] as? String else { return nil }
                    let icon = (m["icon"] as? String).flatMap { UIImage(systemName: $0) }
                    let attrs: UIMenuElement.Attributes =
                        (m["isDestructive"] as? Bool == true) ? .destructive : []
                    NSLog("[Galeria] buildNavBarRightItems: menu action id=%@ label=%@", mid, label)
                    return UIAction(title: label, image: icon, attributes: attrs) { [weak self] _ in
                        NSLog("[Galeria] UIAction fired: buttonId=%@ menuItemId=%@ index=%d", id, mid, self?.currentIndex ?? 0)
                        self?.onHeaderActionCallback?(id, mid, self?.currentIndex ?? 0)
                    }
                }
                // UIBarButtonItem(image:menu:) doesn't present menus reliably in a
                // standalone UINavigationBar (no UINavigationController backing it).
                // UIButton with showsMenuAsPrimaryAction=true handles its own presentation.
                let button = UIButton(type: .system)
                button.setImage(image, for: .normal)
                button.tintColor = theme.tintColor
                button.menu = UIMenu(children: actions)
                button.showsMenuAsPrimaryAction = true
                button.frame = CGRect(x: 0, y: 0, width: 44, height: 44)
                NSLog("[Galeria] buildNavBarRightItems: created UIButton with menu for id=%@, frame=%@", id, NSCoder.string(for: button.frame))
                buttons.append(UIBarButtonItem(customView: button))
            } else {
                let btn = UIBarButtonItem(
                    image: image,
                    style: .plain,
                    target: self,
                    action: #selector(navBarItemTapped(_:))
                )
                btn.tintColor = theme.tintColor
                btn.accessibilityIdentifier = id
                buttons.append(btn)
            }
        }

        NSLog("[Galeria] buildNavBarRightItems: setting %d rightBarButtonItems", buttons.count)
        // Reverse so the first item in the prop array appears leftmost on screen
        navItem.rightBarButtonItems = buttons.reversed()
    }

    @objc private func navBarItemTapped(_ sender: UIBarButtonItem) {
        guard let id = sender.accessibilityIdentifier else { return }
        NSLog("[Galeria] navBarItemTapped: id=%@ index=%d", id, currentIndex)
        onHeaderActionCallback?(id, nil, currentIndex)
    }

    private func setupGestures() {
        addGestureRecognizer(transition.verticalDismissGestureRecognizer)
        transition.verticalDismissGestureRecognizer.delegate = self

        let singleTapGesture = UITapGestureRecognizer(target: self, action: #selector(didSingleTap))
        singleTapGesture.numberOfTapsRequired = 1
        addGestureRecognizer(singleTapGesture)
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        backgroundView.frame = bounds
        pageViewController.view.frame = bounds

        pageViewController.view.setNeedsLayout()
        pageViewController.view.layoutIfNeeded()
        for child in pageViewController.children {
            child.view.setNeedsLayout()
            child.view.layoutIfNeeded()
        }

        let navBarHeight: CGFloat = 44
        let statusBarHeight = safeAreaInsets.top
        let horizontalPadding: CGFloat = 16
        navBar.frame = CGRect(
            x: horizontalPadding,
            y: statusBarHeight,
            width: bounds.width - (horizontalPadding * 2),
            height: navBarHeight
        )
    }

    @objc private func dismissViewer() {
        navigationView?.popView(animated: true)
    }

    @objc private func didSingleTap() {
        let targetAlpha: CGFloat = navBar.alpha > 0.5 ? 0.0 : 1.0
        UIView.animate(withDuration: 0.235) {
            self.navBar.alpha = targetAlpha
        }
    }

    @objc private func didTapRightNavItem() {
        onRightNavBarTapped?(currentIndex)
    }
}

extension ImageViewerRootView: TransitionProvider {
    func transitionFor(presenting: Bool, otherView: UIView) -> Transition? {
        return transition
    }
}

extension ImageViewerRootView: MatchTransitionDelegate {
    func matchedViewFor(transition: MatchTransition, otherView: UIView) -> UIView? {
        return currentImageView
    }

    func matchTransitionWillBegin(transition: MatchTransition) {
        navBar.alpha = 0
        transition.overlayView?.isHidden = hideBlurOverlay
    }
}

extension ImageViewerRootView: UIGestureRecognizerDelegate {
    override func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        // Don't intercept taps that land on the nav bar — lets UIBarButtonItem menus fire
        if gestureRecognizer is UITapGestureRecognizer {
            let location = gestureRecognizer.location(in: self)
            let inNavBar = navBar.frame.contains(location)
            NSLog("[Galeria] gestureRecognizerShouldBegin: tapGesture location=%@ navBar.frame=%@ inNavBar=%d → shouldBegin=%d",
                  NSCoder.string(for: location), NSCoder.string(for: navBar.frame), inNavBar ? 1 : 0, inNavBar ? 0 : 1)
            if inNavBar {
                return false
            }
        }
        if let scrollView = currentScrollView {
            return scrollView.zoomScale <= scrollView.minimumZoomScale + 0.01
        }
        return true
    }

    func gestureRecognizer(
        _ gestureRecognizer: UIGestureRecognizer,
        shouldReceive touch: UITouch
    ) -> Bool {
        // Reject touches that hit the nav bar so bar buttons and custom button menus fire
        if gestureRecognizer is UITapGestureRecognizer {
            let location = touch.location(in: self)
            let inNavBar = navBar.frame.contains(location)
            NSLog("[Galeria] shouldReceive(touch): location=%@ navBar.frame=%@ inNavBar=%d → shouldReceive=%d",
                  NSCoder.string(for: location), NSCoder.string(for: navBar.frame), inNavBar ? 1 : 0, inNavBar ? 0 : 1)
            if inNavBar {
                return false
            }
        }
        return true
    }

    func gestureRecognizer(
        _ gestureRecognizer: UIGestureRecognizer,
        shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer
    ) -> Bool {
        return false
    }
}

extension ImageViewerRootView: UIPageViewControllerDataSource {
    func pageViewController(
        _ pageViewController: UIPageViewController,
        viewControllerBefore viewController: UIViewController
    ) -> UIViewController? {
        guard let vc = viewController as? ImageViewerController,
              let datasource = imageDatasource,
              vc.index > 0 else {
            return nil
        }

        let newIndex = vc.index - 1
        let newVC = ImageViewerController(
            index: newIndex,
            imageItem: datasource.imageItem(at: newIndex),
            imageLoader: imageLoader
        )
        newVC.view.gestureRecognizers?.removeAll(where: { $0 is UIPanGestureRecognizer })
        return newVC
    }

    func pageViewController(
        _ pageViewController: UIPageViewController,
        viewControllerAfter viewController: UIViewController
    ) -> UIViewController? {
        guard let vc = viewController as? ImageViewerController,
              let datasource = imageDatasource,
              vc.index < datasource.numberOfImages() - 1 else {
            return nil
        }

        let newIndex = vc.index + 1
        let newVC = ImageViewerController(
            index: newIndex,
            imageItem: datasource.imageItem(at: newIndex),
            imageLoader: imageLoader
        )
        newVC.view.gestureRecognizers?.removeAll(where: { $0 is UIPanGestureRecognizer })
        return newVC
    }

    func presentationCount(for pageViewController: UIPageViewController) -> Int {
        guard !hidePageIndicators else { return 0 }
        let count = imageDatasource?.numberOfImages() ?? 0
        return count > 1 ? count : 0
    }

    func presentationIndex(for pageViewController: UIPageViewController) -> Int {
        return currentIndex
    }
}

extension ImageViewerRootView: UIPageViewControllerDelegate {
    func pageViewController(
        _ pageViewController: UIPageViewController,
        didFinishAnimating finished: Bool,
        previousViewControllers: [UIViewController],
        transitionCompleted completed: Bool
    ) {
        if completed, let currentVC = pageViewController.viewControllers?.first as? ImageViewerController {
            currentIndex = currentVC.index
            onIndexChange?(currentIndex)
        }
    }
}
