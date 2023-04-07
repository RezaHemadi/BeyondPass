//
//  getUserProfilePhoto.swift
//  ARWorld
//
//  Created by Reza Hemadi on 4/7/18.
//  Copyright © 2018 ArvandGroup. All rights reserved.
//

import Foundation

func getUserProfilePhoto(_ user: PFUser, completion: @escaping (_ image: UIImage?, _ error: Error?) -> Void) {
    // check if user has uploaded a photo to the db
    if let imageFile = user["profilePic"] as? PFFileObject {
        imageFile.getDataInBackground {
            (imageData, error) in
            if let imageData = imageData {
                let image = UIImage(data: imageData)
                completion(image, nil)
            } else if let error = error {
                completion(nil, error)
            }
        }
    } else {
        // Attempt to get progile picture from Facebook
        Profile.loadCurrentProfile {
            (profile, error) in
            if let profile = profile {
                let imageURL = profile.imageURL(forMode: Profile.PictureMode.normal, size: CGSize.init(width: 512, height:512))!
                
                URLSession.shared.dataTask(with: imageURL) {
                    (data: Data?, urlResponse: URLResponse?, error: Error?) in
                    if let data = data {
                        let image = UIImage(data: data)
                        completion(image, nil)
                    }
                    }.resume()
            }
        }
    }
}
