//
//  ViewController.swift
//  Chinese Time
//
//  Created by Leo Liu on 4/17/23.
//

import UIKit

class ViewController: UIViewController {
    
    @IBOutlet weak var watchFace: WatchFaceView?
    
    func newSize(frame: CGSize, idealSize: CGSize) -> CGSize {
        let height: CGFloat
        let width: CGFloat
        if frame.width > frame.height {
            height = min(frame.height, idealSize.width)
            width = min(idealSize.height / idealSize.width * height, frame.width * 0.8)
        } else {
            width = min(frame.width, idealSize.width)
            height = min(idealSize.height / idealSize.width * width, frame.height * 0.8)
        }
        return CGSize(width: width, height: height)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        let screen = UIScreen.main.bounds
        let newSize = newSize(frame: screen.size, idealSize: watchFace!.watchLayout.watchSize)
        watchFace!.frame = CGRect(x: (screen.width - newSize.width) / 2.0, y: (screen.height - newSize.height) / 2.0,
                                  width: newSize.width, height: newSize.height)
        watchFace!.setAutoRefresh()
        // Do any additional setup after loading the view.
    }
    
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        let screen = UIScreen.main.bounds
        let newSize = newSize(frame: screen.size, idealSize: watchFace!.watchLayout.watchSize)
        watchFace!.updateSize(with: CGRect(x: (screen.width - newSize.width) / 2.0, y: (screen.height - newSize.height) / 2.0,
                                           width: newSize.width, height: newSize.height))
        super.traitCollectionDidChange(previousTraitCollection)
    }
}

