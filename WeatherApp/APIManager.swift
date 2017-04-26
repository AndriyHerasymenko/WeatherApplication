//
//  APIManager.swift
//  WeatherApp
//
//  Created by Andriy Herasymenko on 4/20/17.
//  Copyright © 2017 Andriy Herasymenko. All rights reserved.
//

import Foundation

typealias JSONTask = URLSessionDataTask
typealias JSONCompletionHandler = ([String:AnyObject]?, HTTPURLResponse?, Error?) -> Void

protocol JSONDecodable {
    
    init?(JSON: [String: AnyObject])
    
}

protocol FinalURLPoint {
    
    var baseURL: URL { get }
    var path: String { get }
    var request: URLRequest { get }
    
}

enum APIResult<T> {
    
    case Success(T)
    case Failure(Error)
    
}

protocol APIManager {
    var sessionConfiguration: URLSessionConfiguration { get }
    var session: URLSession { get }
    
    func JSONTaskWith(request: URLRequest, completionHandler:  @escaping JSONCompletionHandler) -> JSONTask
    func fetch<T: JSONDecodable>(request: URLRequest, parse: @escaping ([String: AnyObject]) -> T?, completionHandler: @escaping (APIResult<T>) -> Void)
    
}

extension APIManager {
    func JSONTaskWith(request: URLRequest, completionHandler: @escaping JSONCompletionHandler) -> JSONTask {
        
        let dataTask = session.dataTask(with: request) { (data, response, error) in
            
            guard let HTTPResponse = response as? HTTPURLResponse else {
                
                let userInfo = [
                    NSLocalizedDescriptionKey: NSLocalizedString("Missing HTTP Response", comment: "")
                ]
                let error = NSError(domain: SWINetworkingErrorDomain, code: 100, userInfo: userInfo)
                
                completionHandler(nil, nil, error)
                return
            }
            // Default Implimitation(part1)
            if data == nil {
                if let error = error {
                    completionHandler(nil, HTTPResponse, error)
                }
            } else {
                switch HTTPResponse.statusCode {
                case 200:
                    do {
                        let json = try JSONSerialization.jsonObject(with: data!, options: []) as? [String: AnyObject]
                        completionHandler(json, HTTPResponse, nil)
                    } catch let error as NSError {
                        completionHandler(nil, HTTPResponse, error)
                    }
                default:
                    print("We have got response status \(HTTPResponse.statusCode)")
                }
            }
        }
        return dataTask
    }

    // Default Implimatation(Part2)
    func fetch<T>(request: URLRequest, parse: @escaping ([String: AnyObject]) -> T?, completionHandler: @escaping (APIResult<T>) -> Void) {
        // вызываем первый метод
        let dataTask = JSONTaskWith(request: request) { (json, response, error) in
            DispatchQueue.main.sync {
                // проверяем получился ли у нас json или nil
                guard let json = json else {
                    // смотрим на наличие ошибки
                    if let error = error {
                        // если nil вызываем ошибку
                        completionHandler(.Failure(error))
                    }
                    // если все нормально идем дальше и смотрим
                    return
                }
                // смотрим получилось ли у нас получить опциональное T через parse(json)
                if let value = parse(json) {
                    completionHandler(.Success(value))
                } else {
                    let error = NSError(domain: SWINetworkingErrorDomain, code: 200, userInfo: nil)
                    completionHandler(.Failure(error))
                }
            }
        }
        dataTask.resume()
    }

}










