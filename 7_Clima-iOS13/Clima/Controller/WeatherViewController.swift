//
//  ViewController.swift
//  Clima
//
//  Created by Angela Yu on 01/09/2019.
//  Copyright © 2019 App Brewery. All rights reserved.
//

import UIKit
import CoreLocation

class WeatherViewController: UIViewController {

    @IBOutlet weak var conditionImageView: UIImageView!
    @IBOutlet weak var temperatureLabel: UILabel!
    @IBOutlet weak var cityLabel: UILabel!
    @IBOutlet weak var searchField: UITextField!
    @IBOutlet weak var background: UIImageView!
    @IBOutlet weak var JokeButton: UIButton!
    @IBOutlet weak var jokeLabel: UILabel!
    @IBAction func JokeButtonTapped(_ sender: UIButton) {
        fetchDadJoke()
    }
    
    //MARK: Properties
    var weatherManager = WeatherDataManager()
    let locationManager = CLLocationManager()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        locationManager.delegate = self
        weatherManager.delegate = self
        searchField.delegate = self
        jokeLabel.text = "Press the button to get a joke!"
    }


}
 
//MARK:- TextField extension
extension WeatherViewController: UITextFieldDelegate {
    
        @IBAction func searchBtnClicked(_ sender: UIButton) {
            searchField.endEditing(true)    //dismiss keyboard
            print(searchField.text!)
            
            searchWeather()
        }
        
        func fetchDadJoke() {
        // APIのURL
        let url = URL(string: "https://icanhazdadjoke.com/")!
        
        // URLリクエストを作成
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("application/json", forHTTPHeaderField: "Accept")
            // JSON形式をリクエスト

        // ネットワークリクエストを送信
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            // エラーチェック
            if let error = error {
                print("Error fetching joke: \(error)")
                DispatchQueue.main.async {
                    self.jokeLabel.text = "Failed to fetch joke. Try again!"
                }
                return
            }

            // データ確認
            guard let data = data else {
                print("No data returned")
                DispatchQueue.main.async {
                    self.jokeLabel.text = "No joke found. Try again!"
                }
                return
            }

            // JSONをデコード
            do {
                if let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any],
                   let joke = json["joke"] as? String {
                    // メインスレッドでUIを更新
                    DispatchQueue.main.async {
                        self.jokeLabel.text = joke
                        print(joke)
                    }
                } else {
                    print("Unexpected JSON structure")
                }
            } catch {
                print("Failed to decode JSON: \(error)")
                DispatchQueue.main.async {
                    self.jokeLabel.text = "Error decoding joke. Try again!"
                }
            }
        }

        // リクエストを開始
        task.resume()
        }

        
    
        func searchWeather(){
            if let cityName = searchField.text{
                weatherManager.fetchWeather(cityName)
            }
        }
        
        // when keyboard return clicked
        func textFieldShouldReturn(_ textField: UITextField) -> Bool {
            searchField.endEditing(true)    //dismiss keyboard
            print("action: search, city: \(searchField.text!)")
            
            searchWeather()
            return true
        }
        
        // when textfield deselected
        func textFieldShouldEndEditing(_ textField: UITextField) -> Bool {
            // by using "textField" (not "searchField") this applied to any textField in this Controller(cuz of delegate = self)
            if textField.text != "" {
                return true
            }else{
                textField.placeholder = "Type something here"
                return false            // check if city name is valid
            }
        }
        
        // when textfield stop editing (keyboard dismissed)
        func textFieldDidEndEditing(_ textField: UITextField) {
    //        searchField.text = ""   // clear textField
        }
}

//MARK:- View update extension
extension WeatherViewController: WeatherManagerDelegate {
    
    func updateWeather(weatherModel: WeatherModel){
        DispatchQueue.main.sync {
            temperatureLabel.text = weatherModel.temperatureString
            cityLabel.text = weatherModel.cityName
            self.conditionImageView.image = UIImage(systemName: weatherModel.conditionName)
            switch weatherModel.cityName {
            case "Tokyo":
                background.image = UIImage(named: "Tokyo")
            default:
                background.image = UIImage(named: "background")
            }
        }
    }
    
    func failedWithError(error: Error){
        print(error)
    }
}

// MARK:- CLLocation
extension WeatherViewController: CLLocationManagerDelegate {
    
    @IBAction func locationButtonClicked(_ sender: UIButton) {
        // Get permission
        locationManager.requestWhenInUseAuthorization()
        locationManager.requestLocation()
    }
    
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        if let location = locations.last {
            let lat = location.coordinate.latitude
            let lon = location.coordinate.longitude
            weatherManager.fetchWeather(lat, lon)
        }
    }
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print(error)
    }
}
