//
//  CommentTableViewCell.swift
//  Rewind
//
//  Created by Shyam on 27/11/25.
//

import UIKit

class CommentTableViewCell: UITableViewCell {
    
    static let reuseIdentifier = "CommentCell"
    
    // MARK: - UI Components
    
    private let avatarImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        let config = UIImage.SymbolConfiguration(pointSize: 32, weight: .regular)
        imageView.image = UIImage(systemName: "person.crop.circle.fill", withConfiguration: config)
        imageView.tintColor = UIColor.white.withAlphaComponent(0.7)
        return imageView
    }()
    
    private let commentTextLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.numberOfLines = 0
        label.font = UIFont.systemFont(ofSize: 15)
        label.textColor = .white
        return label
    }()
    
    // MARK: - Init
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - UI Setup
    
    private func setupUI() {
        backgroundColor = .clear
        selectionStyle = .none
        
        contentView.addSubview(avatarImageView)
        contentView.addSubview(commentTextLabel)
        
        NSLayoutConstraint.activate([
            avatarImageView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            avatarImageView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 12),
            avatarImageView.widthAnchor.constraint(equalToConstant: 32),
            avatarImageView.heightAnchor.constraint(equalToConstant: 32),
            
            commentTextLabel.leadingAnchor.constraint(equalTo: avatarImageView.trailingAnchor, constant: 12),
            commentTextLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            commentTextLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 12),
            commentTextLabel.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -12)
        ])
    }
    
    // MARK: - Configuration
    
    public func configure(with comment: Comment) {
        let usernameAttr: [NSAttributedString.Key: Any] = [
            .font: UIFont.boldSystemFont(ofSize: 15),
            .foregroundColor: UIColor.white
        ]
        let commentAttr: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 15),
            .foregroundColor: UIColor.white.withAlphaComponent(0.9)
        ]
        let timestampAttr: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 13),
            .foregroundColor: UIColor.white.withAlphaComponent(0.6)
        ]

        let attributedString = NSMutableAttributedString(string: "\(comment.username)  ", attributes: usernameAttr)
        attributedString.append(NSAttributedString(string: comment.commentText, attributes: commentAttr))
        attributedString.append(NSAttributedString(string: "\n\(comment.timestamp)", attributes: timestampAttr))

        commentTextLabel.attributedText = attributedString
    }
}
