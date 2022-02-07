import GeometryKit
import ResultBuilderKit
import UIKit

extension AnyRemovingTransition {

  public static func contextual(
    destinationComponent: ContextualTransitionSourceComponentType,
    destinationMirroViewProvider: AnyMirrorViewProvider
  ) -> Self {

    return .init { context in
      
      let sourceView = context.fromViewController.view!
      
      AnyRemovingInteraction.Contextual.runEnclosing(
        transitionContext: context,
        disclosedView: sourceView,
        destinationComponent: destinationComponent,
        destinationMirroViewProvider: destinationMirroViewProvider,
        gestureVelocity: .zero
      )
      
    }

  }

}

extension AnyRemovingInteraction {
  public enum Contextual {
        
    // TODO: naming
    public static func runEnclosing(
      transitionContext: RemovingTransitionContext,
      disclosedView: UIView,
      destinationComponent: ContextualTransitionSourceComponentType,
      destinationMirroViewProvider: AnyMirrorViewProvider,
      gestureVelocity: CGPoint?
    ) {
      
      let draggingView = disclosedView
      
      let reparentingView = destinationComponent.requestReparentView()
      
      let fromViewMirror = AnyMirrorViewProvider.snapshot(caches: true, viewProvider: { transitionContext.fromViewController.view! }).view()
      
      let maskView = UIView()
      maskView.backgroundColor = .black

      maskView.frame = transitionContext.fromViewController.view.bounds
      fromViewMirror.mask = maskView
      fromViewMirror.alpha = 1
      fromViewMirror.frame = transitionContext.fromViewController.view.frame
                        
      let entrypointSnapshotView = destinationMirroViewProvider.view()
      
      let displayingSubscription = transitionContext.requestDisplayOnTop(.view(reparentingView))

      reparentingView.addSubview(fromViewMirror)
      reparentingView.addSubview(entrypointSnapshotView)
      entrypointSnapshotView.frame = .init(origin: draggingView.frame.origin, size: destinationComponent.contentView.bounds.size)
      entrypointSnapshotView.alpha = 1
      
      transitionContext.fromViewController.view.layer.opacity = 0

      transitionContext.addCompletionEventHandler { _ in
        reparentingView.removeFromSuperview()
        entrypointSnapshotView.removeFromSuperview()
        fromViewMirror.removeFromSuperview()
        displayingSubscription.dispose()
      }

      let translation = Geometry.centerAndScale(
        from: fromViewMirror.frame,
        to: CGRect(
          origin: transitionContext.frameInContentView(for: destinationComponent.contentView).origin,
          size: Geometry.sizeThatAspectFill(
            aspectRatio: fromViewMirror.bounds.size,
            minimumSize: destinationComponent.contentView.bounds.size
          )
        )
      )

      let velocityForAnimation: CGVector = {
        
        guard let gestureVelocity = gestureVelocity else {
          return .zero
        }

        let targetCenter = translation.center
        let delta = CGPoint(
          x: targetCenter.x - draggingView.center.x,
          y: targetCenter.y - draggingView.center.y
        )

        let velocity = CGVector.init(
          dx: gestureVelocity.x / delta.x,
          dy: gestureVelocity.y / delta.y
        )

        return velocity

      }()
      
      Fluid.startPropertyAnimators(
        buildArray {
          Fluid.makePropertyAnimatorsForTranformUsingCenter(
            view: fromViewMirror,
            duration: 0.8,
            position: .custom(translation.center),
            scale: translation.scale,
            velocityForTranslation: velocityForAnimation,
            velocityForScaling: 8
          )
          UIViewPropertyAnimator(duration: 0.6, dampingRatio: 1) {
            transitionContext.contentView.backgroundColor = .clear
          }
          UIViewPropertyAnimator(duration: 0.8, dampingRatio: 0.8) {
            entrypointSnapshotView.frame = transitionContext.frameInContentView(for: destinationComponent.contentView)
            entrypointSnapshotView.alpha = 1
          }
          UIViewPropertyAnimator(duration: 0.6, dampingRatio: 1) {
            fromViewMirror.alpha = 0
          }
          UIViewPropertyAnimator(duration: 0.6, dampingRatio: 1) {
            maskView.frame = transitionContext.fromViewController.view.bounds
            maskView.frame.size.height = destinationComponent.contentView.bounds.height / translation.scale.y
            maskView.layer.cornerRadius = 24
            if #available(iOS 13.0, *) {
              maskView.layer.cornerCurve = .continuous
            } else {
              // Fallback on earlier versions
            }
          }
        },
        completion: {
          transitionContext.notifyAnimationCompleted()
        }
      )
    }
    
    // TODO: naming
    public static func runZoomOut(
      transitionContext: RemovingTransitionContext,
      disclosedView: UIView,
      destinationView: UIView,
      destinationMirroViewProvider: AnyMirrorViewProvider,
      gestureVelocity: CGPoint?
    ) {
      
      let draggingView = disclosedView
      
      let interpolationView = destinationMirroViewProvider.view()

      var targetRect = Geometry.rectThatAspectFit(
        aspectRatio: draggingView.bounds.size,
        boundingRect: transitionContext.frameInContentView(for: destinationView)
      )

      targetRect = targetRect.insetBy(
        dx: targetRect.width / 3,
        dy: targetRect.height / 3
      )

      let translation = Geometry.centerAndScale(
        from: draggingView.bounds,
        to: targetRect
      )

      let velocityForAnimation: CGVector = {
        
        guard let gestureVelocity = gestureVelocity else {
          return .zero
        }

        let targetCenter = translation.center
        let delta = CGPoint(
          x: targetCenter.x - draggingView.center.x,
          y: targetCenter.y - draggingView.center.y
        )

        let velocity = CGVector.init(
          dx: gestureVelocity.x / delta.x,
          dy: gestureVelocity.y / delta.y
        )

        return velocity

      }()

      let velocityForScaling: CGFloat = {

        //                    let gestureVelocity = gesture.velocity(in: gesture.view!)

        // TODO: calculate dynamic velocity
        // set greater than 0, throwing animation would be more clear. like springboard
        return 6

      }()

      var animators: [UIViewPropertyAnimator] = []

      let translationAnimators = Fluid.makePropertyAnimatorsForTranformUsingCenter(
        view: draggingView,
        duration: 0.85,
        position: .custom(translation.center),
        scale: translation.scale,
        velocityForTranslation: velocityForAnimation,
        velocityForScaling: velocityForScaling  //sqrt(pow(velocityForAnimation.dx, 2) + pow(velocityForAnimation.dy, 2))
      )

      let backgroundAnimator = UIViewPropertyAnimator(duration: 0.6, dampingRatio: 1) {
        transitionContext.contentView.backgroundColor = .clear
      }

      animators += translationAnimators + [backgroundAnimator]

      /// handling interpolation view
      do {
        interpolationView.center = .init(
          x: draggingView.frame.minX,
          y: draggingView.frame.minY
        )
        interpolationView.transform = .init(scaleX: 0.5, y: 0.5)

        transitionContext.contentView.addSubview(interpolationView)

        let interpolationViewAnimators =
          Fluid.makePropertyAnimatorsForTranformUsingCenter(
            view: interpolationView,
            duration: 0.85,
            position: .custom(translation.center),
            scale: .init(x: 1, y: 1),
            velocityForTranslation: velocityForAnimation,
            velocityForScaling: velocityForScaling
          )

        let interpolationViewStyleAnimator = UIViewPropertyAnimator(
          duration: 0.85,
          dampingRatio: 1
        ) {
          interpolationView.alpha = 1
        }

        animators += interpolationViewAnimators + [interpolationViewStyleAnimator]
      }

      Fluid.startPropertyAnimators(animators) {
        transitionContext.notifyAnimationCompleted()
      }
      
    }
  }
}
