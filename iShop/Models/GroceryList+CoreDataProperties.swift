import Foundation
import CoreData

extension GroceryList {
    @nonobjc public class func fetchRequest() -> NSFetchRequest<GroceryList> {
        return NSFetchRequest<GroceryList>(entityName: "GroceryList")
    }

    @NSManaged public var groceryListId: UUID?
    @NSManaged public var name: String?
    @NSManaged public var dateCreated: Date?
    @NSManaged public var items: NSSet?

    // Convenience calculated properties
    public var wrappedId: UUID {
        groceryListId ?? UUID()
    }

    public var wrappedName: String {
        name ?? "Untitled List"
    }

    public var itemsArray: [GroceryItem] {
        let set = items as? Set<GroceryItem> ?? []
        return set.sorted {
            $0.wrappedName < $1.wrappedName
        }
    }

    public var totalSpending: Double {
        let set = items as? Set<GroceryItem> ?? []
        return set.reduce(0) { $0 + $1.price }
    }

    public var formattedTotalSpending: String {
        return String(format: "$%.2f", totalSpending)
    }

    public var availableItemsCount: Int {
        let set = items as? Set<GroceryItem> ?? []
        return set.filter { $0.isAvailable }.count
    }
}

// MARK: Generated accessors for items
extension GroceryList {
    @objc(addItemsObject:)
    @NSManaged public func addToItems(_ value: GroceryItem)

    @objc(removeItemsObject:)
    @NSManaged public func removeFromItems(_ value: GroceryItem)

    @objc(addItems:)
    @NSManaged public func addToItems(_ values: NSSet)

    @objc(removeItems:)
    @NSManaged public func removeFromItems(_ values: NSSet)
}
