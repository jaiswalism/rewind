import UIKit
import AVFoundation
import Combine

class MyJournalsListViewController: UIViewController {

    private var floatingActionButton: UIButton?
    @IBOutlet weak var timelineTableView: UITableView!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var subtitleLabel: UILabel!
    private var emptyStateLabel = UILabel()

    private let journalViewModel = JournalViewModel()
    private var cancellables = Set<AnyCancellable>()

    private var journalEntries: [DBJournal] = []
    private var audioPlayer: AVPlayer?
    private var refreshControl = UIRefreshControl()

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        bindViewModel()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(true, animated: false)
        updateBackButton()
        fetchJournals()
    }

    private func bindViewModel() {
        journalViewModel.$journals
            .receive(on: DispatchQueue.main)
            .sink { [weak self] journals in
                guard let self else { return }
                self.journalEntries = journals.sorted {
                    ($0.createdDate ?? .distantPast) > ($1.createdDate ?? .distantPast)
                }
                self.updateHeaderTitle()
                self.updateEmptyState()
                self.timelineTableView.reloadData()
                self.refreshControl.endRefreshing()
            }
            .store(in: &cancellables)

        journalViewModel.$error
            .compactMap { $0 }
            .receive(on: DispatchQueue.main)
            .sink { [weak self] error in
                self?.refreshControl.endRefreshing()
                self?.showError(error)
            }
            .store(in: &cancellables)

        NotificationCenter.default.publisher(for: JournalViewModel.journalDidChangeNotification)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.fetchJournals()
            }
            .store(in: &cancellables)
    }

    private func showError(_ message: String) {
        let alert = UIAlertController(title: "Error", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }

    @objc private func handlePullToRefresh() {
        fetchJournals()
    }

    private func fetchJournals() {
        Task {
            await journalViewModel.fetchAllJournals(refresh: true)
        }
    }

    private func updateBackButton() {
        guard let navController = navigationController else { return }

        view.subviews
            .filter { $0.accessibilityIdentifier == "glass-back-button" }
            .forEach { $0.removeFromSuperview() }

        if navController.viewControllers.first !== self {
            GlassBackButton.add(to: self, action: #selector(backButtonTapped(_:)))
            if let button = view.subviews.reversed().first(where: { $0 is UIButton }) {
                button.accessibilityIdentifier = "glass-back-button"
            }
        }
    }

    private func setupUI() {
        titleLabel.text = "My Journals"
        titleLabel.numberOfLines = 1
        titleLabel.adjustsFontSizeToFitWidth = true
        titleLabel.minimumScaleFactor = 0.82

        subtitleLabel.textColor = UIColor.white.withAlphaComponent(0.82)
        subtitleLabel.font = .systemFont(ofSize: 15, weight: .semibold)
        subtitleLabel.numberOfLines = 1

        updateHeaderTitle()

        timelineTableView.dataSource = self
        timelineTableView.delegate = self

        let bundle = Bundle(for: JournalTimelineCell.self)
        timelineTableView.register(
            UINib(nibName: JournalTimelineCell.identifier, bundle: bundle),
            forCellReuseIdentifier: JournalTimelineCell.identifier
        )

        timelineTableView.allowsSelection = true
        timelineTableView.rowHeight = UITableView.automaticDimension
        timelineTableView.estimatedRowHeight = 164.0
        timelineTableView.backgroundColor = UIColor(named: "colors/Primary/Dark")
        timelineTableView.separatorStyle = .none
        timelineTableView.contentInset = UIEdgeInsets(top: 12, left: 0, bottom: 96, right: 0)
        timelineTableView.showsVerticalScrollIndicator = false
        refreshControl.addTarget(self, action: #selector(handlePullToRefresh), for: .valueChanged)
        timelineTableView.refreshControl = refreshControl

        setupEmptyState()
        updateEmptyState()
        setupFloatingActionButton()
    }

    private func setupEmptyState() {
        emptyStateLabel.text = "No journals yet. Tap + to create your first entry."
        emptyStateLabel.textColor = UIColor.white.withAlphaComponent(0.8)
        emptyStateLabel.font = .systemFont(ofSize: 16, weight: .medium)
        emptyStateLabel.textAlignment = .center
        emptyStateLabel.numberOfLines = 0
        emptyStateLabel.frame = CGRect(x: 24, y: 0, width: view.bounds.width - 48, height: 160)
        timelineTableView.backgroundView = emptyStateLabel
    }

    private func updateHeaderTitle() {
        subtitleLabel.text = "\(journalEntries.count) entries - Latest first"
    }

    private func updateEmptyState() {
        timelineTableView.backgroundView?.isHidden = !journalEntries.isEmpty
    }

    private func setupFloatingActionButton() {
        floatingActionButton?.removeFromSuperview()

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

        floatingActionButton = fab
    }

    @objc private func fabTapped() {
        let vc = NewJournalTypeViewController(nibName: "NewJournalTypeViewController", bundle: nil)
        navigationController?.pushViewController(vc, animated: true)
    }

    @objc private func backButtonTapped(_ sender: Any) {
        navigationController?.popViewController(animated: true)
    }

    private func playVoice(url: String) {
        guard let mediaURL = URL(string: url) else { return }

        let playerItem = AVPlayerItem(url: mediaURL)
        audioPlayer = AVPlayer(playerItem: playerItem)
        audioPlayer?.play()
    }

    private func formattedDateLabel(for date: Date?) -> String {
        guard let date else { return "Unknown date" }

        let calendar = Calendar.current
        let timeFormatter = DateFormatter()
        timeFormatter.dateFormat = "h:mm a"

        if calendar.isDateInToday(date) {
            return "Today - \(timeFormatter.string(from: date))"
        }

        if calendar.isDateInYesterday(date) {
            return "Yesterday - \(timeFormatter.string(from: date))"
        }

        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "MMM d"
        return "\(dateFormatter.string(from: date)) - \(timeFormatter.string(from: date))"
    }

    private func normalizedMoodText(for entry: DBJournal) -> String {
        let emotion = entry.emotion?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        if !emotion.isEmpty {
            return emotion.capitalized
        }

        let fallback = entry.title.trimmingCharacters(in: .whitespacesAndNewlines)
        if fallback.isEmpty {
            return "Journal"
        }

        return String(fallback.prefix(22))
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

        let dateLabel = formattedDateLabel(for: entry.createdDate)
        let moodText = normalizedMoodText(for: entry)
        let titleText = entry.title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? "Untitled Entry" : entry.title
        let previewText = entry.content.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? "No content" : entry.content

        cell.configure(
            dateText: dateLabel,
            moodText: moodText,
            titleText: titleText,
            previewText: previewText,
            showPlayButton: false,
            onPlay: nil
        )

        return cell
    }

    func tableView(_ tableView: UITableView,
                   didSelectRowAt indexPath: IndexPath) {

        let vc = JournalDetailViewViewController(
            nibName: "JournalDetailViewViewController",
            bundle: nil
        )

        vc.journal = journalEntries[indexPath.row]
        navigationController?.pushViewController(vc, animated: true)
    }
}
