//
//  SolutionTableViewCell.swift
//  SearchPubChem
//
//  Created by Jae Seung Lee on 11/9/19.
//  Copyright © 2019 Jae Seung Lee. All rights reserved.
//

import UIKit

class SolutionTableViewCell: UITableViewCell {

    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
    func populate(with solution: Solution) {
        textLabel?.text = solution.name
        detailTextLabel?.text = getDetailText(from: solution)
    }
    
    func getDetailText(from solution: Solution) -> String? {
        guard let date = solution.created else {
            return nil
        }
        return getString(from: date)
    }
    
    func getString(from date: Date) -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .medium
        dateFormatter.timeStyle = .none
        dateFormatter.locale = Locale.current
        return dateFormatter.string(from: date)
    }
}
