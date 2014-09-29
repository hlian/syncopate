import UIKit

class SpringyAnimator : NSObject, UIViewControllerAnimatedTransitioning {
    var reversed = false
    var lastFrame : CGRect?
    var lastSuperview : UIView?

    func transitionDuration(transitionContext: UIViewControllerContextTransitioning!) -> NSTimeInterval {
        return 0.5
    }

    func animateTransition(transitionContext: UIViewControllerContextTransitioning!) {
        let fromVC = transitionContext.viewControllerForKey(UITransitionContextFromViewControllerKey);
        let fromVCFrame = transitionContext.initialFrameForViewController(fromVC);
        let toVC = transitionContext.viewControllerForKey(UITransitionContextToViewControllerKey);

        if (self.reversed) {
            transitionContext.containerView().addSubview(fromVC.view)
        } else {
            self.lastSuperview = toVC.view.superview
            self.lastFrame = self.lastSuperview!.convertRect(toVC.view.frame, toView: transitionContext.containerView())
            toVC.view.frame = self.lastFrame!
            transitionContext.containerView().addSubview(toVC.view);
        }

        UIView.animateWithDuration(
            self.transitionDuration(transitionContext),
            delay: 0,
            usingSpringWithDamping: 0.7,
            initialSpringVelocity: 0.6,
            options: UIViewAnimationOptions.CurveEaseInOut,
            animations: { () -> Void in
                if (self.reversed) {
                    fromVC.view.frame = self.lastFrame!
                } else {
                    toVC.view.frame = fromVCFrame
                }
            },
            completion: { finished in
                if (self.reversed) {
                    fromVC.view.frame = transitionContext.containerView().convertRect(self.lastFrame!, toView: self.lastSuperview!)
                }
                transitionContext.completeTransition(true)
                if (self.reversed) {
                    self.lastSuperview!.addSubview(fromVC.view)
                }
                self.reversed = !self.reversed
            })
    }
}

class HomeViewController: UIViewController, UIViewControllerTransitioningDelegate {
    let songHeight = 100
    let fauns = NSMutableOrderedSet()
    var modalAnimator = SpringyAnimator()

    dynamic var modalFaun : SongViewController?

    func addFaun(songFaun: SongViewController) {
        assert(!fauns.containsObject(songFaun), "addFaun: already contains")
        fauns.addObject(songFaun)
        self.view.addSubview(songFaun.view)
        songFaun.didMoveToParentViewController(self)

        songFaun.modalPresentationStyle = UIModalPresentationStyle.Custom
        songFaun.transitioningDelegate = self
    }

    override func loadView() {
        UILabel.appearance().font = UIFont(name: "Times", size: 16)

        let scrollView = UIScrollView()
        scrollView.alwaysBounceVertical = true
        scrollView.backgroundColor = UIColor(white: 0.95, alpha: 1)

        self.title = "Syncopate"
        self.view = scrollView

        self.prepareModal()
    }

    override func viewWillAppear(animated: Bool) {
        let onTap = { (controller : SongViewController) -> Void in
            if (self.modalFaun == nil) {
                self.modalFaun = controller
            } else if (self.modalFaun! == controller) {
                self.modalFaun = nil
            }
        }

        self.addFaun(SongViewController(
            frame: CGRectMake(10, CGFloat(10), self.view.bounds.size.width - 20, CGFloat(self.songHeight)),
            song: Song(url: NSURL(string: "https://a.tumblr.com/tumblr_mndqjdrkkq1s1b8mno1_r1.mp3")),
            onTap: onTap
        ))

        self.addFaun(SongViewController(
            frame: CGRectMake(10, CGFloat(self.songHeight + 20), self.view.bounds.size.width - 20, CGFloat(self.songHeight)),
            song: Song(url: NSURL(string: "https://a.tumblr.com/tumblr_naqik7VOSl1te74f8o1.mp3")),
            onTap: onTap
        ))
    }

    // MARK: transitioning

    func prepareModal() {
        self.rac_valuesForKeyPath("modalFaun", observer: self).subscribeNext { [weak self] x in
            if let faun = x as? SongViewController {
                self!.presentViewController(faun, animated: true, completion: nil)
            } else {
                self!.dismissViewControllerAnimated(true, completion: nil)
            }
        }
    }

    func animationControllerForPresentedController(
        presented: UIViewController!,
        presentingController presenting: UIViewController!,
        sourceController source: UIViewController!) -> UIViewControllerAnimatedTransitioning! {
            return self.modalAnimator
    }

    func animationControllerForDismissedController(
        dismissed: UIViewController!) -> UIViewControllerAnimatedTransitioning! {
            return self.modalAnimator
    }
}

