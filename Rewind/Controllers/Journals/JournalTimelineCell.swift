//
//  JournalTimelineCell.swift
//  Rewind
//
//  Created by Shyam on 26/11/25.
//

import UIKit

class JournalTimelineCell: UITableViewCell {
    static let identifier = "JournalTimelineCell"
    
    // MARK: - Outlets (Connected to JournalTimelineCell.xib)
    @IBOutlet weak var cardView: UIView!
    @IBOutlet weak var timeLabel: UILabel!
    @IBOutlet weak var moodLabel: UILabel!
    @IBOutlet weak var entryTextLabel: UILabel!
    @IBOutlet weak var timelineConnectorTop: UIView!
    @IBOutlet weak var timelineConnectorBottom: UIView!
    @IBOutlet weak var timeCircle: UIView!

    override func awakeFromNib() {
        super.awakeFromNib()
        
        selectionStyle = .none
        
        // Match the background colour of the tableView (colors/Primary/Dark)
        contentView.backgroundColor = UIColor(named: "colors/Primary/Dark")
        
        // Card styling
        cardView.layer.cornerRadius = 16
        cardView.clipsToBounds = true
        
        // Time circle styling
        timeCircle.layer.cornerRadius = timeCircle.bounds.height / 2
        
        // Ensure connectors match the timeline colour (colors/Blue&Shades/blue-400)
        let blue400 = UIColor(named: "colors/Blue&Shades/blue-400")
        timelineConnectorTop.backgroundColor = blue400
        timelineConnectorBottom.backgroundColor = blue400
    }
    
    func configure(time: String, mood: String, entry: String, isFirst: Bool, isLast: Bool) {
        timeLabel.text = time
        moodLabel.text = mood
        entryTextLabel.text = entry
        
        // Control the visibility of the timeline connectors based on cell position
        timelineConnectorTop.isHidden = isFirst
        timelineConnectorBottom.isHidden = isLast
    }
}
