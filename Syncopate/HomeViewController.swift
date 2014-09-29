import UIKit

class HomeViewController: UIViewController {
    let songHeight = 100
    let fauns = NSMutableOrderedSet()

    func addFaun(songFaun: SongViewController) {
        assert(!fauns.containsObject(songFaun), "addFaun: already contains")
        fauns.addObject(songFaun)
        self.updateFaunLocations()
    }

    func updateFaunLocations() {
        for i in 0...(self.fauns.count - 1) {
            let songFaun = fauns[i] as SongViewController
            if (songFaun.index != i) {
                songFaun.index = i
            }
        }
    }

    override func loadView() {
        let scrollView = UIScrollView()
        scrollView.alwaysBounceVertical = true
        scrollView.backgroundColor = UIColor(white: 0.95, alpha: 1)

        self.title = "Syncopate"
        self.view = scrollView
    }

    override func viewWillAppear(animated: Bool) {
        self.addFaun(SongViewController(
            frame: CGRectMake(10, CGFloat(10), self.view.bounds.size.width - 20, CGFloat(self.songHeight)),
            song: Song(url: NSURL(string: "https://a.tumblr.com/tumblr_mndqjdrkkq1s1b8mno1_r1.mp3"))))
        self.addFaun(SongViewController(
            frame: CGRectMake(10, CGFloat(self.songHeight + 20), self.view.bounds.size.width - 20, CGFloat(self.songHeight)),
            song: Song(url: NSURL(string: "https://a.tumblr.com/tumblr_naqik7VOSl1te74f8o1.mp3"))))

        for i in 0...(self.fauns.count - 1) {
            let songFaun = fauns[i] as SongViewController
            self.view.addSubview(songFaun.view)
            songFaun.didMoveToParentViewController(self)
        }
    }
}

