import UIKit

class JournalTimelineCell: UITableViewCell {
    static let identifier = "JournalTimelineCell"

    @IBOutlet weak var cardView: UIView!
    @IBOutlet weak var dateLabel: UILabel!
    @IBOutlet weak var moodLabel: UILabel!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var previewLabel: UILabel!

    private var playButton: UIButton!
    private var onPlayTapped: (() -> Void)?

    override func awakeFromNib() {
        super.awakeFromNib()

        selectionStyle = .none
        contentView.backgroundColor = UIColor(named: "colors/Primary/Dark")

        cardView.backgroundColor = UIColor.white.withAlphaComponent(0.08)
        cardView.layer.cornerRadius = 18
        cardView.layer.borderWidth = 1.0
        cardView.layer.borderColor = UIColor.white.withAlphaComponent(0.18).cgColor
        cardView.clipsToBounds = true

        dateLabel.textColor = UIColor.white.withAlphaComponent(0.75)
        dateLabel.font = .systemFont(ofSize: 13, weight: .medium)

        moodLabel.textColor = UIColor.white
        moodLabel.font = .systemFont(ofSize: 12, weight: .semibold)
        moodLabel.backgroundColor = UIColor(named: "colors/Blue&Shades/blue-400")?.withAlphaComponent(0.9)
        moodLabel.layer.cornerRadius = 10
        moodLabel.clipsToBounds = true

        titleLabel.textColor = .white
        titleLabel.font = .systemFont(ofSize: 19, weight: .bold)

        previewLabel.textColor = UIColor.white.withAlphaComponent(0.9)
        previewLabel.font = .systemFont(ofSize: 15, weight: .regular)

        setupPlayButton()
    }

    private func setupPlayButton() {
        playButton = UIButton(type: .system)
        playButton.translatesAutoresizingMaskIntoConstraints = false
        playButton.setImage(UIImage(systemName: "play.circle.fill"), for: .normal)
        playButton.tintColor = UIColor.white.withAlphaComponent(0.95)
        playButton.isHidden = true
        playButton.addTarget(self, action: #selector(playButtonAction), for: .touchUpInside)

        cardView.addSubview(playButton)

        NSLayoutConstraint.activate([
            playButton.trailingAnchor.constraint(equalTo: cardView.trailingAnchor, constant: -14),
            playButton.topAnchor.constraint(equalTo: cardView.topAnchor, constant: 12),
            playButton.widthAnchor.constraint(equalToConstant: 30),
            playButton.heightAnchor.constraint(equalToConstant: 30)
        ])
    }

    @objc private func playButtonAction() {
        onPlayTapped?()
    }

    func configure(
        dateText: String,
        moodText: String,
        titleText: String,
        previewText: String,
        showPlayButton: Bool = false,
        onPlay: (() -> Void)? = nil
    ) {
        dateLabel.text = dateText
        moodLabel.text = "  \(moodText)  "
        titleLabel.text = titleText
        previewLabel.text = previewText

        playButton.isHidden = !showPlayButton
        onPlayTapped = onPlay
    }
}
