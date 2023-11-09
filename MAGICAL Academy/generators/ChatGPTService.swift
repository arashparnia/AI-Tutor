//
//  ChatGPTService.swift
//  MAGICAL Academy
//
//  Created by arash parnia on 11/7/23.
//

import Foundation

struct ChatGPTService {
    private let apiKey: String
    private let session: URLSession
    
    init(session: URLSession = .shared) {
        self.apiKey = ChatGPTService.fetchAPIKey()
        self.session = session
    }
    
    private static func fetchAPIKey() -> String {
        // Implement a secure way to retrieve the API key. This is just an example.
        // You might want to retrieve it from the environment variables or a secure store.
        guard let apiKey = ProcessInfo.processInfo.environment["CHAT_GPT_API_KEY"] else {
            fatalError("API Key not found")
        }
        return apiKey
    }
    
    
    
    func fetchResponse(for messages: [[String: String]], completion: @escaping (Result<String, Error>) -> Void) {
        guard let url = URL(string: "https://api.openai.com/v1/chat/completions") else {
            completion(.failure(URLError(.badURL)))
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let body: [String: Any] = [
            "model": "gpt-3.5-turbo-16k-0613",
            "messages": messages,
            "temperature": 1.0,
            "max_tokens": 256,
            "top_p": 1,
            "frequency_penalty": 0,
            "presence_penalty": 0
        ]
        
        do {
            let requestBody = try JSONSerialization.data(withJSONObject: body, options: [])
            request.httpBody = requestBody
        } catch {
            completion(.failure(error))
            return
        }
        
        let task = session.dataTask(with: request) { data, response, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
                completion(.failure(URLError(.badServerResponse)))
                return
            }
            
            guard let data = data else {
                completion(.failure(URLError(.badServerResponse)))
                return
            }
            
            do {
                if let jsonObject = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any],
                   let choices = jsonObject["choices"] as? [[String: Any]],
                   let firstChoice = choices.first,
                   let message = firstChoice["message"] as? [String: Any],
                   let text = message["content"] as? String {
                    completion(.success(text))
                } else {
                    completion(.failure(URLError(.cannotParseResponse)))
                }
            } catch {
                completion(.failure(error))
            }
        }
        
        task.resume()
    }
}
