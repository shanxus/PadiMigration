//
//  EntityHelperClass.swift
//  FastQuantum
//
//  Created by Shan on 2018/3/27.
//  Copyright © 2018年 ShanStation. All rights reserved.
//

import Foundation
import UIKit
import Firebase

final class EntityHelperClass {            
    static var ref: DatabaseReference! {
        return Database.database().reference()
    }
    
    static func getDateNow() -> TimeInterval {
        let date = Date()
        let now = date.timeIntervalSince1970
        return now
    }
    
    static func getPadiEntityDateString(with timeInterval: TimeInterval) -> String {
        
        let date = Date(timeIntervalSince1970: timeInterval)
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy/MM/dd"
        let timeResult = formatter.string(from: date)
        
        return timeResult
    }
    
    static func upload(image: UIImage, fileName: String, completion: @escaping ((_ downloadURL: String) -> Void)) {
        
        var ref: StorageReference {
            return Storage.storage().reference().child("eventImage").child(fileName)
        }
        
        guard let target = UIImageJPEGRepresentation(image, 0.1) else {return}
        
        let uploadTask = ref.putData(target, metadata: nil) { (metadata, error) in
            
            if error != nil {
                print(error?.localizedDescription ?? "error")
            } else {
                /* use this to get url. */
                ref.downloadURL(completion: { (url, error) in
                    if let url = url {
                        completion(url.absoluteString)
                    }
                })
            }
        }
        
        uploadTask.observe(.progress) { (snapshot) in
            print(snapshot.progress ?? "NO More Progress.")
        }
    }
}







