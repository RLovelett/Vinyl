//
//  RequestMatcherRegistryTests.swift
//  Vinyl
//
//  Created by David Rodrigues on 16/02/16.
//  Copyright © 2016 Velhotes. All rights reserved.
//

import XCTest
@testable import Vinyl
import SwiftCheck

class RequestMatcherRegistryTests: XCTestCase {
    func testProperties() {
        property("Requests with identical paths and query parameters should match") <- forAllNoShrink(
              Gen<RequestMatcherType>.fromElementsOf([RequestMatcherType.path, .query, .body])
            , urlStringGen
            , urlPathGen
            , pathParameterGen
            , Optional<String>.arbitrary
        ) { (type, url, path, params, body) in
            let registry = RequestMatcherRegistry(types: [type])
            let commonData = body?.data(using: String.Encoding.utf8)

            var aRequest = URLRequest(url: URL(string: url + path + params)!)
            aRequest.httpBody = commonData
            
            var anotherRequest = URLRequest(url: URL(string: url + path + params)!)
            anotherRequest.httpBody = commonData
            
            return registry.matchableRequests(aRequest, anotherRequest: anotherRequest)
        }
        
        property("Requests with identical headers should match") <- forAllNoShrink(
              urlStringGen
            , HTTPHeaders.arbitrary
        ) { (url, headers) in
            let registry = RequestMatcherRegistry(types: [.headers])
            
            var aRequest = URLRequest(url: URL(string: url)!)
            aRequest.allHTTPHeaderFields = headers
            
            var anotherRequest = URLRequest(url: URL(string: url)!)
            anotherRequest.allHTTPHeaderFields = headers
            
            return registry.matchableRequests(aRequest, anotherRequest: anotherRequest)
        }
        
        property("Requests with mixed values shouldn't match") <- forAllNoShrink(
              urlStringGen
            , Positive<Int>.arbitrary
        ) { (url, size) in
            return forAllNoShrink(
                  lowerStringGen.proliferateSized(size.getPositive)
                , lowerStringGen.proliferateSized(size.getPositive)
            ) { (keys, vals) in
                let headers = HTTPHeaders(keys: keys, values: vals.sorted(isOrderedBefore: >))
                let upperHeaders = HTTPHeaders(keys: keys, values: vals.sorted(isOrderedBefore: <))
                let registry = RequestMatcherRegistry(types: [.headers])

                var aRequest = URLRequest(url: URL(string: url)!)
                aRequest.allHTTPHeaderFields = headers

                var anotherRequest = URLRequest(url: URL(string: url)!)
                anotherRequest.allHTTPHeaderFields = upperHeaders

                return registry.matchableRequests(aRequest, anotherRequest: anotherRequest)
            }
        }.expectFailure
        
        property("Requests with mix-case headers should match") <- forAllNoShrink(
              urlStringGen
            , Positive<Int>.arbitrary
        ) { (url, size) in
            return forAllNoShrink(
                  lowerStringGen.proliferateSized(size.getPositive)
                , lowerStringGen.proliferateSized(size.getPositive)
            ) { (keys, vals) in
                let headers = HTTPHeaders(keys: keys, values: vals)
                let upperHeaders = HTTPHeaders(headers.map { (l, r) in (l.uppercased(), r.uppercased()) })
                let registry = RequestMatcherRegistry(types: [.headers])
                
                var aRequest = URLRequest(url: URL(string: url)!)
                aRequest.allHTTPHeaderFields = headers
                
                var anotherRequest = URLRequest(url: URL(string: url)!)
                anotherRequest.allHTTPHeaderFields = upperHeaders
                
                return registry.matchableRequests(aRequest, anotherRequest: anotherRequest)
            }
        }
    }
}
