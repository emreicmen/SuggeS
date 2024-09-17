//
//  UploadViewController.swift
//  Sugges
//
//  Created by Emre İÇMEN on 29.08.2024.
//

import UIKit
import CoreLocation
import MapKit
import FirebaseAuth
import FirebaseStorage
import FirebaseFirestore
import PhotosUI

class UploadViewController: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate,UITextViewDelegate {

    //MARK: Declarations
    @IBOutlet weak var placeNameTextField: UITextField!
    @IBOutlet weak var placeDistrictTextField: UITextField!
    @IBOutlet weak var placeKindTextField: UITextField!
    @IBOutlet weak var placeRateTextFied: UITextField!
    @IBOutlet weak var placeSummaryTextField: UITextView!
    @IBOutlet weak var scrollView: UIScrollView!
    @IBOutlet private weak var pagerControl: UIPageControl!
    @IBOutlet weak var placePhoto: UIImageView!
    @IBOutlet weak var mapKit: MKMapView!
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    var blurEffectView: UIVisualEffectView?

    //Firebase
    let currentUser = Auth.auth().currentUser?.email
    let storage = Storage.storage()
    let uuid = UUID().uuidString
    let fireStoreDatabase = Firestore.firestore()
    var fireStoreReference: DocumentReference? = nil
    
    //Location
    var locationManager = CLLocationManager()
    var latitude: Double = 0.0
    var longitude: Double = 0.0
    
    //Image
    var images: [UIImage] = []
    let imageWidth: CGFloat = 377
    let imageHeight: CGFloat = 200
    var imagesToLoad: [UIImage] = []

    var userName = String()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        locationManagerDefinations()
        
        gestureRecognizerDefinations()
        
        setupScrollView()
        
        setupPageControl()
        
        placePhoto.image = UIImage(named: "selectImage")
        
        imagesToLoad.removeAll(keepingCapacity: false)
        
        placeSummaryTextField.delegate = self

        self.view.bringSubviewToFront(pagerControl)
    }
    
    
    override func viewWillAppear(_ animated: Bool) {
        
        clearFields()
        
        gestureRecognizerDefinations()
        
        setupScrollView()
        
        imagesToLoad.removeAll(keepingCapacity: false)
        
        placeSummaryTextField.delegate = self

        self.view.bringSubviewToFront(pagerControl)
        
        activityIndicator.hidesWhenStopped = true
        activityIndicator.stopAnimating()
        self.view.bringSubviewToFront(activityIndicator)


    }
    
    override func viewWillDisappear(_ animated: Bool) {
        imagesToLoad.removeAll()
        updateScrollView()
    }
    
    func textViewDidBeginEditing(_ textView: UITextView) {
        placeSummaryTextField.text = ""  // İçeriği sil
    }

    
    func saveData(postedTime: Date, imageUrls: [String], completion: @escaping () -> Void) {
        
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
    
    //MARK: Firebase Data Save
    @IBAction func saveButton(_ sender: Any) {
        
        addBlurEffect()
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

                    // Tüm resimler yüklendiğinde çağrılır
                    dispatchGroup.notify(queue: .main) {
                        
                        self.saveData(postedTime: postedTime, imageUrls: imageUrls) {
                            if let tabBarController = self.tabBarController {
                                tabBarController.selectedIndex = 0  // İlk tab index'i 0'dır
                            }
                        }
                        self.removeBlurEffect()
                        self.activityIndicator.stopAnimating()
                    }
                }
                else{
                    makeAlert(title: "Error", message: "Please select a Photo!")
                    self.removeBlurEffect()
                    self.activityIndicator.stopAnimating()
                }
            }
        } else {
            self.makeAlert(title: "Error", message: "Please fill all the areas!")
            self.removeBlurEffect()
            self.activityIndicator.stopAnimating()
        }
    }
}

//MARK: Location Stuffs
extension UploadViewController: CLLocationManagerDelegate {
    
    //Sürekli enlem boylam ve hızdaki değişiklilikleri verecek
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        
        let sonKonum = locations[locations.count - 1]
        
        latitude = sonKonum.coordinate.latitude
        longitude = sonKonum.coordinate.longitude
        print("\(latitude) - \(longitude)")
        
        let konum = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
        //Zoom miktarı
        let span = MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
        let bolge = MKCoordinateRegion(center: konum, span: span)
        mapKit.setRegion(bolge, animated: true)
        
        //Kırmızı pin oluşturmak için
        let pin = MKPointAnnotation()
        pin.coordinate = konum
        pin.title = "You are Here!"
        mapKit.addAnnotation(pin)
    }
    
    func locationManagerDefinations() {
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.requestWhenInUseAuthorization()
        locationManager.startUpdatingLocation()
        locationManager.delegate = self
    }
}

//MARK: ImageView Stuffs
extension UploadViewController: PHPickerViewControllerDelegate {
    
        @objc func openPhotoGallery() {
        var config = PHPickerConfiguration()
        config.selectionLimit = 3 // Maksimum 3 resim seçilebilir
        config.filter = .images // Sadece görselleri seçmke için

        let picker = PHPickerViewController(configuration: config)
        picker.delegate = self
        present(picker, animated: true, completion: nil)
    }
    
    func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
        
        picker.dismiss(animated: true, completion: nil)
        
        // Eğer bir resim seçilmediyse çıkış yap
        guard !results.isEmpty else { return }
        
        imagesToLoad.removeAll()
        
        placePhoto.image = nil
        
        for result in results {
            if result.itemProvider.canLoadObject(ofClass: UIImage.self) {
                result.itemProvider.loadObject(ofClass: UIImage.self) { [weak self] (object, error) in
                    if let image = object as? UIImage {
                        DispatchQueue.main.async {
                            self?.imagesToLoad.append(image) // Seçilen resmi diziye ekleyin
                            self?.updateScrollView()
                        }
                    }
                }
            }
        }
    }
    
    // Kullanıcı iptal ettiğinde çağrılır
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        dismiss(animated: true, completion: nil)
    }

    func gestureRecognizerDefinations() {
        placePhoto.isUserInteractionEnabled = true
        let gestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(openPhotoGallery))
        placePhoto.addGestureRecognizer(gestureRecognizer)
    }
}

//MARK: ScrollView
extension UploadViewController: UIScrollViewDelegate {
    
    func setupScrollView() {
        
        scrollView.delegate = self
        scrollView.isPagingEnabled = true
        scrollView.showsHorizontalScrollIndicator = false
        scrollView.isHidden = true // Başlangıçta gizli
    }
    
    func updateScrollView() {
        
        if !imagesToLoad.isEmpty {
            placePhoto.image = nil
        }
        scrollView.isHidden = false
        pagerControl.isHidden = false
        
        // Mevcut tüm görüntüleri ve içerikleri temizleyin
        for subview in scrollView.subviews {
            subview.removeFromSuperview()
        }
        
        scrollView.contentSize = CGSize(width: imageWidth * CGFloat(imagesToLoad.count), height: imageHeight)
        
        for i in 0..<imagesToLoad.count {
            let imageView = UIImageView(image: imagesToLoad[i])
            imageView.contentMode = .scaleAspectFit
            imageView.frame = CGRect(x: imageWidth * CGFloat(i), y: 0, width: imageWidth, height: imageHeight)
            imageView.isUserInteractionEnabled = true // Kullanıcı etkileşimini etkinleştir
            
            // Her bir imageViewa dokunma tanıyıcı ekleme
            let tapGesture = UITapGestureRecognizer(target: self, action: #selector(openPhotoGallery))
            imageView.addGestureRecognizer(tapGesture)
            
            scrollView.addSubview(imageView)
        }

        pagerControl.numberOfPages = imagesToLoad.count
        scrollView.contentOffset = .zero
    }
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        // ScrollView kaydırıldığında, pageControl'un currentPage'ini güncelleme
        let pageIndex = round(scrollView.contentOffset.x / imageWidth)
        pagerControl.currentPage = Int(pageIndex)
    }
    
    func setupPageControl() {
        pagerControl.currentPage = 0
        pagerControl.isHidden = true
        pagerControl.addTarget(self, action: #selector(pageControlChanged(_:)), for: .valueChanged)
        pagerControl.hidesForSinglePage = true
    }
    
    @objc func pageControlChanged(_ sender: UIPageControl) {
        // PageControl değiştirildiğinde, ScrollView'u doğru sayfaya kaydırma
        let offset = CGPoint(x: imageWidth * CGFloat(sender.currentPage), y: 0)
        scrollView.setContentOffset(offset, animated: true)
    }
}

//MARK: Other Stuffs
extension UploadViewController {
    
    func clearFields() {
        placePhoto.image = UIImage(named: "selectImage")
        placeNameTextField.text = ""
        placeRateTextFied.text = ""
        placeKindTextField.text = ""
        placeDistrictTextField.text = ""
    }
        
    func addBlurEffect() {
        // Zaten bir blur efekti eklenmiş mi kontrol et
        if blurEffectView == nil {
            // Blur efekti oluşturma
            let blurEffect = UIBlurEffect(style: .regular) // .light, .dark gibi farklı stiller de seçebilirsiniz
            let blurView = UIVisualEffectView(effect: blurEffect)
            blurView.frame = view.bounds
            blurView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
            blurView.alpha = 0 // Başlangıçta görünmez
            
            // Blur view'ı Activity Indicator'ın altına ekleme
            view.insertSubview(blurView, belowSubview: activityIndicator)
            
            // Blur view'ı geri referans olarak saklama
            blurEffectView = blurView
            
            // Animasyon ile görünür yapma
            UIView.animate(withDuration: 0.3) {
                blurView.alpha = 1
            }
        }
    }
    
    func removeBlurEffect() {
        if let blurView = blurEffectView {
            // Animasyon ile görünmez yapma
            UIView.animate(withDuration: 0.3, animations: {
                blurView.alpha = 0
            }) { _ in
                blurView.removeFromSuperview()
                self.blurEffectView = nil
            }
        }
    }
        
    func makeAlert(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: UIAlertController.Style.alert)
        let okButton = UIAlertAction(title: "Ok", style: UIAlertAction.Style.default, handler: nil)
        alert.addAction(okButton)
        self.present(alert, animated: true, completion: nil)
    }
}

