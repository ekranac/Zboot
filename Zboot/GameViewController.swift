//
//  GameViewController.swift
//  Zboot
//
//  Created by Ziga Besal on 29/04/2017.
//  Copyright © 2017 Ziga Besal. All rights reserved.
//

import UIKit

class GameViewController: UIViewController {
    
    @IBOutlet weak var bucket: UILabel!
    
    fileprivate var gameIsActive: Bool!

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        gameIsActive = true
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override var prefersStatusBarHidden: Bool {
        return true
    }

    @IBAction func moveBucket(_ sender: UIPanGestureRecognizer) {
        if !gameIsActive {
            return
        }
        let translation = sender.translation(in: self.view)
        guard let senderView = sender.view, let rootView = senderView.superview else {
            print("Could not retrieve view")
            return
        }
        let currentOriginPositionX = senderView.frame.origin.x
        let newOriginPositionX = currentOriginPositionX + translation.x
        
        if newOriginPositionX > 0.0 && (newOriginPositionX+senderView.frame.width) < rootView.frame.width {
            senderView.center = CGPoint(x: senderView.center.x+translation.x, y: senderView.center.y)
            sender.setTranslation(CGPoint.zero, in: self.view)
        }

    }

}

