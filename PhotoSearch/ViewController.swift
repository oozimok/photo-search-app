//
//  ViewController.swift
//  PhotoSearch
//
//  Created by Oleg Ozimok on 11/02/2019.
//  Copyright © 2019 Oleg Ozimok. All rights reserved.
//

import UIKit

class ViewController: UIViewController {

    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var textField: UITextField!
    @IBOutlet weak var loader: UIActivityIndicatorView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        textField.delegate = self
        textField.becomeFirstResponder()
        imageView.layer.masksToBounds = true
        searchImage(text: "zebra")
    }
    
    func showError(text: String) {
        self.showLoader(show: false)
        let alert = UIAlertController(title: "Ошибка", message: text, preferredStyle: .alert)
        let ok = UIAlertAction(title: "Ok", style: .default)
        alert.addAction(ok)
        DispatchQueue.main.async() {
            self.present(alert, animated: true)
        }
    }
    
    func showLoader(show: Bool) {
        DispatchQueue.main.async() {
            if show {
                self.loader.startAnimating()
            } else {
                self.loader.stopAnimating()
            }
        }
    }

    func searchImage(text: String) {
        self.showLoader(show: true)
        self.imageView.image = nil

        let textToSearch = text.addingPercentEncoding(withAllowedCharacters: .urlHostAllowed) ?? ""
        
        let base = "https://api.unsplash.com/search/photos"
        let key = "?client_id=3e85aab43f6724d70fd6efe1539e7d7982263c8a3d1cc99d281e7dedbf6e48a0"
        let options = "&per_page=1&query=\(textToSearch)"
        let searchUrl = base + key + options
        
        let url = URL(string: searchUrl)!
        
        URLSession.shared.dataTask(with: url) { (data, response, error) in
            guard
                let httpURLResponse = response as? HTTPURLResponse, httpURLResponse.statusCode == 200,
                let mimeType = response?.mimeType, mimeType == "application/json",
                let jsonData = data, error == nil
            else {
                self.showError(text: "Нет данных")
                return
            }
                
            guard let jsonAny = try? JSONSerialization.jsonObject(with: jsonData, options: []) else {
                self.showError(text: "Не удалось десериализовать данные")
                return
            }

            guard let json = jsonAny as? [String:Any] else {
                self.showError(text: "Не удалось преобразовать данные")
                return
            }
            
            guard let resultsArray = json["results"] as? [Any] else {
                self.showError(text: "Не удалось получить массив")
                return
            }
            
            guard resultsArray.count > 0 else {
                self.showError(text: "Не удалось найти фотографию")
                return
            }
            
            guard let photo = resultsArray[0] as? [String:Any] else {
                self.showError(text: "Не удалось получить информацию о фотографии")
                return
            }
            
            guard let urls = photo["urls"] as? [String:Any] else {
                self.showError(text: "Не удалось получить список адресов фотографий")
                return
            }

            guard let photoUrl = urls["small"] as? String else {
                self.showError(text: "Не удалось получить адрес фотографии")
                return
            }
            
            let url = URL(string: photoUrl)
            
            URLSession.shared.dataTask(with: url!) { data, response, error in
                guard
                    let httpURLResponse = response as? HTTPURLResponse, httpURLResponse.statusCode == 200,
                    let mimeType = response?.mimeType, mimeType.hasPrefix("image"),
                    let data = data, error == nil,
                    let image = UIImage(data: data)
                else {
                    self.showError(text: "Не удалось получить фотографию")
                    return
                }
                self.showLoader(show: false)
                DispatchQueue.main.async() {
                    self.imageView.image = image
                }
            }.resume()
            
        }.resume()
    }
}

extension ViewController: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        searchImage(text: textField.text!)
        return true
    }
}
