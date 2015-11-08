//
//  SongViewController.swift
//  Syncopate
//
//  Created by hao on 8/25/14.
//
//

import UIKit

class SongView : UIView {
    let song : Song
    let titleLabel : UILabel

    required init?(coder: NSCoder) {
        preconditionFailure("no")
    }

    required init(frame: CGRect, song: Song, metadataSignal: RACSignal) {
        self.song = song
        self.titleLabel = UILabel(frame: CGRectMake(20, 20, frame.width - 20, 40))
        super.init(frame: frame)

        titleLabel.text = "Loading..."
        titleLabel.font = UIFont(name: "Avenir Next", size: 18)
        metadataSignal.subscribeNext { [weak self] x in
            let metadata = (x as! [String: String]?)
            if let title = metadata?["title"] {
                self!.titleLabel.text = title
            } else {
                self!.titleLabel.text = "?"
            }
        }

        addSubview(titleLabel)
    }
}

class SongViewController: UIViewController {
    var songView: SongView!
    var topInset: CGFloat {
        didSet {
            songView.frame = CGRectMake(0, topInset, view.bounds.size.width, view.bounds.size.height - topInset)
        }
    }

    let song : Song
    let player : AVPlayer
    let onTap : (SongViewController, Bool) -> Void

    dynamic var playing : Bool
    dynamic var metadata : [String: String]?

    required init?(coder aDecoder: NSCoder) {
        preconditionFailure("no")
    }

    required init(song: Song, onTap: (SongViewController, Bool) -> Void) {
        self.song = song
        self.onTap = onTap

        player = AVPlayer(URL: song.url)
        playing = false
        metadata = nil
        topInset = 0

        super.init(nibName: nil, bundle: nil)

        rac_valuesForKeyPath("player.currentItem.asset.commonMetadata", observer: self).subscribeNext { [weak self] array in
            var metadata : [String: String] = [:]
            for item in (array as! [AVMetadataItem]) {
                if let commonKey = item.commonKey where commonKey != "artwork" && commonKey != "identifier" {
                    metadata[commonKey] = item.stringValue
                }
            }
            self!.metadata = metadata
        }
    }

    override func loadView() {
        view = UIView(frame: CGRectMake(0, 0, 300, 300))
        songView = SongView(
            frame: view.bounds,
            song: song,
            metadataSignal: rac_valuesForKeyPath("metadata", observer: self)
        )

        view.addSubview(songView)
        songView.autoresizingMask = [.FlexibleHeight, .FlexibleWidth]


        rac_valuesForKeyPath("playing", observer: self).subscribeNext {
            [unowned self] x in
            let playing = (x as! NSNumber).boolValue
            self.view.backgroundColor = playing ? UIColor(red: 1.0, green: 0.9, blue: 0.9, alpha: 0.992) : UIColor.whiteColor()
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        let tapGesture = UITapGestureRecognizer(target: self, action: "didTap")
        view.addGestureRecognizer(tapGesture)
    }

    override func didMoveToParentViewController(parent: UIViewController?) {
        if parent == nil {
            player.pause()
            playing = false
            onTap(self, false)
        }
    }

    func didTap() {
        player.play()
        playing = true
        onTap(self, true)
    }
}
