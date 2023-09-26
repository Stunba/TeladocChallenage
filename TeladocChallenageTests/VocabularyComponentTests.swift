//
//  VocabularyComponentTests.swift
//  TeladocChallenageTests
//
//  Created by Artem Bastun on 26/09/2023.
//

import XCTest
import Combine
@testable import TeladocChallenage

extension VocabularyComponentViewModel.State: Equatable {
    public static func == (lhs: TeladocChallenage.VocabularyComponentViewModel.State, rhs: TeladocChallenage.VocabularyComponentViewModel.State) -> Bool {
        switch (lhs, rhs) {
        case (.loading, .loading):
            return true
        case (loaded(let lhs), .loaded(let rhs)):
            return lhs == rhs
        case (.error, .error):
            return true
        default:
            return false
        }
    }
}

final class MockVocabularyBuilder: VocabularyBuiling {
    func build(from url: URL) async throws -> Vocabulary {
        let frequencies: [String: Int] = ["Apple": 5, "Banana": 3, "Cherry": 2]
        let vocabulary = Vocabulary(frequencies)
        return vocabulary
    }
}

final class VocabularyComponentTests: XCTestCase {
    var component: VocabularyComponent!
    var cancellables = Set<AnyCancellable>()

    override func setUpWithError() throws {
        let dependencies = VocabularyComponent.Dependencies(
            listCreator: Creator { VocabularyComponentViewModel() },
            sortComponentCreator: { _ in
                SortOptionComponent<SortOption, String>(
                    items: SortOption.allCases, selected: nil, actionTitle: "", viewModelCreator: { $0.rawValue }
                )
            },
            vocabularyBuilder: MockVocabularyBuilder().eraseToVocabularyBuilder,
            fileURL: URL(fileURLWithPath: "testfile.txt")
        )
        component = VocabularyComponent(dependencies)
    }

    func testInitialState() {
        XCTAssertEqual(component.viewModel.state, .loading)
    }

    func testSorting() {
        component.viewModel.actionSubject.send(.sort)
        XCTAssertNotNil(component.viewModel.sortComponent)

        let testData = [WordItem(text: "Banana", frequency: 3),
                        WordItem(text: "Apple", frequency: 5),
                        WordItem(text: "Cherry", frequency: 2)]
        
        component.viewModel.sortComponent?.selectActionSubject.send(.alphabetical)
        XCTAssertEqual(component.viewModel.state, .loaded(testData.sorted(by: { $0.text < $1.text })))

        component.viewModel.actionSubject.send(.sort)
        component.viewModel.sortComponent?.selectActionSubject.send(.frequency)
        XCTAssertEqual(component.viewModel.state, .loaded(testData.sorted(by: { $0.frequency < $1.frequency })))
    }
}
