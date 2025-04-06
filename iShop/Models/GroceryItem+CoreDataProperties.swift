//
//  GroceryItem+CoreDataProperties.swift
//  iShop
//
//  Created by Yashika Lodh on 4/5/25.
//
//

import Foundation
import CoreData


extension GroceryItem {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<GroceryItem> {
        return NSFetchRequest<GroceryItem>(entityName: "GroceryItem")
    }

    @NSManaged public var groceryItemIdString: String?
    @NSManaged public var name: String?
    @NSManaged public var quantity: Int16
    @NSManaged public var quantityThreshold: Int16
    @NSManaged public var price: Double
    @NSManaged public var isAvailable: Bool
    @NSManaged public var expirationDate: Date?
    @NSManaged public var dateAdded: Date?
    @NSManaged public var parentList: GroceryList?
    
    public var groceryItemId: UUID? {
        get {
            if let idString = groceryItemIdString {
                return UUID(uuidString: idString)
            }
            return nil
        }
        set {
            groceryItemIdString = newValue?.uuidString
        }
    }

    public var wrappedId: UUID {
        groceryItemId ?? UUID()
        }

        public var wrappedName: String {
            name ?? "Unknown Item"
        }

        public var formattedPrice: String {
            return String(format: "$%.2f", price)
        }

        public var isLowStock: Bool {
            return quantity <= quantityThreshold
        }

        public var isExpiringSoon: Bool {
            guard let expDate = expirationDate else { return false }
            let twoDaysFromNow = Calendar.current.date(byAdding: .day, value: 2, to: Date()) ?? Date()
            return expDate <= twoDaysFromNow && expDate > Date()
        }

}

extension GroceryItem : Identifiable {
    public var id: UUID {
            return groceryItemId ?? UUID()
        }
}
