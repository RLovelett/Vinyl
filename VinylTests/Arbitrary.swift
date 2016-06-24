//
//  Arbitrary.swift
//  Vinyl
//
//  Created by Robert Widmann on 2/20/16.
//  Copyright © 2016 Velhotes. All rights reserved.
//

import Foundation
import SwiftCheck

/// Generates an array of lowercase alphabetic `Character`s.
let lowerStringGen =
Gen<Character>.fromElementsIn("a"..."z")
    .proliferateNonEmpty
    .map(String.init)

/// Generates a URL of the form `(http|https)://<domain>.com`.
let urlStringGen : Gen<String> = sequence([
    Gen<String>.fromElementsOf(["http://", "https://"]),
    lowerStringGen,
    Gen.pure(".com"),
    ])
    .map { $0.reduce("", combine: +) }

// Generates a JSON string of the form '"string"'
let jsonString: Gen<String> = lowerStringGen.map { "\"" + $0 + "\""}

// Generates a JSON string pair of the form '"key":"value"'
let jsonStringPair: Gen<String> = sequence([
    jsonString,
    Gen.pure(":"),
    jsonString])
    .map { $0.reduce("", combine: +) }

// Generates a JSON string pair of the form '"key":"value", "key1":"value1" ....'
let jsonStringPairs = Gen.sized({ jsonStringPair.proliferateSized($0 + 1) })
    .map({ $0.joined(separator: ",") })

// Generates a JSON of the form '{"key":"value", "key1":"value1" .... }'
let basicJSONDic : Gen<AnyObject> = sequence([
    Gen.pure("{"),
    jsonStringPairs,
    Gen.pure("}")
    ])
    .map { $0.reduce("", combine: +) }
    .map { $0.data(using: String.Encoding.utf8)! }
    .map { try! JSONSerialization.jsonObject(with: $0, options: .allowFragments) }

/// Generates a path of the form `<some>/<path>/<to>/.../<somewhere>`.
let urlPathGen : Gen<String> =
(curry(+) <^> Gen.pure("/") <*> lowerStringGen)
    .proliferate
    .map { $0.reduce("", combine: +) }

/// Generates an array of parameters of the form `<param>=<arg>`,
let parameterGen : Gen<String> = sequence([
    lowerStringGen,
    Gen.pure("="),
    lowerStringGen,
    ])
    .map { $0.reduce("", combine: +) }

/// Generates a set of parameters.
let pathParameterGen : Gen<String> = Gen.sized({ parameterGen.proliferateSized($0 + 1) })
    .map({ (["?"] + $0).joined(separator: "&") })

private func curry<A, B, C>(_ f : (A, B) -> C) -> (A) -> (B) -> C {
    return { a in { b in f(a, b) } }
}

extension Dictionary {
    init(keys: [Key], values: [Value]) {
        self.init()

        for (key, value) in zip(keys, values) {
            self[key] = value
        }
    }
}
