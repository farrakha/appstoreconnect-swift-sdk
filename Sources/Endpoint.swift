//
//  Endpoints.swift
//  AppStoreConnect-Swift-SDK
//
//  Created by Antoine van der Lee on 05/11/2018.
//

import Foundation

public enum HTTPMethod: String {
    case options = "OPTIONS"
    case get     = "GET"
    case head    = "HEAD"
    case post    = "POST"
    case put     = "PUT"
    case patch   = "PATCH"
    case delete  = "DELETE"
    case trace   = "TRACE"
    case connect = "CONNECT"
}

/// Defines all data needed to build the URL Request with.
public struct APIEndpoint<T> {

    /// The path to the endpoint.
    let path: String

    /// The HTTP Method to use for the request.
    let method: HTTPMethod

    /// The parameters to send with the request. Can be `nil`.
    let parameters: [String: Any]?
    
    /// The body to send with the request. Can be `nil`.
    let body: Data?
    
    init(path: String, method: HTTPMethod = .get, parameters: [String: Any]? = nil, body: Data? = nil) {
        self.path = path
        self.method = method
        self.parameters = parameters
        self.body = body
    }
}

extension APIEndpoint {
    
    /// Generates an URL based on the current endpoint in combination with the current API version.
    internal var url: URL {
        // swiftlint:disable:next force_unwrapping
        var urlComponents = URLComponents(string: "https://api.appstoreconnect.apple.com/v1/")!
        urlComponents.path = path
        urlComponents.queryItems = parameters?.map {
            URLQueryItem(name: $0.key, value: $0.value as? String)
        }
        return urlComponents.url!
    }


    /// Generates a request based on the current endpoint.
    public func asURLRequest() -> URLRequest {
        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = method.rawValue

        if let body = body {
            if urlRequest.value(forHTTPHeaderField: "Content-Type") == nil {
                urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
            }
            urlRequest.httpBody = body
        }
        
        return urlRequest
    }
}
