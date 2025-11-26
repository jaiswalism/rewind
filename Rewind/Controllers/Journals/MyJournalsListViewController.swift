//
//  MyJournalsListViewController.swift
//  Rewind
//
//  Created by Shyam on 11/11/25.
//

import UIKit

class MyJournalsListViewController: UIViewController {

    @IBOutlet weak var backButton: UIButton!
    @IBOutlet weak var dateCollectionView: UICollectionView!
    @IBOutlet weak var timelineTableView: UITableView!
    @IBOutlet weak var titleLabel: UILabel!
    
    // --- Data Source Simulation ---
    // Matches the visible dates in the screenshot
    let days: [(day: String, date: String)] = [
        ("Mon", "25"), ("Tue", "26"), ("Wed", "27"),
        ("Thu", "28"), ("Fri", "29"), ("Sat", "30"),
        ("Sun", "1")
    ]
    
    // Matches the journal entries in the screenshot
    let journalEntries: [(time: String, mood: String, entry: String)] = [
        ("10:00", "Feeling Positive Today", "I’m grateful for the supportive phone call I had with my best friend."),
        ("10:00", "Feeling Positive Today", "I’m grateful for the supportive phone call I had with my best friend."),
        ("10:00", "Feeling Positive Today", "I’m grateful for the supportive phone call I had with my best friend."),
        ("10:00", "Feeling Positive Today", "I’m grateful for the supportive phone call I had with my best friend."),
    ]
    // -----------------------------

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
    }
    
    func setupUI() {
        // --- Collection View Setup ---
        dateCollectionView.dataSource = self
        dateCollectionView.delegate = self
        
        // 1. Register the custom DateCollectionViewCell (using class registration)
        dateCollectionView.register(DateCollectionViewCell.self,
                                   forCellWithReuseIdentifier: DateCollectionViewCell.identifier)
        
        // Set up the flow layout programmatically to define item size if not done in XIB
        if let layout = dateCollectionView.collectionViewLayout as? UICollectionViewFlowLayout {
            // Calculated approximate item size (width to fit 5-6 cells, height from screenshot)
            layout.itemSize = CGSize(width: 60, height: 80)
            layout.sectionInset = UIEdgeInsets(top: 0, left: 20, bottom: 0, right: 20)
        }
        
        // Select the current date (index 1 for 'Tue 26')
        let selectedIndex = IndexPath(item: 1, section: 0)
        dateCollectionView.selectItem(at: selectedIndex, animated: false, scrollPosition: .centeredHorizontally)
        
        // --- Table View Setup ---
        timelineTableView.dataSource = self
        timelineTableView.delegate = self
        
        // 2. Register the custom JournalTimelineCell (using XIB registration)
        let bundle = Bundle(for: JournalTimelineCell.self)
        timelineTableView.register(UINib(nibName: JournalTimelineCell.identifier, bundle: bundle),
                                   forCellReuseIdentifier: JournalTimelineCell.identifier)
        
        timelineTableView.separatorStyle = .none
        timelineTableView.allowsSelection = false
        
        // Enable row height calculation based on cell constraints
        timelineTableView.rowHeight = UITableView.automaticDimension
        timelineTableView.estimatedRowHeight = 180.0
        
        // Set table view background to match the bottom part (colors/Primary/Dark)
        timelineTableView.backgroundColor = UIColor(named: "colors/Primary/Dark")
    }
    
    @IBAction func backButtonTapped(_ sender: Any) {
        // Implement navigation back functionality here
    }
}

// MARK: - UICollectionViewDataSource & Delegate
extension MyJournalsListViewController: UICollectionViewDataSource, UICollectionViewDelegate {
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return days.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: DateCollectionViewCell.identifier,
                                                            for: indexPath) as? DateCollectionViewCell else {
            return UICollectionViewCell()
        }
        
        let data = days[indexPath.item]
        cell.configure(day: data.day, date: data.date)
        return cell
    }
}

// MARK: - UITableViewDataSource & Delegate
extension MyJournalsListViewController: UITableViewDataSource, UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return journalEntries.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: JournalTimelineCell.identifier,
                                                            for: indexPath) as? JournalTimelineCell else {
            return UITableViewCell()
        }
        
        let entry = journalEntries[indexPath.row]
        let isFirst = indexPath.row == 0
        let isLast = indexPath.row == journalEntries.count - 1
        
        cell.configure(time: entry.time,
                       mood: entry.mood,
                       entry: entry.entry,
                       isFirst: isFirst,
                       isLast: isLast)
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let headerView = UIView()
        headerView.backgroundColor = UIColor(named: "colors/Primary/Dark")

        let label = UILabel()
        label.text = "Timeline"
        label.font = .systemFont(ofSize: 18, weight: .bold)
        label.textColor = UIColor(named: "colors/Primary/Light")
        label.translatesAutoresizingMaskIntoConstraints = false
        headerView.addSubview(label)
        
        NSLayoutConstraint.activate([
            label.leadingAnchor.constraint(equalTo: headerView.leadingAnchor, constant: 20),
            label.bottomAnchor.constraint(equalTo: headerView.bottomAnchor, constant: -8)
        ])

        return headerView
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 40
    }
}
