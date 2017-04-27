//
//  EventTableViewCell.swift
//  the-blue-alliance-ios
//
//  Created by Zach Orr on 3/17/17.
//  Copyright © 2017 The Blue Alliance. All rights reserved.
//

import UIKit

class EventTableViewCell: UITableViewCell {

    public var event: Event? {
        didSet {
            nameLabel?.text = event?.name
            locationLabel?.text = event?.locationName
            dateLabel?.text = event?.dateString()
        }
        
    }
    
    @IBOutlet private var nameLabel: UILabel?
    @IBOutlet private var locationLabel: UILabel?
    @IBOutlet private var dateLabel: UILabel?

}