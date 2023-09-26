//
//  VocabularyBuilder.swift
//  TeladocChallenage
//
//  Created by Artem Bastun on 26/09/2023.
//

import Foundation
import Combine

// TODO: rename
protocol VocabularyBuiling {
    associatedtype Source
    func build(from source: Source) async throws -> Vocabulary
}

struct VocabularyBuilder<Source>: VocabularyBuiling {
    private let building: (Source) async throws -> Vocabulary

    init(building: @escaping (Source) async throws -> Vocabulary) {
        self.building = building
    }

    func build(from source: Source) async throws -> Vocabulary {
        try await building(source)
    }
}

extension VocabularyBuiling {
    var eraseToVocabularyBuilder: VocabularyBuilder<Source> {
        return VocabularyBuilder(building: { try await self.build(from: $0) })
    }
}

extension VocabularyBuiling {
    func buildPublisher(from source: Source) -> AnyPublisher<Vocabulary, Swift.Error> {
        Future { promise in
            Task {
                do {
                    let product = try await self.build(from: source)
                    promise(.success(product))
                } catch {
                    promise(.failure(error))
                }
            }
        }
        .eraseToAnyPublisher()
    }
}

struct TextVocabularyBuilder: VocabularyBuiling {
    func build(from text: String) async throws -> Vocabulary {
        let words = text.components(separatedBy: .alphanumerics.inverted)
        let data: [String: Int] = words
            .filter { !$0.isEmpty }
            .reduce(into: [:]) { result, word in

            let key = word.lowercased()
            result[key] = result[key, default: 0] + 1
        }
        return Vocabulary(data)
    }
}

struct FileVocabularyBuilder: VocabularyBuiling {
    struct Dependencies {
        let vocabularyBuilder: VocabularyBuilder<String>
        let batchSize: Int
    }

    private let dependencies: Dependencies

    init(dependencies: Dependencies) {
        self.dependencies = dependencies
    }

    func build(from fileURL: URL) async throws -> Vocabulary {
        let handle = try FileHandle(forReadingFrom: fileURL)
        defer { try? handle.close() }

        return try await withThrowingTaskGroup(
            of: Vocabulary.self,
            returning: Vocabulary.self
        ) { [dependencies] group in

            var lines: [String] = []
            for try await line in handle.bytes.lines {
                lines.append(line)
                if lines.count == dependencies.batchSize {
                    let text = lines.joined(separator: "\n")
                    lines = []
                    group.addTask {
                        return try await dependencies.vocabularyBuilder.build(from: text)
                    }
                }
            }
            let text = lines.joined(separator: "\n")
            group.addTask {
                return try await dependencies.vocabularyBuilder.build(from: text)
            }
            return try await group.reduce(Vocabulary(), +)
        }
    }
}
