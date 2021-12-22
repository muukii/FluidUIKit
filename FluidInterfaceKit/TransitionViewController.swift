import UIKit

/// Supports transition
/// compatible with ``ZStackViewController``
open class TransitionViewController: WrapperViewController {

  private struct State: Equatable {

    var countViewDidAppear = 0

  }

  private var state: State = .init()

  public var transition: TransitionPair

  public init(
    bodyViewController: UIViewController,
    transition: TransitionPair
  ) {

    self.transition = transition
    super.init(bodyViewController: bodyViewController)
  }

  public init(
    view: UIView,
    transition: TransitionPair
  ) {

    self.transition = transition
    super.init(view: view)

  }

  func startAddingTransition(context: ZStackViewControllerAddingTransitionContext) {

    guard let addingTransition = transition.adding else {
      return
    }

    addingTransition.startTransition(
      context: context
    )

  }

  func startRemovingTransition(context: ZStackViewControllerRemovingTransitionContext) {

    guard let removingTransition = transition.removing else {
      view.removeFromSuperview()
      return
    }

    removingTransition.startTransition(context: context)
  }

  open override func viewDidAppear(_ animated: Bool) {
    super.viewDidAppear(animated)

    state.countViewDidAppear += 1

    if state.countViewDidAppear == 1 {

      /// check if this view controller was presented by presentation(modal)
      if parent == nil,
        let addingTransition = transition.adding,
        let presentingViewController = presentingViewController,
        let presentationController = presentationController
      {

        /// presenting as presentation
        /// super.viewDidAppear(animated)

        addingTransition.startTransition(
          context: .init(
            contentView: presentationController.containerView!,
            fromViewController: presentingViewController,
            toViewController: self
          )
        )

      }

    }
  }

//  open override func viewWillDisappear(_ animated: Bool) {
//    super.viewWillDisappear(animated)
//  }
//
//  open func remove(overrideTransition: AnyZStackViewControllerRemovingTransition? = nil) {
//
//  }

}
