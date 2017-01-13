//
//  DetailViewController.swift
//  DubizzleMoviesApp
//
//  Created by Hassan Abid on 09/01/2017.
//  Copyright © 2017 Hassan Abid. All rights reserved.
//

import UIKit

class DetailViewController: UIViewController {


    @IBOutlet weak var posterImage: UIImageView!

    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var overviewLabel: UILabel!
    @IBOutlet weak var voteCount: UILabel!
    @IBOutlet weak var relaseDateLabel: UILabel!
    
    let IMAGE_BASE_URL = "https://image.tmdb.org/t/p/w300"
    
    var detailItem: Movie?
    
    func configureView() {
        // Update the user interface for the detail item.
        if let detail = self.detailItem {
            
            let formatted_date = self.getFormattedDateForUI(detail.release_date)
            self.relaseDateLabel.text = "Released on \(formatted_date)"

            self.titleLabel.text = detail.title
            self.voteCount.text = "Votes : \(detail.vote_count)"
            self.overviewLabel.text = detail.overview
            
            self.posterImage.kf.setImage(with: URL(string: "\(IMAGE_BASE_URL)\(detail.poster_path)")!,
                                                 placeholder: nil,
                                                 options: [.transition(.fade(1))],
                                                 progressBlock: nil,
                                                 completionHandler: nil)

        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.configureView()
    }

    
    //MARK : - Utils
    
    func getFormattedDateForUI(_ date: Date?) -> String {
        
        if let release_date = date {
            
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyy-MM-dd"
            return formatter.string(from: release_date)
        }
        
        return ""
    }


}

