//
//  APIProvider.swift
//  AppStoreConnect-Swift-SDK
//
//  Created by Antoine van der Lee on 05/11/2018.
//

import Foundation

public typealias RequestCompletionHandler<T> = (Result<T>) -> Void

/// The configuration needed to set up the API Provider including all needed information for performing API requests.
public struct APIConfiguration {
    
    /// Your private key ID from App Store Connect (Ex: 2X9R4HXF34)
    let privateKeyID: String
    
    let privateKey: String
    
    /// Your issuer ID from the API Keys page in App Store Connect (Ex: 57246542-96fe-1a63-e053-0824d011072a)
    let issuerID: String
    
    /// Creates a new API configuration to use for initialising the API Provider.
    ///
    /// - Parameters:
    ///   - privateKeyID: Your private key ID from App Store Connect (Ex: 2X9R4HXF34)
    ///   - issuerID: Your issuer ID from the API Keys page in App Store Connect (Ex: 57246542-96fe-1a63-e053-0824d011072a)
    public init(issuerID: String, privateKeyID: String, privateKey: String) {
        self.privateKeyID = privateKeyID
        self.privateKey = privateKey
        self.issuerID = issuerID
    }
}

/// Provides access to all API Methods. Can be used to perform API requests.
public final class APIProvider {
    
    /// The session manager which is used to perform network requests with.
    private let session = URLSession(configuration: .default)

    /// Contains a JSON Decoder which can be reused.
    private let jsonDecoder: JSONDecoder = {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return decoder
    }()
    
    /// The configuration needed to set up the API Provider including all needed information for performing API requests.
    private let configuration: APIConfiguration
    
    /// The authenticator to handle all JWT signing related actions.
    private lazy var requestsAuthenticator = JWTRequestsAuthenticator(apiConfiguration: self.configuration)
    
    /// Creates a new APIProvider instance which can be used to perform API Requests to the App Store Connect API.
    ///
    /// - Parameters:
    ///   - configuration: The configuration needed to set up the API Provider including all needed information for performing API requests.
    ///   - protocolClasses: Optional protocal classes to use for mocking with unit tests.
    public init(configuration: APIConfiguration, protocolClasses: [AnyClass]? = nil) {
        self.configuration = configuration

        
        //defaultSessionManager.adapter = requestsAuthenticator
    }
        
    /// Performs a data request to the given API endpoint
    ///
    /// - Parameters:
    ///   - endpoint: The API endpoint to request.
    ///   - completion: The completion callback which will be called on completion containing the result.
    @discardableResult
    public func request(_ endpoint: APIEndpoint<Void>, completion: @escaping RequestCompletionHandler<Void>) -> URLSessionDataTask {
        let request = try! requestsAuthenticator.adapt(endpoint.asURLRequest())
        let dataRequest = session.dataTask(with: request) { (data, response, error) in
            if let error = error {
                completion(Result.failure(error))
            } else {
                completion(Result.success(()))
            }
        }
        dataRequest.resume()
        return dataRequest
    }
    
    /// Performs a data request to the given API endpoint
    ///
    /// - Parameters:
    ///   - endpoint: The API endpoint to request.
    ///   - completion: The completion callback which will be called on completion containing the result.
    @discardableResult
    public func request<T: Decodable>(_ endpoint: APIEndpoint<T>, completion: @escaping RequestCompletionHandler<T>) -> URLSessionDataTask {
        let request = try! requestsAuthenticator.adapt(endpoint.asURLRequest())
        let dataRequest = session.dataTask(with: request) { (data, response, error) in
            if let error = error {
                completion(Result.failure(error))
            } else if let data = data,
                let codable = try? self.jsonDecoder.decode(T.self, from: data) {
                completion(Result.success(codable))
            }
            completion(Result.failure(JSONMappingError.invalidResponse))
        }
        dataRequest.resume()
        return dataRequest
    }
    
    /// Performs a data request to the given ResourceLinks
    ///
    /// - Parameters:
    ///   - resourceLinks: The resourceLinks to request.
    ///   - completion: The completion callback which will be called on completion containing the result.
    @discardableResult
    public func request<T: Decodable>(_ resourceLinks: ResourceLinks<T>, completion: @escaping RequestCompletionHandler<T>) -> URLSessionDataTask {
        let dataRequest = session.dataTask(with: resourceLinks.`self`) { (data, response, error) in
            if let error = error {
                completion(Result.failure(error))
            } else if let data = data,
                let codable = try? self.jsonDecoder.decode(T.self, from: data) {
                completion(Result.success(codable))
            }
            completion(Result.failure(JSONMappingError.invalidResponse))
        }
        dataRequest.resume()
        return dataRequest

    }
}
    enum JSONMappingError: Error {
        /// Indicates that the response is not a valid JSON dictionary.
        case invalidResponse
    }

//extension DataRequest {
//    
//    /// Defines errors which are caused on JSON mapping.
//    enum JSONMappingError: Error {
//        /// Indicates that the response is not a valid JSON dictionary.
//        case invalidResponse
//    }
//    
//    /// Maps the response to the given JSONDecodable data type.
//    ///
//    /// - Parameters:
//    ///   - type: The type to map to.
//    ///   - completion: The result of the mapping. An error will be returned if mapping fails.
//    @discardableResult
//    func dataResponse(decoder: JSONDecoder, completion: @escaping RequestCompletionHandler<Data?>) -> Self {
//        return validate(statusCode: 200..<300).responseData(queue: DispatchQueue.global(qos: .background)) { response in
//            if let error = response.error {
//                // Try to parse api error
//                guard let data = response.data, let apiError = try? decoder.decode(ErrorResponse.self, from: data) else {
//                    completion(Result.failure(error))
//                    return
//                }
//                completion(Result.failure(apiError))
//            } else {
//                completion(Result.success(response.data))
//            }
//        }
//    }
//    
//    /// Maps the response to the given JSONDecodable data type.
//    ///
//    /// - Parameters:
//    ///   - type: The type to map to.
//    ///   - completion: The result of the mapping. An error will be returned if mapping fails.
//    @discardableResult
//    func mapResponseTo<T: Decodable>(_ type: T.Type, decoder: JSONDecoder, completion: @escaping RequestCompletionHandler<T>) -> Self {
//        return dataResponse(decoder: decoder) { response in
//            let result = response.flatMap({ data -> T in
//                // Try to parse the model
//                guard let data = data else {
//                    throw JSONMappingError.invalidResponse
//                }
//                let codable = try decoder.decode(T.self, from: data)
//                return codable
//            })
//            completion(result)
//        }
//    }
//}

public enum Result<Value> {
    case success(Value)
    case failure(Error)

    /// Returns `true` if the result is a success, `false` otherwise.
    public var isSuccess: Bool {
        switch self {
        case .success:
            return true
        case .failure:
            return false
        }
    }

    /// Returns `true` if the result is a failure, `false` otherwise.
    public var isFailure: Bool {
        return !isSuccess
    }

    /// Returns the associated value if the result is a success, `nil` otherwise.
    public var value: Value? {
        switch self {
        case .success(let value):
            return value
        case .failure:
            return nil
        }
    }

    /// Returns the associated error value if the result is a failure, `nil` otherwise.
    public var error: Error? {
        switch self {
        case .success:
            return nil
        case .failure(let error):
            return error
        }
    }
}

// MARK: - CustomStringConvertible

extension Result: CustomStringConvertible {
    /// The textual representation used when written to an output stream, which includes whether the result was a
    /// success or failure.
    public var description: String {
        switch self {
        case .success:
            return "SUCCESS"
        case .failure:
            return "FAILURE"
        }
    }
}

// MARK: - CustomDebugStringConvertible

extension Result: CustomDebugStringConvertible {
    /// The debug textual representation used when written to an output stream, which includes whether the result was a
    /// success or failure in addition to the value or error.
    public var debugDescription: String {
        switch self {
        case .success(let value):
            return "SUCCESS: \(value)"
        case .failure(let error):
            return "FAILURE: \(error)"
        }
    }
}

// MARK: - Functional APIs

extension Result {
    /// Creates a `Result` instance from the result of a closure.
    ///
    /// A failure result is created when the closure throws, and a success result is created when the closure
    /// succeeds without throwing an error.
    ///
    ///     func someString() throws -> String { ... }
    ///
    ///     let result = Result(value: {
    ///         return try someString()
    ///     })
    ///
    ///     // The type of result is Result<String>
    ///
    /// The trailing closure syntax is also supported:
    ///
    ///     let result = Result { try someString() }
    ///
    /// - parameter value: The closure to execute and create the result for.
    public init(value: () throws -> Value) {
        do {
            self = try .success(value())
        } catch {
            self = .failure(error)
        }
    }

    /// Returns the success value, or throws the failure error.
    ///
    ///     let possibleString: Result<String> = .success("success")
    ///     try print(possibleString.unwrap())
    ///     // Prints "success"
    ///
    ///     let noString: Result<String> = .failure(error)
    ///     try print(noString.unwrap())
    ///     // Throws error
    public func unwrap() throws -> Value {
        switch self {
        case .success(let value):
            return value
        case .failure(let error):
            throw error
        }
    }

    /// Evaluates the specified closure when the `Result` is a success, passing the unwrapped value as a parameter.
    ///
    /// Use the `map` method with a closure that does not throw. For example:
    ///
    ///     let possibleData: Result<Data> = .success(Data())
    ///     let possibleInt = possibleData.map { $0.count }
    ///     try print(possibleInt.unwrap())
    ///     // Prints "0"
    ///
    ///     let noData: Result<Data> = .failure(error)
    ///     let noInt = noData.map { $0.count }
    ///     try print(noInt.unwrap())
    ///     // Throws error
    ///
    /// - parameter transform: A closure that takes the success value of the `Result` instance.
    ///
    /// - returns: A `Result` containing the result of the given closure. If this instance is a failure, returns the
    ///            same failure.
    public func map<T>(_ transform: (Value) -> T) -> Result<T> {
        switch self {
        case .success(let value):
            return .success(transform(value))
        case .failure(let error):
            return .failure(error)
        }
    }

    /// Evaluates the specified closure when the `Result` is a success, passing the unwrapped value as a parameter.
    ///
    /// Use the `flatMap` method with a closure that may throw an error. For example:
    ///
    ///     let possibleData: Result<Data> = .success(Data(...))
    ///     let possibleObject = possibleData.flatMap {
    ///         try JSONSerialization.jsonObject(with: $0)
    ///     }
    ///
    /// - parameter transform: A closure that takes the success value of the instance.
    ///
    /// - returns: A `Result` containing the result of the given closure. If this instance is a failure, returns the
    ///            same failure.
    public func flatMap<T>(_ transform: (Value) throws -> T) -> Result<T> {
        switch self {
        case .success(let value):
            do {
                return try .success(transform(value))
            } catch {
                return .failure(error)
            }
        case .failure(let error):
            return .failure(error)
        }
    }

    /// Evaluates the specified closure when the `Result` is a failure, passing the unwrapped error as a parameter.
    ///
    /// Use the `mapError` function with a closure that does not throw. For example:
    ///
    ///     let possibleData: Result<Data> = .failure(someError)
    ///     let withMyError: Result<Data> = possibleData.mapError { MyError.error($0) }
    ///
    /// - Parameter transform: A closure that takes the error of the instance.
    /// - Returns: A `Result` instance containing the result of the transform. If this instance is a success, returns
    ///            the same instance.
    public func mapError<T: Error>(_ transform: (Error) -> T) -> Result {
        switch self {
        case .failure(let error):
            return .failure(transform(error))
        case .success:
            return self
        }
    }

    /// Evaluates the specified closure when the `Result` is a failure, passing the unwrapped error as a parameter.
    ///
    /// Use the `flatMapError` function with a closure that may throw an error. For example:
    ///
    ///     let possibleData: Result<Data> = .success(Data(...))
    ///     let possibleObject = possibleData.flatMapError {
    ///         try someFailableFunction(taking: $0)
    ///     }
    ///
    /// - Parameter transform: A throwing closure that takes the error of the instance.
    ///
    /// - Returns: A `Result` instance containing the result of the transform. If this instance is a success, returns
    ///            the same instance.
    public func flatMapError<T: Error>(_ transform: (Error) throws -> T) -> Result {
        switch self {
        case .failure(let error):
            do {
                return try .failure(transform(error))
            } catch {
                return .failure(error)
            }
        case .success:
            return self
        }
    }

    /// Evaluates the specified closure when the `Result` is a success, passing the unwrapped value as a parameter.
    ///
    /// Use the `withValue` function to evaluate the passed closure without modifying the `Result` instance.
    ///
    /// - Parameter closure: A closure that takes the success value of this instance.
    /// - Returns: This `Result` instance, unmodified.
    @discardableResult
    public func withValue(_ closure: (Value) throws -> Void) rethrows -> Result {
        if case let .success(value) = self { try closure(value) }

        return self
    }

    /// Evaluates the specified closure when the `Result` is a failure, passing the unwrapped error as a parameter.
    ///
    /// Use the `withError` function to evaluate the passed closure without modifying the `Result` instance.
    ///
    /// - Parameter closure: A closure that takes the success value of this instance.
    /// - Returns: This `Result` instance, unmodified.
    @discardableResult
    public func withError(_ closure: (Error) throws -> Void) rethrows -> Result {
        if case let .failure(error) = self { try closure(error) }

        return self
    }

    /// Evaluates the specified closure when the `Result` is a success.
    ///
    /// Use the `ifSuccess` function to evaluate the passed closure without modifying the `Result` instance.
    ///
    /// - Parameter closure: A `Void` closure.
    /// - Returns: This `Result` instance, unmodified.
    @discardableResult
    public func ifSuccess(_ closure: () throws -> Void) rethrows -> Result {
        if isSuccess { try closure() }

        return self
    }

    /// Evaluates the specified closure when the `Result` is a failure.
    ///
    /// Use the `ifFailure` function to evaluate the passed closure without modifying the `Result` instance.
    ///
    /// - Parameter closure: A `Void` closure.
    /// - Returns: This `Result` instance, unmodified.
    @discardableResult
    public func ifFailure(_ closure: () throws -> Void) rethrows -> Result {
        if isFailure { try closure() }

        return self
    }
}
