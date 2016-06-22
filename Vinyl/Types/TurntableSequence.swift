//
//  TurntableSequence.swift
//  Vinyl
//
//  Created by Ryan Lovelett on 7/16/16.
//  Copyright © 2016 Velhotes. All rights reserved.
//

import Foundation

internal protocol TurntableSequence {
    init(sequenceOf: [Track], inOrder: Turntable.PlaybackSequence)
    mutating func next(for request: URLRequest) -> Track?
}

private func byMatching(
    _ track: Track,
    with request: URLRequest
) -> (Bool, Turntable.PlaybackSequence.MatchType) -> Bool {
    return { (previous: Bool, type: Turntable.PlaybackSequence.MatchType) -> Bool in
        return previous && type.match(track, with: request)
    }
}

internal struct LoopingSequence: TurntableSequence {

    let tracks: [Track]

    let orderBy: Turntable.PlaybackSequence

    var currentIndex: Array<Track>.Index

    init(sequenceOf: [Track], inOrder: Turntable.PlaybackSequence) {
        self.tracks = sequenceOf
        self.orderBy = inOrder
        self.currentIndex = sequenceOf.startIndex
    }

    mutating func next(for request: URLRequest) -> Track? {
        switch self.orderBy {
        case .vinylOrder:
            let track = self.tracks[self.currentIndex]
            self.currentIndex = self.currentIndex.advanced(by: 1)
            if self.currentIndex >= self.tracks.endIndex {
                self.currentIndex = self.tracks.startIndex
            }
            return track
        case .properties(matching: let matchers):
            for track in self.tracks {
                guard matchers.reduce(true, combine: byMatching(track, with: request))
                    else { continue }
                return track
            }
            return .none
        }
    }

}

internal struct EphemeralSequence: TurntableSequence {

    var tracks: [Track]

    let matchers: [Turntable.PlaybackSequence.MatchType]

    init(sequenceOf: [Track], inOrder: Turntable.PlaybackSequence) {
        self.tracks = sequenceOf
        switch inOrder {
        case .vinylOrder:
            self.matchers = []
        case .properties(matching: let matchers):
            self.matchers = matchers
        }
    }

    mutating func next(for request: URLRequest) -> Track? {
        for (offset, track) in self.tracks.enumerated() {
            guard matchers.reduce(true, combine: byMatching(track, with: request)) else { continue }
            let index = self.tracks.index(self.tracks.startIndex, offsetBy: offset)
            self.tracks.remove(at: index)
            return track
        }
        return .none
    }

}
