//
//  MasterViewController.swift
//  DubizzleMoviesApp
//
//  Created by Hassan Abid on 09/01/2017.
//  Copyright © 2017 Hassan Abid. All rights reserved.
//

import UIKit
import RealmSwift
import Alamofire
import SwiftyJSON
import Kingfisher

class MasterViewController: UITableViewController {

    
    let realm = try! Realm()
    let results = try! Realm().objects(Movie.self).sorted(byProperty: "release_date", ascending: false)
    let defaults = UserDefaults.standard
    var notificationToken: NotificationToken?
    
    let API_BASE_URL = "https://api.themoviedb.org/3/discover/movie"
    let API_KEY = "API_KEY"
    
    let MIN_YEAR = 2015
    let MAX_YEAR = 2017
    
    let IMAGE_BASE_URL = "https://image.tmdb.org/t/p/w500"
    
    
    var detailViewController: DetailViewController? = nil

    var activityIndicatorView: UIActivityIndicatorView!

    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupUI()
        
    }

    override func viewWillAppear(_ animated: Bool) {
        self.clearsSelectionOnViewWillAppear = self.splitViewController!.isCollapsed
        super.viewWillAppear(animated)
    }


    //MARK: - UI
    
    func setupUI() {
    
        // Do any additional setup after loading the view, typically from a nib.
        self.navigationItem.leftBarButtonItem = self.editButtonItem
        
        let addButton = UIBarButtonItem(image: UIImage(named: "filter_list"), style: .plain, target: self, action: #selector(filterMovies(_:)))
        self.navigationItem.rightBarButtonItem = addButton
        if let split = self.splitViewController {
            let controllers = split.viewControllers
            self.detailViewController = (controllers[controllers.count-1] as! UINavigationController).topViewController as? DetailViewController
            
        }
        
        // Set results notification block
        self.notificationToken = results.addNotificationBlock { (changes: RealmCollectionChange) in
            switch changes {
            case .initial:
                print("Results are now populated and can be accessed without blocking the UI")
                self.tableView.reloadData()
                print("results.count: \(self.results.count)")
                break
            case .update(_, let deletions, let insertions, let modifications):
                print(" Query results have changed, so apply them to the TableView")
                self.tableView.beginUpdates()
                self.tableView.insertRows(at: insertions.map { IndexPath (row: $0, section: 0) } , with: .automatic)
                self.tableView.deleteRows(at: deletions.map { IndexPath (row: $0, section: 0)}, with: .automatic)
                self.tableView.reloadRows(at: modifications.map { IndexPath (row : $0, section: 0)}, with: .automatic)
                self.tableView.endUpdates()
                break
            case .error(let err):
                
                fatalError("\(err)")
                break
            }
        }
        
        activityIndicatorView = UIActivityIndicatorView(activityIndicatorStyle: UIActivityIndicatorViewStyle.gray)
        self.tableView.backgroundView = activityIndicatorView
        
        setDefaultValues()

        if(results.count == 0) {
            getMoviesviaApi() {_,_ in }
        }
    
    }
    
    
    func getMoviesviaApi(completion: @escaping (Bool, Error?) -> ()) {
        
        activityIndicatorView.startAnimating()
        
        let minYear = defaults.value(forKey: "MinYear") as! Int
        let maxYear = defaults.value(forKey: "MaxYear") as! Int
    
        let params: Parameters = ["api_key": API_KEY,
                      "primary_release_date.gte" : "\(minYear)-01-01",
                      "primary_release_date.lte" : "\(maxYear)-12-31"]
        
    
        Alamofire.request(API_BASE_URL, parameters: params)
            .responseJSON { response in
                

                switch response.result {
                    
                case .success:
                    if let value = response.result.value {
                        let json = JSON(value)
                        print("JSON: \(json.count))")
                        let json_movies = json["results"].array
                        print("JSON Movies : \(json_movies?.count)")
                        if let movies = json_movies  {
                            
                            self.addMoviesinBackground(movies)
                            completion(true, nil)

                        } else  {
                            
                            completion(false, NSError(domain: "MoviesListNotFound", code: 200, userInfo: nil))

                        }
                        self.activityIndicatorView.stopAnimating()

                        
                    }
                case .failure(let error):
                        print(error)
                        completion(false, error)
                        self.activityIndicatorView.stopAnimating()
                }
                
        }

    }
    
    // MARK: - Realm helper functions 
    
    func update() {
        print("update")
        getMoviesviaApi() {_,_ in }
    }
    
    func addMoviesinBackground(_ data : Array<JSON>!) {
        
        deleteMovies()
        
        let queue = DispatchQueue.global(priority: DispatchQueue.GlobalQueuePriority.default)
        // Import many items in a background thread
        queue.async {
            // Get new realm and table since we are in a new thread
            let realm = try! Realm()
            realm.beginWrite()
            for subJson in data {
                // Add row via dictionary. Order is ignored.

                realm.create(Movie.self, value: ["title": subJson["title"].stringValue,
                                                 "overview": subJson["overview"].stringValue,
                                                 "release_date": self.getFormattedDate(subJson["release_date"].stringValue)!,
                                                 "id": subJson["id"].int!,
                                                 "poster_path": subJson["poster_path"].stringValue,
                                                 "backdrop_path": subJson["backdrop_path"].stringValue,
                                                 "vote_average": subJson["vote_average"].double!,
                                                 "vote_count": subJson["vote_count"].int!])
            }
            
            try! realm.commitWrite()
        }
    }
    
    
    
    func deleteMovies() {
        
        try! realm.write {
            realm.deleteAll()
            NSLog("deleted existing movies");
        }
    }

    
    // MARK: - Segues

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "showDetail" {
            if let indexPath = self.tableView.indexPathForSelectedRow {
                let object = results[indexPath.row]
                let controller = (segue.destination as! UINavigationController).topViewController as! DetailViewController
                controller.detailItem = object
                controller.navigationItem.leftBarButtonItem = self.splitViewController?.displayModeButtonItem
                controller.navigationItem.leftItemsSupplementBackButton = true
            }
        }
    }

    // MARK: - Table View

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return results.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
       
        
        
        let cellIdentifier = "MovieTableViewCell"
        
        let cell = tableView.dequeueReusableCell(withIdentifier: cellIdentifier, for: indexPath) as! MovieTableViewCell
        
        let object = results[indexPath.row]
        cell.movieTitle?.text = object.title
        let formatted_date = getFormattedDateForUI(object.release_date)
        cell.movieReleaseDate.text = "\(formatted_date)"
    
        cell.moveBackgroundImage.kf.setImage(with: URL(string: "\(IMAGE_BASE_URL)\(object.backdrop_path)")!,
                                      placeholder: nil,
                                      options: [.transition(.fade(1))],
                                      progressBlock: nil,
                                      completionHandler: nil)
        
        
        return cell

    }

    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the specified item to be editable.
        return true
    }

    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            try! realm.write {
                realm.delete(results[indexPath.row])
            }

        } else if editingStyle == .insert {
            // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view.
        }
    }
    
    //MARK : - Utils 
    
    func getFormattedDate (_ releaseDate : String) -> Date? {
        
        print("\(releaseDate)")
    
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.date(from: releaseDate)


    
    }
    
    func getFormattedDateForUI(_ date: Date?) -> String {
    
        if let release_date = date {
        
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyy-MM-dd"
            return formatter.string(from: release_date)
        }
        
        return ""
    }

    func filterMovies(_ sender: Any) {
        
        // Show an altert view
        showYearEntryAlert()
    }
    
    func showYearEntryAlert() {
        
        let title = NSLocalizedString("Filter Movies", comment: "")
        let message = NSLocalizedString("Select Min and Max Year", comment: "")
        let cancelButtonTitle = NSLocalizedString("Cancel", comment: "")
        let otherButtonTitle = NSLocalizedString("OK", comment: "")
        
        let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)

        alertController.addTextField { textFieldMinYear in
            
            textFieldMinYear.placeholder = "Min Year e.g 2014"
            textFieldMinYear.textContentType = UITextContentType.telephoneNumber

        }
        
        alertController.addTextField { textFieldMaxYear in
            
            textFieldMaxYear.placeholder = "Max Year e.g 2016"
            textFieldMaxYear.textContentType = UITextContentType.telephoneNumber
            
        }
        
        let cancelAction = UIAlertAction(title: cancelButtonTitle, style: .cancel) { _ in
            
            NSLog("Do nothing")
            
        }
        
        let otherAction = UIAlertAction(title: otherButtonTitle, style: .default) { _ in
            
            let minYearTextField = alertController.textFields![0] as UITextField
            let maxYearTextField = alertController.textFields![1] as UITextField
            
            if let minYearText = minYearTextField.text {
               self.defaults.set(Int(minYearText), forKey: "MinYear")
            }
            
            if let maxYearText = minYearTextField.text {
                self.defaults.set(Int(maxYearText), forKey: "MaxYear")
            }
            NSLog("Filter Movies : \(minYearTextField.text) - \(maxYearTextField.text)")
            
            // Fetch movies again!
            self.getMoviesviaApi() {_,_ in }
            
        }
        
        alertController.addAction(cancelAction)
        alertController.addAction(otherAction)
        
        present(alertController, animated: true, completion: nil)
    }
    
    func setDefaultValues() {
    
        if let _ = defaults.value(forKey: "MaxYear") {
            
        } else {
            defaults.set(MAX_YEAR, forKey: "MaxYear")
        }
        
        if let _ = defaults.value(forKey: "MinYear") {
            
        } else {
            defaults.set(MIN_YEAR, forKey: "MinYear")
        }
    }
    
    func configureGrayActivityIndicatorView() {
        activityIndicatorView.activityIndicatorViewStyle = .gray
        
        activityIndicatorView.hidesWhenStopped = true
    }


}

