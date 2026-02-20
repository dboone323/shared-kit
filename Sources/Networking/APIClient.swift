//
// APIClient.swift
// SharedKit
//
// Generic HTTP client for network requests
//

import Foundation

public enum APIError: Error {
    case invalidURL
    case requestFailed
    case decodingFailed
    case serverError(statusCode: Int)
}

public struct APIClient {
    public static let shared = APIClient()
    private let session = URLSession.shared

    public func fetch<T: Decodable>(
        _ type: T.Type,
        from urlString: String,
        completion: @escaping (Result<T, APIError>) -> Void
    ) {
        guard let url = URL(string: urlString) else {
            completion(.failure(.invalidURL))
            return
        }

        session.dataTask(with: url) { data, response, error in
            if error != nil {
                completion(.failure(.requestFailed))
                return
            }

            guard let httpResponse = response as? HTTPURLResponse,
                (200...299).contains(httpResponse.statusCode)
            else {
                let statusCode = (response as? HTTPURLResponse)?.statusCode ?? 0
                completion(.failure(.serverError(statusCode: statusCode)))
                return
            }

            guard let data else {
                completion(.failure(.decodingFailed))
                return
            }

            do {
                let decoded = try JSONDecoder().decode(T.self, from: data)
                completion(.success(decoded))
            } catch {
                completion(.failure(.decodingFailed))
            }
        }.resume()
    }
}
