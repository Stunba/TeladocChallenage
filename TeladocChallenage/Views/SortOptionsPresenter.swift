//
//  SortOptionsPresenter.swift
//  TeladocChallenage
//
//  Created by Artem Bastun on 26/09/2023.
//

import UIKit
import Combine

struct SortOptionsPresenter {
    private let presenting: UIViewController

    init(presenting: UIViewController) {
        self.presenting = presenting
    }

    @discardableResult
    func present(_ component: SortOptionComponent<SortOption, String>) -> Cancellable {
        let viewController = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        for option in component.items {
            let action = UIAlertAction(title: component.viewModel(for: option), style: .default) { _ in
                component.selectActionSubject.send(option)
            }
            action.isEnabled = !(component.selected == option)
            viewController.addAction(action)
        }
        viewController.addAction(
            UIAlertAction(title: component.actionTitle, style: .cancel, handler: nil)
        )
        presenting.present(viewController, animated: true)
        return AnyCancellable.empty
    }

    func dismiss() {
        presenting.dismiss(animated: true)
    }
}
