//
//  HeartsView.swift
//  Zboot
//
//  Created by Ziga Besal on 06/05/2017.
//  Copyright © 2017 Ziga Besal. All rights reserved.
//

import Foundation
import UIKit

class HeartsView: UIStackView {
    
    fileprivate let maxNumberOfHearts = 3
    
    override init(frame: CGRect) {
        super.init(frame: frame)
    }
    
    required init(coder: NSCoder) {
        super.init(coder: coder)
    }
    
    public func setHearts(numberOfHearts hearts: Int) {
        self.subviews.forEach({ $0.removeFromSuperview() })
        for index in 0..<maxNumberOfHearts {
            let heartLabel = UILabel()
            
            heartLabel.text = hearts > index ? "❤️" : ""
            heartLabel.textAlignment = .center
            heartLabel.font = UIFont(name: "Avenir-Medium", size: 30.0)
            
            heartLabel.translatesAutoresizingMaskIntoConstraints = false
            heartLabel.heightAnchor.constraint(equalToConstant: self.frame.height).isActive = true
            heartLabel.widthAnchor.constraint(equalToConstant:
                self.frame.width / CGFloat(maxNumberOfHearts)).isActive = true
            
            addArrangedSubview(heartLabel)
        }
    }
    
}
