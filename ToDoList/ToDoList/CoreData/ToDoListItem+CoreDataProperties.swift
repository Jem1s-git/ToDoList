//
//  ToDoListItem+CoreDataProperties.swift
//  ToDoList
//
//  Created by Jem1s on 22.09.2024.
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
