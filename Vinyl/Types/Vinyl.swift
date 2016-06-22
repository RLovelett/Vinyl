//
//  Record.swift
//  Vinyl
//
//  Created by Ryan Lovelett on 6/24/16.
//  Copyright © 2016 Velhotes. All rights reserved.
//

import Argo
import Foundation

public struct Vinyl {

    internal let tracks: [Track]

    /// Attempt to find a test fixture with the specified name having a `.json` extension. It is
    /// meant to be a common initializer function for the `Record` protocol conforming types.
    ///
    /// - parameter withName: The name of the fixture to find. Without the `.json` file-extension.
    /// - returns: The `URL` referencing the fixture to be loaded and parsed.
    /// - throws: If the requested fixture cannot be found it throws `RecordError.missing`
    public init(fixtureWithName name: String) throws {
        let bundle = Bundle.allBundles.filter() { $0.bundlePath.hasSuffix(".xctest") }.first
        guard let resource = bundle?.urlForResource(name, withExtension: "json")
            else { throw TurntableError.missing(resource: name + ".json") }
        try self.init(contentsOf: resource)
    }

    /// This function loads the contents of a `URL` and then attempts to convert it to an
    /// `Array<Track>`. It is meant to be a common initializer function for the `Record` protocol
    /// conforming types.
    ///
    /// - parameter contentsOf: The `URL` referencing the fixture to be loaded and parsed.
    /// - returns: A collection of `Track` values that could be parsed from the provided fixture.
    /// - throws: If the fixture is malformed the function throws an `RecordError.format`
    init(contentsOf fixture: URL) throws {
        let data = try Data(contentsOf: fixture)
        let foundationJSON = try JSONSerialization.jsonObject(with: data, options: .allowFragments)
        let json = JSON(foundationJSON)
        let decodedTracks: Decoded<[Track]> = decodeArray(json)
        switch decodedTracks {
        case .success(let tracks):
            self.tracks = tracks
        case .failure(_):
            throw TurntableError.invalidFormat(resource: fixture.description)
        }
    }

}
