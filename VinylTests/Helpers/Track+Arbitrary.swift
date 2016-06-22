//
//  Track+Arbitrary.swift
//  Vinyl
//
//  Created by Ryan Lovelett on 6/24/16.
//  Copyright © 2016 Velhotes. All rights reserved.
//

import SwiftCheck
@testable import Vinyl

// Concatenates an array of `String` `Gen`erators together in order.
private func glue(parts: [Gen<String>]) -> Gen<String> {
    return sequence(parts).map { $0.reduce("", combine: +) }
}

private let lowalpha: Gen<Character> = .fromElementsIn("a"..."z")
private let upalpha: Gen<Character> = .fromElementsIn("A"..."Z")
private let digit: Gen<Character> = .fromElementsIn("0"..."9")
private let alpha: Gen<Character> = .oneOf([lowalpha, upalpha])
private let alphanum: Gen<Character> = .oneOf([alpha, digit])
private let mark: Gen<Character> = .fromElementsOf(["-", "_", ".", "!", "~", "*", "'", "(", ")"])
private let unreserved: Gen<Character> = .oneOf([alphanum, mark])

private let schemeGen = Gen<Character>.oneOf([
    alpha,
    digit,
    Gen.pure("+"),
    Gen.pure("-"),
    Gen.pure(".")
    ]).proliferateNonEmpty
    .map({ String.init($0) })
    .suchThat({
        $0.unicodeScalars.first.map({ CharacterSet.lowercaseLetters.contains($0) }) ?? false
    })

private let hostname = Gen<Character>.oneOf([
    alphanum,
    Gen.pure("-"),
    ]).proliferateNonEmpty.map({ String.init($0) })
private let tld = alpha
    .proliferateNonEmpty
    .suchThat({ $0.count > 1 })
    .map({ String.init($0) })
private let hostGen = glue(parts: [hostname, Gen.pure("."), tld])

private let portGen = Gen<Int?>.frequency([
    (1, Gen<Int?>.pure(nil)),
    (3, Optional.some <^> Int.arbitrary.map({ abs($0) }))
])

private let pathPartGen: Gen<String> = Gen<Character>.oneOf([
    alpha,
    Gen.pure("/")
    ]).proliferateNonEmpty
    .map({ "/" + String.init($0) })
private let pathGen = Gen<String?>.frequency([
    (1, Gen<String?>.pure(nil)),
    (3, Optional.some <^> pathPartGen)
])

extension URLComponents : Arbitrary {
    public static var arbitrary: Gen<URLComponents> {
        var components = URLComponents()
        components.scheme = schemeGen.generate
        components.host = hostGen.generate
        components.port = portGen.generate
        components.path = pathGen.generate
        return Gen.pure(components)
    }
}

extension URL : Arbitrary {
    public static var arbitrary: Gen<URL> {
        return URLComponents.arbitrary
            .suchThat({ $0.url != nil })
            .map({ $0.url! })
    }
}