//
//  PersonalInformationViewController.swift
//  Rewind
//
//  Created on 01/19/26.
//

import UIKit

class PersonalInformationViewController: UIViewController {

    // MARK: - UI Components
    private let scrollView: UIScrollView = {
        let scrollView = UIScrollView()
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.showsVerticalScrollIndicator = false
        scrollView.backgroundColor = .clear
        return scrollView
    }()

    private let contentView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()

    private let backButton: UIButton = {
        let button = UIButton(type: .system)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setImage(UIImage(systemName: "chevron.left"), for: .normal)
        button.tintColor = .white
        button.backgroundColor = UIColor.white.withAlphaComponent(0.2)
        button.layer.cornerRadius = 20
        return button
    }()

    private let titleLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.text = "Personal Information"
        label.font = UIFont.boldSystemFont(ofSize: 22)
        label.textColor = .white
        return label
    }()

    private let avatarContainerView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.isUserInteractionEnabled = true
        return view
    }()
    
    private let avatarImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        imageView.backgroundColor = .white
        imageView.image = UIImage(systemName: "person.crop.circle.fill")
        imageView.tintColor = UIColor(red: 0.4, green: 0.45, blue: 0.95, alpha: 1.0)
        return imageView
    }()
    
    private let editAvatarButton: UIButton = {
        let button = UIButton(type: .system)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.backgroundColor = .white
        button.setImage(UIImage(systemName: "pencil"), for: .normal)
        button.tintColor = UIColor(red: 0.4, green: 0.45, blue: 0.95, alpha: 1.0)
        button.layer.cornerRadius = 18
        button.layer.borderWidth = 3
        button.layer.borderColor = UIColor(red: 0.4, green: 0.45, blue: 0.95, alpha: 1.0).cgColor
        return button
    }()
    
    private var nameTextField: UITextField?
    private var emailTextField: UITextField?
    private var passwordTextField: UITextField?
    private var locationTextField: UITextField?
    private var dobTextField: UITextField?
    
    private var gradientLayer: CAGradientLayer?

    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupActions()
        loadUserData()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        avatarImageView.layer.cornerRadius = avatarImageView.frame.width / 2
        gradientLayer?.frame = view.bounds
    }

    // MARK: - Setup
    private func setupUI() {
        // Gradient Background
        let gradient = CAGradientLayer()
        gradient.frame = view.bounds
        gradient.colors = [
            UIColor(red: 0.35, green: 0.4, blue: 0.95, alpha: 1.0).cgColor,
            UIColor(red: 0.45, green: 0.5, blue: 1.0, alpha: 1.0).cgColor
        ]
        gradient.locations = [0.0, 1.0]
        view.layer.insertSublayer(gradient, at: 0)
        gradientLayer = gradient

        view.addSubview(backButton)
        view.addSubview(titleLabel)
        view.addSubview(scrollView)
        scrollView.addSubview(contentView)
        
        contentView.addSubview(avatarContainerView)
        avatarContainerView.addSubview(avatarImageView)
        avatarContainerView.addSubview(editAvatarButton)

        NSLayoutConstraint.activate([
            // Back Button
            backButton.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 10),
            backButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            backButton.widthAnchor.constraint(equalToConstant: 40),
            backButton.heightAnchor.constraint(equalToConstant: 40),

            // Title
            titleLabel.centerYAnchor.constraint(equalTo: backButton.centerYAnchor),
            titleLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),

            // ScrollView
            scrollView.topAnchor.constraint(equalTo: backButton.bottomAnchor, constant: 20),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            // ContentView
            contentView.topAnchor.constraint(equalTo: scrollView.topAnchor),
            contentView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
            contentView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
            contentView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
            contentView.widthAnchor.constraint(equalTo: scrollView.widthAnchor),
            
            // Avatar Container
            avatarContainerView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 30),
            avatarContainerView.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            avatarContainerView.widthAnchor.constraint(equalToConstant: 140),
            avatarContainerView.heightAnchor.constraint(equalToConstant: 140),
            
            // Avatar Image
            avatarImageView.topAnchor.constraint(equalTo: avatarContainerView.topAnchor),
            avatarImageView.leadingAnchor.constraint(equalTo: avatarContainerView.leadingAnchor),
            avatarImageView.trailingAnchor.constraint(equalTo: avatarContainerView.trailingAnchor),
            avatarImageView.bottomAnchor.constraint(equalTo: avatarContainerView.bottomAnchor),
            
            // Edit Button
            editAvatarButton.trailingAnchor.constraint(equalTo: avatarContainerView.trailingAnchor, constant: -5),
            editAvatarButton.bottomAnchor.constraint(equalTo: avatarContainerView.bottomAnchor, constant: -5),
            editAvatarButton.widthAnchor.constraint(equalToConstant: 36),
            editAvatarButton.heightAnchor.constraint(equalToConstant: 36),
        ])
        
        setupForm()
    }
    
    private func setupForm() {
        // Name Field
        let nameField = createFormField(title: "Full Name", placeholder: "Enter your name", icon: "person.fill")
        nameTextField = getTextField(from: nameField)
        
        // Email Field
        let emailField = createFormField(title: "Email Address", placeholder: "your.email@example.com", icon: "envelope.fill")
        emailTextField = getTextField(from: emailField)
        emailTextField?.isEnabled = false // Email from signup, read-only
        emailTextField?.alpha = 0.7
        
        // Password Field
        let passwordField = createFormField(title: "Password", placeholder: "••••••••", icon: "lock.fill", isSecure: true)
        passwordTextField = getTextField(from: passwordField)
        
        // Location Field
        let locationField = createFormField(title: "Location", placeholder: "City, Country", icon: "location.fill")
        locationTextField = getTextField(from: locationField)
        
        // DOB Field
        let dobField = createFormField(title: "Date of Birth", placeholder: "MM/DD/YYYY", icon: "calendar")
        dobTextField = getTextField(from: dobField)
        
        // Save Button
        let saveButton = UIButton(type: .system)
        saveButton.translatesAutoresizingMaskIntoConstraints = false
        saveButton.setTitle("Save Changes", for: .normal)
        saveButton.titleLabel?.font = UIFont.boldSystemFont(ofSize: 18)
        saveButton.setTitleColor(UIColor(red: 0.4, green: 0.45, blue: 0.95, alpha: 1.0), for: .normal)
        saveButton.backgroundColor = .white
        saveButton.layer.cornerRadius = 28
        saveButton.layer.shadowColor = UIColor.black.cgColor
        saveButton.layer.shadowOffset = CGSize(width: 0, height: 4)
        saveButton.layer.shadowRadius = 8
        saveButton.layer.shadowOpacity = 0.2
        saveButton.addTarget(self, action: #selector(saveButtonTapped), for: .touchUpInside)
        
        let stackView = UIStackView(arrangedSubviews: [nameField, emailField, passwordField, locationField, dobField])
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.axis = .vertical
        stackView.spacing = 24
        stackView.distribution = .fill
        
        contentView.addSubview(stackView)
        contentView.addSubview(saveButton)
        
        NSLayoutConstraint.activate([
            stackView.topAnchor.constraint(equalTo: avatarContainerView.bottomAnchor, constant: 40),
            stackView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 24),
            stackView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -24),
            
            saveButton.topAnchor.constraint(equalTo: stackView.bottomAnchor, constant: 40),
            saveButton.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 24),
            saveButton.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -24),
            saveButton.heightAnchor.constraint(equalToConstant: 56),
            saveButton.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -40)
        ])
    }
    
    private func createFormField(title: String, placeholder: String, icon: String, isSecure: Bool = false) -> UIView {
        let container = UIView()
        container.translatesAutoresizingMaskIntoConstraints = false
        
        let titleLabel = UILabel()
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.text = title
        titleLabel.font = UIFont.systemFont(ofSize: 13, weight: .semibold)
        titleLabel.textColor = .white
        
        let textFieldContainer = UIView()
        textFieldContainer.translatesAutoresizingMaskIntoConstraints = false
        textFieldContainer.backgroundColor = UIColor.white.withAlphaComponent(0.25)
        textFieldContainer.layer.cornerRadius = 16
        textFieldContainer.layer.borderWidth = 1.5
        textFieldContainer.layer.borderColor = UIColor.white.withAlphaComponent(0.4).cgColor
        
        let iconView = UIImageView()
        iconView.translatesAutoresizingMaskIntoConstraints = false
        iconView.image = UIImage(systemName: icon)
        iconView.tintColor = .white
        iconView.contentMode = .scaleAspectFit
        
        let textField = UITextField()
        textField.translatesAutoresizingMaskIntoConstraints = false
        textField.placeholder = placeholder
        textField.textColor = .white
        textField.font = UIFont.systemFont(ofSize: 16, weight: .medium)
        textField.attributedPlaceholder = NSAttributedString(
            string: placeholder,
            attributes: [.foregroundColor: UIColor.white.withAlphaComponent(0.6)]
        )
        textField.isSecureTextEntry = isSecure
        textField.tag = container.hash
        
        textFieldContainer.addSubview(iconView)
        textFieldContainer.addSubview(textField)
        
        var constraints = [
            iconView.leadingAnchor.constraint(equalTo: textFieldContainer.leadingAnchor, constant: 18),
            iconView.centerYAnchor.constraint(equalTo: textFieldContainer.centerYAnchor),
            iconView.widthAnchor.constraint(equalToConstant: 22),
            iconView.heightAnchor.constraint(equalToConstant: 22),
            
            textField.leadingAnchor.constraint(equalTo: iconView.trailingAnchor, constant: 14),
            textField.centerYAnchor.constraint(equalTo: textFieldContainer.centerYAnchor),
        ]
        
        if isSecure {
            let eyeButton = UIButton(type: .system)
            eyeButton.translatesAutoresizingMaskIntoConstraints = false
            eyeButton.setImage(UIImage(systemName: "eye.fill"), for: .normal)
            eyeButton.tintColor = .white
            eyeButton.addTarget(self, action: #selector(togglePasswordVisibility(_:)), for: .touchUpInside)
            eyeButton.tag = textField.tag
            
            textFieldContainer.addSubview(eyeButton)
            
            constraints.append(contentsOf: [
                eyeButton.trailingAnchor.constraint(equalTo: textFieldContainer.trailingAnchor, constant: -18),
                eyeButton.centerYAnchor.constraint(equalTo: textFieldContainer.centerYAnchor),
                eyeButton.widthAnchor.constraint(equalToConstant: 28),
                eyeButton.heightAnchor.constraint(equalToConstant: 28),
                textField.trailingAnchor.constraint(equalTo: eyeButton.leadingAnchor, constant: -8)
            ])
        } else {
            constraints.append(
                textField.trailingAnchor.constraint(equalTo: textFieldContainer.trailingAnchor, constant: -18)
            )
        }
        
        NSLayoutConstraint.activate(constraints)
        
        container.addSubview(titleLabel)
        container.addSubview(textFieldContainer)
        
        NSLayoutConstraint.activate([
            titleLabel.topAnchor.constraint(equalTo: container.topAnchor),
            titleLabel.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 4),
            
            textFieldContainer.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 8),
            textFieldContainer.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            textFieldContainer.trailingAnchor.constraint(equalTo: container.trailingAnchor),
            textFieldContainer.heightAnchor.constraint(equalToConstant: 56),
            textFieldContainer.bottomAnchor.constraint(equalTo: container.bottomAnchor)
        ])
        
        return container
    }
    
    private func getTextField(from container: UIView) -> UITextField? {
        for subview in container.subviews {
            for innerSubview in subview.subviews {
                if let textField = innerSubview as? UITextField {
                    return textField
                }
            }
        }
        return nil
    }
    
    private func loadUserData() {
        // TODO: Load actual user data from UserDefaults, database, or API
        // For now, using placeholder data
        nameTextField?.text = "Aviral Sharma"
        emailTextField?.text = "diaryofmind@gmail.com"
        locationTextField?.text = "Chennai, India"
        dobTextField?.text = "Jun 24, 2004"
    }
    
    private func setupActions() {
        backButton.addTarget(self, action: #selector(backButtonTapped), for: .touchUpInside)
        editAvatarButton.addTarget(self, action: #selector(editAvatarTapped), for: .touchUpInside)
        
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        view.addGestureRecognizer(tapGesture)
    }
    
    // MARK: - Actions
    @objc private func backButtonTapped() {
        navigationController?.popViewController(animated: true)
    }
    
    @objc private func editAvatarTapped() {
        let imagePicker = UIImagePickerController()
        imagePicker.delegate = self
        imagePicker.sourceType = .photoLibrary
        imagePicker.allowsEditing = true
        present(imagePicker, animated: true)
    }
    
    @objc private func togglePasswordVisibility(_ sender: UIButton) {
        guard let textField = passwordTextField else { return }
        textField.isSecureTextEntry.toggle()
        let iconName = textField.isSecureTextEntry ? "eye.fill" : "eye.slash.fill"
        sender.setImage(UIImage(systemName: iconName), for: .normal)
    }
    
    @objc private func saveButtonTapped() {
        // TODO: Implement save functionality
        print("Save tapped")
        print("Name: \(nameTextField?.text ?? "")")
        print("Email: \(emailTextField?.text ?? "")")
        print("Location: \(locationTextField?.text ?? "")")
        print("DOB: \(dobTextField?.text ?? "")")
        
        // Show success feedback
        let alert = UIAlertController(title: "Success", message: "Your information has been updated", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
    
    @objc private func dismissKeyboard() {
        view.endEditing(true)
    }
}

// MARK: - UIImagePickerControllerDelegate
extension PersonalInformationViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        if let editedImage = info[.editedImage] as? UIImage {
            avatarImageView.image = editedImage
        } else if let originalImage = info[.originalImage] as? UIImage {
            avatarImageView.image = originalImage
        }
        picker.dismiss(animated: true)
    }
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true)
    }
}
