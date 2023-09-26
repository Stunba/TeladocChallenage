//
//  Vocabulary.swift
//  TeladocChallenage
//
//  Created by Artem Bastun on 26/09/2023.
//

import Foundation

struct Vocabulary {
    private let storage: [String: Int]

    init(_ storage: [String : Int] = [:]) {
        self.storage = storage
    }

    var words: [String] {
        Array(storage.keys)
    }

    subscript (word: String) -> Int {
        storage[word, default: 0]
    }

    var frequencies: [String: Int] {
        return storage
    }

    func merge(_ another: Vocabulary) -> Vocabulary {
        Vocabulary(
            storage.merging(another.storage, uniquingKeysWith: +)
        )
    }
}

extension Vocabulary {
    static func + (lhs: Vocabulary, rhs: Vocabulary) -> Vocabulary  {
        lhs.merge(rhs)
    }
}
