import ObjectiveC
import UIKit

class HomeToSongAnimationController : NSObject, UIViewControllerAnimatedTransitioning, UIViewControllerTransitioningDelegate {
    let duration : NSTimeInterval = 0.5
    let damping : CGFloat = 0.7

    var maximizing = true
    var originalFrame : CGRect?
    var originalSuperview : UIView?

    func transitionDuration(transitionContext: UIViewControllerContextTransitioning) -> NSTimeInterval {
        return self.duration
    }

    func animateTransition(ctx: UIViewControllerContextTransitioning) {
        let songVC = self.songViewControllerOf(ctx)
        let homeVC = self.homeViewControllerOf(ctx)

        if (self.maximizing) {
            // The song view controller is weird! Its view is already in the hierarchy; it as a VC
            // is already a child of the home VC.
            self.originalFrame = songVC.view.frame
            self.originalSuperview = songVC.view.superview

            ctx.containerView().insertSubview(songVC.view, aboveSubview: homeVC.view)
            self.springlyAnimate({ () -> Void in
                songVC.view.frame = homeVC.view.frame
            }, completionBlock: { (finished) -> Void in
                assert(!ctx.transitionWasCancelled())
                if (!finished) {
                    self.animateTransition(ctx)
                    return
                }
                ctx.completeTransition(true)
            })
        } else {
            ctx.containerView().insertSubview(homeVC.view, belowSubview: songVC.view)
            self.springlyAnimate({ () -> Void in
                songVC.view.frame = ctx.containerView().convertRect(self.originalFrame!, fromView: self.originalSuperview!)
            }, completionBlock: { (finished) -> Void in
                assert(!ctx.transitionWasCancelled())
                if (!finished) {
                    self.animateTransition(ctx)
                    return
                }

                ctx.completeTransition(true)
                songVC.view.frame = self.originalFrame!
                self.originalSuperview!.addSubview(songVC.view)
            })
        }
    }

    func springlyAnimate(animationBlock: () -> Void, completionBlock: (Bool) -> Void) {
        UIView.animateWithDuration(
            self.duration,
            delay: 0,
            usingSpringWithDamping: self.damping,
            initialSpringVelocity: 0,
            options: UIViewAnimationOptions.CurveLinear | UIViewAnimationOptions.BeginFromCurrentState,
            animations: animationBlock,
            completion: completionBlock)
    }

    func animationControllerForPresentedController(
            presented: UIViewController,
            presentingController presenting: UIViewController,
            sourceController source: UIViewController)-> UIViewControllerAnimatedTransitioning? {
        self.maximizing = true
        return self
    }

    func animationControllerForDismissedController(dismissed: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        self.maximizing = false
        return self
    }

    private func songViewControllerOf(ctx: UIViewControllerContextTransitioning) -> UIViewController {
        let key = (self.maximizing ? UITransitionContextToViewControllerKey : UITransitionContextFromViewControllerKey)
        let vc = ctx.viewControllerForKey(key)!
        return vc
    }

    private func homeViewControllerOf(ctx: UIViewControllerContextTransitioning) -> UIViewController {
        let key = (!self.maximizing ? UITransitionContextToViewControllerKey : UITransitionContextFromViewControllerKey)
        let vc = ctx.viewControllerForKey(key)!
        return vc
    }
}

class HomeViewController: UIViewController {
    let songHeight = 100
    let fauns = NSMutableOrderedSet()

    var animationControllerKey: Void?
    var preparedSongs = false

    dynamic var modalFaun : SongViewController?

    func addFaun(songFaun: SongViewController) {
        assert(!fauns.containsObject(songFaun), "addFaun: already contains")
        fauns.addObject(songFaun)
        self.view.addSubview(songFaun.view)
        songFaun.didMoveToParentViewController(self)

        songFaun.modalPresentationStyle = UIModalPresentationStyle.Custom

        let ac = HomeToSongAnimationController()
        songFaun.transitioningDelegate = ac
        objc_setAssociatedObject(songFaun, &animationControllerKey, ac, UInt(OBJC_ASSOCIATION_RETAIN_NONATOMIC))
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
        if (!self.preparedSongs) {
            self.prepareSongs()
            self.preparedSongs = true
        }
    }

    func prepareSongs() {
        let onTap = { (controller : SongViewController) -> Void in
            if (self.modalFaun == nil) {
                self.modalFaun = controller
            } else if (self.modalFaun! == controller) {
                self.modalFaun = nil
            }
        }

        self.addFaun(SongViewController(
            frame: CGRectMake(10, CGFloat(10), self.view.bounds.size.width - 20, CGFloat(self.songHeight)),
            song: Song(url: NSURL(string: "https://a.tumblr.com/tumblr_mndqjdrkkq1s1b8mno1_r1.mp3")!),
            onTap: onTap
        ))

        self.addFaun(SongViewController(
            frame: CGRectMake(10, CGFloat(self.songHeight + 20), self.view.bounds.size.width - 20, CGFloat(self.songHeight)),
            song: Song(url: NSURL(string: "https://a.tumblr.com/tumblr_naqik7VOSl1te74f8o1.mp3")!),
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
}

