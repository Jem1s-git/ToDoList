//
//  ToDoListItem+CoreDataProperties.swift
//  ToDoList
//
//  Created by Кирилл Уваров on 02.10.2024.
//
//

import Foundation
import CoreData


extension ToDoListItem {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<ToDoListItem> {
        return NSFetchRequest<ToDoListItem>(entityName: "ToDoListItem")
    }

    @NSManaged public var createAt: Date?
    @NSManaged public var isCompleted: Bool
    @NSManaged public var name: String?

}

extension ToDoListItem : Identifiable {

}
