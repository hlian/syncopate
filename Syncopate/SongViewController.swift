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

    required init(coder: NSCoder) {
        assertionFailure("no")
    }

    required init(frame: CGRect, song: Song, playingSignal: RACSignal) {
        self.song = song

        super.init(frame: frame)

        playingSignal.subscribeNext({ [weak self] x in
            let playing = (x as NSNumber).boolValue
            self!.backgroundColor = playing ? UIColor.blueColor() : UIColor.whiteColor();
        });
    }
}

class SongViewController: UIViewController {
    let song : Song
    let player : AVPlayer
    let frame : CGRect
    let onTap : SongViewController -> Void
    dynamic var playing : Bool

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

        super.init(nibName: nil, bundle: nil)

        self.rac_valuesForKeyPath("player.currentItem.asset.commonMetadata", observer: self).subscribeNext { [weak self] array in
            for item in (array as [AVMetadataItem]) {
                if (item.commonKey != "artwork" && item.commonKey != "identifier") {
                    println(self!.hash, item.stringValue)
                }
            }
        }
    }

    override func loadView() {
        self.view = SongView(
            frame: self.frame,
            song: self.song,
            playingSignal: self.rac_valuesForKeyPath("playing", observer: self))
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        let tapGesture = UITapGestureRecognizer(target: self, action: "didTap")
        self.view.backgroundColor = UIColor.whiteColor()
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
