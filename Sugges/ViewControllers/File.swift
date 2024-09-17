//
//  File.swift
//  Sugges
//
//  Created by Emre İÇMEN on 17.09.2024.
//

import Foundation
/*
@IBAction func saveButton(_ sender: Any) {

    activityIndicator.startAnimating()
    
    let timestamp = Date().timeIntervalSince1970
    let postedTime = Date(timeIntervalSince1970: timestamp)
    
    let storageReference = storage.reference()
    let mediaFolder = storageReference.child("media")
    
    let stringNumber = placeRateTextFied.text!
    
    if let placeRateNumber = Int(stringNumber) {
        
        if placeRateNumber > 10 {
            makeAlert(title: "Rate number check!", message: "Rate must be between 0 to 10")
        }else {
            
            if imagesToLoad.count > 0 {
                var imageUrls: [String] = []
                let dispatchGroup = DispatchGroup()

                for image in imagesToLoad {
                    if let data = image.jpegData(compressionQuality: 0.5) {
                        let uuid = UUID().uuidString
                        let imageReference = mediaFolder.child("\(uuid).jpeg")

                        dispatchGroup.enter()
                        imageReference.putData(data, metadata: nil) { (metadata, error) in
                            if error != nil {
                                self.makeAlert(title: "Error", message: error?.localizedDescription ?? "Error when reaching medias")
                                dispatchGroup.leave()  // Hata olursa işlemi gruptan çıkar
                            } else {
                                imageReference.downloadURL { (url, error) in
                                    if let url = url {
                                        imageUrls.append(url.absoluteString)
                                    }
                                    dispatchGroup.leave()  // İşlemi gruptan çıkar
                                }
                            }
                        }
                    }
                }

                savePostToFirebase(completion: {
                    self.activityIndicator.stopAnimating()
                    if let tabBarController = self.tabBarController {
                        tabBarController.selectedIndex = 0  // İlk tab index'i 0'dır
                    }
                }, postedTime: postedTime, imageUrls: imageUrls)

            }
            else{
                makeAlert(title: "Error", message: "Please select a Photo!")
            }
        }
    } else {
        self.makeAlert(title: "Error", message: "Please fill all the areas!")
    }
}

 func savePostToFirebase(completion: @escaping () -> Void, postedTime: Date, imageUrls: [String]) {
     
     let dispatchGroup = DispatchGroup()

     // Tüm resimler yüklendiğinde çağrılır
     dispatchGroup.notify(queue: .main) {
         // Resim URL'leri ve diğer bilgileri Firestore'a yükle
         let fireStorePost = [
             "isVisited": false,
             "postedBy": self.currentUser ?? "",
             "date": postedTime,
             "placeName": self.placeNameTextField.text!,
             "placeKind": self.placeKindTextField.text!,
             "placeRate": self.placeRateTextFied.text ?? "",
             "placeDistrict": self.placeDistrictTextField.text ?? "",
             "placeLatitude": self.latitude,
             "placeLongitude": self.longitude,
             "imageUrl": imageUrls,  // Birden fazla resim URL'sini kaydediyoruz
             "placeSummary": self.placeSummaryTextField.text!
         ] as [String: Any]
         
         self.fireStoreReference = self.fireStoreDatabase.collection("Posts").addDocument(data: fireStorePost, completion: { (error) in
             if error != nil {
                 self.makeAlert(title: "Error", message: error?.localizedDescription ?? "")
             }
         })
         
         completion()

     }
 }
*/
