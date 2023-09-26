//
//  ListComponent.swift
//  TeladocChallenage
//
//  Created by Artem Bastun on 26/09/2023.
//

import Foundation
import Combine

extension AnyCancellable {
    static var empty: Self {
        return Self {}
    }
}

struct SortOptionComponent<Item, ViewModel> {
    let items: [Item]
    let selected: Item?
    let actionTitle: String
    private let viewModelCreator: (Item) -> ViewModel

    let selectActionSubject = PassthroughSubject<Item, Never>()

    init(items: [Item], selected: Item?, actionTitle: String, viewModelCreator: @escaping (Item) -> ViewModel) {
        self.items = items
        self.selected = selected
        self.actionTitle = actionTitle
        self.viewModelCreator = viewModelCreator
    }

    func viewModel(for item: Item) -> ViewModel {
        viewModelCreator(item)
    }
}

final class VocabularyComponentViewModel {
    enum State {
        case loading
        case loaded([WordItem])
        case error(Swift.Error)
    }

    enum Action {
        case cancel
        case sort
    }

    @Published fileprivate(set) var state: State
    @Published fileprivate(set) var sortComponent: SortOptionComponent<SortOption, String>? = nil

    let actionSubject = PassthroughSubject<Action, Never>()

    private var cancellables = Set<AnyCancellable>()

    init() {
        state = .loading
    }
}

enum SortOption: String, CaseIterable {
    case alphabetical
    case alphabeticalDescending
    case frequency
    case frequencyDescending
}

struct WordItem: Equatable {
    let text: String
    let frequency: Int
}

protocol VocabularyComponentProtocol {
    var viewModel: VocabularyComponentViewModel { get }
}

final class VocabularyComponent: VocabularyComponentProtocol {
    struct Dependencies {
        let viewModelCreator: () -> VocabularyComponentViewModel
        let sortComponentCreator: (SortOption?) -> SortOptionComponent<SortOption, String>
        let vocabularyBuilder: VocabularyBuilder<URL>
        let fileURL: URL
    }

    let viewModel: VocabularyComponentViewModel

    private let sortSubject: CurrentValueSubject<SortOption, Never>

    private var cancellables = Set<AnyCancellable>()
    private var sortCancellable: Cancellable?

    init(_ dependencies: Dependencies) {
        self.viewModel = dependencies.viewModelCreator()
        self.sortSubject = CurrentValueSubject(.frequencyDescending)

        sortSubject.sink { [weak self] sorting in
            guard let self = self, case .loaded(let array) = self.viewModel.state else {
                return
            }

            self.viewModel.state = .loaded(self.sorted(items: array, using: sorting))
        }
        .store(in: &cancellables)

        viewModel.actionSubject
            .filter { $0 == .sort }
            .sink { [weak self, dependencies] _ in
                let node = dependencies.sortComponentCreator(self?.sortSubject.value)
                self?.sortCancellable = node.selectActionSubject.sink { option in
                    self?.sortSubject.value = option
                    self?.viewModel.sortComponent = nil
                }
                self?.viewModel.sortComponent = node
            }
            .store(in: &cancellables)

        dependencies.vocabularyBuilder.buildPublisher(from: dependencies.fileURL)
            .sink(receiveCompletion: { [weak self] completion in

            switch completion {
            case .failure(let error):
                self?.viewModel.state = .error(error)
            case .finished: break
            }
        }, receiveValue: { [weak self] product in
            guard let self = self else { return }
            let items = product.frequencies.keys.map { WordItem(text: $0, frequency: product[$0]) }
            self.viewModel.state = .loaded(self.sorted(items: items, using: self.sortSubject.value))
        })
        .store(in: &cancellables)
    }

    private func sorted(items: [WordItem], using option: SortOption) -> [WordItem] {
        items.sorted(by: {
            switch option {
            case .alphabetical:
                return $0.text < $1.text
            case .frequency:
                return $0.frequency < $1.frequency
            case .alphabeticalDescending:
                return $0.text > $1.text
            case .frequencyDescending:
                return $0.frequency > $1.frequency
            }
        })
    }
}

extension URL {
    static var textURL: URL { Bundle.main.url(forResource: "Romeo-and-Juliet", withExtension: "txt")! }
}

extension VocabularyComponent {
    static func create() -> VocabularyComponent {
        VocabularyComponent(
            Dependencies(
                viewModelCreator: { VocabularyComponentViewModel() },
                sortComponentCreator: { 
                    SortOptionComponent(
                        items: SortOption.allCases,
                        selected: $0,
                        actionTitle: "Cancel",
                        viewModelCreator: { option in
                            switch option {
                            case .alphabetical:
                                return "Alphabetical ↑"
                            case .alphabeticalDescending:
                                return "Alphabetical ↓"
                            case .frequency:
                                return "Frequency ↑"
                            case .frequencyDescending:
                                return "Frequency ↓"
                            }
                        }
                    )
                },
                vocabularyBuilder: FileVocabularyBuilder(
                    dependencies: FileVocabularyBuilder.Dependencies(
                        vocabularyBuilder: TextVocabularyBuilder().eraseToVocabularyBuilder,
                        batchSize: 100
                    )
                ).eraseToVocabularyBuilder,
                fileURL: .textURL
            )
        )
    }
}
