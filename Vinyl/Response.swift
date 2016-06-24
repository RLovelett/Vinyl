//
//  Response.swift
//  Vinyl
//
//  Created by David Rodrigues on 18/02/16.
//  Copyright © 2016 Velhotes. All rights reserved.
//

import Foundation

struct Response {
    let urlResponse: HTTPURLResponse?
    let body: Data?
    let error: NSError?
    
    init(urlResponse: HTTPURLResponse?, body: Data? = nil, error: NSError? = nil) {
        self.urlResponse = urlResponse
        self.body = body
        self.error = error
    }
}

extension Response {
    
    init(encodedResponse: EncodedObject) {
        guard
            let urlString = encodedResponse["url"] as? String,
            let url = URL(string: urlString),
            let statusCode = encodedResponse["status"] as? Int,
            let headers = encodedResponse["headers"] as? HTTPHeaders,
            let urlResponse = HTTPURLResponse(url: url, statusCode: statusCode, httpVersion: nil, headerFields: headers)
        else {
            fatalError("key not found 😞 for Response (check url/statusCode/headers) check \n------\n\(encodedResponse)\n------\n")
        }
        
        self.init(urlResponse: urlResponse, body: decodeBody(encodedResponse["body"], headers: headers), error: nil)
    }
}

func ==(lhs: Response, rhs: Response) -> Bool {
    return lhs.urlResponse == rhs.urlResponse && lhs.body == rhs.body && lhs.error == rhs.error
}

extension Response: Hashable {
    
    var hashValue: Int {
        
        let body = self.body?.description ?? ""
        let error = self.error?.description ?? ""
        
        return "\(urlResponse?.hashValue):\((body)):\(error)".hashValue
    }
    
}
