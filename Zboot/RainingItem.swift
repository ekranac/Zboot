//
//  RainingItem.swift
//  Zboot
//
//  Created by Ziga Besal on 06/05/2017.
//  Copyright © 2017 Ziga Besal. All rights reserved.
//

import Foundation
import UIKit

public class RainingItem: UILabel {
    
    fileprivate var controller: GameViewController!
    fileprivate var rootView: UIView!
    
    fileprivate var displayLink: CADisplayLink!
    
    fileprivate let candies = ["🍬", "🍫", "🍩", "🍭", "🍪", "🍦", "🍰", "🍡"]
    fileprivate let fruitsAndVeggies = ["🥔", "🍐", "🥝", "🥑", "🥕", "🍆", "🍋"]
    
    dynamic var wasCaught = false
    fileprivate var isObserved = false
    var type: RainingItemType!
    
    public init(controller: UIViewController) {
        guard let gameController = controller as? GameViewController else {
            super.init(frame: CGRect(x: Double(controller.view.frame.width / 2.0),
                                     y: -35.0,
                                     width: 30.0,
                                     height: 30.0))
            return
        }
        self.controller = gameController
        self.rootView = controller.view
        
        let randomXPosition = Double(arc4random_uniform(
            UInt32(rootView.frame.width - 30.0)))
        super.init(frame: CGRect(x: randomXPosition,
                                 y: -35.0, // Start off the screen, on top
                                 width: 30.0,
                                 height: 30.0))
        self.textAlignment = .center
        self.font = UIFont(name: "Avenir-Medium", size: 30.0)
        let isGood = arc4random_uniform(2) == 1
        if isGood {
            self.text = candies[Int(arc4random_uniform(UInt32(candies.count)))]
            self.type = .good
        } else {
            self.text = fruitsAndVeggies[Int(arc4random_uniform(UInt32(fruitsAndVeggies.count)))]
            self.type = .bad
        }
        
        // Register CADisplayLink to keep track of frame position
        displayLink = CADisplayLink(target: self, selector: #selector(animationDidUpdate))
        displayLink.add(to: .main, forMode: .defaultRunLoopMode)
    }
    
    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    deinit {
        self.removeObserver(self.controller!, forKeyPath: "wasCaught", context: &GameViewController.kvoContext)
    }
    
    func fall() {
        UIView.animate(withDuration: 10.0, animations: {() in
            let translationY = self.rootView.frame.height + 35.0
            let translateTransform = CGAffineTransform.init(translationX: 0.0,
                                                            y: translationY)
            self.transform = translateTransform
        }, completion: { (didNotCatchWithBucket) in
            self.wasCaught = !didNotCatchWithBucket
            if didNotCatchWithBucket {
                self.removeFromSuperview()
            }
            self.displayLink.invalidate()
        })
    }
    
    func animationDidUpdate(displayLink: CADisplayLink) {
        guard let currentFrame = self.layer.presentation()?.frame else {
            return
        }
        
        if currentFrame.origin.y < controller.bucket.frame.origin.y && currentFrame.origin.y > (controller.bucket.frame.origin.y - 20.0) && controller.bucket.frame.intersects(currentFrame) {
            self.removeFromSuperview()
        }
    }
    
    override public func addObserver(_ observer: NSObject, forKeyPath keyPath: String, options: NSKeyValueObservingOptions = [], context: UnsafeMutableRawPointer?) {
        isObserved = true
        super.addObserver(observer, forKeyPath: keyPath, options: options, context: context)
    }
    
    override public func removeObserver(_ observer: NSObject, forKeyPath keyPath: String, context: UnsafeMutableRawPointer?) {
        if !isObserved {
            return
        }
        super.removeObserver(observer, forKeyPath: keyPath, context: context)
        isObserved = false
    }
    
    enum RainingItemType {
        case bad
        case good
    }
}
