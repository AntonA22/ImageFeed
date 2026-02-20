//
//  URLSession+data.swift.swift
//  ImageFeed
//
//  Created by Антон Абалуев on 01.02.2026.
//

import Foundation

enum NetworkError: Error {  // 1
    case httpStatusCode(Int)
    case urlRequestError(Error)
    case urlSessionError
    case invalidRequest
    case decodingError(Error)
}

extension URLSession {
    func data(
        for request: URLRequest,
        completion: @escaping (Result<Data, Error>) -> Void
    ) -> URLSessionTask {

        let fulfillCompletionOnTheMainThread: (Result<Data, Error>) -> Void = { result in
            DispatchQueue.main.async { completion(result) }
        }

        let task = dataTask(with: request) { data, response, error in
            if
                let data,
                let response,
                let statusCode = (response as? HTTPURLResponse)?.statusCode
            {
                if 200 ..< 300 ~= statusCode {
                    fulfillCompletionOnTheMainThread(.success(data))
                } else {
                    logError("URLSession.data", "NetworkError.httpStatusCode=\(statusCode), url=\(request.url?.absoluteString ?? "nil")")
                    fulfillCompletionOnTheMainThread(.failure(NetworkError.httpStatusCode(statusCode)))
                }
            } else if let error {
                logError("URLSession.data", "NetworkError.urlRequestError=\(error.localizedDescription), url=\(request.url?.absoluteString ?? "nil")")
                fulfillCompletionOnTheMainThread(.failure(NetworkError.urlRequestError(error)))
            } else {
                logError("URLSession.data", "NetworkError.urlSessionError, url=\(request.url?.absoluteString ?? "nil")")
                fulfillCompletionOnTheMainThread(.failure(NetworkError.urlSessionError))
            }
        }

        return task
    }
}


extension URLSession {
    func objectTask<T: Decodable>(
        for request: URLRequest,
        completion: @escaping (Result<T, Error>) -> Void
    ) -> URLSessionTask {

        let decoder = JSONDecoder()

        let task = data(for: request) { result in
            switch result {
            case .success(let data):
                do {
                    let decodedObject = try decoder.decode(T.self, from: data)
                    completion(.success(decodedObject))
                } catch {
                    let body = String(data: data, encoding: .utf8) ?? ""
                    logError(
                        "URLSession.objectTask",
                        "decodingError=\(error.localizedDescription), type=\(T.self), url=\(request.url?.absoluteString ?? "nil"), data=\(body)"
                    )
                    completion(.failure(NetworkError.decodingError(error)))
                }

            case .failure(let error):
                logError(
                    "URLSession.objectTask",
                    "upstreamError=\(error.localizedDescription), type=\(T.self), url=\(request.url?.absoluteString ?? "nil")"
                )
                completion(.failure(error))
            }
        }

        return task
    }
}

func logError(_ tag: String, _ message: String) {
    print("[\(tag)]: ERROR \(message)")
}
