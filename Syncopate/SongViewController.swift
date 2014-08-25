//
//  SongViewController.swift
//  Syncopate
//
//  Created by hao on 8/25/14.
//
//

import UIKit

class SongViewController: UIViewController {
    let song : Song
    let player : AVPlayer

    var index : Int = 0
    var songFrame : CGRect = CGRectMake(0, 0, 0, 0)

    required init(coder aDecoder: NSCoder) {
        assertionFailure("no")
    }

    required init(song: Song) {
        self.song = song
        self.player = AVPlayer.playerWithURL(self.song.url) as AVPlayer

        super.init(nibName: nil, bundle: nil)

        self.rac_valuesForKeyPath("player.currentItem.asset.commonMetadata", observer: self).subscribeNext { array in
            for item in (array as [AVMetadataItem]) {
                if (item.commonKey != "artwork" && item.commonKey != "identifier") {
                    println(self.hash, item.stringValue)
                }
            }
        }
    }

    override func loadView() {
        self.view = UIView()
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
            self.view.backgroundColor = UIColor.blueColor().colorWithAlphaComponent(0.1)
        } else {
            self.player.pause()
            self.view.backgroundColor = UIColor.whiteColor()
        }
    }
}
