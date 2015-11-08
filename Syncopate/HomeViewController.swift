import ObjectiveC
import UIKit

class HomeToSongAnimationController : NSObject, UIViewControllerAnimatedTransitioning, UIViewControllerTransitioningDelegate {
    let duration : NSTimeInterval = 0.5
    let damping : CGFloat = 0.5
    let songView : UIView

    var maximizing = true
    var originalFrame : CGRect?
    var originalSuperview : UIView?

    init(songView: UIView) {
        self.songView = songView
    }

    func transitionDuration(transitionContext: UIViewControllerContextTransitioning?) -> NSTimeInterval {
        return duration
    }

    func animateTransition(ctx: UIViewControllerContextTransitioning) {
        let songVC = songViewControllerOf(ctx) as! SongViewController
        let homeVC = homeViewControllerOf(ctx)
        let containerView = ctx.containerView()!

        if (maximizing) {
            containerView.insertSubview(songVC.view, aboveSubview: homeVC.view)
            songVC.view.frame = ctx.containerView()!.convertRect(originalFrame!, fromView: originalSuperview!)
            springlyAnimate({
                songVC.view.frame = containerView.bounds
                songVC.topInset = homeVC.topLayoutGuide.length
            }, completionBlock: { (finished) -> Void in
                assert(!ctx.transitionWasCancelled())
                if (!finished) {
                    self.animateTransition(ctx)
                    return
                }
                ctx.completeTransition(true)
            })
        } else {
            let originalSuperview = self.originalSuperview!
            containerView.insertSubview(homeVC.view, belowSubview: songVC.view)
            springlyAnimate({
                songVC.view.frame = ctx.containerView()!.convertRect(self.originalFrame!, fromView: originalSuperview)
                songVC.topInset = 0
            }, completionBlock: { (finished) -> Void in
                assert(!ctx.transitionWasCancelled())
                if (!finished) {
                    self.animateTransition(ctx)
                    return
                }

                ctx.completeTransition(true)
                songVC.view.frame = self.originalFrame!
                originalSuperview.addSubview(songVC.view)
            })
        }
    }

    func springlyAnimate(animationBlock: () -> Void, completionBlock: (Bool) -> Void) {
        UIView.animateWithDuration(
            duration,
            delay: 0,
            usingSpringWithDamping: damping,
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
            willPresent()
            return self
    }

    func animationControllerForDismissedController(dismissed: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        willDismiss()
        return self
    }

    func willPresent() {
        maximizing = true
        originalFrame = songView.frame
        originalSuperview = songView.superview!
    }

    func willDismiss() {
        maximizing = false
    }

    private func songViewControllerOf(ctx: UIViewControllerContextTransitioning) -> UIViewController {
        let key = (maximizing ? UITransitionContextToViewControllerKey : UITransitionContextFromViewControllerKey)
        let vc = ctx.viewControllerForKey(key)!
        return vc
    }

    private func homeViewControllerOf(ctx: UIViewControllerContextTransitioning) -> UIViewController {
        let key = (!maximizing ? UITransitionContextToViewControllerKey : UITransitionContextFromViewControllerKey)
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
        view.addSubview(songFaun.view)
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

        title = "Syncopate"
        view = scrollView
        navigationController!.delegate = self

        prepareModal()
    }

    override func viewWillAppear(animated: Bool) {
        if !preparedSongs {
            prepareSongs()
            preparedSongs = true
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
        let onTap = {
            [unowned self] (controller: SongViewController, presenting: Bool) -> Void in
            if (self.modalFaun == nil && presenting) {
                self.modalFaun = controller
            } else if (self.modalFaun! == controller && !presenting) {
                self.modalFaun = nil
            }
        }

        let song1 = SongViewController(
            song: Song(url: NSURL(string: "https://a.tumblr.com/tumblr_mndqjdrkkq1s1b8mno1_r1.mp3")!),
            onTap: onTap
        )
        let song2 = SongViewController(
            song: Song(url: NSURL(string: "https://a.tumblr.com/tumblr_naqik7VOSl1te74f8o1.mp3")!),
            onTap: onTap
        )
        song1.view.frame = CGRectMake(10, CGFloat(10), view.bounds.size.width - 20, CGFloat(songHeight))
        song2.view.frame = CGRectMake(10, CGFloat(songHeight + 20), view.bounds.size.width - 20, CGFloat(songHeight))
        addFaun(song1)
        addFaun(song2)
    }

    // MARK: transitioning

    func prepareModal() {
        rac_valuesForKeyPath("modalFaun", observer: self).subscribeNext { [weak self] x in
            if let faun = x as? SongViewController {
                self!.navigationController!.pushViewController(faun, animated: true)
            } else {
                self!.navigationController!.popToViewController(self!, animated: true)
            }
        }
    }
}

