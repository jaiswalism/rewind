import UIKit

class AgeCell: UICollectionViewCell {
    
    static let identifier = "AgeCell"
    
    // The background circle
    private let circleView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        // Use the color from your design
        view.backgroundColor = UIColor(white: 1.0, alpha: 0.2)
        view.isHidden = true
        return view
    }()
    
    // The age number label
    private let ageLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.textAlignment = .center
        label.textColor = .white
        return label
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupUI() {
        // We add the circle to the cell's content view
        contentView.addSubview(circleView)
        contentView.addSubview(ageLabel)
        
        // The label is always centered in the cell
        NSLayoutConstraint.activate([
            ageLabel.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            ageLabel.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            
            // The circle is also centered and sized
            circleView.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            circleView.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            circleView.widthAnchor.constraint(equalToConstant: 160),
            circleView.heightAnchor.constraint(equalToConstant: 160)
        ])
        
        // Make the circle view circular
        circleView.layer.cornerRadius = 160 / 2
    }
    
    func configure(with age: Int) {
        ageLabel.text = "\(age)"
    }
    
    // This is called by the view controller to update the cell's style
    func updateAppearance(distanceFromCenter: Int) {
        switch distanceFromCenter {
        case 0:
            // --- CENTER (LARGE) ---
            ageLabel.font = .systemFont(ofSize: 108, weight: .heavy)
            ageLabel.textColor = UIColor(named: "colors/Primary/Light")
            circleView.isHidden = false
            
        case 1:
            // --- ADJACENT (MEDIUM) ---
            ageLabel.font = .systemFont(ofSize: 60, weight: .heavy)
            ageLabel.textColor = UIColor(named: "colors/Primary/Dark :active")
            circleView.isHidden = true
            
        default:
            // --- EXTREME (SMALL) ---
            ageLabel.font = .systemFont(ofSize: 30, weight: .heavy)
            circleView.isHidden = true
            ageLabel.textColor = UIColor(named: "colors/Primary/Dark :active")
        }
    }
}
