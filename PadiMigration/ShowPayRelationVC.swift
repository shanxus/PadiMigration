//
//  ShowPayRelationVC.swift
//  FastQuantum
//
//  Created by Shan on 2018/5/8.
//  Copyright © 2018年 ShanStation. All rights reserved.
//

import UIKit
import SwiftyJSON

class ShowPayRelationVC: UIViewController {

    @IBOutlet weak var navigationLabel: UIView!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var relationTable: UITableView!

    var userID: String?
    //var payID: String?
    
    var payIDs: [String] = []
    
    let dispatch = DispatchGroup()
    
    var relation: [PayRelation]? {
        didSet {
            if let _ = relation {
                relationTable.reloadData()
            }
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        relationTable.delegate = self
        relationTable.dataSource = self
        relationTable.tableFooterView = UIView()
        fetchPayInfo()
    }

    @IBAction func dismissTapped(_ sender: Any) {
        /* This is a push animation for transition.
        let transition = CATransition()
        transition.duration = 0.3
        transition.type = kCATransitionPush
        transition.subtype = kCATransitionFromLeft
        transition.timingFunction = CAMediaTimingFunction(name:kCAMediaTimingFunctionDefault)
        view.window!.layer.add(transition, forKey: kCATransition)
        */
        self.dismiss(animated: true, completion: nil)
    }
    
    func fetchPayInfo() {
        guard let user = userID else {return}
        
        var memberList: [String] = []
        let dispatch = DispatchGroup()
        let helper = ExamplePay()
        
        var isMemberListGetFetched: Bool = false
        
        var payers: [PayPayer] = []
        var payees: [PayPayee] = []
        var pps: [PersonalPay] = []
        
        for pay in payIDs {
            /* Fetch member list information. And this fetching is only necessary for once. */
            if isMemberListGetFetched == false {
                isMemberListGetFetched = true
                dispatch.enter()
                helper.fetchPayAttribute(for: DBPathStrings.memberListPath, payID: pay, userID: user) { (fetched: JSON) in
                    for each in fetched.arrayValue {
                        memberList.append(each.stringValue)
                    }
                    dispatch.leave()
                }
            }
            
            /* Fetch payers. */
            dispatch.enter()
            helper.fetchPayAttribute(for: DBPathStrings.payerPath, payID: pay, userID: user) { (fetched: JSON) in
                for (key, info) in fetched {
                    let newPayer = PayPayer(id: key, info: info)
                    payers.append(newPayer)
                }
                dispatch.leave()
            }
 
            /* Fetch payees. */
            dispatch.enter()
            helper.fetchPayAttribute(for: DBPathStrings.payeePath, payID: pay, userID: user) { (fetched: JSON) in
                for (payeeID, info) in fetched {
                    for (payerID, _) in info {
                        let newPayee = PayPayee(ID: payeeID, shouldGiveTo: payerID)
                        payees.append(newPayee)
                    }
                }
                dispatch.leave()
            }
            
            /* Fetch PPs. */
            helper.fetchPayAttribute(for: DBPathStrings.ppPath, payID: pay, userID: user) { (fetched: JSON) in
                for (key, info) in fetched {
                    let newPP = PersonalPay(id: key, info: info)
                    pps.append(newPP)
                }
            }
        }
        
        /* Build tables and relations after each dispatch got finished. */
        dispatch.notify(queue: .main) { 
            let relationHelper = RelationTable()
            let table = relationHelper.buildTable(memberList: memberList, payers: payers, payees: payees, personalPays: pps)
            self.relation = relationHelper.transformIntoRelation(relationTable: table, memberList: memberList)
        }
    }
}

extension ShowPayRelationVC: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
    }
}

extension ShowPayRelationVC: UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        guard let count = relation?.count else {return 0}
        
        return count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if let cell = tableView.dequeueReusableCell(withIdentifier: "ShowPayRelationTVC", for: indexPath) as? ShowPayRelationTVC {
            
            guard let relation = relation else {return UITableViewCell()}
            
            let memberDataHelper = ExampleMainUser.shareInstance
            if let payer = relation[indexPath.row].payerID {
                memberDataHelper.getAttribute(for: DBPathStrings.imageURLPath, userID: payer, completion: { (fetched: JSON) in
                    let url = URL(string: fetched.stringValue)
                    DispatchQueue.main.async {
                        cell.rightSideImage.kf.setImage(with: url)
                    }
                })
            }
            
            if let payee = relation[indexPath.row].payeeID {
                memberDataHelper.getAttribute(for: DBPathStrings.imageURLPath, userID: payee, completion: { (fetched: JSON) in
                    let url = URL(string: fetched.stringValue)
                    DispatchQueue.main.async {
                        cell.leftSideImage.kf.setImage(with: url)
                    }
                })
                
                memberDataHelper.getAttribute(for: DBPathStrings.namePath, userID: payee, completion: { (fetched: JSON) in
                    let name = fetched.stringValue
                    cell.leftSideName.text = name
                })
            }
            
            if let value = relation[indexPath.row].valueShouldPay {
                cell.leftSideDescription.text = "\(value)"
            }
            cell.rightSideDescription.text = "付給"
            
            return cell
        }
        
        return UITableViewCell()
    }
}













