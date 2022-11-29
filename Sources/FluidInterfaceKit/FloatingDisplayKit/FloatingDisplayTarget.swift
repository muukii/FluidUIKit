
import UIKit

public final class FloatingDisplayTarget {

  private let notificationWindow: NotificationWindow
  private let notificationViewController: NotificationViewController

  public var additionalSafeAreaInsets: UIEdgeInsets {
    get { notificationViewController.additionalSafeAreaInsets }
    set { notificationViewController.additionalSafeAreaInsets = newValue }
  }

  public var windowLevel: UIWindow.Level {
    get {
      return notificationWindow.windowLevel
    }
    set {
      notificationWindow.windowLevel = newValue
    }
  }

  public var contentView: UIView {
    notificationViewController.view
  }

  public func makeWindowVisible() {
    notificationWindow.isHidden = false
  }

  public func hideWindow() {
    notificationWindow.isHidden = true
  }


  public init(useActiveWindowSafeArea: Bool = false) {
    self.notificationViewController = .init(useActiveWindowSafeArea: useActiveWindowSafeArea)

    if #available(iOS 13, *) {

      let windowScene = UIApplication.shared
        .connectedScenes
        .lazy
        .filter { $0.activationState == .foregroundActive }
        .compactMap { $0 as? UIWindowScene }
        .first

      if let windowScene = windowScene {
        notificationWindow = .init(windowScene: windowScene)
      } else {
        notificationWindow = .init(frame: .zero)
      }

    } else {
      notificationWindow = .init(frame: .zero)
    }

    notificationWindow.windowLevel = UIWindow.Level(rawValue: 5)
    notificationWindow.isHidden = true
    notificationWindow.backgroundColor = UIColor.clear
    notificationWindow.frame = UIScreen.main.bounds
    notificationViewController.beginAppearanceTransition(true, animated: false)
    notificationWindow.rootViewController = notificationViewController
    notificationViewController.endAppearanceTransition()
  }

  deinit {
    notificationWindow.isHidden = true
  }

}

extension FloatingDisplayTarget {

  fileprivate class NotificationWindow: UIWindow {

    override init(frame: CGRect) {
      super.init(frame: frame)
      isOpaque = false
    }

    @available(iOS 13.0, *)
    override init(windowScene: UIWindowScene) {
      super.init(windowScene: windowScene)
      isOpaque = false
    }

    required init?(coder _: NSCoder) {
      fatalError("init(coder:) has not been implemented")
    }

    override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
      let view = super.hitTest(point, with: event)

      if view == self {
        return nil
      }
      return view
    }
  }

  fileprivate final class NotificationViewController: UIViewController {
    private let useActiveWindowSafeArea: Bool

    init(useActiveWindowSafeArea: Bool) {
      self.useActiveWindowSafeArea = useActiveWindowSafeArea
      super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
      fatalError("init(coder:) has not been implemented")
    }

    override fileprivate func loadView() {
      view = View(useActiveWindowSafeArea: useActiveWindowSafeArea)
    }

    override fileprivate func viewDidLoad() {
      super.viewDidLoad()
      view.isOpaque = false
      view.backgroundColor = UIColor.clear
    }

    fileprivate class View: UIView {
      private let useActiveWindowSafeArea: Bool
      private var activeWindowSafeAreaLayoutGuide: UILayoutGuide!
      private var activeWindowSafeAreaLayoutGuideConstraintLeft: NSLayoutConstraint!
      private var activeWindowSafeAreaLayoutGuideConstraintRight: NSLayoutConstraint!
      private var activeWindowSafeAreaLayoutGuideConstraintTop: NSLayoutConstraint!
      private var activeWindowSafeAreaLayoutGuideConstraintBottom: NSLayoutConstraint!

      init(useActiveWindowSafeArea: Bool) {
        self.useActiveWindowSafeArea = useActiveWindowSafeArea
        super.init(frame: .zero)
        if useActiveWindowSafeArea {
          SafeAreaFinder.shared.start()
          self.activeWindowSafeAreaLayoutGuide = .init()
          self.addLayoutGuide(activeWindowSafeAreaLayoutGuide)
          activeWindowSafeAreaLayoutGuideConstraintLeft = activeWindowSafeAreaLayoutGuide.leftAnchor.constraint(equalTo: leftAnchor)
          activeWindowSafeAreaLayoutGuideConstraintRight = activeWindowSafeAreaLayoutGuide.rightAnchor.constraint(equalTo: rightAnchor)
          activeWindowSafeAreaLayoutGuideConstraintTop = activeWindowSafeAreaLayoutGuide.topAnchor.constraint(equalTo: topAnchor)
          activeWindowSafeAreaLayoutGuideConstraintBottom = activeWindowSafeAreaLayoutGuide.bottomAnchor.constraint(equalTo: bottomAnchor)
          NotificationCenter.default.addObserver(self, selector: #selector(handleInsetsUpdate), name: SafeAreaFinder.notificationName, object: nil)
          SafeAreaFinder.shared.request()
          NSLayoutConstraint.activate([
            activeWindowSafeAreaLayoutGuideConstraintLeft,
            activeWindowSafeAreaLayoutGuideConstraintRight,
            activeWindowSafeAreaLayoutGuideConstraintTop,
            activeWindowSafeAreaLayoutGuideConstraintBottom
          ])
        }
      }

      @objc private func handleInsetsUpdate(notification: Notification) {
        let insets = notification.object as! UIEdgeInsets
        self.activeWindowSafeAreaLayoutGuideConstraintLeft.constant = insets.left
        self.activeWindowSafeAreaLayoutGuideConstraintRight.constant = insets.right
        self.activeWindowSafeAreaLayoutGuideConstraintTop.constant = insets.top
        self.activeWindowSafeAreaLayoutGuideConstraintBottom.constant = insets.bottom
        setNeedsLayout()
        UIViewPropertyAnimator(duration: 0.6, dampingRatio: 1) { [self] in
          self.layoutIfNeeded()
        }
        .startAnimation()
      }

      required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
      }

      override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        let view = super.hitTest(point, with: event)

        if view == self {
          return nil
        }
        return view
      }

      override var safeAreaLayoutGuide: UILayoutGuide {
        if useActiveWindowSafeArea {
          return activeWindowSafeAreaLayoutGuide
        } else {
          return super.safeAreaLayoutGuide
        }
      }

      deinit {
        if useActiveWindowSafeArea {
          SafeAreaFinder.shared.pause()
        }
      }
    }
  }

}
