//
//  DefaultIconSelectVC.swift
//  PadiMigration
//
//  Created by Shan on 2018/6/4.
//  Copyright © 2018年 Shan. All rights reserved.
//

import UIKit

class DefaultIconSelectVC: UIViewController {

    @IBOutlet weak var viewTitleLabel: UILabel!
    @IBOutlet weak var iconsTableView: UITableView!
    
    var defaultIcons: [String] = []
    
    var categories: [String] = ["food", "transport", "room"]
    var categoriesCH: [String] = ["食物", "交通", "房間"]
    
    var categoryCount: [Int] = [10, 6, 1]
    
    override func viewDidLoad() {
        super.viewDidLoad()

        iconsTableView.dataSource = self
        iconsTableView.delegate = self
        
        loadIcons()
        iconsTableView.reloadData()
    }
    
    @IBAction func cancelTapped(_ sender: Any) {
        self.dismiss(animated: true, completion: nil)
    }
    @IBAction func saveTapped(_ sender: Any) {
    }
    
    func loadIcons() {
        for (index, each) in categoryCount.enumerated() {
            for i in 1...each {
                let iconName = "\(categories[index])" + "\(i)"
                defaultIcons.append(iconName)
            }
        }
    }
    
}

extension DefaultIconSelectVC: UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return defaultIcons.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "defaultIconsTVC", for: indexPath) as? DefaultIconSelectTVC else {return UITableViewCell()}
        cell.iconImage.image = UIImage(named: defaultIcons[indexPath.row])
        cell.iconName.text = defaultIcons[indexPath.row]
        return cell
    }
}

extension DefaultIconSelectVC: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
    }
}
