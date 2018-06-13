//
//  GeneralService.swift
//  FastQuantum
//
//  Created by Shan on 2018/4/24.
//  Copyright © 2018年 ShanStation. All rights reserved.
//

import Foundation
import UIKit
import FirebaseDatabase
import FirebaseStorage
import SwiftyJSON

class GeneralService {
    static func findTopVC() -> UIViewController {
        var topController:UIViewController = (UIApplication.shared.keyWindow?.rootViewController)!
        // find the topmost view to present another view.
        while (topController.presentedViewController != nil) {
            topController = topController.presentedViewController!
        }
        return topController         
    }
    
    static func createUserInDB(userID: String, email: String, name: String) {
        var ref: DatabaseReference! {
            return Database.database().reference()
        }
        let userRef = ref.child(DBPathStrings.userDataPath).child(userID)
        let userNameRef = userRef.child(DBPathStrings.namePath)
        userNameRef.observeSingleEvent(of: .value) { (snapshot) in
            let json = JSON(snapshot.value ?? "")
            if let _ = json.string {
                // do nothing because name exists.                
            } else {
                userRef.setValue(["\(DBPathStrings.accountPath)":email,
                                  "\(DBPathStrings.namePath)":name,
                                  "\(DBPathStrings.imageURLPath)":DBPathStrings.defaultMemberImageURL])
            }
        }
    }
    
    static func storeUserMessageToken(userID: String, token: String) {
        var ref: DatabaseReference! {
            return Database.database().reference()
        }
        let tokenRef = ref.child(DBPathStrings.userDataPath).child(userID).child(DBPathStrings.token)
        tokenRef.setValue(token)
    }
    
    func upload(image: Data, uuid: String, path: String, completion: @escaping ((_ downloadURL: String) -> Void)) {
        var ref: StorageReference {
            return Storage.storage().reference().child(path)
        }
        
        let imgSaveRef = ref.child(uuid)
        
        imgSaveRef.putData(image, metadata: nil) { (metadata, error) in
            if error != nil {
                print("upload error: ", error ?? "" )
            } else {
                imgSaveRef.downloadURL { (url, error) in
                    if error == nil {
                        if let downloadURL = url {
                            let downloadString = downloadURL.absoluteString
                            completion(downloadString)
                        }
                    } else {
                        print("download error: ", error?.localizedDescription ?? "")
                    }
                }
            }
        }
    }
    
    func deleteFromStorageBy(folderPath: String, uid: String) {
        var ref: StorageReference! {
            return Storage.storage().reference()
        }
        let folderRef = ref.child(folderPath)
        let targetRef = folderRef.child(uid)
        targetRef.delete { (error) in
            if let error = error {
                print("deleting \(folderPath) image fails: ", error.localizedDescription )
            } else {
                print("deleting \(folderPath) image successes.")
            }
        }
    }
}















