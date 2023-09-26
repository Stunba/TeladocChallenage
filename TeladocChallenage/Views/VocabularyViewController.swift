//
//  VocabularyViewController.swift
//  TeladocChallenage
//
//  Created by Artem Bastun on 26/09/2023.
//

import Foundation

import UIKit
import Combine

final class DataSource: NSObject, UITableViewDataSource, UITableViewDelegate {
    typealias Item = WordItem
    typealias CellConfiguration = (UITableViewCell, Item) -> Void
    private let items: [Item]
    private let cellIdentifier: String
    private let cellConfiguration: CellConfiguration

    init(items: [WordItem], cellIdentifier: String, cellConfiguration: @escaping CellConfiguration) {
        self.items = items
        self.cellIdentifier = cellIdentifier
        self.cellConfiguration = cellConfiguration
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        items.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: cellIdentifier, for: indexPath)
        cellConfiguration(cell, items[indexPath.row])
        return cell
    }

    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        // TODO: move to VM
        guard let header = tableView.dequeueReusableHeaderFooterView(withIdentifier: "Header") else { return nil }
        var configuration = UIListContentConfiguration.valueCell()
        let attrs: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 12),
            .foregroundColor: UIColor(red: 0.4, green: 0.4, blue: 0.4, alpha: 1)
        ]
        configuration.attributedText = NSAttributedString(string: "Word".uppercased(), attributes: attrs)
        configuration.secondaryAttributedText = NSAttributedString(string: "Frequency".uppercased(), attributes: attrs)
        header.contentConfiguration = configuration
        return header
    }
}

extension UIBarButtonItem {
    static func sort(target: Any?, action: Selector) -> UIBarButtonItem {
        var buttonConfig = UIButton.Configuration.plain()
        buttonConfig.image = UIImage(systemName: "arrow.up.arrow.down")
        buttonConfig.preferredSymbolConfigurationForImage = UIImage.SymbolConfiguration(pointSize: 12, weight: .semibold)
        buttonConfig.title = "Sort"
        buttonConfig.contentInsets.leading = 0
        buttonConfig.imagePadding = 8
        let button = UIButton(configuration: buttonConfig)
        button.addTarget(target, action: action, for: .touchUpInside)
        return UIBarButtonItem(customView: button)
    }
}

final class VocabularyViewController: UIViewController {
    private let tableView = UITableView(frame: .zero, style: .grouped)
    private let loadingView = UIActivityIndicatorView(style: .large)

    fileprivate let cellIdentifier = "Cell"
    fileprivate let headerIdentifier = "Header"

    var actionSubject: PassthroughSubject<VocabularyComponentViewModel.Action, Never>?
    var dataSource: DataSource? {
        didSet {
            tableView.dataSource = dataSource
            tableView.delegate = dataSource
            tableView.reloadData()
        }
    }

    init() {
        super.init(nibName: nil, bundle: nil)
        loadViewIfNeeded()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func loadView() {
        let container = UIView()
        container.backgroundColor = .systemBackground

        container.addSubview(tableView)
        tableView.translatesAutoresizingMaskIntoConstraints = false
        [
            tableView.topAnchor.constraint(equalTo: container.topAnchor),
            tableView.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: container.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: container.bottomAnchor)
        ]
            .forEach { $0.isActive = true}


        container.addSubview(loadingView)
        loadingView.translatesAutoresizingMaskIntoConstraints = false
        loadingView.centerXAnchor.constraint(equalTo: container.centerXAnchor).isActive = true
        loadingView.centerYAnchor.constraint(equalTo: container.centerYAnchor).isActive = true

        self.view = container
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        navigationItem.leftBarButtonItems = [.sort(target: self, action: #selector(sortAction(_:)))]

        tableView.register(UITableViewCell.self, forCellReuseIdentifier: cellIdentifier)
        tableView.register(UITableViewHeaderFooterView.self, forHeaderFooterViewReuseIdentifier: headerIdentifier)
    }

    @objc func sortAction(_ sender: Any) {
        actionSubject?.send(.sort)
    }
}

// MARK: Presenting
extension VocabularyViewController {
    func loadingState(title: String) {
        tableView.isHidden = true

        loadingView.startAnimating()
    }

    func contentState(items: [WordItem]) {
        loadingView.stopAnimating()

        self.dataSource = DataSource(items: items, cellIdentifier: cellIdentifier) { cell, item in
            var configuration = UIListContentConfiguration.valueCell()
            let attrs: [NSAttributedString.Key: Any] = [.font: UIFont.systemFont(ofSize: 17), .foregroundColor: UIColor.label]
            configuration.attributedText = NSAttributedString(string: item.text, attributes: attrs)
            configuration.secondaryAttributedText = NSAttributedString(string: "\(item.frequency)",attributes: attrs)
            cell.contentConfiguration = configuration
        }

        tableView.isHidden = false
        navigationController?.setNavigationBarHidden(false, animated: true)
    }

    func errorState(title: String, message: String) {
        loadingView.stopAnimating()
        tableView.isHidden = true
        
        let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alertController.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        present(alertController, animated: true)
    }
}
