//
//  AgeSelectionViewController.swift
//  Rewind
//
//  Created by Shyam on 15/04/26.
//

import UIKit

/// Third onboarding step: Age Selection with wheel-style picker.
/// Reuses the existing AgePickerLayout and AgeCell components.
class AgeSelectionViewController: OnboardingBaseViewController {

    // MARK: - Data

    private let ageRange = Array(18...99)
    private var selectedAge: Int = 25
    private var currentActiveIndex: Int = 0

    // MARK: - UI Components

    private let agePickerContainer: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()

    private lazy var collectionView: UICollectionView = {
        let layout = AgePickerLayout()
        let cv = UICollectionView(frame: .zero, collectionViewLayout: layout)
        cv.translatesAutoresizingMaskIntoConstraints = false
        cv.decelerationRate = .fast
        cv.showsHorizontalScrollIndicator = false
        cv.backgroundColor = .clear
        cv.dataSource = self
        cv.delegate = self
        cv.register(AgeCell.self, forCellWithReuseIdentifier: AgeCell.identifier)
        return cv
    }()

    private var agePickerLayout: AgePickerLayout {
        return collectionView.collectionViewLayout as! AgePickerLayout
    }

    private let infoLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.textAlignment = .center
        label.textColor = UIColor.white.withAlphaComponent(0.7)
        label.font = UIFont.systemFont(ofSize: 14, weight: .regular)
        label.text = "We need your age to comply with our 18+ policy"
        label.numberOfLines = 0
        return label
    }()

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        configurePageIndicator(current: 3)
        headingLabel.text = "How old are you?"
        buildAgePicker()
        setupNextButton()
        scrollToDefaultAge()
    }

    // MARK: - Layout

    private func buildAgePicker() {
        agePickerContainer.addSubview(collectionView)

        NSLayoutConstraint.activate([
            collectionView.topAnchor.constraint(equalTo: agePickerContainer.topAnchor),
            collectionView.leadingAnchor.constraint(equalTo: agePickerContainer.leadingAnchor),
            collectionView.trailingAnchor.constraint(equalTo: agePickerContainer.trailingAnchor),
            collectionView.bottomAnchor.constraint(equalTo: agePickerContainer.bottomAnchor),
            collectionView.heightAnchor.constraint(equalToConstant: 200),
            collectionView.widthAnchor.constraint(equalToConstant: 600) // Ensure it has a width for the layout to calculate centering
        ])

        mainStackView.addArrangedSubview(headingLabel)
        mainStackView.setCustomSpacing(24, after: headingLabel)
        mainStackView.addArrangedSubview(agePickerContainer)
        mainStackView.setCustomSpacing(16, after: agePickerContainer)
        mainStackView.addArrangedSubview(infoLabel)
        mainStackView.setCustomSpacing(40, after: infoLabel)
        mainStackView.addArrangedSubview(nextButton)
    }

    private func scrollToDefaultAge() {
        guard let defaultIndex = ageRange.firstIndex(of: selectedAge) else { return }
        currentActiveIndex = defaultIndex

        DispatchQueue.main.async {
            self.scrollToIndex(index: defaultIndex, animated: false)
            self.collectionView.layoutIfNeeded()
            self.updateVisibleCellAppearances()
        }
    }

    private func scrollToIndex(index: Int, animated: Bool) {
        let xOffset = CGFloat(index) * self.agePickerLayout.cellSlotWidth
        self.collectionView.setContentOffset(CGPoint(x: xOffset, y: 0), animated: animated)
    }

    private func updateVisibleCellAppearances() {
        let activeIndex = Int(max(0, round(collectionView.contentOffset.x / agePickerLayout.cellSlotWidth)))

        if activeIndex != currentActiveIndex {
            currentActiveIndex = activeIndex
            selectedAge = ageRange[activeIndex]
        }

        for cell in collectionView.visibleCells {
            if let ageCell = cell as? AgeCell, let indexPath = collectionView.indexPath(for: ageCell) {
                let distance = abs(indexPath.item - activeIndex)
                ageCell.updateAppearance(distanceFromCenter: distance)
            }
        }
    }

    private func setupNextButton() {
        nextButton.configurationUpdateHandler = { [weak self] button in
            guard let self = self else { return }
            var config = button.configuration
            if button.isEnabled {
                config?.background.backgroundColor = self.unselectedColor
                config?.attributedTitle?.foregroundColor = UIColor(named: "colors/Blue&Shades/blue-400")
            } else {
                config?.background.backgroundColor = UIColor.systemGray4
                config?.attributedTitle?.foregroundColor = UIColor.systemGray
            }
            button.configuration = config
        }

        nextButton.addTarget(self, action: #selector(nextTapped), for: .touchUpInside)
        // Age is always valid (defaults to 25)
        updateNextButtonState(isEnabled: true)
    }

    @objc private func nextTapped() {
        OnboardingDataManager.shared.age = selectedAge
        navigateTo(HelpHistoryViewController())
    }
}

// MARK: - UICollectionViewDataSource
extension AgeSelectionViewController: UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return ageRange.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: AgeCell.identifier, for: indexPath) as! AgeCell

        let age = ageRange[indexPath.item]
        cell.configure(with: age)

        let distance = abs(indexPath.item - currentActiveIndex)
        cell.updateAppearance(distanceFromCenter: distance)

        return cell
    }
}

// MARK: - UICollectionViewDelegate
extension AgeSelectionViewController: UICollectionViewDelegate {

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        scrollToIndex(index: indexPath.item, animated: true)
    }

    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        updateVisibleCellAppearances()
    }

    func scrollViewWillEndDragging(_ scrollView: UIScrollView, withVelocity velocity: CGPoint, targetContentOffset: UnsafeMutablePointer<CGPoint>) {
        var offset = targetContentOffset.pointee
        let index = (offset.x / agePickerLayout.cellSlotWidth)
        var roundedIndex = Int(round(index))

        roundedIndex = max(0, min(roundedIndex, ageRange.count - 1))

        offset = CGPoint(x: CGFloat(roundedIndex) * agePickerLayout.cellSlotWidth,
                         y: scrollView.contentInset.top)

        targetContentOffset.pointee = offset

        self.selectedAge = ageRange[roundedIndex]
    }
}
