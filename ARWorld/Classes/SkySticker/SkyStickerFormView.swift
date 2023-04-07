//
//  SkyStickerFormView.swift
//  ARWorld
//
//  Created by Reza Hemadi on 4/27/18.
//  Copyright © 2018 ArvandGroup. All rights reserved.
//

import UIKit

class SkyStickerFormView: UIView {
    
    // MARK: - Properties
    var collectionView: UICollectionView!
    var label: UILabel!
    var closeButton: UIButton!
    var items: [SkySticker.Model] = SkySticker.Model.allModels
    var delegate: SkyStickerFormViewDelegate?
    
    // MARK: - Initialization
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        layer.cornerRadius = 5.0
        clipsToBounds = true
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func showCollectionView() {
        label = UILabel(frame: CGRect(x: bounds.minX, y: bounds.minY, width: bounds.width, height: 30))
        label.font = UIFont(name: "HelveticaNeue", size: 17)
        label.text = "SkySticker"
        label.textAlignment = .center
        label.textColor = UIColor(red: 240/255.0, green: 255/255.0, blue: 76/255.0, alpha: 1)
        //label.adjustsFontSizeToFitWidth = true
        addSubview(label)
        //label.translatesAutoresizingMaskIntoConstraints = false
        
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .vertical
        let itemWidth: CGFloat = (bounds.width) / 2 - 5
        layout.itemSize = CGSize(width: itemWidth, height: itemWidth + 15)
        layout.minimumInteritemSpacing = 2
        layout.minimumLineSpacing = 2
        
        collectionView = UICollectionView(frame: CGRect(x: bounds.minX, y: bounds.minY + 30, width: bounds.width, height: bounds.height - label.bounds.height - 40), collectionViewLayout: layout)
        
        collectionView.collectionViewLayout = layout
        collectionView.dataSource = self
        collectionView.delegate = self
        collectionView.backgroundColor = UIColor(red: 118/255.0, green: 125/255.0, blue: 130/255.0, alpha: 0.6)
        
        collectionView.register(SkyStickerFormViewCell.self, forCellWithReuseIdentifier: "cell")
        
        addSubview(collectionView)
        
        let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(tap))
        collectionView.addGestureRecognizer(tapGestureRecognizer)
        
        closeButton = UIButton(frame: CGRect(x: bounds.midX - 35, y: bounds.maxY - 35, width: 70, height: 30))
        closeButton.setTitle("Close", for: .normal)
        closeButton.titleLabel?.adjustsFontSizeToFitWidth = true
        closeButton.backgroundColor = UIColor(red: 68/255.0, green: 68/255.0, blue: 68/255, alpha: 0.8)
        closeButton.titleLabel?.textColor = UIColor.white
        closeButton.titleLabel?.textAlignment = .center
        closeButton.layer.cornerRadius = 5.0
        addSubview(closeButton)
        closeButton.addTarget(self, action: #selector(closeView), for: .touchUpInside)
    }
    @objc func closeView() {
        delegate?.skyStickerView(self)
        removeFromSuperview()
    }
    @objc func tap(sender: UITapGestureRecognizer) {
        if let indexPath = collectionView.indexPathForItem(at: sender.location(in: collectionView)) {
            let item = items[indexPath.row]
            closeView()
            delegate?.skyStickerView(self, didSelect: item)
        }
    }
}
extension SkyStickerFormView: UICollectionViewDelegate, UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "cell", for: indexPath) as! SkyStickerFormViewCell
        cell.name = items[indexPath.row].getName()
        cell.image = items[indexPath.row].getImage()
        cell.imageView.contentMode = .scaleAspectFit
        return cell
    }
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return items.count
    }
}
protocol SkyStickerFormViewDelegate {
    func skyStickerView(_ viewClosed: SkyStickerFormView)
    func skyStickerView(_ view: SkyStickerFormView, didSelect item: SkySticker.Model)
}
