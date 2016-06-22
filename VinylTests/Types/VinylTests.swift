//
//  VinylTests.swift
//  Vinyl
//
//  Created by Ryan Lovelett on 7/16/16.
//  Copyright © 2016 Velhotes. All rights reserved.
//

import XCTest
@testable import Vinyl

final class VinylTests: XCTestCase {

    func testMissingFixture() {
        do {
            let _ = try Vinyl(fixtureWithName: "🏅👻🍻")
        } catch TurntableError.missing(let name) {
            XCTAssertEqual(name, "🏅👻🍻.json")
        } catch let error as NSError {
            XCTFail(error.description)
        }
    }

    func testMalformedFixture() {
        do {
            let _ = try Vinyl(fixtureWithName: "dvr_multiple")
        } catch TurntableError.invalidFormat(let name) {
            XCTAssertTrue(name.contains("dvr_multiple.json"))
        } catch let error as NSError {
            XCTFail(error.description)
        }
    }

}
