//
//  PersonController.swift
//  FindACrew
//
//  Created by Scott Gardner on 4/6/20.
//  Copyright © 2020 Scott Gardner. All rights reserved.
//

import Foundation

final class PersonController {
    enum HTTPMethod: String {
        case get = "GET"
        case put = "PUT"
        case post = "POST"
        case delete = "DELETE"
    }
    
    var people = [Person]()
    
    private let baseURL = URL(string: "https://swapi.co")!
    private lazy var peopleURL = URL(string: "/api/people", relativeTo: baseURL)!
    private var task: URLSessionTask?
    
    func searchForPeopleWith(searchTerm: String, completion: @escaping () -> Void) {
        task?.cancel()
        var urlComponents = URLComponents(url: peopleURL, resolvingAgainstBaseURL: true)
        let searchQueryItem = URLQueryItem(name: "search", value: searchTerm)
        urlComponents?.queryItems = [searchQueryItem]
        
        guard let requestURL = urlComponents?.url else {
            print("Request URL is nil")
            completion()
            return
        }
        
        var request = URLRequest(url: requestURL)
        request.httpMethod = HTTPMethod.get.rawValue
        
        task = URLSession.shared.dataTask(with: request) { [weak self] data, _, error in
            if let error = error {
                print("Error fetching data: \(error.localizedDescription)")
                return
            }
            
            guard let self = self else { return }
            
            guard let data = data else {
                print("No data returned from dataTask")
                return
            }
            
            let jsonDecoder = JSONDecoder()
            
            do {
                let personSearch = try jsonDecoder.decode(PersonSearch.self, from: data)
                self.people = personSearch.results
            } catch {
                print("Unable to decode data into instance of PersonSearch: \(error.localizedDescription)")
            }
            
            completion()
        }
        
        task?.resume()
    }
}

