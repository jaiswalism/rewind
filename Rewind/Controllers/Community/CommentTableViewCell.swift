//
//  CommentTableViewCell.swift
//  Rewind
//
//  Created by Shyam on 27/11/25.
//

import UIKit

class CommentTableViewCell: UITableViewCell {
    
    static let reuseIdentifier = "CommentCell"
    
    private let bubbleView: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.white.withAlphaComponent(0.1)
        view.layer.cornerRadius = 12
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    private let usernameLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 14, weight: .bold)
        label.textColor = .white
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let commentLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 15, weight: .regular)
        label.textColor = .white
        label.numberOfLines = 0
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let timeLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 12, weight: .regular)
        label.textColor = UIColor.white.withAlphaComponent(0.6)
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupUI() {
        backgroundColor = .clear
        selectionStyle = .none
        
        contentView.addSubview(bubbleView)
        bubbleView.addSubview(usernameLabel)
        bubbleView.addSubview(commentLabel)
        bubbleView.addSubview(timeLabel)
        
        NSLayoutConstraint.activate([
            bubbleView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 5),
            bubbleView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -5),
            bubbleView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            bubbleView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            
            usernameLabel.topAnchor.constraint(equalTo: bubbleView.topAnchor, constant: 10),
            usernameLabel.leadingAnchor.constraint(equalTo: bubbleView.leadingAnchor, constant: 12),
            
            timeLabel.centerYAnchor.constraint(equalTo: usernameLabel.centerYAnchor),
            timeLabel.trailingAnchor.constraint(equalTo: bubbleView.trailingAnchor, constant: -12),
            
            commentLabel.topAnchor.constraint(equalTo: usernameLabel.bottomAnchor, constant: 4),
            commentLabel.leadingAnchor.constraint(equalTo: bubbleView.leadingAnchor, constant: 12),
            commentLabel.trailingAnchor.constraint(equalTo: bubbleView.trailingAnchor, constant: -12),
            commentLabel.bottomAnchor.constraint(equalTo: bubbleView.bottomAnchor, constant: -10)
        ])
    }
    
    func configure(with comment: Comment) {
        // Handle anonymous or user-provided names
        if let user = comment.user {
             usernameLabel.text = user.name
        } else {
             usernameLabel.text = "Anonymous"
        }
        
        commentLabel.text = comment.commentText
        // Time logic (placeholder)
        timeLabel.text = "Just now" 
    }
}
