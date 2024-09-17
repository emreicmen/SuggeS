//
//  ViewController.swift
//  Sugges
//
//  Created by Emre İÇMEN on 29.08.2024.
//

import UIKit
import Firebase
import Kingfisher
import FirebaseAuth

class FeedViewController: UIViewController {
    
    //MARK: Declarations
    let fireStoreDatabase = Firestore.firestore()
    var userEmail = Auth.auth().currentUser?.email ?? ""

    @IBOutlet weak var searchBar: UISearchBar!
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var userNameTextField: UILabel!
    
    var userEmailArray = [String]()
    var placeKindArray = [String]()
    var placeNameArray = [String]()
    var placeLatitudeArray = [Double]()
    var placeLongitudeArray = [Double]()
    var placeRateArray = [String]()
    var placeSummaryArray = [String]()
    var placeDistrictArray = [String]()
    var placeImageArray = [String]()
    var documentIdArray = [String]()
    var placeAddedDateArray = [String]()
    
    // Filtrelenmiş diziler
    var filteredPlaceNameArray = [String]()
    var filteredPlaceRateArray = [String]()
    var filteredPlaceDistrictArray = [String]()
    var filteredPlaceSummaryArray = [String]()
    var filteredPlaceKindArray = [String]()
    var filteredPlaceImageArray = [String]()
    var filteredDocumentIdArray = [String]()
    var filteredPlaceAddedDateArray = [String]()
    
    var isSearching = false // Arama modunu kontrol etmek için
    
    var choosenPostId: String = ""

    var isDataFetched = false
    var userName = String()
    var posts = [Post]() // Tüm gönderileri tutar
    var filteredPosts = [Post]() // Filtrelenmiş gönderileri tutar (arama için)
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
            
        searchBar.delegate = self
        tableView.delegate = self
        tableView.dataSource = self
        userNameTextField.text = nil

        // Kullanıcı adını gerçek zamanlı dinle
        if !userEmail.isEmpty {
            getUserNameFromFirebase(email: userEmail)
            
        }
        print(userEmail)
        
        tableView.reloadData()
        
        getAllPosts()
        
    }

    func getAllPosts() {
        
        getPostsFromFirebase { result in
                switch result {
                case .success(let posts):
                    DispatchQueue.main.async {
                        // Tüm dizileri temizle
                        self.placeImageArray.removeAll()
                        self.placeDistrictArray.removeAll()
                        self.placeKindArray.removeAll()
                        self.placeNameArray.removeAll()
                        self.placeRateArray.removeAll()
                        self.documentIdArray.removeAll()
                        self.placeSummaryArray.removeAll()
                        self.placeAddedDateArray.removeAll()

                        // Her gönderiyi dolaş ve dizilere ekle
                        for post in posts {
                            self.placeImageArray.append(contentsOf: post.imageUrls) // Her gönderinin resim URL'lerini ekle
                            self.placeDistrictArray.append(post.placeDistrict)
                            self.placeKindArray.append(post.placeKind)
                            self.placeNameArray.append(post.placeName)
                            self.placeRateArray.append(post.placeRate)
                            self.documentIdArray.append(post.userId!)
                            self.placeSummaryArray.append(post.placeSummary)
                            self.placeAddedDateArray.append(post.date)
                        }
                        
                        self.tableView.reloadData()
                    }
                    
                case .failure(let error):
                    // Hata durumunu yönetin
                    DispatchQueue.main.async {
                        self.makeAlert(title: "Error", message: error.localizedDescription)
                    }
                }
            }
            
            if userEmail == "" {
                if let receivedString = UserDefaults.standard.string(forKey: "userEmailString") {
                    self.userEmail = receivedString
                }
            }
            
            UserDefaults.standard.set(userName, forKey: "userName")
    }
    
    //MARK: UserInfo tablosundan değişiklikleri dinleyip anlık çekme
    func getUserNameFromFirebase(email: String) {
        fireStoreDatabase.collection("UserInfo").whereField("email", isEqualTo: userEmail).addSnapshotListener { (querySnapshot, error) in
            if let error = error {
                print("Hata oluştu: \(error.localizedDescription)")
            } else {
                // Sorgudan dönen belgeler varsa
                if let documents = querySnapshot?.documents, !documents.isEmpty {
                    // İlk belgeyi al ve username alanını çek
                    if let username = documents.first?.data()["userName"] as? String {
                        self.userNameTextField.text = username
                        self.userName = username
                        UserDefaults.standard.set(username, forKey: "userName")

                    } else {
                        print("Username not found.")
                    }
                } else {
                    print("No matching user. No user with this e-mail in database.")
                }
            }
        }
    }
    
    //MARK: Firebase'den Postları çekme
    func getPostsFromFirebase(completion: @escaping (Result<[Post], Error>) -> Void) {
        
        guard !isDataFetched else { return }
        isDataFetched = true

        //Veri çekmek için gerekli sorgu
        fireStoreDatabase.collection("Posts")
            .whereField("isVisited", isEqualTo: false)
            .whereField("postedBy", isEqualTo: userEmail)
            .order(by: "date", descending: true)
            .addSnapshotListener { (snapshot, error) in
                
                if let error = error {
                    print("Firestore Error: \(error.localizedDescription)")
                    self.makeAlert(title: "Error", message: error.localizedDescription)
                    self.isDataFetched = false
                    completion(.failure(error))
                    return
                }

                guard let snapshot = snapshot, !snapshot.documents.isEmpty else {
                    let alert = UIAlertController(title: "No Post Yet", message: "Add Post to show!", preferredStyle: .alert)
                    let okButton = UIAlertAction(title: "Ok", style: .default) { _ in
                        self.tabBarController?.selectedIndex = 1
                    }
                    alert.addAction(okButton)
                    self.present(alert, animated: true, completion: nil)
                    self.isDataFetched = false
                    return
                }

                self.posts.removeAll()
                
                //Verileri alanlarıyla çekme
                for document in snapshot.documents {
                    
                    var postedDate = ""
                    var imageUrls: [String] = []
                    
                    let data = document.data()
                    let userId = document.documentID
                                        
                    if let timestamp = data["date"] as? Timestamp {
                        let date: Date = timestamp.dateValue()
                        let dateFormatter = DateFormatter()
                        dateFormatter.dateStyle = .medium
                        dateFormatter.timeStyle = .medium
                        postedDate = dateFormatter.string(from: date)
                    } else {
                        print("Error: Date field not found or not a Timestamp.")
                    }

                    if let imageArray = data["imageUrl"] as? [String], !imageArray.isEmpty {
                        imageUrls = imageArray
                    } else if let imageString = data["imageUrl"] as? String {
                        imageUrls.append(imageString)
                    }

                    //Alanları teker teker alma
                    guard let placeKind = data["placeKind"] as? String,
                          let placeDistrict = data["placeDistrict"] as? String,
                          let placeLatitude = data["placeLatitude"] as? Double,
                          let placeLongitude = data["placeLongitude"] as? Double,
                          let placeName = data["placeName"] as? String,
                          let placeRate = data["placeRate"] as? String,
                          let placeSummary = data["placeSummary"] as? String else {
                              let fieldError = NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Some fields are missing."])
                              self.makeAlert(title: "Error", message: fieldError.localizedDescription)
                              self.isDataFetched = false
                              completion(.failure(fieldError))
                              return
                    }

                    //Çekilen alanların Post cinsinden oluşturulan objeye atama
                    let post = Post(date: postedDate,
                                    imageUrls: imageUrls,
                                    placeDistrict: placeDistrict,
                                    placeKind: placeKind,
                                    placeLatitude: placeLatitude,
                                    placeLongitude: placeLongitude,
                                    placeName: placeName,
                                    placeRate: placeRate,
                                    placeSummary: placeSummary,
                                    userId: userId)
                    
                    //Çekilen alanların eklenmesi
                    self.posts.append(post)
                }
                
                completion(.success(self.posts))
                self.tableView.reloadData()
            }
    }
    
    func makeAlert(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: UIAlertController.Style.alert)
        let okButton = UIAlertAction(title: "Ok", style: UIAlertAction.Style.default, handler: nil)
        alert.addAction(okButton)
        self.present(alert, animated: true, completion: nil)
    }
}

//MARK: TableView işlemleri
extension FeedViewController: UITableViewDelegate, UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
            // Arama modundaysa, filtrelenmiş dizinin uzunluğunu döndür, değilse tüm gönderi dizisinin uzunluğunu döndür
            return isSearching ? filteredPosts.count : posts.count
        }
        
        func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
            
            let post: Post
            
            let cell = tableView.dequeueReusableCell(withIdentifier: "feedCell", for: indexPath) as! FeedTableViewCell
            
            // Arama modundaysa, filtrelenmiş gönderiyi kullan
            if isSearching {
                post = filteredPosts[indexPath.row]
            } else {
                // Normal moddaysa, tüm gönderiyi kullan
                post = posts[indexPath.row]
            }

            cell.placeName.text = post.placeName
            cell.placeKind.text = post.placeKind
            cell.placeDistrict.text = post.placeDistrict
            cell.placeRate.text = post.placeRate
            cell.placeAddedDate.text = post.date
            
            // Her gönderinin ilk resmini göster (eğer varsa)
            if let imageUrlString = post.imageUrls.first, let url = URL(string: imageUrlString) {
                cell.placeImage.kf.setImage(with: url)
            } else {
                // Eğer resim yoksa bir placeholder
                cell.placeImage.image = UIImage(named: "placeholder")
            }
            return cell
        }

    //MARK: Visited durumunu değiştirme
    func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        
        let deleteAction = UIContextualAction(style: .destructive, title: "Move to Visited") { [weak self] contextualAction, view, bool in
            guard let self = self else { return }
            
            let alert = UIAlertController(title: "Archive Action", message: "Do you want to move to Visited this Place?", preferredStyle: .alert)
            let cancelAction = UIAlertAction(title: "Cancel", style: .cancel)
            alert.addAction(cancelAction)
            
            let okAction = UIAlertAction(title: "Archive", style: .destructive) { action in
                
                let documentID = self.isSearching ? self.filteredDocumentIdArray[indexPath.row] : self.documentIdArray[indexPath.row]
                let documentReference = self.fireStoreDatabase.collection("Posts").document(documentID)

                // isVisited alanını true olarak güncelleyin
                documentReference.updateData(["isVisited": true]) { error in
                    if let error = error {
                        print("Error updating document: \(error.localizedDescription)")
                    } else {
                        print("Document successfully updated")
                    }
                }
                //Visited durumu değiştirildikten sonra verileri tekrar çekiyoruz ki işlem yapılan post gösterilmesin
                DispatchQueue.main.async {
                    self.getAllPosts()
                }
            }
            alert.addAction(okAction)
            self.present(alert, animated: true)
        }
        return UISwipeActionsConfiguration(actions: [deleteAction])
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        let post: Post
        
        if isSearching {
            guard indexPath.row < filteredPosts.count else {
                print("Hata: indexPath.row, filteredPosts dizisinin sınırlarını aşıyor.")
                return
            }
            //Arama modundaysa filtrelenmiş gönderiyi kullan
            post = filteredPosts[indexPath.row]
        } else {
            guard indexPath.row < posts.count else {
                print("Hata: indexPath.row, posts dizisinin sınırlarını aşıyor.")
                return
            }
            //Normal moddaysa tüm gönderiyi kullan
            post = posts[indexPath.row]
        }
        //Doğrudan Post nesnesinden userId alınır
        choosenPostId = post.userId!
        print(choosenPostId)
        performSegue(withIdentifier: "toDetailsVC", sender: nil)
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 150.0
    }
    
    //Segue
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "toDetailsVC" {
            let destinationVC = segue.destination as! DetailsViewController
            destinationVC.selectedPostId = choosenPostId
        }
    }
}

//MARK: SearchBar
extension FeedViewController: UISearchBarDelegate {
    
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        
        if searchText.isEmpty {
            isSearching = false
            //Arama iptal edildiğinde filtrelenmiş gönderileri temizleme
            filteredPosts.removeAll()
        } else {
            isSearching = true
            filterContentForSearchText(searchText)
        }
        tableView.reloadData()
    }

    private func filterContentForSearchText(_ searchText: String) {
        
        filteredPosts = posts.filter { post in
            let doesMatch = post.placeName.lowercased().contains(searchText.lowercased()) ||
                            post.placeRate.lowercased().contains(searchText.lowercased()) ||
                            post.placeDistrict.lowercased().contains(searchText.lowercased()) ||
                            post.placeSummary.lowercased().contains(searchText.lowercased())

            return doesMatch
        }
        tableView.reloadData()
    }

    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        isSearching = false
        searchBar.text = ""
        filteredPosts.removeAll()
        print("Arama iptal edildi.")
        tableView.reloadData()
    }
}



