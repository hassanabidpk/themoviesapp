//
//  Movie.swift
//  DubizzleMoviesApp
//
//  Created by Hassan Abid on 11/01/2017.
//  Copyright © 2017 Hassan Abid. All rights reserved.
//

import Foundation
import RealmSwift


class Movie: Object {
    
    dynamic var title = ""
    dynamic var overview = ""
    dynamic var release_date: Date? = nil
    dynamic var id = 0
    dynamic var poster_path = ""
    dynamic var backdrop_path = ""
    dynamic var vote_average = 0.0
    dynamic var vote_count = 0
    
}
