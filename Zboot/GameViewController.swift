//
//  GameViewController.swift
//  Zboot
//
//  Created by Ziga Besal on 29/04/2017.
//  Copyright © 2017 Ziga Besal. All rights reserved.
//

import SAConfettiView
import UIKit

class GameViewController: UIViewController {

    enum GameState {
        case active
        case inactive
        case paused
    }

    static var kvoContext: UInt = 1
    fileprivate let highScoreKey = "highScore"
    fileprivate let showInstructionsKey = "shouldShowInstructions"

    @IBOutlet weak var bucket: UILabel!
    @IBOutlet weak var bucketConstraintX: NSLayoutConstraint!
    @IBOutlet weak var heartsView: HeartsView!
    @IBOutlet weak var scoreLabel: UILabel!
    @IBOutlet weak var gameStateButton: UIButton!
    fileprivate var candyRainTimer: Timer!
    fileprivate var confettiView: SAConfettiView!

    fileprivate var messages: MessagesUtils!
    fileprivate var itemsToFallAtOnce = 1
    fileprivate var highScore: Int!
    fileprivate var interval = 1.0
    fileprivate var score = 0 {
        willSet {
            scoreLabel.text = String(newValue)
            if newValue == 1 {
                messages.removeView(withTag: MessagesUtils.tagInstructionsLabel)
                UserDefaults.standard.set(false, forKey: showInstructionsKey)
            }
            if newValue != 0 && newValue % 10 == 0 {
                setDifficulty(score: newValue)
            }
        }
    }

    var wasPaused = false
    var gameState = GameState.inactive {
        willSet {
            switch newValue {
            case .active:
                wasPaused = gameState == .paused
                startOrResumeGame()
            case .inactive:
                endGame()
            case .paused:
                pauseGame()
            }
        }
    }

    fileprivate var heartsLeft: Int = 0 {
        willSet {
            if newValue == 0 {
                gameState = .inactive
            }
            heartsView.setHearts(numberOfHearts: newValue)

        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        messages = MessagesUtils(parentController: self)
        messages.showStartGame()

        highScore = UserDefaults.standard.integer(forKey: highScoreKey)
        scoreLabel.text = String(highScore)
        confettiView = SAConfettiView(frame: self.view.frame)
        confettiView.type = .Confetti

        guard let startGameButton = messages.getViewWithTag(tag: MessagesUtils.tagStartGameButton)
            as? UIButton else {
                return
        }
        startGameButton.addTarget(self, action: #selector(setGameState), for: .touchUpInside)
    }

    override var prefersStatusBarHidden: Bool {
        return true
    }

    @objc fileprivate func setGameState(sender: UIView) {
        switch sender.tag {
        case MessagesUtils.tagStartGameButton, MessagesUtils.tagRetryGameButton:
            gameState = .active
            break
        default:
            break
        }
    }
	
	@objc fileprivate func shareHighScore() {
		guard let highScore = highScore
		else {
			return
		}
		
		let shareText = "Just reached a new high score of \(highScore) in Zboot! Check it out here: https://apple.co/2D6EYMC"
		let shareController = UIActivityViewController(activityItems: [shareText], applicationActivities: nil)
		present(shareController, animated: true, completion: nil)
	}

    func startOrResumeGame() {
        candyRainTimer = scheduleNewCandyRainTimer(controller: self, withTimeInterval: interval)
        if !wasPaused {
            self.view.subviews.forEach({(view) -> Void in
                if let rainingItem = view as? RainingItem {
                    rainingItem.removeObserver(self, forKeyPath: "wasCaught", context: &GameViewController.kvoContext)
                    rainingItem.removeFromSuperview()
                }
            })
            if confettiView != nil {
                confettiView.stopConfetti()
                confettiView.removeFromSuperview()
            }

            messages.removeView(withTag: MessagesUtils.tagTitleLabel)
            messages.removeView(withTag: MessagesUtils.tagStartGameButton)
            messages.removeView(withTag: MessagesUtils.tagGameOverLabel)
            messages.removeView(withTag: MessagesUtils.tagRetryGameButton)
			messages.removeView(withTag: MessagesUtils.tagShareHighScoreButton)
            score = 0
            heartsLeft = 3
            interval = 1.0
            gameStateButton.isHidden = false
            heartsView.isHidden = false
            itemsToFallAtOnce = 1

            if UserDefaults.standard.bool(forKey: showInstructionsKey) {
                messages.showInstructions()
            }
        } else {
            self.view.subviews.forEach({(view) -> Void in
                if let rainingItem = view as? RainingItem {
                    rainingItem.resume()
                }
            })
        }
    }

    func pauseGame() {
        candyRainTimer.invalidate()
        self.view.subviews.forEach({(view) -> Void in
            if let rainingItem = view as? RainingItem {
                rainingItem.pause()
            }
        })
    }

    fileprivate func endGame() {
        let newHighScore = highScore < score
		messages.showGameOver(didAchieveHighScore: newHighScore)

        if newHighScore {
            highScore = score
            UserDefaults.standard.set(highScore, forKey: highScoreKey)

            // The falling confetti acutally doesn't remain within frame bounds, how bow dah
            // Imagine how confused I had been for the last 30 mins
            confettiView.frame.origin.y = -self.view.frame.size.height
            confettiView.alpha = 0.3
            confettiView.startConfetti()
            self.view.addSubview(confettiView)

            UIView.animate(withDuration: 3.0, delay: 0.0, options: [], animations: {
                self.confettiView.transform = CGAffineTransform.init(translationX: 0, y: self.view.frame.size.height)
                self.confettiView.alpha = 1
            }) { (_) in
                UIView.animate(withDuration: 3.0, delay: 0.0, options: [.curveLinear], animations: {
                    self.confettiView.transform = CGAffineTransform.init(
                        translationX: 0,
                        y: self.view.frame.size.height
                    )
                    self.confettiView.alpha = 0
                }, completion: { (_) in
                    self.confettiView.stopConfetti()
                })
            }
			
			guard let shareButton = messages.getViewWithTag(tag: MessagesUtils.tagShareHighScoreButton) as? UIButton
			else {
				return
			}
			
			shareButton.addTarget(self, action: #selector(shareHighScore), for: .touchUpInside)
        }
        candyRainTimer.invalidate()
        gameStateButton.isHidden = true

        guard let retryButton = messages.getViewWithTag(tag: MessagesUtils.tagRetryGameButton) as? UIButton
		else {
            return
        }

        retryButton.addTarget(self, action: #selector(setGameState), for: .touchUpInside)
    }

    @IBAction func moveBucket(_ sender: UIPanGestureRecognizer) {
        if gameState != .active {
            return
        }
        let translation = sender.translation(in: self.view)
        guard let senderView = sender.view, let rootView = senderView.superview else {
            print("Could not retrieve view")
            return
        }
        let currentConstraintConstantX = bucketConstraintX.constant
        let newConstraintConstantX = currentConstraintConstantX + translation.x

        if newConstraintConstantX > (-(rootView.frame.width/2)+senderView.frame.width/2)
            && newConstraintConstantX < (rootView.frame.width/2)-(senderView.frame.width/2) {
            bucketConstraintX.constant = newConstraintConstantX
            sender.setTranslation(CGPoint.zero, in: self.view)
        }

    }

    @IBAction func changeGameStateClick(_ sender: UIButton) {
        if gameState == .active {
            gameStateButton.setTitle("▶️", for: UIControlState.normal)
            gameState = .paused
        } else {
            gameStateButton.setTitle("⏸", for: UIControlState.normal)
            gameState = .active
        }
    }

    fileprivate func scheduleNewCandyRainTimer(controller: UIViewController,
                                               withTimeInterval interval: TimeInterval) -> Timer {
        guard let viewController = controller as? GameViewController else {
            return Timer()
        }
        return Timer.scheduledTimer(withTimeInterval: interval, repeats: true, block: {(_) in
            var lastDelay: Double = 0.0
            for _ in 0..<viewController.itemsToFallAtOnce {
                // Can't let multiple items fall at the same time,
                // makes it pretty much impossible for the user to catch them
                lastDelay += (Double(arc4random() / UINT32_MAX) + 0.5)
                DispatchQueue.main.asyncAfter(deadline: .now() + lastDelay, execute: {() in
                    let rainingItem = RainingItem(controller: controller)
                    viewController.view.addSubview(rainingItem)
                    rainingItem.fall()
                    rainingItem.addObserver(controller,
                                            forKeyPath: "wasCaught",
                                            options: .new,
                                            context: &GameViewController.kvoContext)
                    if self.gameState != .active {
                        rainingItem.pause()
                    }
                })
            }
        })
    }

    fileprivate func setDifficulty(score: Int) {
        itemsToFallAtOnce = score / 10
        candyRainTimer.invalidate()
        interval = TimeInterval(CGFloat(score / 10) / 2)
        candyRainTimer = scheduleNewCandyRainTimer(controller: self,
                                                   withTimeInterval: interval)
    }

    override public func observeValue(forKeyPath keyPath: String?,
                                      of object: Any?,
                                      change: [NSKeyValueChangeKey : Any]?,
                                      context: UnsafeMutableRawPointer?) {
        guard context == &GameViewController.kvoContext, keyPath=="wasCaught", gameState == .active else {
            return
        }
        guard let wasCaught = change?[.newKey] as? Bool,
            let rainingItem = object as? RainingItem,
            let type = rainingItem.type else {
                return
        }

        if wasCaught {
            switch type {
            case .good:
                messages.showScreenMessage(didCatchCandy: true)
                score+=1
                break
            case .bad:
                messages.showScreenMessage(didCatchCandy: false)
                heartsLeft-=1
            }
        } else if !wasCaught && type == .good {
            messages.showScreenMessage(didCatchCandy: false)
            heartsLeft -= 1
        }
    }

}
