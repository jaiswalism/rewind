import UIKit
import AVFoundation
import Combine

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
    
    private let journalViewModel = JournalViewModel()
    private var cancellables = Set<AnyCancellable>()
    
    var journalEntries: [DBJournal] = []
    
    var audioPlayer: AVPlayer?

    override func viewDidLoad() {
        super.viewDidLoad()
        hidesBottomBarWhenPushed = true
        setupUI()
        setupBackButton()
        bindViewModel()
    }
    
    private func bindViewModel() {
        journalViewModel.$journals
            .receive(on: DispatchQueue.main)
            .sink { [weak self] journals in
                self?.journalEntries = journals
                self?.timelineTableView.reloadData()
            }
            .store(in: &cancellables)
        
        journalViewModel.$error
            .compactMap { $0 }
            .receive(on: DispatchQueue.main)
            .sink { [weak self] error in
                self?.showError(error)
            }
            .store(in: &cancellables)
    }
    
    private func showError(_ message: String) {
        let alert = UIAlertController(title: "Error", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(true, animated: animated)
        fetchJournals()
    }
    
    private func fetchJournals() {
        Task {
            await journalViewModel.fetchJournals()
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
    
    private func setupFloatingActionButton() {
        let fab = UIButton(type: .system)
        fab.translatesAutoresizingMaskIntoConstraints = false
        
        let config = UIImage.SymbolConfiguration(pointSize: 24, weight: .semibold)
        let plusImage = UIImage(systemName: "plus", withConfiguration: config)
        fab.setImage(plusImage, for: .normal)
        fab.tintColor = .white
        
        fab.backgroundColor = UIColor(named: "colors/Blue&Shades/blue-400")
        fab.layer.cornerRadius = 28
        
        fab.layer.shadowColor = UIColor.black.cgColor
        fab.layer.shadowOpacity = 0.3
        fab.layer.shadowOffset = CGSize(width: 0, height: 4)
        fab.layer.shadowRadius = 5
        
        fab.addTarget(self, action: #selector(fabTapped), for: .touchUpInside)
        
        view.addSubview(fab)
        
        NSLayoutConstraint.activate([
            fab.widthAnchor.constraint(equalToConstant: 56),
            fab.heightAnchor.constraint(equalToConstant: 56),
            fab.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -24),
            fab.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -24)
        ])
    }
    
    @objc private func fabTapped() {
        let vc = NewJournalTypeViewController(nibName: "NewJournalTypeViewController", bundle: nil)
        navigationController?.pushViewController(vc, animated: true)
    }
    
    @objc func backButtonTapped(_ sender: Any) {
        navigationController?.popViewController(animated: true)
    }
    
    func playVoice(url: String) {
        guard let mediaURL = URL(string: url) else { return }
        
        let playerItem = AVPlayerItem(url: mediaURL)
        audioPlayer = AVPlayer(playerItem: playerItem)
        audioPlayer?.play()
    }
}

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
        
        let moodHeadline = entry.emotion ?? entry.title
        
        cell.configure(time: timeString,
                       mood: moodHeadline,
                       entry: entry.content,
                       isFirst: isFirst,
                       isLast: isLast,
                       showPlayButton: false,
                       onPlay: nil)
        
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
