//
//  SettingsViewController.swift
//  Sugges
//
//  Created by Emre İÇMEN on 29.08.2024.
//

import UIKit
import FirebaseAuth
import Firebase

class SettingsViewController: UIViewController {

    @IBOutlet weak var addPlaceCountTextField: UITextField!
    @IBOutlet weak var visitedPlaceCountTextField: UITextField!
    @IBOutlet weak var userNameLabel: UILabel!
    @IBOutlet weak var userNameTextField: UITextField!
    
    let fireStoreDatabase = Firestore.firestore()
    var userEmail = Auth.auth().currentUser?.email ?? ""
    var isDataFetched = false
    
    var userName = String()
    var documentIdArray = [String]()
    var visitedPlaceCount = Int()
    var addedPlaceCount = Int()
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        getDatasFromFirebase { placeCount in
            self.addPlaceCountTextField.text = placeCount
        }

        getUserEmailFromUserData()
        
        getUserFromFirebase { userNameByFirebase in
            self.userName = userNameByFirebase
            self.userNameLabel.text = "Username: \(userNameByFirebase)"
        }
        self.userNameTextField.isUserInteractionEnabled = true
    }
        
    //MARK: Update username
    @IBAction func updateButton(_ sender: Any) {

        updateUserName(byEmail: userEmail, newUserName: userNameTextField.text!) { success in
            if self.userNameTextField.text != "" {
                DispatchQueue.main.async {
                    if success {
                        let alert = UIAlertController(title: "Succes", message: "Username succesfully updated!", preferredStyle: UIAlertController.Style.alert)
                        let okButton = UIAlertAction(title: "Ok", style: UIAlertAction.Style.default) { _ in
                            self.userNameTextField.text = nil
                            self.tabBarController?.selectedIndex = 0
                        }
                        alert.addAction(okButton)
                        self.present(alert, animated: true, completion: nil)
                    } else {
                        self.makeAlert(title: "Error", message: "Username couldn't updated!")
                    }
                }
            }else{
                self.makeAlert(title: "Error", message: "Username field can not be empty!!!")
            }
            
        }
        self.userNameTextField.isUserInteractionEnabled = false
    }
            
    //MARK: Log out
    @IBAction func logOut(_ sender: Any) {
        
        logOtProcess {
            self.performSegue(withIdentifier: "toLogInVC", sender: nil)
        }

    }
}

//MARK: Firebase Veri upload/download/logput
extension SettingsViewController {
    
    //MARK: Username çekme
    func getUserFromFirebase(completion: @escaping (String) -> Void) {

        guard !userEmail.trimmingCharacters(in: .whitespaces).isEmpty else {
            return
        }

        fireStoreDatabase.collection("UserInfo").whereField("email", isEqualTo: self.userEmail).getDocuments { (querySnapshot, error) in
            if let error = error {
                print("Error: \(error.localizedDescription)")
            } else {
                // Sorgudan dönen belgeler varsa
                if let documents = querySnapshot?.documents, !documents.isEmpty {
                    // İlk belgeyi al ve username alanını çek
                    if let username = documents.first?.data()["userName"] as? String {
                        completion(username)
                    } else {
                        print("Username not found!.")
                    }
                } else {
                    print("No matching user. No user with this e-mail in database.")
                }
            }
        }
    }
    
    //MARK: Post sayısını çekme
    func getDatasFromFirebase(completion: @escaping (String) -> Void){
        // Veriler daha önce çekildiyse yeniden çekme
        guard !isDataFetched else { return }
        isDataFetched = true
        
        fireStoreDatabase.collection("Posts").whereField("isVisited", isEqualTo: false).whereField("postedBy", isEqualTo: userEmail).addSnapshotListener { (snapshot, error) in
            if let error = error {
                print("Firestore Hatası: \(error.localizedDescription)")
                self.makeAlert(title: "Error", message: error.localizedDescription)
                self.isDataFetched = false // Hata olursa tekrar denemek için flag'i false yap
                return
            }
            
            // Eğer snapshot boşsa veya kullanıcının hiç gönderisi yoksa
            guard let snapshot = snapshot, !snapshot.documents.isEmpty else {
                self.makeAlert(title: "No Added Place", message: "Add place for show!")
                self.isDataFetched = false
                
                return
            }
            
            self.documentIdArray.removeAll()

            for document in snapshot.documents {
                let documentID = document.documentID
                self.documentIdArray.append(documentID)
            }
            self.addedPlaceCount = self.documentIdArray.count
            
            if self.addedPlaceCount <= 0 {
                self.addPlaceCountTextField.text = "None"
            }else {
                completion(String(self.addedPlaceCount))
            }

        }
        
        fireStoreDatabase.collection("Posts").whereField("isVisited", isEqualTo: true).whereField("postedBy", isEqualTo: userEmail).addSnapshotListener { (snapshot, error) in
            if let error = error {
                print("Firestore Hatası: \(error.localizedDescription)")
                self.makeAlert(title: "Error", message: error.localizedDescription)
                self.isDataFetched = false // Hata olursa tekrar denemek için flag'i false yap
                return
            }
            
            // Eğer snapshot boşsa veya kullanıcının hiç gönderisi yoksa
            guard let snapshot = snapshot, !snapshot.documents.isEmpty else {
                self.isDataFetched = false
                return
            }
            
            self.documentIdArray.removeAll()

            for document in snapshot.documents {
                let documentID = document.documentID
                self.documentIdArray.append(documentID)
            }
            self.visitedPlaceCount = self.documentIdArray.count
            
            if self.visitedPlaceCount <= 0 {
                self.visitedPlaceCountTextField.text = "None"
            }else {
                self.visitedPlaceCountTextField.text = String(self.visitedPlaceCount)
            }

        }

    }
        
    //MARK: Username update
    private func updateUserName(byEmail email: String, newUserName: String, completion: @escaping (Bool) -> Void) {
            
        if userNameTextField.text == "" {
            makeAlert(title: "Error", message: "Username can not be Empty!!!")
        }
        else{
            fireStoreDatabase.collection("UserInfo").whereField("email", isEqualTo: email).getDocuments { querySnapshot, error in
                    if let error = error {
                        self.makeAlert(title: "Error", message: "Error while updating username.Please try again later")
                        completion(false)
                        return
                    }
                    
                    guard let documents = querySnapshot?.documents, !documents.isEmpty else {
                        completion(false)
                        return
                    }
                    
                    for document in documents {
                        self.fireStoreDatabase.collection("UserInfo").document(document.documentID).updateData(["userName": newUserName]) { error in
                            if let error = error {
                                self.makeAlert(title: "Error", message: "Error while updating username.Please try again later")
                                completion(false)
                            } else {
                                completion(true)
                            }
                        }
                        return
                    }
                    
                    completion(false)
                }
            }
        }
    
    //MARK: Logout
    func logOtProcess(completion: @escaping () -> Void) {
        do {
            try Auth.auth().signOut()
            completion()

        }catch {
            self.makeAlert(title: "Error", message: "Error when Log Out. Try again!")
        }
    }
}

//MARK: Other stuffs
extension SettingsViewController {
    
    func makeAlert(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: UIAlertController.Style.alert)
        let okButton = UIAlertAction(title: "Ok", style: UIAlertAction.Style.default, handler: nil)
        alert.addAction(okButton)
        self.present(alert, animated: true, completion: nil)
    }
    
    func getUserEmailFromUserData() {
        
        if userEmail.isEmpty {
            if let receivedString = UserDefaults.standard.string(forKey: "userEmailString") {
                self.userEmail = receivedString
            }
        }
    }
}
