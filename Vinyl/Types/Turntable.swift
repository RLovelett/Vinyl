//
//  Turntable.swift
//  Vinyl
//
//  Created by Rui Peres on 12/02/2016.
//  Copyright © 2016 Velhotes. All rights reserved.
//

import Foundation

public final class Turntable: URLSession {

    public enum PlaybackSequence {
        case vinylOrder
        case properties(matching: [MatchType])

        public enum MatchType {
            case method
            case url
            case path
            case query
            case headers
            case body
            case custom(using: (Track, URLRequest) -> Bool)
        }
    }

    public enum ReplayCount {
        case none
        case unlimited
    }

    private var sequence: TurntableSequence

    private let queue: OperationQueue

    private let _delegate: URLSessionDelegate?

    public init(
        play vinyl: Vinyl,
        in queue: OperationQueue? = .none,
        match sequenceType: PlaybackSequence = .vinylOrder,
        replay duration: ReplayCount = .none,
        notify delegate: URLSessionDelegate? = .none
    ) {
        switch duration {
        case .none:
            self.sequence = EphemeralSequence(sequenceOf: vinyl.tracks, inOrder: sequenceType)
        case .unlimited:
            self.sequence = LoopingSequence(sequenceOf: vinyl.tracks, inOrder: sequenceType)
        }

        if let queue = queue {
            self.queue = queue
        } else {
            self.queue = OperationQueue()
            self.queue.maxConcurrentOperationCount = 1
        }

        self._delegate = delegate

        super.init()
    }

}

// MARK: - Configuring a Session

extension Turntable {

    override public var delegate: URLSessionDelegate? {
        return _delegate
    }

}

// MARK: - Adding Data Tasks to a Session

extension Turntable {

    public override func dataTask(with url: URL) -> URLSessionDataTask {
        let request = URLRequest(url: url)
        return self.dataTask(with: request)
    }

    public override func dataTask(with request: URLRequest) -> URLSessionDataTask {
        return self.dataTask(with: request, completionHandler: { (_, _, _) in })
    }

    public override func dataTask(
        with url: URL,
        completionHandler: (Data?, URLResponse?, NSError?) -> Void
    ) -> URLSessionDataTask {
        let request = URLRequest(url: url)
        return self.dataTask(with: request, completionHandler: completionHandler)
    }

    public override func dataTask(
        with request: URLRequest,
        completionHandler: (Data?, URLResponse?, NSError?) -> Void
    ) -> URLSessionDataTask {
        guard let response = self.sequence.next(for: request)?.response else {
            let error = TurntableError.recordNotFound(for: request).error()
            let task = TurntableTask(send: error, for: request, whenCompleteCall: completionHandler)
            task.queue = self.queue
            task.delegate = self.delegate as? URLSessionDataDelegate
            return task
        }

        let task = TurntableTask(send: response, for: request, whenCompleteCall: completionHandler)
        task.queue = self.queue
        task.delegate = self.delegate as? URLSessionDataDelegate
        return task
    }

}

/// Extract the `URLQueryItem`s from an `URL` instance and sort them by name.
private func thing(from url: URL) -> [URLQueryItem]? {
    let temp = URLComponents(url: url, resolvingAgainstBaseURL: true)?
        .queryItems?.lazy.sorted(isOrderedBefore: { $0.name < $1.name })
    return temp
}

extension Turntable.PlaybackSequence.MatchType {

    // TODO: Reduce the cyclomatic complexity of this function below 10
    // swiftlint:disable:next cyclomatic_complexity
    func match(_ track: Track, with request: URLRequest) -> Bool {
        switch self {
        case .method:
            return track.request.method == request.method
        case .url:
            return track.request.url == request.url
        case .path:
            return track.request.url.path == request.url?.path
        case .query:
            switch (thing(from: track.request.url), request.url.flatMap(thing(from:))) {
            case let (.some(trackQueryItems), .some(rquestQueryItems)):
                return trackQueryItems == rquestQueryItems
            default: return false
            }
        case .headers:
            switch (track.request.headers, request.allHTTPHeaderFields) {
            case let (.some(trackHeaders), .some(requestHeaders)):
                return trackHeaders == requestHeaders
            default: return false
            }
        case body:
            switch (track.request.body, request.httpBody) {
            case let (.some(trackBody), .some(requestBody)):
                return NSData(data: trackBody).isEqual(to: requestBody)
            default:
                return false
            }
        case custom(let matchUsing):
            return matchUsing(track, request)
        }
    }

}
