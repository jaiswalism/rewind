//
//  OnboardingAgeViewController.swift
//  Rewind
//
//  Created by Shyam on 07/11/25.
//

import UIKit

class OnboardingAgeViewController: UIViewController {

    @IBOutlet var collectionView: UICollectionView!
    
    let ageRange = Array(18...99)
    var selectedAge: Int = 18
    
    private let agePickerLayout = AgePickerLayout()
    private var currentActiveIndex: Int = 0

    override func viewDidLoad() {
        super.viewDidLoad()
        setupCollectionView()
        scrollToDefaultAge()
    }
    
    private func setupCollectionView() {
        collectionView.collectionViewLayout = agePickerLayout
        collectionView.decelerationRate = .fast
        
        collectionView.dataSource = self
        collectionView.delegate = self
        
        collectionView.register(AgeCell.self, forCellWithReuseIdentifier: AgeCell.identifier)
        
        collectionView.showsHorizontalScrollIndicator = false
        collectionView.backgroundColor = .clear
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
            // print("Selected Age: \(selectedAge)") // For debugging
        }
        
        for cell in collectionView.visibleCells {
            if let ageCell = cell as? AgeCell, let indexPath = collectionView.indexPath(for: ageCell) {
                let distance = abs(indexPath.item - activeIndex)
                ageCell.updateAppearance(distanceFromCenter: distance)
            }
        }
    }
    @IBAction func preferNotToSay(_ sender: Any) {
        let alert = UIAlertController(
            title: "Age Required",
            message: "To comply with our 18+ policy, we need your age to continue.",
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
    @IBAction func backButton(_ sender: Any) {
        let genderVC = OnboardingGenderViewController(nibName: "OnboardingGenderViewController", bundle: nil)
        self.setRootViewController(genderVC)
    }
    @IBAction func nextButton(_ sender: Any) {
        OnboardingDataManager.shared.age = selectedAge
        
        let profhelpVC = OnboardingProfHelpViewController(nibName: "OnboardingProfHelpViewController", bundle: nil)
        self.setRootViewController(profhelpVC)
    }
}

// MARK: - UICollectionViewDataSource
extension OnboardingAgeViewController: UICollectionViewDataSource {
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
extension OnboardingAgeViewController: UICollectionViewDelegate {
    
    // This handles tapping on a cell to center it.
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        // We just need to tell the collection view to scroll to that index
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
