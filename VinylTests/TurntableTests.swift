//
//  TurntableTests.swift
//  Vinyl
//
//  Created by Rui Peres on 12/02/2016.
//  Copyright © 2016 Velhotes. All rights reserved.
//

import XCTest
@testable import Vinyl

class TurntableTests: XCTestCase {
    
    func test_Vinyl_single() {
        
        let turntable = Turntable(vinylName: "vinyl_single")
        
        singleCallTest(turntable)
    }
    
    func test_DVR_single() {
        
        let turntable = Turntable(cassetteName: "dvr_single")
        
        singleCallTest(turntable)
    }
    
    func test_Vinyl_multiple() {
        
        let turntable = Turntable(vinylName: "vinyl_multiple")
        
        multipleCallTest(turntable)
    }
    
    func test_DVR_multiple() {
        
        let turntable = Turntable(cassetteName: "dvr_multiple")
        
        multipleCallTest(turntable)
    }
    
    func test_Vinyl_multiple_differentMethods() {
        
        let expectation = self.expectation(withDescription: "Expected callback to have the correct URL")
        defer { self.waitForExpectations(withTimeout: 4, handler: nil) }
        
        let turntable = Turntable(
            vinylName: "vinyl_multiple",
            turntableConfiguration: TurntableConfiguration(matchingStrategy: .requestAttributes(types: [.url], playTracksUniquely: true)))
        
        var request1 = URLRequest(url: URL(string: "http://api.test1.com")!)
        request1.httpMethod = "POST"
        
        var request2 = URLRequest(url: URL(string: "http://api.test2.com")!)
        request2.httpMethod = "POST"
        
        var numberOfCalls = 0
        let checker: (Data?, URLResponse?, NSError?) -> () = { (data, response, anError) in
            
            guard let httpResponse = response as? HTTPURLResponse else { fatalError("\(response) should be a NSHTTPURLResponse") }
            
            switch numberOfCalls {
            case 0:
                XCTAssertEqual(httpResponse.url!.absoluteString, "http://api.test1.com")
                numberOfCalls += 1
            case 1:
                XCTAssertEqual(httpResponse.url!.absoluteString, "http://api.test2.com")
                expectation.fulfill()
            default: break
            }
        }
        
        turntable.dataTask(with: request1, completionHandler: checker).resume()
        turntable.dataTask(with: request2, completionHandler: checker).resume()
    }
    
    func test_Vinyl_multiple_andNotUniquely() {
        
        let expectation = self.expectation(withDescription: "Expected callback to have the correct URL")
        defer { self.waitForExpectations(withTimeout: 4, handler: nil) }
        
        let turntable = Turntable(
            vinylName: "vinyl_multiple",
            turntableConfiguration: TurntableConfiguration(matchingStrategy: .requestAttributes(types: [.url], playTracksUniquely: false)))
        
        let url1String = "http://api.test1.com"
        let url2String = "http://api.test2.com"
        
        var numberOfCalls = 0
        let checker: (Data?, URLResponse?, NSError?) -> () = { (data, response, anError) in
            
            guard let httpResponse = response as? HTTPURLResponse else { fatalError("\(response) should be a NSHTTPURLResponse") }
            
            numberOfCalls += 1
            
            switch numberOfCalls {
            case 1:
                XCTAssertEqual(httpResponse.url!.absoluteString, url1String)
            case 2...4:
                XCTAssertEqual(httpResponse.url!.absoluteString, url2String)
                if numberOfCalls == 4 {
                    expectation.fulfill()
                }
            default: break
            }
        }
        
        turntable.dataTask(with: URL(string: url1String)!, completionHandler: checker).resume()
        turntable.dataTask(with: URL(string: url2String)!, completionHandler: checker).resume()
        turntable.dataTask(with: URL(string: url2String)!, completionHandler: checker).resume()
        turntable.dataTask(with: URL(string: url2String)!, completionHandler: checker).resume()
    }
    
    
    func test_Vinyl_multiple_uniquely() {
        
        let expectation = self.expectation(withDescription: "Expected callback to have the correct URL")
        defer { self.waitForExpectations(withTimeout: 4, handler: nil) }
        
        let turntable = Turntable(
            vinylName: "vinyl_multiple",
            turntableConfiguration: TurntableConfiguration(matchingStrategy: .requestAttributes(types: [.url], playTracksUniquely: true)))
        
        let url1String = "http://api.test1.com"
        let url2String = "http://api.test2.com"
        
        let mockedTrackedNotFound = MockedTrackedNotFoundErrorHandler { expectation.fulfill() }
        turntable.errorHandler = mockedTrackedNotFound
        
        var numberOfCalls = 0
        let checker: (Data?, URLResponse?, NSError?) -> () = { (data, response, anError) in
            
            guard let httpResponse = response as? HTTPURLResponse else { fatalError("\(response) should be a NSHTTPURLResponse") }
            
            switch numberOfCalls {
            case 0:
                XCTAssertEqual(httpResponse.url!.absoluteString, url1String)
                numberOfCalls += 1
            case 1:
                XCTAssertEqual(httpResponse.url!.absoluteString, url2String)
                numberOfCalls += 1
            case 2:
                fatalError("This shouldn't be reached")
            default: break
            }
        }
        
        turntable.dataTask(with: URL(string: url1String)!, completionHandler: checker).resume()
        turntable.dataTask(with: URL(string: url2String)!, completionHandler: checker).resume()
        turntable.dataTask(with: URL(string: url2String)!, completionHandler: checker).resume()
        turntable.dataTask(with: URL(string: url2String)!, completionHandler: checker).resume()
        turntable.dataTask(with: URL(string: url2String)!, completionHandler: checker).resume()
    }
    
    func test_Vinyl_upload() {
        
        let expectation = self.expectation(withDescription: "Expected callback to have the correct response and data")
        defer { self.waitForExpectations(withTimeout: 4, handler: nil) }
        
        let turntable = Turntable(
            vinylName: "vinyl_upload",
            turntableConfiguration: TurntableConfiguration(matchingStrategy: .requestAttributes(types: [.method, .url, .body], playTracksUniquely: true)))
        
        let urlString = "http://api.test.com"
        var request = URLRequest(url: URL(string: urlString)!)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        let data = try! JSONSerialization.data(withJSONObject: ["username": "ziggy", "password": "stardust"], options: [])
        
        turntable.uploadTask(with: request, from: data, completionHandler: { (data, response, error) in
            XCTAssertNil(error)
            
            guard let httpResponse = response as? HTTPURLResponse else { fatalError("\(response) should be a NSHTTPURLResponse") }
            
            let body: AnyObject = ["token": "thespidersfrommars"]
            let responseBody = try! JSONSerialization.jsonObject(with: data!, options: [])
            
            XCTAssertEqual(httpResponse.url!.absoluteString, urlString)
            XCTAssertEqual(httpResponse.statusCode, 200)
            XCTAssertTrue(responseBody.isEqual(body))
            XCTAssertNotNil(httpResponse.allHeaderFields)
            
            expectation.fulfill()
        }).resume()
    }
    
    func test_playVinyl() {
        
        let turntableConfiguration = TurntableConfiguration()
        let turntable = Turntable(configuration: turntableConfiguration)
        
        let tracks = [
            TrackFactory.createValidTrack(
                URL(string: "http://api.test.com")!,
                body: "hello".data(using: String.Encoding.utf8),
                headers: [:])
        ]
        
        let vinyl = Vinyl(tracks: tracks)
        turntable.loadVinyl(vinyl)
        singleCallTest(turntable)
    }
    
    func test_playVinylFile() {
        
        let turntableConfiguration = TurntableConfiguration()
        let turntable = Turntable(configuration: turntableConfiguration)
        
        turntable.loadVinyl("vinyl_single")
        singleCallTest(turntable)
    }
    
    func test_playCassetteFile() {
        
        let turntableConfiguration = TurntableConfiguration()
        let turntable = Turntable(configuration: turntableConfiguration)
        
        turntable.loadCassette("dvr_single")
        singleCallTest(turntable)
    }
    
    //MARK: Aux methods
    
    private func singleCallTest(_ turntable: Turntable) {
        
        let expectation = self.expectation(withDescription: "Expected callback to have the correct URL")
        defer { self.waitForExpectations(withTimeout: 4, handler: nil) }
        
        let urlString = "http://api.test.com"
        
        turntable.dataTask(with: URL(string: urlString)!) { (data, response, anError) in
            
            XCTAssertNil(anError)
            
            guard let httpResponse = response as? HTTPURLResponse else { fatalError("\(response) should be a NSHTTPURLResponse") }
            
            let body = "hello".data(using: String.Encoding.utf8)!
            
            XCTAssertEqual(httpResponse.url!.absoluteString, urlString)
            XCTAssertEqual(httpResponse.statusCode, 200)
            XCTAssertTrue(data! == body)
            XCTAssertNotNil(httpResponse.allHeaderFields)
            
            expectation.fulfill()
            }.resume()
    }
    
    private func multipleCallTest(_ turntable: Turntable) {
        
        let expectation = self.expectation(withDescription: "Expected callback to have the correct URL")
        defer { self.waitForExpectations(withTimeout: 4, handler: nil) }
        
        let url1String = "http://api.test1.com"
        let url2String = "http://api.test2.com"
        
        var numberOfCalls = 0
        let checker: (Data?, URLResponse?, NSError?) -> () = { (data, response, anError) in
            
            guard let httpResponse = response as? HTTPURLResponse else { fatalError("\(response) should be a NSHTTPURLResponse") }
            
            switch numberOfCalls {
            case 0:
                XCTAssertEqual(httpResponse.url!.absoluteString, url1String)
                numberOfCalls += 1
            case 1:
                XCTAssertEqual(httpResponse.url!.absoluteString, url2String)
                expectation.fulfill()
            default: break
            }
        }
        
        turntable.dataTask(with: URL(string: url1String)!, completionHandler: checker).resume()
        turntable.dataTask(with: URL(string: url2String)!, completionHandler: checker).resume()
    }
    
    // MARK: - Track Order strategy
    
    func test_Vinyl_withTrackOrder() {
        
        let expectation = self.expectation(withDescription: "All tracks should be placed in order")
        defer { self.waitForExpectations(withTimeout: 4, handler: nil) }
        
        var tracks = [
            TrackFactory.createValidTrack(
                URL(string: "http://feelGoodINC.com/request/2")!,
                body: nil,
                headers: [ "header1": "value1" ]),
            TrackFactory.createValidTrack(
                URL(string: "http://feelGoodINC.com/request/1")!,
                body: nil,
                headers: [ "header1": "value1", "header2": "value2" ]),
            TrackFactory.createValidTrack(
                URL(string: "https://rand.com/")!)
        ]
        
        var request1 = URLRequest(url: URL(string: "http://random.com")!)
        request1.httpMethod = "POST"
        
        var request2 = URLRequest(url: URL(string: "http://random.com/random")!)
        request2.httpMethod = "DELETE"
        
        var request3 = URLRequest(url: URL(string: "http://random.com/random/another/one")!)
        request3.httpMethod = "PUT"
        
        let checker: (Data?, URLResponse?, NSError?) -> () = { (taskData, response, anError) in
            
            guard let httpResponse = response as? HTTPURLResponse else {
                fatalError("response should be a `NSHTTPURLResponse`")
            }
            
            if let track = tracks.first {
                
                XCTAssertTrue(httpResponse.statusCode == 200)
                
                if let responseHeaders = httpResponse.allHeaderFields as? HTTPHeaders, let originalHeaders = track.response.urlResponse?.allHeaderFields as? HTTPHeaders {
                    XCTAssertTrue(responseHeaders == originalHeaders)
                }
                
                XCTAssertTrue(httpResponse.url == track.response.urlResponse?.url)
                
                tracks.remove(at: tracks.index(of: track)!)
            }
            
            if tracks.isEmpty {
                expectation.fulfill()
            }
        }
        
        let turntable = Turntable(
            vinyl: Vinyl(tracks: tracks),
            turntableConfiguration: TurntableConfiguration(matchingStrategy: .trackOrder))
        
        turntable.dataTask(with: request1, completionHandler: checker).resume()
        turntable.dataTask(with: request2, completionHandler: checker).resume()
        turntable.dataTask(with: request3, completionHandler: checker).resume()
    }
    
    //MARK: - Delegate queue
    
    func test_Vinyl_defaultQueue() {
        
        let expectation = self.expectation(withDescription: "Expected callback to be called on background thread")
        defer { self.waitForExpectations(withTimeout: 4, handler: nil) }
        
        let turntable = Turntable(vinylName: "vinyl_single")
        
        let urlString = "http://api.test.com"
        
        turntable.dataTask(with: URL(string: urlString)!) { (data, response, anError) in
            
            XCTAssertFalse(Thread.isMainThread())
            expectation.fulfill()
            }.resume()
    }
    
    func test_Vinyl_mainQueue() {
        
        let expectation = self.expectation(withDescription: "Expected callback to be called on main thread")
        defer { self.waitForExpectations(withTimeout: 4, handler: nil) }
        
        let turntable = Turntable(vinylName: "vinyl_single", delegateQueue: OperationQueue.main())
        
        let urlString = "http://api.test.com"
        
        turntable.dataTask(with: URL(string: urlString)!) { (data, response, anError) in
            
            XCTAssertTrue(Thread.isMainThread())
            expectation.fulfill()
            }.resume()
    }
    
    func test_Vinyl_Delegate() {
        
        let turntable = Turntable(vinylName: "vinyl_single", delegateQueue: OperationQueue.main())
        XCTAssertNil(turntable.delegate)
    }

    func test_Vinyl_Delegate_Messages() {

        let expectation = self.expectation(withDescription: #function)
        defer { self.waitForExpectations(withTimeout: 4, handler: nil) }

        let delegate = XCTestNSURLSessionDataDelegate(expectation: expectation)
        let turntable = Turntable(vinylName: "vinyl_single", delegate: delegate)
        let urlString = "http://api.test.com"

        let task = turntable.dataTask(with: URL(string: urlString)!)
        task.resume()
    }
}
