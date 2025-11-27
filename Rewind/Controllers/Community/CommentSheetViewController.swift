//
//  CommentSheetViewController.swift
//  Rewind
//
//  Created by Shyam on 27/11/25.
//

import UIKit

// NEW: Structure for holding comment data
struct Comment {
    let username: String
    let commentText: String
    let timestamp: String
}

class CommentSheetViewController: UIViewController {
    
    // MARK: - UI Components
    private let titleLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.text = "Comments"
        label.font = UIFont.boldSystemFont(ofSize: 18)
        label.textColor = .white
        return label
    }()
    
    private let closeButton: UIButton = {
        let button = UIButton(type: .system)
        button.translatesAutoresizingMaskIntoConstraints = false
        let config = UIImage.SymbolConfiguration(pointSize: 20, weight: .semibold)
        button.setImage(UIImage(systemName: "xmark", withConfiguration: config), for: .normal)
        button.tintColor = .white
        return button
    }()
    
    private let commentsTableView: UITableView = {
        let tableView = UITableView()
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.backgroundColor = .clear
        tableView.separatorStyle = .none
        tableView.estimatedRowHeight = 60
        tableView.rowHeight = UITableView.automaticDimension
        return tableView
    }()
    
    // The gray bar at the bottom
    private let commentInputView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        // FIX: Set color to Dark:hover
        view.backgroundColor = UIColor(named: "colors/Primary/Dark :hover")
        return view
    }()
    
    // NEW: Input field components
    private let inputTextField = UITextField()
    private let sendButton = UIButton(type: .system)

    // NEW: Sample Data
    private var sampleComments: [Comment] = [
        Comment(username: "User123", commentText: "This is so true! We forget the simple things in life. Thanks for sharing.", timestamp: "2h"),
        Comment(username: "GratitudeGiver", commentText: "Love this energy! Keep rewinding to the good stuff. 🙏", timestamp: "5h"),
        Comment(username: "Aviral Sharma", commentText: "Just wanted to say thank you for the feedback on the app features!", timestamp: "1d")
    ]
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Assign delegates and register cell
        commentsTableView.dataSource = self
        commentsTableView.register(CommentTableViewCell.self, forCellReuseIdentifier: CommentTableViewCell.reuseIdentifier)
        
        // Add targets
        closeButton.addTarget(self, action: #selector(dismissView), for: .touchUpInside)
        
        setupUI()
        setupInputViewContent()
    }
    
    // MARK: - Setup
    private func setupUI() {
        // FIX: Set view background color to Dark:hover
        view.backgroundColor = UIColor(named: "colors/Primary/Dark :hover")
        
        view.addSubview(titleLabel)
        view.addSubview(closeButton)
        view.addSubview(commentsTableView)
        view.addSubview(commentInputView)
        
        setupConstraints()
    }
    
    private func setupConstraints() {
        let safeArea = view.safeAreaLayoutGuide
        
        NSLayoutConstraint.activate([
            // Close Button
            closeButton.topAnchor.constraint(equalTo: safeArea.topAnchor, constant: 16),
            closeButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            closeButton.widthAnchor.constraint(equalToConstant: 44),
            closeButton.heightAnchor.constraint(equalToConstant: 44),
            
            // Title Label (Centered)
            titleLabel.centerYAnchor.constraint(equalTo: closeButton.centerYAnchor),
            titleLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            
            // Comment Input Bar (Fixed to the bottom)
            commentInputView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            commentInputView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            commentInputView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            
            // Comments Table View
            commentsTableView.topAnchor.constraint(equalTo: closeButton.bottomAnchor, constant: 10),
            commentsTableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            commentsTableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            commentsTableView.bottomAnchor.constraint(equalTo: commentInputView.topAnchor),
        ])
    }
    
    private func setupInputViewContent() {
        // Setup text field
        inputTextField.translatesAutoresizingMaskIntoConstraints = false
        inputTextField.attributedPlaceholder = NSAttributedString(
            string: "Add a comment...",
            attributes: [NSAttributedString.Key.foregroundColor: UIColor.white.withAlphaComponent(0.7)]
        )
        inputTextField.textColor = .white
        inputTextField.backgroundColor = UIColor.white.withAlphaComponent(0.1)
        inputTextField.layer.cornerRadius = 20
        inputTextField.clipsToBounds = true
        // Add padding
        let paddingView = UIView(frame: CGRect(x: 0, y: 0, width: 15, height: 40))
        inputTextField.leftView = paddingView
        inputTextField.leftViewMode = .always
        
        // Setup send button
        sendButton.translatesAutoresizingMaskIntoConstraints = false
        sendButton.setTitle("Send", for: .normal)
        sendButton.titleLabel?.font = UIFont.boldSystemFont(ofSize: 16)
        sendButton.tintColor = UIColor(named: "colors/Primary/Light")
        sendButton.addTarget(self, action: #selector(sendComment), for: .touchUpInside)

        // Add to the input view
        commentInputView.addSubview(inputTextField)
        commentInputView.addSubview(sendButton)
        
        let inputArea = commentInputView.safeAreaLayoutGuide

        NSLayoutConstraint.activate([
            // Input Text Field
            inputTextField.leadingAnchor.constraint(equalTo: commentInputView.leadingAnchor, constant: 16),
            inputTextField.topAnchor.constraint(equalTo: commentInputView.topAnchor, constant: 10),
            inputTextField.trailingAnchor.constraint(equalTo: sendButton.leadingAnchor, constant: -8),
            inputTextField.heightAnchor.constraint(equalToConstant: 40),

            // Send Button
            sendButton.trailingAnchor.constraint(equalTo: commentInputView.trailingAnchor, constant: -16),
            sendButton.centerYAnchor.constraint(equalTo: inputTextField.centerYAnchor),
            sendButton.widthAnchor.constraint(equalToConstant: 60),

            // Define the input view's height by pinning the text field's bottom to the safe area bottom.
            inputTextField.bottomAnchor.constraint(equalTo: inputArea.bottomAnchor, constant: -10)
        ])
    }
    
    // MARK: - Actions
    @objc private func dismissView() {
        dismiss(animated: true, completion: nil)
    }
    
    @objc private func sendComment() {
        guard let text = inputTextField.text, !text.isEmpty else { return }
        
        let newComment = Comment(username: "Me", commentText: text, timestamp: "Now")
        sampleComments.append(newComment)
        
        let indexPath = IndexPath(row: sampleComments.count - 1, section: 0)
        commentsTableView.insertRows(at: [indexPath], with: .automatic)
        commentsTableView.scrollToRow(at: indexPath, at: .bottom, animated: true)
        
        inputTextField.text = ""
    }
}

// MARK: - UITableViewDataSource
extension CommentSheetViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return sampleComments.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: CommentTableViewCell.reuseIdentifier, for: indexPath) as? CommentTableViewCell else {
            return UITableViewCell()
        }
        let comment = sampleComments[indexPath.row]
        cell.configure(with: comment)
        return cell
    }
}
