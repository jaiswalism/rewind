//
//  JournalDetailViewViewController.swift
//  Rewind
//
//  Created by Shyam on 11/11/25.
//

import UIKit

class JournalDetailViewViewController: UIViewController {

    var journal: DBJournal?
    
    private let scrollView: UIScrollView = {
        let sv = UIScrollView()
        sv.translatesAutoresizingMaskIntoConstraints = false
        sv.showsVerticalScrollIndicator = false
        return sv
    }()
    
    private let contentView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    private let mainStackView: UIStackView = {
        let stack = UIStackView()
        stack.translatesAutoresizingMaskIntoConstraints = false
        stack.axis = .vertical
        stack.spacing = 24
        stack.alignment = .fill
        return stack
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white
        setupBackground()
        setupBackButton()
        setupUI()
        configureData()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(true, animated: animated)
    }
    
    // MARK: - Setup UI
    
    private func setupBackground() {
        let gradientLayer = CAGradientLayer()
        gradientLayer.frame = view.bounds
        gradientLayer.colors = [
            UIColor(red: 0.85, green: 0.93, blue: 1.0, alpha: 1.0).cgColor, // Vibrant Sky Blue
            UIColor(red: 0.92, green: 0.88, blue: 1.0, alpha: 1.0).cgColor  // Vibrant Lavender
        ]
        gradientLayer.startPoint = CGPoint(x: 0, y: 0)
        gradientLayer.endPoint = CGPoint(x: 1, y: 1)
        view.layer.insertSublayer(gradientLayer, at: 0)
        
        let blurEffect = UIBlurEffect(style: .systemUltraThinMaterialLight)
        let blurView = UIVisualEffectView(effect: blurEffect)
        blurView.frame = view.bounds
        blurView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        view.insertSubview(blurView, at: 1)
        
        view.subviews.forEach { if $0 != blurView && $0.layer != gradientLayer { $0.removeFromSuperview() } }
    }
    
    private func setupBackButton() {
        GlassBackButton.add(to: self, action: #selector(backButtonTapped))
    }
    
    @objc func backButtonTapped() {
        navigationController?.popViewController(animated: true)
    }
    
    private func setupUI() {
        view.addSubview(scrollView)
        scrollView.addSubview(contentView)
        contentView.addSubview(mainStackView)
        
        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 60),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            
            contentView.topAnchor.constraint(equalTo: scrollView.topAnchor),
            contentView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
            contentView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
            contentView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
            contentView.widthAnchor.constraint(equalTo: scrollView.widthAnchor),
            
            mainStackView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 20),
            mainStackView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 24),
            mainStackView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -24),
            mainStackView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -40)
        ])
    }
    
    // loading data
    private func configureData() {
        guard let journal = journal else { return }
        
        // Date Label
        let dateLabel = UILabel()
        let formatter = DateFormatter()
        formatter.dateStyle = .long
        formatter.timeStyle = .short
        let dateString = journal.createdDate.map { formatter.string(from: $0) } ?? journal.createdAt
        
        dateLabel.text = dateString.uppercased()
        dateLabel.font = .systemFont(ofSize: 13, weight: .semibold)
        dateLabel.textColor = UIColor.black.withAlphaComponent(0.5) 
        dateLabel.numberOfLines = 1
        mainStackView.addArrangedSubview(dateLabel)
        
        // Title Label
        let titleLabel = UILabel()
        titleLabel.text = journal.title
        titleLabel.font = .systemFont(ofSize: 34, weight: .bold)
        titleLabel.textColor = .black 
        titleLabel.numberOfLines = 0
        mainStackView.addArrangedSubview(titleLabel)
        
        // 3. Emotion Section
        if let emotion = journal.emotion, !emotion.isEmpty {
            let moodScrollView = UIScrollView()
            moodScrollView.showsHorizontalScrollIndicator = false
            moodScrollView.heightAnchor.constraint(equalToConstant: 40).isActive = true
            
            let moodStack = UIStackView()
            moodStack.axis = .horizontal
            moodStack.spacing = 10
            moodStack.translatesAutoresizingMaskIntoConstraints = false
            
            let pill = createMoodPill(text: emotion)
            moodStack.addArrangedSubview(pill)
            
            moodScrollView.addSubview(moodStack)
            NSLayoutConstraint.activate([
                moodStack.leadingAnchor.constraint(equalTo: moodScrollView.leadingAnchor),
                moodStack.trailingAnchor.constraint(equalTo: moodScrollView.trailingAnchor),
                moodStack.centerYAnchor.constraint(equalTo: moodScrollView.centerYAnchor),
                moodStack.heightAnchor.constraint(equalTo: moodScrollView.heightAnchor)
            ])
            
            mainStackView.addArrangedSubview(moodScrollView)
        }
        
        let bodyContainer = UIView()
        bodyContainer.backgroundColor = UIColor.white.withAlphaComponent(0.4) 
        bodyContainer.layer.cornerRadius = 20
        bodyContainer.layer.borderWidth = 1
        bodyContainer.layer.borderColor = UIColor.white.withAlphaComponent(0.6).cgColor 
        
        let bodyLabel = UILabel()
        bodyLabel.text = journal.content
        bodyLabel.font = .systemFont(ofSize: 17, weight: .regular)
        bodyLabel.textColor = UIColor.black.withAlphaComponent(0.85) 
        bodyLabel.numberOfLines = 0
        bodyLabel.translatesAutoresizingMaskIntoConstraints = false
        
        bodyContainer.addSubview(bodyLabel)
        NSLayoutConstraint.activate([
            bodyLabel.topAnchor.constraint(equalTo: bodyContainer.topAnchor, constant: 20),
            bodyLabel.leadingAnchor.constraint(equalTo: bodyContainer.leadingAnchor, constant: 20),
            bodyLabel.trailingAnchor.constraint(equalTo: bodyContainer.trailingAnchor, constant: -20),
            bodyLabel.bottomAnchor.constraint(equalTo: bodyContainer.bottomAnchor, constant: -20)
        ])
        
        mainStackView.addArrangedSubview(bodyContainer)
        
        // 5. Images Section
        let mediaUrls = journal.mediaUrls ?? []
        if !mediaUrls.isEmpty {
            let imageLabel = UILabel()
            imageLabel.text = "Attached Photos"
            imageLabel.font = .systemFont(ofSize: 18, weight: .bold)
            imageLabel.textColor = .black
            mainStackView.addArrangedSubview(imageLabel)
            
            let imagesScrollView = UIScrollView()
            imagesScrollView.showsHorizontalScrollIndicator = false
            imagesScrollView.heightAnchor.constraint(equalToConstant: 200).isActive = true
            
            let imagesStack = UIStackView()
            imagesStack.axis = .horizontal
            imagesStack.spacing = 12
            imagesStack.translatesAutoresizingMaskIntoConstraints = false
            
            for urlString in mediaUrls {
                let imageView = createImageView(from: urlString)
                imagesStack.addArrangedSubview(imageView)
            }
            
            imagesScrollView.addSubview(imagesStack)
            NSLayoutConstraint.activate([
                imagesStack.leadingAnchor.constraint(equalTo: imagesScrollView.leadingAnchor),
                imagesStack.trailingAnchor.constraint(equalTo: imagesScrollView.trailingAnchor),
                imagesStack.centerYAnchor.constraint(equalTo: imagesScrollView.centerYAnchor),
                imagesStack.heightAnchor.constraint(equalToConstant: 200)
            ])
            
            mainStackView.addArrangedSubview(imagesScrollView)
        }
    }
    
    private func createMoodPill(text: String) -> UIView {
        let container = UIView()
        container.backgroundColor = UIColor(named: "colors/Blue&Shades/blue-400")?.withAlphaComponent(0.1) ?? .systemBlue.withAlphaComponent(0.1)
        container.layer.cornerRadius = 16
        container.layer.borderWidth = 1
        container.layer.borderColor = UIColor(named: "colors/Blue&Shades/blue-400")?.withAlphaComponent(0.2).cgColor ?? UIColor.systemBlue.withAlphaComponent(0.2).cgColor
        
        let label = UILabel()
        label.text = text
        label.font = .systemFont(ofSize: 14, weight: .medium)
        label.textColor = UIColor(named: "colors/Blue&Shades/blue-400") ?? .systemBlue 
        label.translatesAutoresizingMaskIntoConstraints = false
        
        container.addSubview(label)
        NSLayoutConstraint.activate([
            label.topAnchor.constraint(equalTo: container.topAnchor, constant: 8),
            label.bottomAnchor.constraint(equalTo: container.bottomAnchor, constant: -8),
            label.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 16),
            label.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -16)
        ])
        
        return container
    }
    
    private func createImageView(from urlString: String) -> UIView {
        let container = UIView()
        container.translatesAutoresizingMaskIntoConstraints = false
        container.widthAnchor.constraint(equalToConstant: 200).isActive = true
        container.heightAnchor.constraint(equalToConstant: 200).isActive = true
        container.layer.cornerRadius = 16
        container.clipsToBounds = true
        container.backgroundColor = UIColor.black.withAlphaComponent(0.05) 
        
        let imageView = UIImageView()
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.contentMode = .scaleAspectFill
        imageView.image = UIImage(systemName: "photo")
        imageView.tintColor = .black.withAlphaComponent(0.2)
        
        
        container.addSubview(imageView)
        NSLayoutConstraint.activate([
            imageView.topAnchor.constraint(equalTo: container.topAnchor),
            imageView.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            imageView.trailingAnchor.constraint(equalTo: container.trailingAnchor),
            imageView.bottomAnchor.constraint(equalTo: container.bottomAnchor)
        ])
        
        return container
    }
}
