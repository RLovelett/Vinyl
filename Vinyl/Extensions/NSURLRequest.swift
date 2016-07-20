//
//  NSURLRequest.swift
//  Vinyl
//
//  Created by Rui Peres on 16/02/2016.
//  Copyright © 2016 Velhotes. All rights reserved.
//

import Foundation

extension URLRequest {
    
    static func createWithEncodedRequest(_ encodedRequest: EncodedObject) -> URLRequest {
        guard
            let urlString = encodedRequest["url"] as? String,
            let url = URL(string: urlString)
            else {
                fatalError("URL not found 😞 for Request: \(encodedRequest)")
        }
        
        let request = NSMutableURLRequest(url: url)
        
        if let method = encodedRequest["method"] as? String {
            request.httpMethod = method
        }
        
        if let headers = encodedRequest["headers"] as? HTTPHeaders {
            request.allHTTPHeaderFields = headers
            
            if let body = decodeBody(encodedRequest["body"], headers: headers) {
                request.httpBody = body
            }
        }
        
        return request as URLRequest
    }
}
