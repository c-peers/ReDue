//
//  ModalInfoView.swift
//  ReDue
//
//  Created by Chase Peers on 11/16/17.
//  Copyright © 2017 Chase Peers. All rights reserved.
//

import UIKit

class ModalInfoView: UIView {
    
    @IBOutlet weak var image: UIImageView!
    @IBOutlet weak var title: UILabel!
    @IBOutlet weak var detail: UILabel!
    
    @IBOutlet weak var imageToTitleSpace: NSLayoutConstraint!
    
    private var length: Double?
    private var duration: Double?
    private let nibName = "ModalInfoView"
    private var contentView: UIView!
    private var timer: Timer?
    
    // Set Up View
    override init(frame: CGRect) {
        // For use in code
        super.init(frame: frame)
        setUpView()
    }
    
    required init?(coder aDecoder: NSCoder) {
        // For use in Interface Builder
        super.init(coder: aDecoder)
        setUpView()
    }
    
    func setUpView() {
        let bundle = Bundle(for: type(of: self))
        let nib = UINib(nibName: self.nibName, bundle: bundle)
        self.contentView = nib.instantiate(withOwner: self, options: nil).first as! UIView
        addSubview(contentView)
        
        contentView.center = self.center
        contentView.autoresizingMask = []
        contentView.translatesAutoresizingMaskIntoConstraints = true
        contentView.alpha = 0.0
        
        title.text = ""
        detail.text = ""
        length = 1
        duration = 0.3
    }
    
    // Provide functions to update view
    func set(image: UIImage) {
        self.image.image = image
    }
    
    func set(title text: String) {
        self.title.text = text
    }
    
    func set(detail text: String) {
        self.detail.text = text
    }
    
    func set(length: Double) {
        self.length = length
    }
    
    func set(animationDuration: Double) {
        self.duration = animationDuration
    }
    
    func checkDetailText() {
        if self.detail.text == "" {
            imageToTitleSpace.constant = 25
        }
    }
    // Allow view to control itself
    override func layoutSubviews() {
        // Rounded corners
        self.layoutIfNeeded()
        self.contentView.layer.masksToBounds = true
        self.contentView.clipsToBounds = true
        self.contentView.layer.cornerRadius = 10
    }
    
    override func didMoveToSuperview() {
        
        checkDetailText()
        
        // Fade in when added to superview
        // Then add a timer to remove the view
        guard let length = self.length else { return }
        guard let duration = self.duration else { return }
        UIView.animate(withDuration: duration, animations: {
            self.contentView.alpha = 1.0
            //self.contentView.transform = CGAffineTransform.identity
        }) { _ in
            self.timer = Timer.scheduledTimer(timeInterval: TimeInterval(length), target: self, selector: #selector(self.removeSelf), userInfo: nil, repeats: false)
        }
    }
    
    @objc func removeSelf() {
        // Animate removal of view
        guard let duration = self.duration else { return }
        UIView.animate(withDuration: duration, animations: {
            self.contentView.alpha = 0.0
        }) { _ in
            self.removeFromSuperview()
        }
    }
    
}

