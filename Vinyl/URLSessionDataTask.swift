//
//  URLSessionDataTask.swift
//  Vinyl
//
//  Created by Rui Peres on 16/02/2016.
//  Copyright © 2016 Velhotes. All rights reserved.
//

import Foundation

private func generate() -> AnyIterator<Int> {
    var current = 0

    return AnyIterator<Int> {
        current = current + 1
        return current
    }
}

private let sharedSequence: AnyIterator<Int> = generate()

typealias URLSessionDataTaskCallback = (Data?, URLResponse?, NSError?) -> Void

public final class URLSessionDataTask: Foundation.URLSessionDataTask {

    private let session: Turntable
    private let request: URLRequest
    private let delegate: URLSessionDataDelegate?
    private let callback: URLSessionDataTaskCallback?

    init(session: Turntable, request: URLRequest, callback: URLSessionDataTaskCallback? = nil) {
        self.session = session
        self.request = request
        self.delegate = session.delegate as? URLSessionDataDelegate
        self.callback = callback
    }

    // MARK: - Controlling the Task State

    public override func cancel() {
        // We won't do anything here
    }

    public override func resume() {
        _state = .running
        var data: Data?
        do {
            let playedTrack = try self.session.player?.playTrack(forRequest: self.request)
            data = playedTrack?.data
            self._response = playedTrack?.response
            self._error = playedTrack?.error

            // Delegate Message #1
            if let response = response {
                self.session.operationQueue.addOperation {
                    self.delegate?.urlSession?(self.session, dataTask: self, didReceive: response) { (_) in }
                }
            }

            // Delegate Message #2
            if let data = data {
                self.session.operationQueue.addOperation {
                    self.delegate?.urlSession?(self.session, dataTask: self, didReceive: data)
                }
            }

            // Delegate Message #3
            self.session.operationQueue.addOperation {
                self.delegate?.urlSession?(self.session, task: self, didCompleteWithError: self.error)
                self.callback?(data, self.response, self.error)
            }
        } catch Error.trackNotFound {
            self.session.errorHandler.handleTrackNotFound(self.request, playTracksUniquely: self.session.turntableConfiguration.playTracksUniquely)
        } catch {
            self.session.errorHandler.handleUnknownError()
        }
        _state = .completed
    }

    public override func suspend() {
        // We won't do anything here
    }

    private var _state: URLSessionTask.State = .suspended
    override public var state: URLSessionTask.State {
        return _state
    }

    // MARK: - Obtaining General Task Information

    override public var currentRequest: URLRequest? {
        return request
    }

    override public var originalRequest: URLRequest? {
        return request
    }

    private var _response: URLResponse? = nil
    override public var response: URLResponse? {
        return _response
    }

    private let _id: Int = sharedSequence.next()!
    override public var taskIdentifier: Int {
        return _id
    }

    private var _error: NSError? = nil
    override public var error: NSError? {
        return _error
    }
}
