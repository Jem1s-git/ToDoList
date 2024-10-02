//
//  NetWorkManager.swift
//  ToDoList
//
//  Created by Jem1s on 22.09.2024.
//

import Foundation

struct TaskModel: Codable {
    let id: Int
    let title: String? // Сделано опциональным
    let todo: String? // Описание может отсутствовать
    let completed: Bool
    
    enum CodingKeys: String, CodingKey {
        case id
        case title
        case todo // Убедитесь, что это соответствует ключу в JSON
        case completed
    }
}
struct TaskResponse: Codable {
    let todos: [TaskModel]
}

var tasks: [TaskModel] = [] // Массив для хранения задач


class NetworkService {
    func fetchTasks(completion: @escaping ([TaskModel]?) -> Void) {
        guard let url = URL(string: "https://dummyjson.com/todos") else {
            print("Некорректный URL")
            completion(nil)
            return
        }
        
        let task = URLSession.shared.dataTask(with: url) { data, response, error in
            guard let data = data, error == nil else {
                print("Ошибка при получении данных:", error ?? "Неизвестная ошибка")
                completion(nil)
                return
            }
            
            // Выводим полученные данные в строковом формате для отладки
            if let jsonString = String(data: data, encoding: .utf8) {
                print("Полученный JSON:\n\(jsonString)")
            }
            
            do {
                // Декодируем данные в объект TaskResponse
                let result = try JSONDecoder().decode(TaskResponse.self, from: data)
                
                // Выводим полученные задачи в консоль
                for task in result.todos {
                    print("ID: \(task.id), Title: \(task.todo ?? "Нет названия"), Description: \(task.todo ?? "Нет описания"), Completed: \(task.completed)")
                }
                
                completion(result.todos) // Передаем массив задач через completion handler
                
            } catch {
                // Выводим подробную информацию об ошибке декодирования
                if let decodingError = error as? DecodingError {
                    switch decodingError {
                    case .keyNotFound(let key, let context):
                        print("Ключ '\(key)' не найден:", context.debugDescription)
                    case .typeMismatch(let type, let context):
                        print("Неверный тип для \(type):", context.debugDescription)
                    case .valueNotFound(let type, let context):
                        print("Значение не найдено для типа \(type):", context.debugDescription)
                    case .dataCorrupted(let context):
                        print("Данные повреждены:", context.debugDescription)
                    default:
                        print("Ошибка декодирования:", error)
                    }
                } else {
                    print("Ошибка декодирования:", error)
                }
                
                completion(nil) // Возвращаем nil в случае ошибки декодирования
            }
        }
        
        task.resume() // Запускаем задачу
    }
}


