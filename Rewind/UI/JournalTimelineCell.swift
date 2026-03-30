//
//  JournalTimelineCell.swift
//  Rewind
//
//  Created by Shyam on 26/11/25.
//

import UIKit

class JournalTimelineCell: UITableViewCell {
    static let identifier = "JournalTimelineCell"
    
    @IBOutlet weak var cardView: UIView!
    @IBOutlet weak var timeLabel: UILabel!
    @IBOutlet weak var moodLabel: UILabel!
    @IBOutlet weak var entryTextLabel: UILabel!
    @IBOutlet weak var timelineConnectorTop: UIView!
    @IBOutlet weak var timelineConnectorBottom: UIView!
    @IBOutlet weak var timeCircle: UIView!

    // Play Button
    var playButton: UIButton!
    var onPlayTapped: (() -> Void)?
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        selectionStyle = .none
        
        contentView.backgroundColor = UIColor(named: "colors/Primary/Dark")
    
        cardView.backgroundColor = .clear
        cardView.layer.cornerRadius = 16
        cardView.clipsToBounds = true
        
        // Add Blur Effect
        let blurEffect = UIBlurEffect(style: .systemUltraThinMaterialDark) // Or .light depending on theme
        let blurView = UIVisualEffectView(effect: blurEffect)
        blurView.frame = cardView.bounds
        blurView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        blurView.layer.cornerRadius = 16
        blurView.clipsToBounds = true

        cardView.insertSubview(blurView, at: 0)
        
        cardView.layer.borderWidth = 1.0
        cardView.layer.borderColor = UIColor.white.withAlphaComponent(0.2).cgColor
        
        entryTextLabel.font = .systemFont(ofSize: 16, weight: .light)
        entryTextLabel.textColor = .white.withAlphaComponent(0.9)

        timeCircle.layer.cornerRadius = timeCircle.bounds.height / 2
        
        let blue400 = UIColor(named: "colors/Blue&Shades/blue-400")
        timelineConnectorTop.backgroundColor = blue400
        timelineConnectorBottom.backgroundColor = blue400
        
        setupPlayButton()
    }
    
    private func setupPlayButton() {
        playButton = UIButton(type: .system)
        playButton.translatesAutoresizingMaskIntoConstraints = false
        playButton.setImage(UIImage(systemName: "play.circle.fill"), for: .normal)
        playButton.tintColor = .white
        playButton.isHidden = true
        playButton.addTarget(self, action: #selector(playButtonAction), for: .touchUpInside)
        
        cardView.addSubview(playButton)
        
        NSLayoutConstraint.activate([
            playButton.trailingAnchor.constraint(equalTo: cardView.trailingAnchor, constant: -16),
            playButton.topAnchor.constraint(equalTo: cardView.topAnchor, constant: 16),
            playButton.widthAnchor.constraint(equalToConstant: 30),
            playButton.heightAnchor.constraint(equalToConstant: 30)
        ])
    }
    
    @objc private func playButtonAction() {
        onPlayTapped?()
    }
    
    func configure(time: String, mood: String, entry: String, isFirst: Bool, isLast: Bool, showPlayButton: Bool = false, onPlay: (() -> Void)? = nil) {
        timeLabel.text = time
        moodLabel.text = mood
        entryTextLabel.text = entry
        
        timelineConnectorTop.isHidden = isFirst
        timelineConnectorBottom.isHidden = isLast
        
        playButton.isHidden = !showPlayButton
        self.onPlayTapped = onPlay
    }
}
