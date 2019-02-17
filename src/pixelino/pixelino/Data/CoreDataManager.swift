//
//  CoreDataManager.swift
//  pixelino
//
//  Created by Sandra Grujovic on 27.08.18.
//  Copyright © 2018 Sandra Grujovic. All rights reserved.
//

import Foundation
import CoreData
import UIKit

class CoreDataManager {

    // Fetches core data context needed for all loading/storing requests.
    public class func getCoreDataContext() -> NSManagedObjectContext? {
        guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else { return nil }
        return appDelegate.persistentContainer.viewContext
    }

    // MARK: Color History Save/Load functions.

    // (Potential) FIXME: Reduce max. amount of saved units in ColorHistory entity to 20.
    // Removes entire color history.
    public static func deleteColorHistory() {
        // Grab Core Data context.
        guard let managedContext = getCoreDataContext() else {
            return
        }

        // Perform actual deletion request.
        let deleteFetch = NSFetchRequest<NSFetchRequestResult>(entityName: "ColorHistory")
        let deleteRequest = NSBatchDeleteRequest(fetchRequest: deleteFetch)

        do {
            try managedContext.execute(deleteRequest)
            try managedContext.save()
        } catch let error as NSError {
            // FIXME: Implement proper error handling.
            print("Could not delete. \(error), \(error.userInfo)")
        }
    }

    // Removes one particular color from color history.
    public static func deleteColorInColorHistory(color: UIColor) {
        // Grab Core Data context.
        guard let managedContext = getCoreDataContext() else {
            return
        }

        // Perform actual deletion request.
        let deleteFetch = NSFetchRequest<NSFetchRequestResult>(entityName: "ColorHistory")
        deleteFetch.predicate = NSPredicate(format: "color == %@", color)
        let deleteRequest = NSBatchDeleteRequest(fetchRequest: deleteFetch)

        do {
            try managedContext.execute(deleteRequest)
            try managedContext.save()
        } catch let error as NSError {
            // FIXME: Implement proper error handling.
            print("Could not delete. \(error), \(error.userInfo)")
        }
    }

    // Saves current color history to CoreData.
    public static func saveColorInColorHistory(color: UIColor) {
        // Grab Core Data context.
        guard let managedContext = getCoreDataContext() else {
            return
        }

        let colorHistoryEntity = NSEntityDescription.entity(forEntityName: "ColorHistory", in: managedContext)!
        let colorHistoryObject = NSManagedObject(entity: colorHistoryEntity, insertInto: managedContext)

        // Perform actual saving request.
        colorHistoryObject.setValue(color, forKey: "color")

        do {
            try managedContext.save()
        } catch let error as NSError {
            // FIXME: Implement proper error handling.
            print("Could not save. \(error), \(error.userInfo)")
        }
    }

    // Loads the currently available color history.
    public static func loadColorHistory() -> [UIColor]? {
        // Grab Core Data context.
        guard let managedContext = getCoreDataContext() else {
            return nil
        }

        // Perform actual fetch request & save to local colorHistory array.
        // Note: The color history is sorted by most recently used color first.
        let request = NSFetchRequest<NSFetchRequestResult>(entityName: "ColorHistory")
        request.returnsObjectsAsFaults = false
        do {
            let result = try managedContext.fetch(request)
            var fetchedColorHistory = [UIColor]()
            //swiftlint:disable:next force_cast
            for data in result as! [NSManagedObject] {
                //swiftlint:disable:next force_cast
                fetchedColorHistory.insert(data.value(forKey: "color") as! UIColor, at: 0)
            }
            return fetchedColorHistory

        } catch let error as NSError {
            print("Could not load any color history. \(error), \(error.userInfo)")
            return nil
        }
    }

    // MARK: Drawing Load/Save - this is used when user saves image to app.

    // Save the current state of the canvas to Core Data, as well as its width and height (both in 'amount of pixels').
    public static func saveDrawing(drawing: Drawing) {
        // Grab Core Data context.
        guard let managedContext = drawing.managedObjectContext else {
            return
        }

        do {
            try managedContext.save()
        } catch let error as NSError {
            // FIXME: Implement proper error handling.
            print("Could not save. \(error), \(error.userInfo)")
        }
    }

    public static func loadAllDrawings() -> [Drawing]? {
        // Grab Core Data context.
        guard let managedContext = getCoreDataContext() else {
            return nil
        }

        let request = NSFetchRequest<NSFetchRequestResult>(entityName: "DrawingModel")
        request.returnsObjectsAsFaults = false
        do {
            let result = try managedContext.fetch(request)
            var drawings = [Drawing]()

            //swiftlint:disable:next force_cast
            for data in result as! [Drawing] {
                drawings.append(data)
            }
            return drawings

        } catch let error as NSError {
            print("Could not load any drawings. \(error), \(error.userInfo)")
            return nil
        }
    }

    public static func saveThumbnail(thumbnail: Thumbnail) {
        // Grab Core Data context.
        guard let managedContext = thumbnail.managedObjectContext else {
            return
        }
        do {
            try managedContext.save()
        } catch let error as NSError {
            // FIXME: Implement proper error handling.
            print("Could not save. \(error), \(error.userInfo)")
        }
    }

    public static func loadAllThumbnails() -> [Thumbnail]? {
        // Grab Core Data context.
        guard let managedContext = getCoreDataContext() else {
            return nil
        }

        let request = NSFetchRequest<NSFetchRequestResult>(entityName: "Thumbnail")
        request.returnsObjectsAsFaults = false

        do {
            let result = try managedContext.fetch(request)
            var thumbnails = [Thumbnail]()

            //swiftlint:disable:next force_cast
            for data in result as! [Thumbnail] {
                thumbnails.append(data)
            }
            return thumbnails

        } catch let error as NSError {
            print("Could not load any thumbnails. \(error), \(error.userInfo)")
            return nil
        }
    }

    /// Removes one particular drawing (based on the corresponding thumbnail).
    public static func deleteDrawing(correspondingThumbnail: Thumbnail) {
        // Grab Core Data context.
        guard let managedContext = getCoreDataContext() else {
            return
        }

        // Perform actual deletion request.
        let deleteFetch = NSFetchRequest<NSFetchRequestResult>(entityName: "Thumbnail")
        deleteFetch.predicate = NSPredicate(format: "id == %@", correspondingThumbnail.id as CVarArg)
        let deleteRequest = NSBatchDeleteRequest(fetchRequest: deleteFetch)

        do {
            try managedContext.execute(deleteRequest)
            try managedContext.save()
        } catch let error as NSError {
            // FIXME: Implement proper error handling.
            print("Could not delete. \(error), \(error.userInfo)")
        }
    }
}
