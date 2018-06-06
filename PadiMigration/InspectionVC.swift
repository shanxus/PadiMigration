//
//  InspectionVC.swift
//  FastQuantum
//
//  Created by Shan on 2018/5/1.
//  Copyright © 2018年 ShanStation. All rights reserved.
//

import UIKit

class InspectionVC: UIViewController {

    let headerColor = UIColor(red: 255/255, green: 248/255, blue: 237/255, alpha: 1)
    
    var payRecordsTableView: UITableView!
    var navigationView: UIView!
    var navigationTitleLabel: UILabel!
    var dismissBtn: UIButton!
    
    var selectedPayers: [String:Float] = [:]
    var selectedPayees: [String] = []
    var selectedPairs: [PersonalPayInfo] = []
    var membersIDList: [String] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.view.backgroundColor = headerColor
        
        membersIDList = transformSelectedPayersIntoIDsArray()
        
        handleLayoutNavigationView()
        handleLayoutNavigationTitleLabel()
        handleLayoutDismissBtn()
        handleLayoutRecordsTable()
        
    }

    func handleLayoutNavigationView() {
        navigationView = CustomView()
        navigationView.backgroundColor = headerColor
        self.view.addSubview(navigationView)
        navigationView.leadingAnchor.constraint(equalTo: self.view.leadingAnchor, constant: 0).isActive = true
        navigationView.trailingAnchor.constraint(equalTo: self.view.trailingAnchor, constant: 0).isActive = true
        navigationView.heightAnchor.constraint(equalToConstant: 50).isActive = true
        navigationView.topAnchor.constraint(equalTo: self.view.topAnchor, constant: 14).isActive = true
        navigationView.translatesAutoresizingMaskIntoConstraints = false
    }
    
    func handleLayoutNavigationTitleLabel() {
        navigationTitleLabel = UILabel()
        navigationTitleLabel.text = "檢視"
        navigationTitleLabel.font = UIFont.systemFont(ofSize: 17)
        navigationView.addSubview(navigationTitleLabel)
        navigationTitleLabel.centerXAnchor.constraint(equalTo: navigationView.centerXAnchor).isActive = true
        navigationTitleLabel.centerYAnchor.constraint(equalTo: navigationView.centerYAnchor).isActive = true
        navigationTitleLabel.sizeToFit()
        navigationTitleLabel.translatesAutoresizingMaskIntoConstraints = false
    }
    
    func handleLayoutDismissBtn() {
        dismissBtn = UIButton(type: .system)
        dismissBtn.setTitle("確認", for: .normal)
        dismissBtn.titleLabel?.font = UIFont.systemFont(ofSize: 15)
        dismissBtn.addTarget(self, action: #selector(dismissTapped), for: .touchUpInside)
        navigationView.addSubview(dismissBtn)
        dismissBtn.heightAnchor.constraint(equalToConstant: 30).isActive = true
        dismissBtn.widthAnchor.constraint(equalToConstant: 50).isActive = true
        dismissBtn.leadingAnchor.constraint(equalTo: navigationView.leadingAnchor, constant: 10).isActive = true
        dismissBtn.centerYAnchor.constraint(equalTo: navigationView.centerYAnchor).isActive = true
        dismissBtn.translatesAutoresizingMaskIntoConstraints = false
    }
    
    func handleLayoutRecordsTable() {
        payRecordsTableView = UITableView()
        payRecordsTableView.backgroundColor = headerColor
        payRecordsTableView.tableFooterView = UIView()
        payRecordsTableView.isUserInteractionEnabled = false
        payRecordsTableView.rowHeight = 60
        payRecordsTableView.delegate = self
        payRecordsTableView.dataSource = self
        payRecordsTableView.register(InspectionTVC.self, forCellReuseIdentifier: "inspectionTVC")
        self.view.addSubview(payRecordsTableView)
        payRecordsTableView.leadingAnchor.constraint(equalTo: self.view.leadingAnchor, constant: 0).isActive = true
        payRecordsTableView.trailingAnchor.constraint(equalTo: self.view.trailingAnchor, constant: 0).isActive = true
        payRecordsTableView.topAnchor.constraint(equalTo: navigationView.bottomAnchor, constant: 0).isActive = true
        payRecordsTableView.bottomAnchor.constraint(equalTo: self.view.bottomAnchor, constant: 0).isActive = true
        payRecordsTableView.translatesAutoresizingMaskIntoConstraints = false
    }

    @objc func dismissTapped() {
        self.dismiss(animated: true, completion: nil)
    }
    
    func handleCategoryLabel(isPersonal: Bool, cellWidth: CGFloat) -> UILabel {
        let label = UILabel()
        label.isUserInteractionEnabled = false
        label.layer.cornerRadius = 5
        label.clipsToBounds = true
        label.textColor = .white
        label.textAlignment = .center
        label.font = UIFont.systemFont(ofSize: 13)
        label.widthAnchor.constraint(equalToConstant: cellWidth * 0.2).isActive = true
        label.adjustsFontSizeToFitWidth = true
        label.translatesAutoresizingMaskIntoConstraints = false
        
        if isPersonal == true {
            label.text = "個人款項"
            label.backgroundColor = .black
            
        } else {
            label.text = "均分款項"
            label.backgroundColor = .darkGray
        }
        return label
    }
    
    func handleDescriptionLabel() -> UILabel {
        let label = UILabel()
        label.isUserInteractionEnabled = false
        label.font = UIFont.systemFont(ofSize: 13)
        label.textAlignment = .right
//        if isPersonal == true {
//            label.text = "幫\(ppPayeeID)付款"
//        } else {
//            label.text = "幫\(count)位使用者付款"
//        }
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }
    
    func transformSelectedPayersIntoIDsArray() -> [String] {
        var arr: [String] = []
        for (key, _) in selectedPayers {
            arr.append(key)
        }
        return arr
    }
}

extension InspectionVC: UITableViewDataSource {
    
    func handleCellImage() -> UIImageView {
        let imgView = UIImageView()
        imgView.isUserInteractionEnabled = false
        imgView.contentMode = .scaleAspectFill
        let imgHeight: CGFloat = 50
        imgView.layer.cornerRadius = imgHeight/2
        imgView.clipsToBounds = true
        imgView.widthAnchor.constraint(equalToConstant: imgHeight).isActive = true
        imgView.heightAnchor.constraint(equalToConstant: imgHeight).isActive = true
        imgView.translatesAutoresizingMaskIntoConstraints = false
        
        return imgView
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        let count = selectedPayers.count + selectedPairs.count
        return count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "inspectionTVC", for: indexPath) as? InspectionTVC else { return UITableViewCell() }
        
        cell.backgroundColor = headerColor
        
        let helper = ExamplePadiFriends()
        
        let isPersonal = (!(indexPath.row > (selectedPayers.count - 1)) == true) ? false : true
        
        /* category label */
        let category = handleCategoryLabel(isPersonal: isPersonal, cellWidth: cell.frame.width)
        cell.addSubview(category)
        cell.categoryLabel = category
        cell.categoryLabel.centerYAnchor.constraint(equalTo: cell.centerYAnchor, constant: -(cell.frame.height * 0.2)).isActive = true
        cell.categoryLabel.trailingAnchor.constraint(equalTo: cell.trailingAnchor, constant: -10).isActive = true
        
        /* description label */
        let description = handleDescriptionLabel()
        cell.addSubview(description)
        cell.descriptionLabel = description
        cell.descriptionLabel.centerYAnchor.constraint(equalTo: cell.centerYAnchor, constant: (cell.frame.height * 0.2)).isActive = true
        cell.descriptionLabel.trailingAnchor.constraint(equalTo: cell.trailingAnchor, constant: -10).isActive = true
        
        if isPersonal == true {
            let offset = membersIDList.count
            if let payeeID = selectedPairs[indexPath.row - offset].payeeID {
                helper.getName(forSingleFriend: payeeID, completion: { (name) in
                    DispatchQueue.main.async {
                        cell.descriptionLabel.text = "幫\(name)付款"
                    }
                })
            }
        } else {
            let count = selectedPayees.count
            cell.descriptionLabel.text = "幫\(count)位付款"
        }
        
        /* imageView */
        let img = handleCellImage()
        cell.addSubview(img)
        cell.recordImage = img
        cell.recordImage.leadingAnchor.constraint(equalTo: cell.leadingAnchor, constant: 20).isActive = true
        cell.recordImage.centerYAnchor.constraint(equalTo: cell.centerYAnchor).isActive = true
        cell.descriptionLabel.leadingAnchor.constraint(equalTo: cell.recordImage.trailingAnchor, constant: 10).isActive = true
        
        if isPersonal == true {
            let offset = membersIDList.count
            if let id = selectedPairs[indexPath.row - offset].payerID {
                helper.getImageURLString(forSingleFriend: id, completion: { (url) in
                    let imgURL = URL(string: url)
                    DispatchQueue.main.async {
                        cell.recordImage.kf.setImage(with: imgURL)
                    }
                })
            }
        } else {
            let id = membersIDList[indexPath.row]
            helper.getImageURLString(forSingleFriend: id, completion: { (url) in
                let imgURL = URL(string: url)
                DispatchQueue.main.async {
                    cell.recordImage.kf.setImage(with: imgURL)
                }
            })
            
        }
        
        return cell
    }
}

extension InspectionVC: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        // should figure out why category label is weird when cell is selected. 
    }
}
















