//
//  PersonSearchViewController.swift
//  FindACrew
//
//  Created by Scott Gardner on 4/6/20.
//  Copyright © 2020 Scott Gardner. All rights reserved.
//

import UIKit

class PersonSearchViewController: UIViewController {

    @IBOutlet weak var searchBar: UISearchBar!
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    
    private let personController = PersonController()
    private lazy var dataSource = makeDataSource()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        searchBar.delegate = self
        tableView.dataSource = dataSource
    }

    private func searchWith(searchTerm: String) {
        activityIndicator.startAnimating()
        
        personController.searchForPeopleWith(searchTerm: searchTerm) {
            DispatchQueue.main.async {
                // Now we're on the main thread! Woot
                self.update()
            }
        }
    }
}

// MARK: - UITableViewDiffableDataSource

extension PersonSearchViewController {
    enum Section {
        case main
    }
    
    private func makeDataSource() -> UITableViewDiffableDataSource<Section, Person> {
        UITableViewDiffableDataSource(tableView: tableView) { tableView, indexPath, person in
            let cell = tableView
                .dequeueReusableCell(withIdentifier: PersonTableViewCell.identifier,
                                     for: indexPath) as! PersonTableViewCell
            
            cell.person = person
            return cell
        }
    }
    
    private func update() {
        var snapshot = NSDiffableDataSourceSnapshot<Section, Person>()
        snapshot.appendSections([.main])
        snapshot.appendItems(personController.people)
        dataSource.apply(snapshot, animatingDifferences: true)
        activityIndicator.stopAnimating()
    }
}

extension PersonSearchViewController: UISearchBarDelegate {
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        guard let searchTerm = searchBar.text else { return }
        searchBar.resignFirstResponder()
        searchWith(searchTerm: searchTerm)
    }
    
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        if searchText.isEmpty {
            personController.people = []
            update()
            return
        }
        
        // Uncomment this code to delay executing searches
        debounce(searchText, current: searchBar.text ?? "") { searchText in
            self.searchWith(searchTerm: searchText)
        }
    }
}

extension PersonSearchViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        searchBar.resignFirstResponder()
        let person = personController.people[indexPath.row]
        dump(person)
    }
}

// MARK: - Optional

extension PersonSearchViewController {
    
    /// Delays executing `action` until after  the `delay` time interval has elapsed between calls.
    /// - Parameters:
    ///   - input: The input to  pass to the `action`
    ///   - delay: The time interval to delay executing the `action`
    ///   - current: The current value to compare with `input` for equality.
    ///   - action: The action to execute after the `delay`.
    /// - Precondition: The `input` and `current` parameter values must be derived from the same source of truth, because they are compared for equality to determine if the `action` should be executed.
    /// - Attention: To implement, uncomment `debounce(_:delay:current:perform:)` in `searchBar(_:textDidChange:)`
    private func debounce<T: Equatable>(_ input: T, delay: TimeInterval = 0.3, current: @escaping @autoclosure () -> T, perform action: @escaping (T) -> Void) {
        DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
            guard input == current() else { return }
            action(input)
        }
    }
}
