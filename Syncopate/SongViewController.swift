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

    required init(coder: NSCoder) {
        assertionFailure("no")
    }

    required init(frame: CGRect, song: Song, playingSignal: RACSignal, metadataSignal: RACSignal) {
        self.song = song
        self.titleLabel = UILabel(frame: CGRectMake(20, 20, frame.width - 20, 40))
        super.init(frame: frame)

        self.titleLabel.text = "Loading..."
        self.titleLabel.font = UIFont(name: "Avenir Next", size: 18)
        metadataSignal.subscribeNext { [weak self] x in
            let metadata = (x as [String: String]?)
            if let title = metadata?["title"] {
                self!.titleLabel.text = title
            } else {
                self!.titleLabel.text = "?"
            }
        }

        playingSignal.subscribeNext({ [weak self] x in
            let playing = (x as NSNumber).boolValue
            self!.backgroundColor = playing ? UIColor(red: 1.0, green: 0.9, blue: 0.9, alpha: 0.992) : UIColor.whiteColor();
        });


        self.addSubview(self.titleLabel)
    }
}

class SongViewController: UIViewController {
    let song : Song
    let player : AVPlayer
    let frame : CGRect
    let onTap : SongViewController -> Void

    dynamic var playing : Bool
    dynamic var metadata : [String: String]?

    var songFrame : CGRect = CGRectMake(0, 0, 0, 0)

    required init(coder aDecoder: NSCoder) {
        assertionFailure("no")
    }

    required init(frame: CGRect, song: Song, onTap: SongViewController -> Void) {
        self.song = song
        self.player = AVPlayer.playerWithURL(self.song.url) as AVPlayer
        self.frame = frame
        self.onTap = onTap

        self.playing = false
        self.metadata = nil

        super.init(nibName: nil, bundle: nil)

        self.rac_valuesForKeyPath("player.currentItem.asset.commonMetadata", observer: self).subscribeNext { [weak self] array in
            var metadata : [String: String] = [:]
            for item in (array as [AVMetadataItem]) {
                if (item.commonKey != "artwork" && item.commonKey != "identifier") {
                    metadata[item.commonKey] = item.stringValue
                }
            }
            self!.metadata = metadata
        }
    }

    override func loadView() {
        self.view = SongView(
            frame: self.frame,
            song: self.song,
            playingSignal: self.rac_valuesForKeyPath("playing", observer: self),
            metadataSignal: self.rac_valuesForKeyPath("metadata", observer: self)
        )
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        let tapGesture = UITapGestureRecognizer(target: self, action: "didTap")
        self.view.addGestureRecognizer(tapGesture)
    }

    func didTap() {
        if (self.player.rate == 0.0) {
            self.player.play()
            self.playing = true
        } else {
            self.player.pause()
            self.playing = false
        }
        self.onTap(self)
    }
}
