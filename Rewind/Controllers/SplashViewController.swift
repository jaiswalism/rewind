//
//  SplashViewController.swift
//  Rewind
//
//  Created by Copilot.
//

import UIKit

final class SplashViewController: UIViewController {
    private let logoView = UIImageView()
    private let titleLabel = UILabel()
    private let subtitleLabel = UILabel()
    private let progressTrack = UIView()
    private let progressFill = UIView()

    override func viewDidLoad() {
        super.viewDidLoad()
        setupView()
        setupBackgroundGlow()
        setupContent()
    }

    private func setupView() {
        view.backgroundColor = UIColor(named: "splashBackground") ?? UIColor(red: 0.93, green: 0.965, blue: 0.957, alpha: 1.0)
    }

    private func setupBackgroundGlow() {
        let topGlow = UIView()
        topGlow.backgroundColor = UIColor.white.withAlphaComponent(traitCollection.userInterfaceStyle == .dark ? 0.10 : 0.22)
        topGlow.layer.cornerRadius = 190
        topGlow.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(topGlow)

        let bottomGlow = UIView()
        bottomGlow.backgroundColor = UIColor(red: 0.49, green: 0.64, blue: 1.00, alpha: traitCollection.userInterfaceStyle == .dark ? 0.26 : 0.18)
        bottomGlow.layer.cornerRadius = 160
        bottomGlow.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(bottomGlow)

        NSLayoutConstraint.activate([
            topGlow.widthAnchor.constraint(equalToConstant: 380),
            topGlow.heightAnchor.constraint(equalToConstant: 380),
            topGlow.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: -145),
            topGlow.topAnchor.constraint(equalTo: view.topAnchor, constant: 80),

            bottomGlow.widthAnchor.constraint(equalToConstant: 320),
            bottomGlow.heightAnchor.constraint(equalToConstant: 320),
            bottomGlow.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: 150),
            bottomGlow.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: 180)
        ])
    }

    private func setupContent() {
        logoView.translatesAutoresizingMaskIntoConstraints = false
        logoView.image = UIImage(named: "splashLogo")
        logoView.contentMode = .scaleAspectFit
        logoView.layer.shadowColor = UIColor.black.cgColor
        logoView.layer.shadowOpacity = traitCollection.userInterfaceStyle == .dark ? 0.18 : 0.08
        logoView.layer.shadowRadius = 16
        logoView.layer.shadowOffset = CGSize(width: 0, height: 10)
        view.addSubview(logoView)

        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.text = "Rewind"
        titleLabel.font = .systemFont(ofSize: 36, weight: .semibold)
        titleLabel.textAlignment = .center
        titleLabel.textColor = UIColor(named: "splashTextPrimary") ?? UIColor(red: 0.10, green: 0.15, blue: 0.22, alpha: 1)
        view.addSubview(titleLabel)

        subtitleLabel.translatesAutoresizingMaskIntoConstraints = false
        subtitleLabel.text = "Your moments, organized"
        subtitleLabel.font = .systemFont(ofSize: 15, weight: .medium)
        subtitleLabel.textAlignment = .center
        subtitleLabel.textColor = UIColor(named: "splashTextSecondary") ?? UIColor(red: 0.31, green: 0.35, blue: 0.43, alpha: 1)
        view.addSubview(subtitleLabel)

        progressTrack.translatesAutoresizingMaskIntoConstraints = false
        progressTrack.backgroundColor = UIColor.white.withAlphaComponent(traitCollection.userInterfaceStyle == .dark ? 0.20 : 0.18)
        progressTrack.layer.cornerRadius = 3
        view.addSubview(progressTrack)

        progressFill.translatesAutoresizingMaskIntoConstraints = false
        progressFill.backgroundColor = (UIColor(named: "splashTextPrimary") ?? UIColor(red: 0.10, green: 0.15, blue: 0.22, alpha: 1)).withAlphaComponent(traitCollection.userInterfaceStyle == .dark ? 0.55 : 0.28)
        progressFill.layer.cornerRadius = 3
        progressTrack.addSubview(progressFill)

        NSLayoutConstraint.activate([
            logoView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            logoView.centerYAnchor.constraint(equalTo: view.centerYAnchor, constant: -52),
            logoView.widthAnchor.constraint(equalToConstant: 240),
            logoView.heightAnchor.constraint(equalToConstant: 240),

            titleLabel.topAnchor.constraint(equalTo: logoView.bottomAnchor, constant: 28),
            titleLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),

            subtitleLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 10),
            subtitleLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),

            progressTrack.topAnchor.constraint(equalTo: subtitleLabel.bottomAnchor, constant: 28),
            progressTrack.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            progressTrack.widthAnchor.constraint(equalToConstant: 92),
            progressTrack.heightAnchor.constraint(equalToConstant: 6),

            progressFill.centerYAnchor.constraint(equalTo: progressTrack.centerYAnchor),
            progressFill.leadingAnchor.constraint(equalTo: progressTrack.leadingAnchor),
            progressFill.widthAnchor.constraint(equalToConstant: 42),
            progressFill.heightAnchor.constraint(equalToConstant: 6)
        ])
    }
}