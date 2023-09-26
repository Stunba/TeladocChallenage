//
//  VocabularyComponentPresenter.swift
//  TeladocChallenage
//
//  Created by Artem Bastun on 26/09/2023.
//

import UIKit
import Combine

struct VocabularyComponentViewModelPresenter {
    private let viewController: VocabularyViewController
    private var listSortPresenter: SortOptionsPresenter?

    init(viewController: VocabularyViewController) {
        self.viewController = viewController
    }

    func present(_ viewModel: VocabularyComponentViewModel) -> Cancellable {
        viewController.actionSubject = viewModel.actionSubject
        var cancellables = Set<AnyCancellable>()
        viewModel.$state
            .receive(on: DispatchQueue.main)
            .sink { [viewController] state in

            switch state {
            case .loading:
                viewController.loadingState(title: "Loading ...") // TODO: get text from view model
            case .loaded(let content):
                viewController.contentState(items: content)
            case .error(let error):
                viewController.errorState(title: "Server error", message: "Something went wrong")
                print(error)
            }
        }
            .store(in: &cancellables)

        viewModel.$sortComponent.sink { [viewController] sortComponent in
            guard let component = sortComponent else {
                return
            }
            let presenter = SortOptionsPresenter(presenting: viewController)
            presenter.present(component)
        }
        .store(in: &cancellables)

        return AnyCancellable { cancellables.forEach { $0.cancel() } }
    }
}

struct VocabularyComponentPresenter {
    private let viewControllerPresenting: (UIViewController) -> AnyCancellable

    init(viewControllerPresenting: @escaping (UIViewController) -> AnyCancellable) {
        self.viewControllerPresenting = viewControllerPresenting
    }

    func present(_ component: VocabularyComponentProtocol) -> Cancellable {
        var cancellables = Set<AnyCancellable>()
        let viewController = VocabularyViewController()
        viewControllerPresenting(viewController).store(in: &cancellables)
        VocabularyComponentViewModelPresenter(viewController: viewController)
            .present(component.viewModel)
            .store(in: &cancellables)

        return AnyCancellable { cancellables.forEach { $0.cancel() } }
    }
}
