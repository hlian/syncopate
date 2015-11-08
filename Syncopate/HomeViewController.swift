import ObjectiveC
import UIKit

class HomeToSongAnimationController : NSObject, UIViewControllerAnimatedTransitioning, UIViewControllerTransitioningDelegate {
    let duration : NSTimeInterval = 3
    let damping : CGFloat = 0.7
    let songView : UIView

    var maximizing = true
    var originalFrame : CGRect?
    var originalSuperview : UIView?

    init(songView: UIView) {
        self.songView = songView
    }

    func transitionDuration(transitionContext: UIViewControllerContextTransitioning?) -> NSTimeInterval {
        return self.duration
    }

    func animateTransition(ctx: UIViewControllerContextTransitioning) {
        let songVC = self.songViewControllerOf(ctx)
        let homeVC = self.homeViewControllerOf(ctx)
        let containerView = ctx.containerView()!

        if (self.maximizing) {
            containerView.insertSubview(songVC.view, aboveSubview: homeVC.view)
            let frame = songVC.view.frame
            songVC.view.frame = self.originalFrame!
            self.springlyAnimate({ () -> Void in
                songVC.view.frame = frame
            }, completionBlock: { (finished) -> Void in
                assert(!ctx.transitionWasCancelled())
                if (!finished) {
                    self.animateTransition(ctx)
                    return
                }
                ctx.completeTransition(true)
            })
        } else {
            containerView.insertSubview(homeVC.view, belowSubview: songVC.view)
            self.springlyAnimate({ () -> Void in
                songVC.view.frame = ctx.containerView()!.convertRect(self.originalFrame!, fromView: self.originalSuperview!)
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
            options: [UIViewAnimationOptions.CurveLinear, UIViewAnimationOptions.BeginFromCurrentState],
            animations: animationBlock,
            completion: completionBlock)
    }

    func animationControllerForPresentedController(
        presented: UIViewController,
        presentingController presenting: UIViewController,
        sourceController source: UIViewController)-> UIViewControllerAnimatedTransitioning? {
            // The song view controller is weird! Its view is already in the hierarchy; it as a VC
            // is already a child of the home VC.
            self.willPresent()
            return self
    }

    func animationControllerForDismissedController(dismissed: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        self.willDismiss()
        return self
    }

    func willPresent() {
        self.maximizing = true
        self.originalFrame = self.songView.frame
        self.originalSuperview = self.songView.superview
    }

    func willDismiss() {
        self.maximizing = false
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

class HomeViewController: UIViewController, UINavigationControllerDelegate {
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

        let ac = HomeToSongAnimationController(songView: songFaun.view)
        songFaun.transitioningDelegate = ac
        objc_setAssociatedObject(songFaun, &animationControllerKey, ac, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
    }

    override func loadView() {
        UILabel.appearance().font = UIFont(name: "Times", size: 16)

        let scrollView = UIScrollView()
        scrollView.alwaysBounceVertical = true
        scrollView.backgroundColor = UIColor(white: 0.95, alpha: 1)

        self.title = "Syncopate"
        self.view = scrollView
        self.navigationController!.delegate = self

        self.prepareModal()
    }

    override func viewWillAppear(animated: Bool) {
        if (!self.preparedSongs) {
            self.prepareSongs()
            self.preparedSongs = true
        }
    }

    func navigationController(navigationController: UINavigationController, animationControllerForOperation operation: UINavigationControllerOperation, fromViewController fromVC: UIViewController, toViewController toVC: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        if (operation == UINavigationControllerOperation.Push) {
            let ac = toVC.transitioningDelegate as! HomeToSongAnimationController
            ac.willPresent()
            return ac
        } else {
            let ac = fromVC.transitioningDelegate as! HomeToSongAnimationController
            ac.willDismiss()
            return ac
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
                self!.navigationController!.pushViewController(faun, animated: true)
            } else {
                self!.navigationController!.popToViewController(self!, animated: true)
            }
        }
    }
}

