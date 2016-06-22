//
//  TurntableTask.swift
//  Vinyl
//
//  Created by Ryan Lovelett on 6/24/16.
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

typealias TurntableTaskCallback = (Data?, URLResponse?, NSError?) -> Void

final class TurntableTask: URLSessionDataTask {

    private let recordedResponse: Track.Response?

    private let request: URLRequest

    private let callback: TurntableTaskCallback?

    internal var delegate: URLSessionDataDelegate?

    internal lazy var queue: OperationQueue = {
        let q = OperationQueue()
        q.maxConcurrentOperationCount = 1
        return q
    }()

    init(
        send: Track.Response? = nil,
        for request: URLRequest,
        whenCompleteCall callback: TurntableTaskCallback? = nil,
        andNotify delegate: URLSessionDataDelegate? = nil
    ) {
        self.recordedResponse = send
        self._error = .none
        self.request = request
        self.callback = callback
        self.delegate = delegate
        super.init()
    }

    init(
        send: NSError,
        for request: URLRequest,
        whenCompleteCall callback: TurntableTaskCallback? = nil,
        andNotify delegate: URLSessionDataDelegate? = nil
    ) {
        self.recordedResponse = nil
        self._error = send
        self.request = request
        self.callback = callback
        self.delegate = delegate
        super.init()
    }

    // MARK: - Controlling the Task State

    /// This overridden function performs no operation.
    override func cancel() { }

    override func resume() {
        _state = .running
        _response = self.recordedResponse.flatMap({ HTTPURLResponse(using: $0) })

        // Delegate Message #1
        if let response = _response {
            self.queue.addOperation() {
                let session = URLSession()
                self.delegate?.urlSession?(session, dataTask: self, didReceive: response) { (_) in }
            }
        }

        // Delegate Message #2
        if let data = self.recordedResponse?.body {
            self.queue.addOperation() {
                let session = URLSession()
                self.delegate?.urlSession?(session, dataTask: self, didReceive: data)
            }
        }

        // Delegate Message #3
        self.queue.addOperation() {
            let session = URLSession()
            self.delegate?.urlSession?(session, task: self, didCompleteWithError: self.error)
            self.callback?(self.recordedResponse?.body, self.response, self.error)
        }

        _state = .completed
    }

    /// This overridden function performs no operation.
    override func suspend() { }

    private var _state: URLSessionTask.State = .suspended
    override var state: URLSessionTask.State {
        return _state
    }

    // MARK: - Obtaining General Task Information

    override var currentRequest: URLRequest? {
        return request
    }

    override var originalRequest: URLRequest? {
        return request
    }

    private var _response: URLResponse? = nil
    override var response: URLResponse? {
        return _response
    }

    private let _taskIdentifier: Int = sharedSequence.next()!
    override var taskIdentifier: Int {
        return _taskIdentifier
    }

    private let _error: NSError?
    override var error: NSError? {
        return _error
    }

}