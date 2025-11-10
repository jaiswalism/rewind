//
//  AgePickerLayout.swift
//  Rewind
//
//  Created by Shyam on 10/11/25.
//

import UIKit

class AgePickerLayout: UICollectionViewLayout {

    // 1. Your Figma Specs
    private let largeCellSize = CGSize(width: 160, height: 160)
    private let mediumCellSize = CGSize(width: 68, height: 65)
    private let smallCellSize = CGSize(width: 38, height: 35)
    private let spacing: CGFloat = 6
    
    // "Virtual" width of the center slot
    var cellSlotWidth: CGFloat {
        largeCellSize.width + spacing
    }
    
    // --- NEW ---
    // This will store the "phantom" padding for the left and right
    private var horizontalPadding: CGFloat = 0
    // --- END NEW ---
    
    // Cache for layout attributes
    private var cache = [UICollectionViewLayoutAttributes]()
    
    private var contentHeight: CGFloat {
        largeCellSize.height
    }
    
    // --- MODIFIED ---
    // The total width now includes the cells *and* the padding
    private var contentWidth: CGFloat {
        guard let collectionView = collectionView else { return 0 }
        let itemCount = collectionView.numberOfItems(inSection: 0)
        
        // This padding is calculated in prepare()
        let totalCellWidth = (CGFloat(itemCount - 1) * cellSlotWidth) + largeCellSize.width
        
        // Add the padding to both sides
        return totalCellWidth + (2 * horizontalPadding)
    }
    // --- END MODIFIED ---
    
    override var collectionViewContentSize: CGSize {
        return CGSize(width: contentWidth, height: contentHeight)
    }
    
    override func shouldInvalidateLayout(forBoundsChange newBounds: CGRect) -> Bool {
        return true
    }
    
    // MARK: - Layout Snapping
    
    override func targetContentOffset(forProposedContentOffset proposedContentOffset: CGPoint, withScrollingVelocity velocity: CGPoint) -> CGPoint {
        guard collectionView != nil else { return .zero }

        // The targetIndex and targetX calculations remain correct,
        // as contentOffset.x = 0 will still map to index 0.
        let targetIndex = Int(round((proposedContentOffset.x) / cellSlotWidth))
        let targetX = CGFloat(targetIndex) * cellSlotWidth
        
        return CGPoint(x: targetX, y: 0)
    }

    // MARK: - Attribute Preparation
    
    override func prepare() {
        guard let collectionView = collectionView else { return }
        
        // --- NEW ---
        // Calculate the padding needed to center the first/last items
        self.horizontalPadding = (collectionView.bounds.width / 2.0) - (largeCellSize.width / 2.0)
        // --- END NEW ---

        cache.removeAll()
        
        let itemCount = collectionView.numberOfItems(inSection: 0)
        guard itemCount > 0 else { return }

        // Find the index of the item that is *closest* to the center
        // This calculation is still correct
        let activeIndex = Int(max(0, round(collectionView.contentOffset.x / cellSlotWidth)))

        // --- Calculate all frames ---
        
        // 1. Calculate the center position for the "active" large cell
        // --- MODIFIED ---
        // We offset ALL frame calculations by the new horizontalPadding
        let activeCellX = horizontalPadding + (CGFloat(activeIndex) * cellSlotWidth)
        // --- END MODIFIED ---
        
        let activeCellFrame = CGRect(
            x: activeCellX,
            y: (collectionView.bounds.height - largeCellSize.height) / 2.0,
            width: largeCellSize.width,
            height: largeCellSize.height
        )
        let activeAttributes = UICollectionViewLayoutAttributes(forCellWith: IndexPath(item: activeIndex, section: 0))
        activeAttributes.frame = activeCellFrame
        activeAttributes.zIndex = 100
        if activeIndex < itemCount {
            cache.append(activeAttributes)
        }

        // 2. Go Right (Medium, Small, etc.)
        // This logic is unchanged; it just flows from the new 'activeCellX'
        var currentX = activeCellFrame.maxX + spacing
        for i in (activeIndex + 1)..<itemCount {
            let distance = i - activeIndex
            let size = sizeForDistance(distance)
            
            let attributes = UICollectionViewLayoutAttributes(forCellWith: IndexPath(item: i, section: 0))
            attributes.frame = CGRect(
                x: currentX,
                y: (collectionView.bounds.height - size.height) / 2.0,
                width: size.width,
                height: size.height
            )
            attributes.alpha = (distance > 2) ? 0.0 : 1.0
            cache.append(attributes)
            currentX += size.width + spacing
        }
        
        // 3. Go Left (Medium, Small, etc.)
        // This logic is also unchanged
        currentX = activeCellFrame.minX - spacing
        for i in (0..<activeIndex).reversed() {
            let distance = activeIndex - i
            let size = sizeForDistance(distance)
            
            let attributes = UICollectionViewLayoutAttributes(forCellWith: IndexPath(item: i, section: 0))
            attributes.frame = CGRect(
                x: currentX - size.width,
                y: (collectionView.bounds.height - size.height) / 2.0,
                width: size.width,
                height: size.height
            )
            attributes.alpha = (distance > 2) ? 0.0 : 1.0
            cache.append(attributes)
            currentX -= (size.width + spacing)
        }
    }
    
    // Helper to get size based on distance from center
    private func sizeForDistance(_ distance: Int) -> CGSize {
        switch distance {
        case 1:
            return mediumCellSize
        case 2...:
            return smallCellSize
        default:
            return largeCellSize
        }
    }

    override func layoutAttributesForElements(in rect: CGRect) -> [UICollectionViewLayoutAttributes]? {
        return cache.filter { $0.frame.intersects(rect) }
    }
    
    override func layoutAttributesForItem(at indexPath: IndexPath) -> UICollectionViewLayoutAttributes? {
        return cache.first { $0.indexPath == indexPath }
    }
}
