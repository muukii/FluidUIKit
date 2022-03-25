import UIKit

extension AnyAddingTransition {

  public static var navigationStyle: Self {

    return .init { context in
      
      context.disableFlexibility()
     
      context.toViewController.view.transform = .init(translationX: context.toViewController.view.bounds.width, y: 0)

      if let fromViewController = context.fromViewController {
        fromViewController.view.transform = .identity
      }

      let animator = UIViewPropertyAnimator(duration: 0.6, dampingRatio: 1) {

        context.toViewController.view.transform = .identity

        if let fromViewController = context.fromViewController {
          fromViewController.view.transform = .init(translationX: -fromViewController.view.bounds.width, y: 0)
        }

      }

      animator.addCompletion { _ in
        
        if let fromViewController = context.fromViewController {
          fromViewController.view.transform = .identity
        }

        context.notifyAnimationCompleted()
      }

      animator.startAnimation()

    }

  }

}
