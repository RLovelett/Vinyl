//
//  Turntable.swift
//  Vinyl
//
//  Created by Rui Peres on 12/02/2016.
//  Copyright © 2016 Velhotes. All rights reserved.
//

import Foundation

enum Error: ErrorProtocol {
    
    case trackNotFound
}

public typealias Plastic = [[String: AnyObject]]
typealias RequestCompletionHandler =  (Data?, URLResponse?, NSError?) -> Void

public final class Turntable: URLSession {
    
    var errorHandler: ErrorHandler = DefaultErrorHandler()
    internal let turntableConfiguration: TurntableConfiguration
    internal var player: Player?
    internal let operationQueue: OperationQueue
    private let _delegate: URLSessionDelegate?
    
    public init(configuration: TurntableConfiguration, delegate: URLSessionDelegate? = nil, delegateQueue: OperationQueue? = nil) {
        _delegate = delegate
        turntableConfiguration = configuration
        if let delegateQueue = delegateQueue {
            operationQueue = delegateQueue
        } else {
            operationQueue = OperationQueue()
            operationQueue.maxConcurrentOperationCount = 1
        }
        super.init()
    }
    
    public convenience init(vinyl: Vinyl, turntableConfiguration: TurntableConfiguration = TurntableConfiguration(), delegate: URLSessionDelegate? = nil, delegateQueue: OperationQueue? = nil) {
        
        self.init(configuration: turntableConfiguration, delegate: delegate, delegateQueue: delegateQueue)
        player = Turntable.createPlayer(vinyl, configuration: turntableConfiguration)
    }
    
    public convenience init(cassetteName: String, bundle: Bundle = testingBundle(), turntableConfiguration: TurntableConfiguration = TurntableConfiguration(), delegate: URLSessionDelegate? = nil, delegateQueue: OperationQueue? = nil) {
        
        let vinyl = Vinyl(plastic: Turntable.createCassettePlastic(cassetteName, bundle: bundle))
        self.init(vinyl: vinyl, turntableConfiguration: turntableConfiguration, delegate: delegate, delegateQueue: delegateQueue)
    }
    
    public convenience init(vinylName: String, bundle: Bundle = testingBundle(), turntableConfiguration: TurntableConfiguration = TurntableConfiguration(), delegate: URLSessionDelegate? = nil, delegateQueue: OperationQueue? = nil) {
        
        let plastic = Turntable.createVinylPlastic(vinylName, bundle: bundle)
        self.init(vinyl: Vinyl(plastic: plastic), turntableConfiguration: turntableConfiguration, delegate: delegate, delegateQueue: delegateQueue)
    }
    
    // MARK: - Private methods

    private func playVinyl(request: URLRequest, fromData bodyData: Data? = nil, completionHandler: RequestCompletionHandler) throws -> URLSessionUploadTask {

        guard let player = player else {
            fatalError("Did you forget to load the Vinyl? 🎶")
        }

        let completion = try player.playTrack(forRequest: transformRequest(request, bodyData: bodyData))

        return URLSessionUploadTask {
            self.operationQueue.addOperation {
                completionHandler(completion.data, completion.response, completion.error)
            }
        }
    }

    private func transformRequest(_ request: URLRequest, bodyData: Data? = nil) -> URLRequest {
        guard let bodyData = bodyData else {
            return request
        }

        guard let mutableRequest = (request as NSURLRequest).mutableCopy() as? NSMutableURLRequest else {
            fatalError("💥 Houston, we have a problem 🚀")
        }

        mutableRequest.httpBody = bodyData

        return mutableRequest as URLRequest
    }

    public override var delegate: URLSessionDelegate? {
        return _delegate
    }
}

// MARK: - NSURLSession methods

extension Turntable {

    public override func dataTask(with url: URL) -> URLSessionDataTask {
        let request = URLRequest(url: url)
        return dataTask(with: request)
    }
    
    public override func dataTask(with url: URL, completionHandler: (Data?, URLResponse?, NSError?) -> Void) -> URLSessionDataTask {
        let request = URLRequest(url: url)
        return dataTask(with: request, completionHandler: completionHandler)
    }

    public override func dataTask(with request: URLRequest) -> URLSessionDataTask {
        return URLSessionDataTask(session: self, request: request)
    }
    
    public override func dataTask(with request: URLRequest, completionHandler: (Data?, URLResponse?, NSError?) -> Void) -> URLSessionDataTask {
        return URLSessionDataTask(session: self, request: request, callback: completionHandler)
    }
    
    public override func uploadTask(with request: URLRequest, from bodyData: Data?, completionHandler: (Data?, URLResponse?, NSError?) -> Void) -> URLSessionUploadTask {
        
        do {
            return try playVinyl(request: request, fromData: bodyData, completionHandler: completionHandler) as URLSessionUploadTask
        }
        catch Error.trackNotFound {
            errorHandler.handleTrackNotFound(request, playTracksUniquely: turntableConfiguration.playTracksUniquely)
        }
        catch {
            errorHandler.handleUnknownError()
        }
        
        return URLSessionUploadTask(completion: {})
    }
    
    public override func invalidateAndCancel() {
        // We won't do anything for
    }
}

// MARK: - Loading Methods

extension Turntable {
    
    public func loadVinyl(_ vinylName: String,  bundle: Bundle = testingBundle()) {
        
        let vinyl = Vinyl(plastic: Turntable.createVinylPlastic(vinylName, bundle: bundle))
        player = Turntable.createPlayer(vinyl, configuration: turntableConfiguration)
    }
    
    public func loadCassette(_ cassetteName: String,  bundle: Bundle = testingBundle()) {
        
        let vinyl = Vinyl(plastic: Turntable.createCassettePlastic(cassetteName, bundle: bundle))
        player = Turntable.createPlayer(vinyl, configuration: turntableConfiguration)
    }
    
    public func loadVinyl(_ vinyl: Vinyl) {
        player = Turntable.createPlayer(vinyl, configuration: turntableConfiguration)
    }
}

// MARK: - Bootstrap methods

extension Turntable {
    
    private static func createPlayer(_ vinyl: Vinyl, configuration: TurntableConfiguration) -> Player {
        
        let trackMatchers = configuration.trackMatchersForVinyl(vinyl)
        return Player(vinyl: vinyl, trackMatchers: trackMatchers)
    }
    
    private static func createCassettePlastic(_ cassetteName: String, bundle: Bundle) -> Plastic {
        
        guard let cassette: [String: AnyObject] = loadJSON(bundle, fileName: cassetteName) else {
            fatalError("💣 Cassette file \"\(cassetteName)\" not found 😩")
        }
        
        guard let plastic = cassette["interactions"] as? Plastic else {
            fatalError("💣 We couldn't find the \"interactions\" key in your cassette 😩")
        }
        
        return plastic
    }
    
    private static func createVinylPlastic(_ vinylName: String, bundle: Bundle) -> Plastic {
        
        guard let plastic: Plastic = loadJSON(bundle, fileName: vinylName) else {
            fatalError("💣 Vinyl file \"\(vinylName)\" not found 😩")
        }
        
        return plastic
    }
}
