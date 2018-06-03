//
//  AddNewVC.swift
//  FastQuantum
//
//  Created by Shan on 2018/3/13.
//  Copyright © 2018年 ShanStation. All rights reserved.
//

import UIKit

class AddNewVC: UIViewController {

    
    @IBOutlet weak var viewTitle: UILabel!
    @IBOutlet weak var selectionTableView: UITableView!
    
    let selectionArray = ["新增活動", "新增好友"]    
    let itemSize = 100
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        viewTitle.text = "新增"
        selectionTableView.dataSource = self
        selectionTableView.delegate = self
        selectionTableView.tableFooterView = UIView()
    }
 
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "showAddNewEventVC" {
            if let dest = segue.destination as? AddNewEventVC {
                dest.viewType = .addNew
                dest.eventNameHolder = "請輸入活動名稱"
            }
        }
    }
}

extension AddNewVC: UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return selectionArray.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if let cell = tableView.dequeueReusableCell(withIdentifier: "AddNewTVC", for: indexPath) as? AddNewTVC {
            cell.selectionTitle.text = selectionArray[indexPath.row]
            cell.indicatorLabel.text = ">"
            return cell
        }
        return UITableViewCell()
    }
}

extension AddNewVC: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        if indexPath.row == 0 {
            performSegue(withIdentifier: "showAddNewEventVC", sender: self)
        } else if indexPath.row == 1 {
            performSegue(withIdentifier: "showAddNewFriendVC", sender: self)
        }
    }
    
}
