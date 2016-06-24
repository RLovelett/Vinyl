//
//  XCTestNSURLSessionDataDelegate.swift
//  Vinyl
//
//  Created by Ryan Lovelett on 6/15/16.
//  Copyright © 2016 Velhotes. All rights reserved.
//

import XCTest

final class XCTestNSURLSessionDataDelegate : NSObject, URLSessionDataDelegate {
    private let expectation: XCTestExpectation
    private var sessionID: Int?

    init(expectation: XCTestExpectation) {
        self.expectation = expectation
        super.init()
    }

    func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive response: URLResponse, completionHandler: (URLSession.ResponseDisposition) -> Void) {
        self.sessionID = dataTask.taskIdentifier
        XCTAssertNotNil(dataTask.originalRequest)
        XCTAssertNotNil(dataTask.currentRequest)
    }

    func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive data: Data) {
        XCTAssertEqual(self.sessionID, dataTask.taskIdentifier)
        XCTAssertNotNil(dataTask.originalRequest)
        XCTAssertNotNil(dataTask.currentRequest)
    }

    func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: NSError?) {
        XCTAssertEqual(self.sessionID, task.taskIdentifier)
        XCTAssertEqual(task.state, URLSessionTask.State.completed)
        XCTAssertNotNil(task.originalRequest)
        XCTAssertNotNil(task.currentRequest)
        expectation.fulfill()
    }
}
