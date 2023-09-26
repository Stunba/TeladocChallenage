//
//  TeladocChallenageTests.swift
//  TeladocChallenageTests
//
//  Created by Artem Bastun on 26/09/2023.
//

import XCTest
@testable import TeladocChallenage

final class FileVocabularyBuilderTests: XCTestCase {
    var textBuilder: TextVocabularyBuilder!
    var builder: FileVocabularyBuilder!

    override func setUpWithError() throws {
        textBuilder = TextVocabularyBuilder()
        builder = FileVocabularyBuilder(
            dependencies: FileVocabularyBuilder.Dependencies(
                vocabularyBuilder: textBuilder.eraseToVocabularyBuilder,
                batchSize: 2
            )
        )
    }

    func testTextBuilder() async throws {
        let str = """
        two one Three three two THREE
        """
        let url = createTemporaryTestFile(with: str)
        let vocab = try await builder.build(from: url)
        let wordsSet = Set(vocab.words)
        XCTAssertEqual(wordsSet.count, vocab.words.count)
        XCTAssertEqual(Set(vocab.words), Set(["one", "two", "three"]))
        XCTAssertEqual(vocab["one"], 1)
        XCTAssertEqual(vocab["two"], 2)
        XCTAssertEqual(vocab["three"], 3)
    }

    func testBuildEmptyVocabulary() async throws {
        let vocabulary = try await textBuilder.build(from: "")
        XCTAssertEqual(vocabulary["empty"], 0)
        XCTAssertEqual(vocabulary.words.count, 0)
    }

    private func createTemporaryTestFile(with content: String) -> URL {
        do {
            let temporaryDirectoryURL = FileManager.default.temporaryDirectory
            let temporaryFileURL = temporaryDirectoryURL.appendingPathComponent(UUID().uuidString)

            try content.write(to: temporaryFileURL, atomically: true, encoding: .utf8)

            return temporaryFileURL
        } catch {
            fatalError("Failed to create a temporary file for testing.")
        }
    }

    func testBuildersResultSame() async throws {
        let url = createTemporaryTestFile(with: generatedText)
        let textVocab = try await textBuilder.build(from: generatedText)
        let fileVocab = try await builder.build(from: url)

        let wordsSet = Set(fileVocab.words)
        XCTAssertEqual(wordsSet.count, fileVocab.words.count)

        XCTAssertEqual(Set(fileVocab.words), Set(textVocab.words))
        for word in fileVocab.words {
            XCTAssertEqual(fileVocab[word], textVocab[word])
        }
    }
}


let generatedText = """
Lorem ipsum dolor sit amet, consectetur adipiscing elit. Integer ut dolor eget purus laoreet ullamcorper. Ut luctus sapien eu lectus ullamcorper, vel blandit lorem suscipit. Sed rhoncus euismod dui, a malesuada lectus sollicitudin vel. Fusce ultrices a elit at blandit. Nullam dignissim, nisi a bibendum bibendum, libero libero bibendum risus, id tristique dolor quam non ex. Proin nec dui eget ligula hendrerit faucibus. Integer vel felis in urna dictum vehicula. Etiam sit amet tellus a ex laoreet interdum eget non arcu. Maecenas id nisl ac velit gravida scelerisque. Aliquam erat volutpat. Vestibulum vitae varius odio. Vestibulum et mattis ex, in euismod justo. Maecenas scelerisque elit sed quam hendrerit, nec facilisis lorem vestibulum. Etiam mattis est non ante dictum, nec luctus purus lacinia.

Phasellus ut libero id orci fermentum malesuada. Sed euismod magna vitae bibendum suscipit. Nam ut pharetra mi. Fusce euismod venenatis enim, in vehicula ex tincidunt nec. Donec posuere magna non eros facilisis, nec scelerisque arcu egestas. Praesent nec neque in purus eleifend mattis. Curabitur auctor vestibulum purus, eu cursus odio facilisis sit amet. Vivamus eget leo augue. Quisque posuere lorem nec odio interdum fringilla. Morbi sit amet lacus vitae purus tincidunt vestibulum sit amet nec velit. Vivamus dignissim vulputate odio in luctus. Aenean vestibulum hendrerit eros, non laoreet ex consectetur et. Fusce convallis eros nec justo sollicitudin egestas. Vivamus tristique ut nunc ut semper. Pellentesque in justo ut velit interdum sodales. Nam finibus interdum elit, vel consequat arcu fermentum a.

Pellentesque auctor ac urna eget bibendum. Nulla malesuada lectus quis urna scelerisque, in sodales arcu vehicula. Suspendisse potenti. Suspendisse non mi non augue convallis aliquam. Proin venenatis, velit ac pharetra suscipit, ligula urna vulputate justo, et tristique arcu risus id purus. Curabitur viverra odio in ex ultricies, vel convallis tellus vulputate. Ut ac dui et ipsum gravida vehicula. Maecenas volutpat vestibulum fringilla. Sed sed risus ac arcu vulputate lacinia.

Cras eget dolor vel tortor venenatis iaculis. Nulla facilisi. In eu rhoncus elit. Duis eu justo ut ligula luctus fringilla. Nullam suscipit, justo non facilisis varius, libero elit ultricies risus, vel congue justo ex eu urna. Sed ultricies tortor et euismod blandit. Integer suscipit efficitur libero, in bibendum metus aliquam sit amet. Curabitur scelerisque vestibulum sapien in hendrerit. Curabitur tristique, risus quis facilisis tempus, ex dui congue massa, vel luctus justo libero eu ex. Vestibulum consectetur ante a arcu tincidunt, id suscipit mi accumsan. Nam lacinia justo a odio elementum, vel pellentesque libero feugiat. In non magna ac erat semper facilisis. Fusce tincidunt justo in erat rhoncus, eu bibendum mi pellentesque. Ut varius bibendum dolor, a ultricies justo volutpat vel. Sed ac sapien ut libero dictum venenatis. Nulla facilisi.
"""
