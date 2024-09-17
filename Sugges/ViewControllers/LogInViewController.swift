//
//  LogInViewController.swift
//  Sugges
//
//  Created by Emre İÇMEN on 29.08.2024.
//

import UIKit
import Firebase
import FirebaseAuth
import MessageUI


class LogInViewController: UIViewController {

    @IBOutlet weak var emailTextField: UITextField!
    @IBOutlet weak var passwordTextField: UITextField!
    @IBOutlet weak var userNameTextField: UITextField!
    @IBOutlet weak var toggleButton: UIButton!
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    
    let fireStoreDatabase = Firestore.firestore()
    
    var blurEffectView: UIVisualEffectView?

    var userEmail = String()
    
    override func viewDidLoad() {
        super.viewDidLoad()
    


    }
    
    override func viewWillAppear(_ animated: Bool) {
        
        activityIndicator.hidesWhenStopped = true
        activityIndicator.stopAnimating()
        
        self.view.bringSubviewToFront(activityIndicator)
        
        passwordTextField.isSecureTextEntry = true // Şifreyi gizle
        toggleButton.setImage(UIImage(systemName: "eye.slash"), for: .normal) // Göz kapalı ikonu
    
        UserDefaults.standard.set(userEmail, forKey: "userEmailString")
    }
    

    
    //MARK: Log In
    @IBAction func logInButton(_ sender: Any) {
        
        activityIndicator.startAnimating()
        addBlurEffect()

        //Login işlemi yapan fonksiyon
        logInProcess {
            guard let _ = self.emailTextField.text,
                  let _ = self.passwordTextField.text else {return}
            
            self.activityIndicator.stopAnimating()
            self.performSegue(withIdentifier: "toFeedVC", sender: nil)
            self.removeBlurEffect()
        }
        
    }
        
    //MARK: Sign Up
    @IBAction func signUpButton(_ sender: Any) {
        
        activityIndicator.startAnimating()
        addBlurEffect()
        
        //SgnUp işlemini yapan fonksiyon
        signUpProcess {
            
            guard let email = self.emailTextField.text else {return}
            self.userEmail = email
        
            
            UserDefaults.standard.set(self.userEmail, forKey: "userEmailString")
            
            self.activityIndicator.stopAnimating()
            self.performSegue(withIdentifier: "toFeedVC", sender: nil)
            self.removeBlurEffect()
        }
        
    }
    
    //MARK: Forgot password
    @IBAction func forgotPasswordButton(_ sender: Any) {
        
        let alert = UIAlertController(title: "Forgot Password", message: "Please type your E-mail", preferredStyle: .alert)
        alert.addTextField { textField in
            textField.placeholder = "E-mail address"
        }
        let resetAction = UIAlertAction(title: "Send", style: .default) { _ in
            if let email = alert.textFields?.first?.text, !email.isEmpty {
                self.resetPassword(email: email)
            } else {
                print("E-mail address can not be empty!")
            }
        }
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
        
        alert.addAction(resetAction)
        alert.addAction(cancelAction)
        
        self.present(alert, animated: true, completion: nil)
    }
    
    func makeAlert(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: UIAlertController.Style.alert)
        let okButton = UIAlertAction(title: "Ok", style: UIAlertAction.Style.default, handler: nil)
        alert.addAction(okButton)
        self.present(alert, animated: true, completion: nil)
    }
}

//MARK: Email Gönderme
extension LogInViewController: MFMailComposeViewControllerDelegate {
    
    func resetPassword(email: String) {
        Auth.auth().sendPasswordReset(withEmail: email) { error in
            if let error = error {
                // Hata durumunda kullanıcıya mesaj gösterin
                print("Password reset error: \(error.localizedDescription)")
            } else {
                // Başarılı durumda kullanıcıya bilgi verin
                self.sendEmail(to: self.userEmail)
            }
        }
    }
    
    func sendEmail(to email: String) {
        if MFMailComposeViewController.canSendMail() {
            let mail = MFMailComposeViewController()
            mail.mailComposeDelegate = self
            mail.setToRecipients([email]) // Gönderilecek e-posta adresi
            mail.setSubject("Password Reminder")
            mail.setMessageBody("Hello, this mail for password reset.", isHTML: false)
            
            self.present(mail, animated: true)
        } else {
            print("E-mail couldn't send. Please make sure for defined mail on your device.")
        }
    }

        // MFMailComposeViewControllerDelegate - E-posta gönderimi tamamlandıktan sonra çağrılır
    func mailComposeController(_ controller: MFMailComposeViewController, didFinishWith result: MFMailComposeResult, error: Error?) {
        controller.dismiss(animated: true)
        
        switch result {
        case .sent:
            makeAlert(title: "Email", message: "E-mail sended succesfully!")
        case .saved:
            makeAlert(title: "Email", message: "E-mail draft saved succesfully!")
        case .cancelled:
            makeAlert(title: "Email", message: "E-mail send process canceled!")
        case .failed:
            makeAlert(title: "Email", message: "E-mail couldnt send: \(error?.localizedDescription ?? "Unkonwn error")")
        @unknown default:
            makeAlert(title: "Email", message: "Unkown error!")
        }
    }
}

//MARK: Firase ile Giriş-Kullanıcı oluşturma
extension LogInViewController {
    
    func logInProcess(completion: @escaping () -> Void){
        
        guard let email = emailTextField.text, !email.isEmpty,
              let password = passwordTextField.text, !password.isEmpty else {
            self.makeAlert(title: "Error", message: "Fill the all areas!!!")
            
            self.activityIndicator.stopAnimating()
            self.removeBlurEffect()
            return
        }
        Auth.auth().signIn(withEmail: emailTextField.text!, password: passwordTextField.text!) { authData, error in
            if error != nil {
                self.makeAlert(title: "Error", message: error?.localizedDescription ?? "Error while Login In")
                self.activityIndicator.stopAnimating()
                self.removeBlurEffect()
            }else {
                completion()
            }
        }
    }

    func signUpProcess(completion: @escaping () -> Void){
        
        guard let email = emailTextField.text, !email.isEmpty,
              let password = passwordTextField.text, !password.isEmpty,
              let userName = userNameTextField.text, !userName.isEmpty else {
            self.makeAlert(title: "Error", message: "Fill the all areas!!!")
            return
        }

        Auth.auth().createUser(withEmail: email, password: password) { authResult, error in
                if let error = error {
                    self.makeAlert(title: "Error!", message: error.localizedDescription)
                    return
                }
                
                let userDictionary: [String: Any] = [
                    "email": email,
                    "userName": userName
                ]
                
                self.fireStoreDatabase.collection("UserInfo").addDocument(data: userDictionary) { error in
                    if let error = error {
                        self.makeAlert(title: "Error!", message: error.localizedDescription)
                        return
                    }
                completion()
                }
            }
    }

}

//MARK: Visual
extension LogInViewController {
    
    func addBlurEffect() {
        
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
    
    // Blur efektini kaldıran fonksiyon
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
    
    @IBAction func togglePasswordVisibility(_ sender: UIButton) {
        passwordTextField.isSecureTextEntry.toggle() // Şifre görünürlüğünü değiştir
        
        if passwordTextField.isSecureTextEntry {
            toggleButton.setImage(UIImage(systemName: "eye.slash"), for: .normal) // Göz kapalı ikonu
        } else {
            toggleButton.setImage(UIImage(systemName: "eye"), for: .normal) // Göz açık ikonu
        }
    }
}
