//
//  CountryOutlineViewCell.swift
//  OutlineView
//
//  Created by  on 12/5/19.
//  Copyright © 2019 Netmedia. All rights reserved.
//

#if os(iOS) || targetEnvironment(macCatalyst)
import UIKit
#endif
import NMOutlineView

@IBDesignable @objcMembers class CountryOutlineViewCell: NMOutlineViewCell {

    @IBOutlet @objc dynamic weak var countryFlag: UIImageView!
    
    @IBOutlet @objc dynamic weak var countryName: UILabel!
    
    @IBOutlet @objc dynamic weak var regionsCount: UILabel!
    

}