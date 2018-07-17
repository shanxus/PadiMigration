//
//  AddNewPaymentInfoBlockTVC.swift
//  FastQuantum
//
//  Created by Shan on 2018/3/14.
//  Copyright © 2018年 ShanStation. All rights reserved.
//

import UIKit

class AddNewPaymentInfoBlockTVC: UITableViewCell {

    @IBOutlet weak var paymentImage: UIImageView!
    @IBOutlet weak var paymentTitle: UILabel!
    @IBOutlet weak var indicatorLabel: UILabel!
    
    weak var selectedPayIconDelegate: defaultIconSelectionDelegate?
    
    override func awakeFromNib() {
        
        paymentImage.isUserInteractionEnabled = true
        let imageTap = UITapGestureRecognizer(target: self, action: #selector(handleCellImageTapped))
        paymentImage.addGestureRecognizer(imageTap)
        
        paymentTitle.isUserInteractionEnabled = true
        let titleTap = UITapGestureRecognizer(target: self, action: #selector(handleCellNameTapped))
        paymentTitle.addGestureRecognizer(titleTap)
    }
    
    @objc func handleCellImageTapped() {
        let topVC = GeneralService.findTopVC()
        if let defaultIconVC = topVC.storyboard?.instantiateViewController(withIdentifier: "DefaultPayIconVC") as? DefaultIconSelectVC {
            defaultIconVC.delegate = self
            topVC.present(defaultIconVC, animated: true, completion: nil)
        }
    }
    
    @objc func handleCellNameTapped() {
        let topVC = GeneralService.findTopVC()
        if let showEditTxtFieldVC = topVC.storyboard?.instantiateViewController(withIdentifier: "showEditTxtFieldVC") as? ShowEditTxtFieldVC {
            
            guard let payNameForNow = paymentTitle.text else {return}
            
            let txtInfo = EditTxtInfo(flag: Flag.addEventName.rawValue, titleTxt: "更改款項名稱", inputTxt: payNameForNow, actionTxt: "儲存")
            showEditTxtFieldVC.viewTxtPrepare = txtInfo
            showEditTxtFieldVC.passEventNameDelegate = self
            
            topVC.present(showEditTxtFieldVC, animated: true, completion: nil)
        }
    }
}

extension AddNewPaymentInfoBlockTVC: defaultIconSelectionDelegate {
    func pass(selectedType: String) {
        paymentImage.image = UIImage(named: selectedType)
        selectedPayIconDelegate?.pass(selectedType: selectedType)
    }
}

extension AddNewPaymentInfoBlockTVC: PassEventNameBack {
    func passEventName(event name: String) {
        paymentTitle.text = name
    }
}








