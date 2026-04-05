import UIKit

// MARK: - Photo Gallery

class PhotoGalleryViewController: UIViewController {

    // MARK: - Properties
    private let mediaUrls: [String]
    private let initialIndex: Int
    
    private var pageViewController: UIPageViewController!
    private var photoViewControllers: [UIViewController] = []
    
    // MARK: - UI Components
    private let closeButton: UIButton = {
        let button = UIButton(type: .system)
        let config = UIImage.SymbolConfiguration(pointSize: 18, weight: .bold)
        let image = UIImage(systemName: "xmark", withConfiguration: config)
        button.setImage(image, for: .normal)
        button.tintColor = .white
        button.backgroundColor = UIColor.black.withAlphaComponent(0.5)
        button.layer.cornerRadius = 20
        button.clipsToBounds = true
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    
    // MARK: - Initialization
    init(mediaUrls: [String], initialIndex: Int = 0) {
        self.mediaUrls = mediaUrls
        self.initialIndex = initialIndex
        super.init(nibName: nil, bundle: nil)
        self.modalPresentationStyle = .overFullScreen
        self.modalTransitionStyle = .crossDissolve
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .black
        
        setupPageViewController()
        setupUI()
    }
    
    private func setupUI() {
        view.addSubview(closeButton)
        
        NSLayoutConstraint.activate([
            closeButton.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 16),
            closeButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            closeButton.widthAnchor.constraint(equalToConstant: 40),
            closeButton.heightAnchor.constraint(equalToConstant: 40)
        ])
        
        closeButton.addTarget(self, action: #selector(handleClose), for: .touchUpInside)
    }
    
    private func setupPageViewController() {
        for (index, url) in mediaUrls.enumerated() {
            let photoVC = SinglePhotoViewController(url: url, index: index, total: mediaUrls.count)
            photoViewControllers.append(photoVC)
        }
        
        pageViewController = UIPageViewController(transitionStyle: .scroll, navigationOrientation: .horizontal, options: nil)
        pageViewController.dataSource = self
        pageViewController.delegate = self
        
        if initialIndex < photoViewControllers.count {
            pageViewController.setViewControllers([photoViewControllers[initialIndex]], direction: .forward, animated: false, completion: nil)
        }
        
        addChild(pageViewController)
        view.insertSubview(pageViewController.view, at: 0)
        pageViewController.view.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            pageViewController.view.topAnchor.constraint(equalTo: view.topAnchor),
            pageViewController.view.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            pageViewController.view.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            pageViewController.view.trailingAnchor.constraint(equalTo: view.trailingAnchor)
        ])
        
        pageViewController.didMove(toParent: self)
    }
    
    @objc private func handleClose() {
        dismiss(animated: true, completion: nil)
    }
}

// MARK: - UIPageViewControllerDataSource
extension PhotoGalleryViewController: UIPageViewControllerDataSource, UIPageViewControllerDelegate {
    func pageViewController(_ pageViewController: UIPageViewController, viewControllerBefore viewController: UIViewController) -> UIViewController? {
        guard let photoVC = viewController as? SinglePhotoViewController,
              let index = photoViewControllers.firstIndex(of: photoVC),
              index > 0 else {
            return nil
        }
        return photoViewControllers[index - 1]
    }
    
    func pageViewController(_ pageViewController: UIPageViewController, viewControllerAfter viewController: UIViewController) -> UIViewController? {
        guard let photoVC = viewController as? SinglePhotoViewController,
              let index = photoViewControllers.firstIndex(of: photoVC),
              index < photoViewControllers.count - 1 else {
            return nil
        }
        return photoViewControllers[index + 1]
    }
}

// MARK: - Single Photo View Controller
class SinglePhotoViewController: UIViewController {
    
    private let urlString: String
    private let index: Int
    private let total: Int
    
    private let imageView: UIImageView = {
        let iv = UIImageView()
        iv.contentMode = .scaleAspectFit
        iv.translatesAutoresizingMaskIntoConstraints = false
        return iv
    }()
    
    private let counterLabel: UILabel = {
        let label = UILabel()
        label.textColor = .white
        label.font = .systemFont(ofSize: 16, weight: .medium)
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    init(url: String, index: Int, total: Int) {
        self.urlString = url
        self.index = index
        self.total = total
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        loadImage()
    }
    
    private func setupUI() {
        view.backgroundColor = .clear
        view.addSubview(imageView)
        view.addSubview(counterLabel)
        
        counterLabel.text = "\(index + 1) / \(total)"
        
        NSLayoutConstraint.activate([
            imageView.topAnchor.constraint(equalTo: view.topAnchor),
            imageView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            imageView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            imageView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            
            counterLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 20),
            counterLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor)
        ])
    }
    
    private func loadImage() {
        if urlString.hasPrefix("local-image://") {
            let filename = urlString.replacingOccurrences(of: "local-image://", with: "")
            if let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first {
                let fileUrl = documentsDirectory.appendingPathComponent(filename)
                if let data = try? Data(contentsOf: fileUrl) {
                    imageView.image = UIImage(data: data)
                } else {
                     imageView.image = UIImage(systemName: "photo")
                }
            }
        } else if urlString.hasPrefix("file://"), let url = URL(string: urlString), let data = try? Data(contentsOf: url) {
            imageView.image = UIImage(data: data)
        } else if urlString.hasPrefix("http") {
             imageView.image = UIImage(systemName: "photo")
             DispatchQueue.global().async {
                 if let url = URL(string: self.urlString), let data = try? Data(contentsOf: url) {
                     DispatchQueue.main.async {
                         self.imageView.image = UIImage(data: data)
                     }
                 }
             }
        } else {
             imageView.image = UIImage(systemName: "photo")
        }
    }
}
