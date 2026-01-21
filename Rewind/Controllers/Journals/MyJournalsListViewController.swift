//
//  MyJournalsListViewController.swift
//  Rewind
//
//  Created by Shyam on 11/11/25.
//

import UIKit

class MyJournalsListViewController: UIViewController {

    var backButton: UIButton!
    @IBOutlet weak var dateCollectionView: UICollectionView!
    @IBOutlet weak var timelineTableView: UITableView!
    @IBOutlet weak var titleLabel: UILabel!
    
    let days: [(day: String, date: String)] = [
        ("Mon", "25"), ("Tue", "26"), ("Wed", "27"),
        ("Thu", "28"), ("Fri", "29"), ("Sat", "30"),
        ("Sun", "1")
    ]
    
    var journalEntries: [Journal] = [] // API Data
    
    // Removed legacy hardcoded data
    // let days ... (Keeping days for now if needed for calendar, but fetching entries is priority)
    
    // Hardcoded days for UI (could be dynamic later)


    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupBackButton()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(true, animated: animated)
        fetchJournals()
    }
    
    private func fetchJournals() {
        JournalService.shared.getJournals { [weak self] result in
            DispatchQueue.main.async {
                switch result {
                case .success(let journals):
                    self?.journalEntries = journals
                    self?.timelineTableView.reloadData()
                case .failure(let error):
                    print("Error fetching journals: \(error)")
                    // Optionally show empty state
                }
            }
        }
    }
    
    func setupBackButton() {
        GlassBackButton.add(to: self, action: #selector(backButtonTapped(_:)))
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
        
        setupFloatingActionButton()
    }
    
    // MARK: - Floating Action Button
    private func setupFloatingActionButton() {
        let fab = UIButton(type: .system)
        fab.translatesAutoresizingMaskIntoConstraints = false
        
        // Icon
        let config = UIImage.SymbolConfiguration(pointSize: 24, weight: .semibold)
        let plusImage = UIImage(systemName: "plus", withConfiguration: config)
        fab.setImage(plusImage, for: .normal)
        fab.tintColor = .white
        
        // Style
        fab.backgroundColor = UIColor(named: "colors/Blue&Shades/blue-400") // Use app theme color
        fab.layer.cornerRadius = 28 // Half of 56 width
        
        // Shadow
        fab.layer.shadowColor = UIColor.black.cgColor
        fab.layer.shadowOpacity = 0.3
        fab.layer.shadowOffset = CGSize(width: 0, height: 4)
        fab.layer.shadowRadius = 5
        
        // Action
        fab.addTarget(self, action: #selector(fabTapped), for: .touchUpInside)
        
        view.addSubview(fab)
        
        // Constraints
        NSLayoutConstraint.activate([
            fab.widthAnchor.constraint(equalToConstant: 56),
            fab.heightAnchor.constraint(equalToConstant: 56),
            fab.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -24),
            fab.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -24)
        ])
    }
    
    @objc private func fabTapped() {
        // Navigate to New Journal Type selection or directly to Add Journal
        let vc = NewJournalTypeViewController(nibName: "NewJournalTypeViewController", bundle: nil)
        
        // If the user wants to keep ONLY the plus button, ensuring no other navigation happens from other places.
        // Assuming this is the primary entry point now.
        navigationController?.pushViewController(vc, animated: true)
    }
    
    @objc func backButtonTapped(_ sender: Any) {
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
        
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        let timeString = entry.createdDate.map { formatter.string(from: $0) } ?? "Now"
        
        // Use title as Mood/Headline for now, or use first mood tag
        let moodHeadline = entry.moodTags?.first ?? entry.title
        
        cell.configure(time: timeString,
                       mood: moodHeadline,
                       entry: entry.content,
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
        
        let entry = journalEntries[indexPath.row]
        vc.journal = entry
        
        navigationController?.pushViewController(vc, animated: true)
    }
}
