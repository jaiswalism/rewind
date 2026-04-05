//
//  CommentSheetViewController.swift
//  Rewind
//
//  Created by Shyam on 27/11/25.
//

import UIKit
import Combine
import Foundation

class CommentSheetViewController: UIViewController {
    // MARK: - Properties
    var postId: String!
    var communityViewModel: CommunityViewModel!
    private var cancellables = Set<AnyCancellable>()

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

    private let activityIndicator: UIActivityIndicatorView = {
        let indicator = UIActivityIndicatorView(style: .medium)
        indicator.translatesAutoresizingMaskIntoConstraints = false
        indicator.color = .white
        indicator.hidesWhenStopped = true
        return indicator
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

    private let commentInputView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.backgroundColor = UIColor(named: "colors/Primary/Dark :hover")
        return view
    }()

    private let inputTextField = UITextField()
    private let sendButton = UIButton(type: .system)

    override func viewDidLoad() {
        super.viewDidLoad()
        commentsTableView.dataSource = self
        commentsTableView.register(CommentTableViewCell.self, forCellReuseIdentifier: CommentTableViewCell.reuseIdentifier)
        closeButton.addTarget(self, action: #selector(dismissView), for: .touchUpInside)
        setupUI()
        setupInputViewContent()
        bindViewModel()
        fetchComments()
    }

    private func bindViewModel() {
        communityViewModel.$comments
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.commentsTableView.reloadData()
            }
            .store(in: &cancellables)
    }

    private func fetchComments() {
        guard let postId = postId, let uuid = UUID(uuidString: postId) else { return }
        activityIndicator.startAnimating()
        Task {
            await communityViewModel.fetchComments(postId: uuid)
            await MainActor.run {
                self.activityIndicator.stopAnimating()
            }
        }
    }

    // ...existing code...

    @objc private func sendComment() {
        guard let text = inputTextField.text, !text.isEmpty, let postId = postId, let uuid = UUID(uuidString: postId) else { return }
        sendButton.isEnabled = false
        Task {
            do {
                _ = try await communityViewModel.addComment(postId: uuid, text: text)
                await MainActor.run {
                    self.sendButton.isEnabled = true
                    self.inputTextField.text = ""
                    let count = self.communityViewModel.comments.count
                    if count > 0 {
                        let indexPath = IndexPath(row: count - 1, section: 0)
                        self.commentsTableView.scrollToRow(at: indexPath, at: .bottom, animated: true)
                    }
                }
            } catch {
                await MainActor.run {
                    self.sendButton.isEnabled = true
                    
                    let alert = UIAlertController(title: "Failed to Post", message: error.localizedDescription, preferredStyle: .alert)
                    alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
                    self.present(alert, animated: true)
                }
            }
        }
    }
    
    // MARK: - Setup
    private func setupUI() {
        view.backgroundColor = UIColor(named: "colors/Primary/Dark :hover") ?? .black
        
        view.addSubview(titleLabel)
        view.addSubview(closeButton)
        view.addSubview(commentsTableView)
        view.addSubview(commentInputView)
        view.addSubview(activityIndicator)
        
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
            
            // Activity Indicator
            activityIndicator.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            activityIndicator.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            
            // Comment Input Bar (Fixed to the bottom)
            commentInputView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            commentInputView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            commentInputView.bottomAnchor.constraint(equalTo: view.keyboardLayoutGuide.topAnchor), // Keyboard support
            
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
        sendButton.tintColor = .white
        sendButton.addTarget(self, action: #selector(sendComment), for: .touchUpInside)

        // Add to the input view
        commentInputView.addSubview(inputTextField)
        commentInputView.addSubview(sendButton)
        
        NSLayoutConstraint.activate([
            // Input View Height (dynamic based on content but min height)
            commentInputView.heightAnchor.constraint(greaterThanOrEqualToConstant: 60),

            // Input Text Field
            inputTextField.leadingAnchor.constraint(equalTo: commentInputView.leadingAnchor, constant: 16),
            inputTextField.topAnchor.constraint(equalTo: commentInputView.topAnchor, constant: 10),
            inputTextField.trailingAnchor.constraint(equalTo: sendButton.leadingAnchor, constant: -8),
            inputTextField.heightAnchor.constraint(equalToConstant: 40),
            inputTextField.bottomAnchor.constraint(equalTo: commentInputView.bottomAnchor, constant: -10),

            // Send Button
            sendButton.trailingAnchor.constraint(equalTo: commentInputView.trailingAnchor, constant: -16),
            sendButton.centerYAnchor.constraint(equalTo: inputTextField.centerYAnchor),
            sendButton.widthAnchor.constraint(equalToConstant: 60),
        ])
    }
    
    // MARK: - Actions
    @objc private func dismissView() {
        dismiss(animated: true, completion: nil)
    }
}

// MARK: - UITableViewDataSource
extension CommentSheetViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return communityViewModel.comments.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: CommentTableViewCell.reuseIdentifier, for: indexPath) as? CommentTableViewCell else {
            return UITableViewCell()
        }
        let comment = communityViewModel.comments[indexPath.row]
        cell.configure(with: comment)
        return cell
    }
}
