//
//  DubizzleMoviesAppTests.swift
//  DubizzleMoviesAppTests
//
//  Created by Hassan Abid on 09/01/2017.
//  Copyright © 2017 Hassan Abid. All rights reserved.
//

import XCTest
@testable import DubizzleMoviesApp

class DubizzleMoviesAppTests: XCTestCase {
    
    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    //MARK: Configuration
    
    func testConfiguration() {
    
        let masterViewController = MasterViewController()
        let API_KEY = masterViewController.API_KEY
        
        XCTAssertNotEqual(API_KEY, "API_KEY")
    }
    
    //MARK: MoviesList
    
    func testMoviesList() {
        
        var resultError: Error? = nil;
        let expectation = self.expectation(description: "Wait for data to load.")
        let masterViewController = MasterViewController()
        masterViewController.getMoviesviaApi() {
            status, error in
            
            resultError = error
            expectation.fulfill()
        }
        
        waitForExpectations(timeout: 30, handler: nil)
        
        XCTAssertNil(resultError)
  
    }

    /*
    func EmptyMoviesList() {
    
        let defaults = UserDefaults.standard
        defaults.set(1750, forKey: "MinYear")
        defaults.set(1751, forKey: "MaxYear")
        defaults.synchronize()
        
        let expectation = self.expectation(description: "Wait for data to load.")
        let masterViewController = MasterViewController()
        masterViewController.deleteMovies()
        masterViewController.getMoviesviaApi(){
            movies in
            expectation.fulfill()
        }

        waitForExpectations(timeout: 20, handler: nil)
        XCTAssertEqual(masterViewController.results.count, 0)

    }
    */
    
}
