//
//  DetailsViewController.swift
//  Sugges
//
//  Created by Emre İÇMEN on 30.08.2024.
//

import UIKit
import MapKit
import Firebase
import Kingfisher
import PhotosUI

class DetailsViewController: UIViewController,UIScrollViewDelegate {

    let fireStoreDatabase = Firestore.firestore()

    //MARK: Declarations
    @IBOutlet weak var postedDateLabel: UILabel!
    @IBOutlet weak var placeNameLabel: UILabel!
    @IBOutlet weak var placeKindLabel: UILabel!
    @IBOutlet weak var placeRateLabel: UILabel!
    @IBOutlet weak var placeSummaryLabel: UITextView!
    @IBOutlet weak var placeDistrictLabel: UILabel!
    @IBOutlet weak var mapKit: MKMapView!
    @IBOutlet weak var placeImageView: UIImageView!
    @IBOutlet weak var pageControl: UIPageControl!
    @IBOutlet weak var scrollView: UIScrollView!
    @IBOutlet weak var collectionView: UICollectionView!
    

    var isVisited = Bool()
    
    var firebaseDatabaseName = String()
    
    var selectedPostId = String()
    var placeLatitude = Double()
    var placeLongitude = Double()
    var placeName = String()
    var imageUrls: [String] = []
    var placeImageViews: [UIImageView] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()

        mapKit.delegate = self
        pageControl.currentPage = 0
        
        getDatasFromFirebase()
        setupScrollView()
        
        self.view.bringSubviewToFront(pageControl)
        pageControl.isUserInteractionEnabled = false
    }
    /*
    
    //MARK: Firebase'den veri alma
    func getDatasFromFirebase() {
        
        getDatas { result in
            
            switch result {
            case .success(let post):
                DispatchQueue.main.async {
                    // İlk görseli ayarla
//                    if let firstImageUrl = post.imageUrls.first, let url = URL(string: firstImageUrl) {
//                        self.placeImageView.kf.setImage(with: url)
//                    }
                    
                    if post.imageUrls.count == 1, let firstImageUrl = post.imageUrls.first, let url = URL(string: firstImageUrl) {
                        // Tek resim varsa sadece placeImageView kullan
                        self.placeImageView.isHidden = false
                        self.scrollView.isHidden = true
                        self.pageControl.isHidden = true
                        self.placeImageView.kf.setImage(with: url)
                    } else if post.imageUrls.count > 1 {
                        // Birden fazla resim varsa scrollView ve pageControl kullan
                        self.placeImageView.isHidden = true
                        self.scrollView.isHidden = false
                        self.pageControl.isHidden = false
                        self.imageUrls = post.imageUrls // Resim URL'lerini ayarla
                        self.setupScrollView() // ScrollView'ı ayarla
                    } else {
                        // Resim yoksa placeholder göster
                        self.placeImageView.isHidden = false
                        self.scrollView.isHidden = true
                        self.pageControl.isHidden = true
                        self.placeImageView.image = UIImage(named: "placeholder") // Placeholder resim göster
                    }
                    
                    
                    // Etiketleri güncelle
                    self.placeKindLabel.text = post.placeKind
                    self.placeDistrictLabel.text = post.placeDistrict
                    self.placeNameLabel.text = post.placeName.uppercased()
                    self.placeRateLabel.text = "\(post.placeRate) / 10"
                    
                    // Özet bilgiyi ayarla
                    if post.placeSummary.isEmpty {
                        self.placeSummaryLabel.text = "Not Info"
                    } else {
                        self.placeSummaryLabel.text = post.placeSummary
                    }
                    
                    // Eklenen tarihi ayarla
                    self.postedDateLabel.text = "Added Date: \(post.date)"
                    
                    // ScrollView'ı ayarla
                    self.setupScrollView()
                    
                    self.placeLatitude = post.placeLatitude
                    self.placeLongitude = post.placeLongitude
                    self.placeName = post.placeName
                
                    self.mapInfos(title: post.placeName, latitude: post.placeLatitude, longitude: post.placeLongitude)

                }
                
            case .failure(let error):
                // Hata durumunu yönetin
                DispatchQueue.main.async {
                    self.makeAlert(title: "Error", message: error.localizedDescription)
                }
            }
        }

        
    }
    
    */
    
    func getDatasFromFirebase() {
        getDatas { result in
            switch result {
            case .success(let post):
                DispatchQueue.main.async {
                    // Çekilen resimleri kontrol et
                    self.imageUrls = post.imageUrls // Resim URL'lerini ayarla
                    
                    if self.imageUrls.count > 0 {
                        // Eğer bir veya birden fazla resim varsa scrollView kullan
                        self.placeImageView.isHidden = true
                        self.scrollView.isHidden = false
                        self.pageControl.isHidden = self.imageUrls.count == 1 // Tek resim varsa sayfa kontrolünü gizle
                        self.setupScrollView() // ScrollView'ı ayarla
                    } else {
                        // Resim yoksa placeholder göster
                        self.placeImageView.isHidden = false
                        self.scrollView.isHidden = true
                        self.pageControl.isHidden = true
                        self.placeImageView.image = UIImage(named: "placeholder") // Placeholder resim göster
                    }

                    // Diğer etiketleri güncelle
                    self.placeKindLabel.text = post.placeKind
                    self.placeDistrictLabel.text = post.placeDistrict
                    self.placeNameLabel.text = post.placeName.uppercased()
                    self.placeRateLabel.text = "\(post.placeRate) / 10"
                    
                    // Özet bilgiyi ayarla
                    if post.placeSummary.isEmpty {
                        self.placeSummaryLabel.text = "Not Info"
                    } else {
                        self.placeSummaryLabel.text = post.placeSummary
                    }
                    
                    // Eklenen tarihi ayarla
                    self.postedDateLabel.text = "Added Date: \(post.date)"
                    
                    self.placeLatitude = post.placeLatitude
                    self.placeLongitude = post.placeLongitude
                    self.placeName = post.placeName

                    self.mapInfos(title: post.placeName, latitude: post.placeLatitude, longitude: post.placeLongitude)
                }
                
            case .failure(let error):
                // Hata durumunu yönetin
                DispatchQueue.main.async {
                    self.makeAlert(title: "Error", message: error.localizedDescription)
                }
            }
        }
    }

    func getDatas(completion: @escaping (Result<Post, Error>) -> Void) {
    
        fireStoreDatabase.collection("Posts").document("\(selectedPostId)").getDocument { (document, error) in

            if let error = error {
                self.makeAlert(title: "Error", message: error.localizedDescription)
                completion(.failure(error))
                return
            }
            
            guard let document = document, document.exists, let data = document.data() else {
                let docError = NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Belge mevcut değil veya veriler alınamadı."])
                self.makeAlert(title: "Error", message: docError.localizedDescription)
                completion(.failure(docError))
                return
            }
            
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
                      let fieldError = NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Gerekli alanlardan bazıları eksik."])
                      self.makeAlert(title: "Error", message: fieldError.localizedDescription)
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
                            placeSummary: placeSummary)
            
            // Başarılı sonuçla tamamla
            completion(.success(post))
        }
    }



}

//MARK: Harita işlemleri
extension DetailsViewController: MKMapViewDelegate {
    
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        
        if annotation is MKUserLocation { // Kullanıcının yerini pin ile göstermek istemiyoruz
            return nil
        }
        
        let reusId = "myAnnotation"
        var pinView = mapView.dequeueReusableAnnotationView(withIdentifier: reusId) as? MKMarkerAnnotationView
        
        if pinView == nil {
            pinView = MKMarkerAnnotationView(annotation: annotation, reuseIdentifier: reusId)
            pinView?.canShowCallout = true
            pinView?.tintColor = UIColor.black
            
            // Callout (baloncuk) içerisinde button olacak
            let button = UIButton(type: UIButton.ButtonType.detailDisclosure)
            pinView?.rightCalloutAccessoryView = button
        } else {
            pinView?.annotation = annotation
        }
        return pinView
    }

    func mapView(_ mapView: MKMapView, annotationView view: MKAnnotationView, calloutAccessoryControlTapped control: UIControl) {
        
        // Navigasyonu başlatmak için
        let requestLocation = CLLocation(latitude: self.placeLatitude, longitude: self.placeLongitude) // requestLocaiton değil requestLocation olmalı.
        
        CLGeocoder().reverseGeocodeLocation(requestLocation) { (placemarks, error) in
            if let placemarks = placemarks, let placemark = placemarks.first { // Optional binding ile placemarks dizisini kontrol ediyoruz
                let newPlacemark = MKPlacemark(placemark: placemark)
                let item = MKMapItem(placemark: newPlacemark)
                item.name = self.placeName
                
                // Nasıl bir navigasyon yapacağımızı belirtiyoruz. Yürüyerek mi araçla mı
                let launchOptions = [MKLaunchOptionsDirectionsModeKey: MKLaunchOptionsDirectionsModeDriving]
                item.openInMaps(launchOptions: launchOptions)
            } else if let error = error {
                print("Error reverse geocoding location: \(error.localizedDescription)")
            }
        }
    }

    func mapInfos(title: String,latitude: Double, longitude: Double) {
        
        let annotation = MKPointAnnotation()
        annotation.title = self.placeName
        let coordinate = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
        annotation.coordinate = coordinate
        
        //Pini gösterme
        self.mapKit.addAnnotation(annotation)
        
        //Burada artık anlık konum aldırmayı durduruyoruz.Amacımız konum değiştiğinde haritanın da ekranda otomatik haritayı getirmesi
        let span = MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
        let region = MKCoordinateRegion(center: coordinate, span: span)
        self.mapKit.setRegion(region, animated: true)
    }

}

//MARK: Stuffs
extension DetailsViewController {
    
    func makeAlert(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: UIAlertController.Style.alert)
        let okButton = UIAlertAction(title: "Ok", style: UIAlertAction.Style.default, handler: nil)
        alert.addAction(okButton)
        self.present(alert, animated: true, completion: nil)
    }
}

//MARK: ScrollView
extension DetailsViewController {
    
    @IBAction func pageControlValueChanged(_ sender: UIPageControl) {
        let currentPage = sender.currentPage
        let x = CGFloat(currentPage) * scrollView.frame.width
        scrollView.setContentOffset(CGPoint(x: x, y: 0), animated: true)
    }

    // Sayfa kaydırma işlemi tamamlandığında PageControl güncelleme
    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        let currentPage = Int(scrollView.contentOffset.x / scrollView.frame.width)
        pageControl.currentPage = currentPage
    }
    
    func setupScrollView() {
        scrollView.delegate = self
        scrollView.contentSize = CGSize(width: scrollView.frame.width * CGFloat(imageUrls.count), height: scrollView.frame.height)
        scrollView.isPagingEnabled = true
        scrollView.showsHorizontalScrollIndicator = false

        pageControl.numberOfPages = imageUrls.count
        pageControl.currentPage = 0

        for (index, urlString) in imageUrls.enumerated() {
            let imageView = UIImageView()
            imageView.contentMode = .scaleAspectFit
            imageView.clipsToBounds = true
            
            if let url = URL(string: urlString) {
                imageView.kf.setImage(with: url)
            }
            
            let xPosition = scrollView.frame.width * CGFloat(index)
            imageView.frame = CGRect(x: xPosition, y: 0, width: scrollView.frame.width, height: scrollView.frame.height)
            scrollView.addSubview(imageView)
            
            placeImageViews.append(imageView)
        }
    }



}
