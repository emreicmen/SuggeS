//
//  VisitedViewController.swift
//  Sugges
//
//  Created by Emre İÇMEN on 11.09.2024.
//

import UIKit
import Firebase
import Kingfisher
import FirebaseAuth


class VisitedViewController: UIViewController{
    
    //MARK: Declarations
    let fireStoreDatabase = Firestore.firestore()
    var userEmail = Auth.auth().currentUser?.email ?? ""
    
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var searchBar: UISearchBar!
    
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
    
    var isSearching = false
    var choosenPostId: String = ""
    var isDataFetched = false
    var isVisited = true
    
    var posts = [Post]() // Tüm gönderileri tutar
    var filteredPosts = [Post]() // Filtrelenmiş gönderileri tutar (arama için)
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        searchBar.delegate = self
        tableView.delegate = self
        tableView.dataSource = self
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        tableView.reloadData()
        
        getAllPosts()
        
    }
    
    
    //MARK: Firebase veri çekme
    
    func getAllPosts() {
        getPostsFromFirebase { result in
            switch result {
            case .success(let posts): // Dönüş türü artık [Post]
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
    }
    
    func getPostsFromFirebase(completion: @escaping (Result<[Post], Error>) -> Void) {
        guard !isDataFetched else { return }
        isDataFetched = true
        
        fireStoreDatabase.collection("Posts")
            .whereField("isVisited", isEqualTo: true)
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
                
                    self.makeAlert(title: "No visited place yet!", message: "Begin the journey!!!")
                    self.isDataFetched = false
                    return
                }
                
                self.posts.removeAll() // Mevcut tüm gönderileri temizle
                
                for document in snapshot.documents {
                    let data = document.data()
                    let userId = document.documentID
                    
                    var postedDate = ""
                    if let timestamp = data["date"] as? Timestamp {
                        let date: Date = timestamp.dateValue()
                        let dateFormatter = DateFormatter()
                        dateFormatter.dateStyle = .medium
                        dateFormatter.timeStyle = .medium
                        postedDate = dateFormatter.string(from: date)
                    } else {
                        print("Error: Date field not found or not a Timestamp.")
                    }
                    
                    var imageUrls: [String] = []
                    if let imageArray = data["imageUrl"] as? [String], !imageArray.isEmpty {
                        imageUrls = imageArray
                    } else if let imageString = data["imageUrl"] as? String {
                        imageUrls.append(imageString)
                    }
                    
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
                    
                    self.posts.append(post) // Posts dizisine gönderiyi ekle
                }
                
                completion(.success(self.posts)) // Tamamlanan veriyle geri dönüş yap
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
//MARK: TableView
extension VisitedViewController:UITableViewDelegate, UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // Arama modundaysa, filtrelenmiş dizinin uzunluğunu döndür, değilse tüm gönderi dizisinin uzunluğunu döndür
        return isSearching ? filteredPosts.count : posts.count
    }
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "visitedCell", for: indexPath) as! VisitedTableViewCell
        
        let post: Post
        if isSearching {
            post = filteredPosts[indexPath.row] // Arama modundaysa, filtrelenmiş gönderiyi kullan
        } else {
            post = posts[indexPath.row] // Normal moddaysa, tüm gönderiyi kullan
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
            cell.placeImage.image = UIImage(named: "placeholder") // Eğer resim yoksa bir placeholder kullanabilirsiniz.
        }
        
        return cell
    }
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let post: Post
        if isSearching {
            guard indexPath.row < filteredPosts.count else {
                print("Hata: indexPath.row, filteredPosts dizisinin sınırlarını aşıyor.")
                return
            }
            post = filteredPosts[indexPath.row] // Arama modundaysa, filtrelenmiş gönderiyi kullan
        } else {
            guard indexPath.row < posts.count else {
                print("Hata: indexPath.row, posts dizisinin sınırlarını aşıyor.")
                return
            }
            post = posts[indexPath.row] // Normal moddaysa, tüm gönderiyi kullan
        }
        
        choosenPostId = post.userId! // Doğrudan Post nesnesinden userId alınır
        print(choosenPostId)
        performSegue(withIdentifier: "toDetailsVC", sender: nil)
    }
    
    //Silme işlemi
    func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        let deleteAction = UIContextualAction(style: .destructive, title: "Delete") { contextualAction, view, bool in
            let alert = UIAlertController(title: "Delete Action", message: "Do you want to delete location?", preferredStyle: .alert)
            let cancelAction = UIAlertAction(title: "Cancel", style: .cancel)
            alert.addAction(cancelAction)
            
            let okAction = UIAlertAction(title: "Delete", style: .destructive) { [weak self] action in
                Task {
                    do {
                        let documentID = self?.isSearching == true ? self?.filteredDocumentIdArray[indexPath.row] : self?.documentIdArray[indexPath.row]
                        try await self?.fireStoreDatabase.collection("Posts").document(documentID!).delete()
                        DispatchQueue.main.async { // Ana iş parçacığında UI güncellemesi yapın
                            self?.getAllPosts()
                            //                            self?.getDatasFromFirebase()
                        }
                    } catch {
                        self?.makeAlert(title: "Error", message: error.localizedDescription)
                    }
                }
            }
            alert.addAction(okAction)
            self.present(alert, animated: true)
        }
        return UISwipeActionsConfiguration(actions: [deleteAction])
    }
    
    //Segue
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "toDetailsVC" {
            let destinationVC = segue.destination as! DetailsViewController
            destinationVC.selectedPostId = choosenPostId
            destinationVC.isVisited = true
        }
    }
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 150.0 // Burada sabit bir yükseklik verdik
    }

}


//MARK: SearchBar
extension VisitedViewController: UISearchBarDelegate  {
    
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        if searchText.isEmpty {
            isSearching = false
            filteredPosts.removeAll() // Arama iptal edildiğinde, filtrelenmiş gönderileri temizleyin
        } else {
            isSearching = true
            filterContentForSearchText(searchText)
        }
        tableView.reloadData()
        print("TableView yeniden yüklendi. Arama metni: '\(searchText)'")
    }

    private func filterContentForSearchText(_ searchText: String) {
        filteredPosts = posts.filter { post in
            let doesMatch = post.placeName.lowercased().contains(searchText.lowercased()) ||
                            post.placeRate.lowercased().contains(searchText.lowercased()) ||
                            post.placeDistrict.lowercased().contains(searchText.lowercased()) ||
                            post.placeSummary.lowercased().contains(searchText.lowercased())
            
            if doesMatch {
                print("Eşleşen gönderi: \(post.placeName)")
            }
            
            return doesMatch
        }
        
        print("Filtreleme tamamlandı. Filtrelenen gönderi sayısı: \(filteredPosts.count)")
        tableView.reloadData() // Sonuçları yeniden yükle
    }

    internal func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        isSearching = false
        searchBar.text = ""
        filteredPosts.removeAll() // Filtrelenmiş gönderileri temizleyin
        print("Arama iptal edildi.")
        tableView.reloadData()
    }

}
