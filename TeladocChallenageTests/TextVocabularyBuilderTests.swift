//
//  TextVocabularyBuilderTests.swift
//  TeladocChallenageTests
//
//  Created by Artem Bastun on 26/09/2023.
//

import XCTest
@testable import TeladocChallenage

final class TextVocabularyBuilderTests: XCTestCase {
    var builder: TextVocabularyBuilder!

    override func setUpWithError() throws {
        builder = TextVocabularyBuilder()
    }

    func testBuildVocabulary() async throws {
        let str = """
        two one Three three two THREE
        """
        let vocab = try await builder.build(from: str)
        let wordsSet = Set(vocab.words)
        XCTAssertEqual(wordsSet.count, vocab.words.count)
        XCTAssertEqual(Set(vocab.words), Set(["one", "two", "three"]))
        XCTAssertEqual(vocab["one"], 1)
        XCTAssertEqual(vocab["two"], 2)
        XCTAssertEqual(vocab["three"], 3)
    }

    func testBuildEmptyVocabulary() async throws {
        let vocabulary = try await builder.build(from: "")
        XCTAssertEqual(vocabulary["empty"], 0)
        XCTAssertEqual(vocabulary.words.count, 0)
    }
}
