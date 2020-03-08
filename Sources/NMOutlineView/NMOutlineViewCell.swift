//
//  NMOutlineViewCell.swift
//
//  Created by Greg Kopel on 11/05/2017.
//  Copyright © 2017 Netmedia. All rights reserved.
//

import UIKit

@objc(NMOutlineViewCell)
@IBDesignable @objcMembers open class NMOutlineViewCell: UITableViewCell {
    
    // MARK: Properties
    @objc dynamic public var objectValue: Any {
        return itemValue.item
    }
    
    static var observerContext = 0
    
    @objc dynamic internal var itemValue: NMOutlineView.NMItem! {
        didSet {
            itemValue.addObserver(self, forKeyPath: #keyPath(NMOutlineView.NMItem.isExpanded), options: [.new], context: &NMOutlineViewCell.observerContext)
        }
    }
    
    /// Expand/Collapse control
    @objc dynamic public var toggleButton: UIButton! = UIButton(type: .custom)
    
    @IBInspectable @objc dynamic open var isExpanded: Bool = false  {
        didSet {
            UIView.animate(withDuration: CATransaction.animationDuration()) {
                if self.isExpanded {
                    self.toggleImageView.transform = CGAffineTransform(rotationAngle: CGFloat.pi / 2)
                }
                else {
                    self.toggleImageView.transform = .identity
                }
            }
        }
    }

    @objc dynamic public var toggleImageView: UIImageView = UIImageView(frame: .zero)

    /// Cell indentation level
    @IBInspectable @objc dynamic public var nmIndentationLevel: Int = 0
    
    
    @objc dynamic override open var indentationWidth: CGFloat {
        didSet {
            if indentationWidth < buttonSize.width {
                self.indentationWidth = buttonSize.width
            }
            layoutIfNeeded()
        }
    }

    /// Toggle Button is Hidden
    @IBInspectable @objc dynamic open var buttonIsHidden: Bool {
        get {
            return self.toggleButton.isHidden
        }
        set(newValue) {
            self.toggleButton.isHidden = newValue
            self.toggleImageView.isHidden = newValue
            layoutIfNeeded()
        }
    }
    
    /// Toggle Button Size
    @IBInspectable @objc dynamic open var buttonSize: CGSize = CGSize.zero
    {
        didSet {
            toggleImageView.frame.size = buttonSize
            if indentationWidth < buttonSize.width {
                super.indentationWidth = buttonSize.width
                self.indentationWidth = buttonSize.width
            }
            layoutIfNeeded()
        }
    } 


    /// Toggle Button Collapsed Image
    @IBInspectable @objc dynamic public var buttonImage: UIImage? {
        get { return toggleImageView.image }
        set { toggleImageView.image = newValue }
    }
    
    
    /// Toggle Button Tint Color
    ///
    @IBInspectable @objc dynamic open var buttonColor: UIColor!
    // Toggle Button Tint Color
    {
        set(newColor) {
            toggleButton.tintColor = newColor
        }
        get {
            return toggleButton.tintColor
        }
    }

    
    @objc dynamic open var onToggle: ((NMOutlineViewCell) -> Void)?

    
    // MARK: Initializer
    @objc override public init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        configureSubviews()
    }
    
    @objc required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        configureSubviews()
    }
    
    @objc override open func awakeFromNib() {
        super.awakeFromNib()
        configureSubviews()
    }
    
    
    @objc override open func prepareForInterfaceBuilder() {
        super.prepareForInterfaceBuilder()
        configureSubviews()
    }
    
    // MARK: Layout
    
    @objc override open func layoutSubviews() {
        super.layoutSubviews()
        
        contentView.frame = contentViewFrame
        toggleButton.frame = toggleButtonFrame
        toggleImageView.frame = toggleImageFrame
        
        textLabel?.frame.size.width -= leadingIntentation
        
        setNeedsDisplay()
    }
    
    
    // MARK: API
    @objc override open func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
    @objc open func update(with item: Any) {

    }
    
    
    @IBAction @objc func toggleButtonAction(sender: UIButton) {
        if let onToggle = self.onToggle {
            onToggle(self)
        }
    }
    
    open override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        if context == &NMOutlineViewCell.observerContext {
            guard let item = object as? NMOutlineView.NMItem else { return }
            self.isExpanded = item.isExpanded
        }
        
    }
    
    //MARK:- Private
    private var leadingIntentation : CGFloat {
        return CGFloat(self.nmIndentationLevel + (self.toggleButton.isHidden ? 0 : 1)) * self.indentationWidth
    }
    private var contentViewFrame : CGRect {
        let indentationX = leadingIntentation
        return CGRect(x: indentationX, y: 0, width: bounds.size.width - indentationX, height: bounds.size.height)
    }
    private var toggleButtonFrame : CGRect {
        return CGRect(x: 0, y: 0, width: leadingIntentation + buttonSize.width, height: bounds.size.height)
    }
    private var toggleImageFrame : CGRect {
        return CGRect(x:layoutMargins.left + leadingIntentation - buttonSize.width - 4, y: (bounds.size.height - buttonSize.height)/2.0, width: buttonSize.width, height: buttonSize.height).integral
    }
    private func configureSubviews() {
        if self.buttonSize == CGSize.zero {
            self.buttonSize = CGSize(width: 19, height: 19)
        }
        if self.indentationWidth == 0 {
            self.indentationWidth = 27
        }
        if self.buttonImage == nil {
            self.buttonImage = UIImage(named: "arrowtriangle.right.fill")
        }
        self.buttonIsHidden = false
        self.toggleImageView.frame = toggleImageFrame
        self.toggleImageView.contentMode  = .center
        self.addSubview(toggleImageView)
        
        self.toggleButton.backgroundColor = .clear // toggleButton is a touch target
        self.toggleButton.addTarget(self, action: #selector(toggleButtonAction(sender:)), for: .primaryActionTriggered)
        self.addSubview(toggleButton)
        self.contentView.frame = contentViewFrame
        self.toggleButton.frame = toggleButtonFrame
        self.isExpanded = false
    }
}

