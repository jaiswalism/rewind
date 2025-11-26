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
    
    let days: [(day: String, date: String)] = [
        ("Mon", "25"), ("Tue", "26"), ("Wed", "27"),
        ("Thu", "28"), ("Fri", "29"), ("Sat", "30"),
        ("Sun", "1")
    ]
    
    let journalEntries: [(time: String, mood: String, entry: String)] = [
        ("10:00", "Feeling Positive Today", "I’m grateful for the supportive phone call I had with my best friend."),
        ("10:00", "Feeling Positive Today", "I’m grateful for the supportive phone call I had with my best friend."),
        ("10:00", "Feeling Positive Today", "I’m grateful for the supportive phone call I had with my best friend."),
        ("10:00", "Feeling Positive Today", "I’m grateful for the supportive phone call I had with my best friend."),
    ]

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
    }
    
    func setupUI() {
        dateCollectionView.dataSource = self
        dateCollectionView.delegate = self
        
        dateCollectionView.register(
            DateCollectionViewCell.self,
            forCellWithReuseIdentifier: DateCollectionViewCell.identifier
        )
        
        if let layout = dateCollectionView.collectionViewLayout as? UICollectionViewFlowLayout {
            layout.itemSize = CGSize(width: 60, height: 80)
            layout.sectionInset = UIEdgeInsets(top: 0, left: 20, bottom: 0, right: 20)
        }
        
        let selectedIndex = IndexPath(item: 1, section: 0)
        dateCollectionView.selectItem(at: selectedIndex, animated: false, scrollPosition: .centeredHorizontally)
        
        timelineTableView.dataSource = self
        timelineTableView.delegate = self
        
        let bundle = Bundle(for: JournalTimelineCell.self)
        timelineTableView.register(
            UINib(nibName: JournalTimelineCell.identifier, bundle: bundle),
            forCellReuseIdentifier: JournalTimelineCell.identifier
        )
        
        timelineTableView.allowsSelection = true
        timelineTableView.rowHeight = UITableView.automaticDimension
        timelineTableView.estimatedRowHeight = 180.0
        timelineTableView.backgroundColor = UIColor(named: "colors/Primary/Dark")
    }
    
    @IBAction func backButtonTapped(_ sender: Any) {
        navigationController?.popViewController(animated: true)
    }
}

// MARK: - UICollectionViewDataSource & Delegate
extension MyJournalsListViewController: UICollectionViewDataSource, UICollectionViewDelegate {
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return days.count
    }
    
    func collectionView(_ collectionView: UICollectionView,
                        cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        guard let cell = collectionView.dequeueReusableCell(
            withReuseIdentifier: DateCollectionViewCell.identifier,
            for: indexPath
        ) as? DateCollectionViewCell else {
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
    
    func tableView(_ tableView: UITableView,
                   cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        guard let cell = tableView.dequeueReusableCell(
            withIdentifier: JournalTimelineCell.identifier,
            for: indexPath
        ) as? JournalTimelineCell else {
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
    
    func tableView(_ tableView: UITableView,
                   didSelectRowAt indexPath: IndexPath) {
        
        let vc = JournalDetailViewViewController(
            nibName: "JournalDetailViewViewController",
            bundle: nil
        )
        
        navigationController?.pushViewController(vc, animated: true)
    }
}
