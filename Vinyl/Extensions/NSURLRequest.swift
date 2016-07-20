//
//  NSURLRequest.swift
//  Vinyl
//
//  Created by Rui Peres on 16/02/2016.
//  Copyright © 2016 Velhotes. All rights reserved.
//

import Foundation

extension URLRequest {

    init(from encodedRequest: EncodedObject) {
        guard
            let urlString = encodedRequest["url"] as? String,
            let url = URL(string: urlString)
            else {
                fatalError("URL not found 😞 for Request: \(encodedRequest)")
        }

        self.init(url: url)
        self.httpMethod = encodedRequest["method"] as? String
        let headers = encodedRequest["headers"] as? HTTPHeaders
        self.allHTTPHeaderFields = headers
        self.httpBody = headers.flatMap({ decode(body: encodedRequest["body"], headers: $0) })
    }
}
