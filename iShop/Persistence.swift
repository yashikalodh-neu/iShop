// Persistence.swift
import CoreData

struct PersistenceController {
    // Singleton for the whole app to use
    static let shared = PersistenceController()

    // Testing configurations
    static var preview: PersistenceController = {
        let controller = PersistenceController(inMemory: true)
        
        // Create sample data for previews
        let viewContext = controller.container.viewContext
        
        let sampleList = GroceryList(context: viewContext)
        sampleList.groceryListId = UUID()
        sampleList.name = "Weekly Groceries"
        sampleList.dateCreated = Date()
        
        let milk = GroceryItem(context: viewContext)
        milk.groceryItemId = UUID()
        milk.name = "Milk"
        milk.quantity = 2
        milk.quantityThreshold = 1
        milk.price = 3.99
        milk.isAvailable = true
        milk.expirationDate = Calendar.current.date(byAdding: .day, value: 5, to: Date())
        milk.dateAdded = Date()
        milk.parentList = sampleList
        
        let eggs = GroceryItem(context: viewContext)
        eggs.groceryItemId = UUID()
        eggs.name = "Eggs"
        eggs.quantity = 6
        eggs.quantityThreshold = 2
        eggs.price = 4.50
        eggs.isAvailable = true
        eggs.expirationDate = Calendar.current.date(byAdding: .day, value: 10, to: Date())
        eggs.dateAdded = Date()
        eggs.parentList = sampleList
        
        try? viewContext.save()
        return controller
    }()

    // Storage for Core Data
    let container: NSPersistentContainer

    // Initialize with option for memory-only storage
    init(inMemory: Bool = false) {
        container = NSPersistentContainer(name: "iShop")
        
        if inMemory {
            container.persistentStoreDescriptions.first?.url = URL(fileURLWithPath: "/dev/null")
        }
        
        container.loadPersistentStores { description, error in
            if let error = error as NSError? {
                // Replace this implementation with code to handle the error appropriately.
                // fatalError() causes the application to generate a crash log and terminate.
                fatalError("Unresolved error \(error), \(error.userInfo)")
            }
        }
        
        container.viewContext.automaticallyMergesChangesFromParent = true
        container.viewContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
    }
    
    // Save context if there are changes
    func save() {
        let context = container.viewContext
        if context.hasChanges {
            do {
                try context.save()
            } catch {
                // Handle save error
                let nsError = error as NSError
                print("Error saving context: \(nsError), \(nsError.userInfo)")
            }
        }
    }
}
