import SwiftUI

struct ListDetailView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @ObservedObject var groceryList: GroceryList
    
    @State private var showingAddItem = false
    @State private var showingSortOptions = false
    @State private var sortOption = SortOption.nameAscending
    
    // Add a refreshID to force UI updates
    @State private var refreshID = UUID()
    
    enum SortOption {
        case nameAscending, nameDescending, priceAscending, priceDescending, expirationDate
    }
    
    var sortedItems: [GroceryItem] {
        let items = groceryList.itemsArray
        
        switch sortOption {
        case .nameAscending:
            return items.sorted { $0.wrappedName < $1.wrappedName }
        case .nameDescending:
            return items.sorted { $0.wrappedName > $1.wrappedName }
        case .priceAscending:
            return items.sorted { $0.price < $1.price }
        case .priceDescending:
            return items.sorted { $0.price > $1.price }
        case .expirationDate:
            return items.sorted {
                guard let date1 = $0.expirationDate else { return false }
                guard let date2 = $1.expirationDate else { return true }
                return date1 < date2
            }
        }
    }
    
    var body: some View {
        List {
            Section(header: Text("Summary")) {
                HStack {
                    Text("Total Spending")
                    Spacer()
                    Text(groceryList.formattedTotalSpending)
                        .fontWeight(.bold)
                }
                
                HStack {
                    Text("Available Items")
                    Spacer()
                    Text("\(groceryList.availableItemsCount) of \(groceryList.itemsArray.count)")
                }
            }
            
            Section(header:
                        HStack {
                            Text("Items")
                            Spacer()
                            Button(action: { showingSortOptions = true }) {
                                Label("Sort", systemImage: "arrow.up.arrow.down")
                                    .font(.caption)
                            }
                        }
            ) {
                ForEach(sortedItems) { item in
                    NavigationLink(destination: ItemDetailViewWrapper(item: item, updateParent: updateView)) {
                        ItemRowView(item: item)
                    }
                }
                .onDelete(perform: deleteItems)
            }
        }
        .id(refreshID) // Force view to refresh when refreshID changes
        .navigationTitle(groceryList.wrappedName)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: { showingAddItem = true }) {
                    Label("Add Item", systemImage: "plus")
                }
            }
            
            // Add a refresh button
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: updateView) {
                    Label("Refresh", systemImage: "arrow.clockwise")
                }
            }
        }
        .sheet(isPresented: $showingAddItem) {
            AddItemViewWrapper(groceryList: groceryList, updateParent: updateView)
        }
        .actionSheet(isPresented: $showingSortOptions) {
            ActionSheet(title: Text("Sort Items"), buttons: [
                .default(Text("Name (A-Z)")) { sortOption = .nameAscending },
                .default(Text("Name (Z-A)")) { sortOption = .nameDescending },
                .default(Text("Price (Low to High)")) { sortOption = .priceAscending },
                .default(Text("Price (High to Low)")) { sortOption = .priceDescending },
                .default(Text("Expiration Date")) { sortOption = .expirationDate },
                .cancel()
            ])
        }
        // Add a notification observer to refresh when context changes
        .onReceive(NotificationCenter.default.publisher(for: .NSManagedObjectContextDidSave)) { _ in
            updateView()
        }
    }
    
    // Function to update the view when items change
    func updateView() {
        // Generate a new UUID to force view refresh
        refreshID = UUID()
        
        // Also reload the grocery list object from the context if needed
        // This ensures we have the latest data from Core Data
        viewContext.refresh(groceryList, mergeChanges: true)
    }
    
    private func deleteItems(offsets: IndexSet) {
        withAnimation {
            let itemsToDelete = offsets.map { sortedItems[$0] }
            
            // Cancel notifications for deleted items
            itemsToDelete.forEach { item in
                if let id = item.groceryItemId {
                    NotificationManager.shared.cancelAllNotifications(for: id)
                }
            }
            
            // Delete the items
            itemsToDelete.forEach(viewContext.delete)
            
            do {
                try viewContext.save()
                // Update the view after deleting items
                updateView()
            } catch {
                // Handle the Core Data error
                print("Error deleting items: \(error)")
            }
        }
    }
}

// Wrapper view for ItemDetailView that handles the update callback
struct ItemDetailViewWrapper: View {
    @ObservedObject var item: GroceryItem
    var updateParent: () -> Void
    
    var body: some View {
        ItemDetailView(item: item)
            .onDisappear {
                // When the detail view is dismissed, update the parent
                updateParent()
            }
    }
}

// Wrapper view for AddItemView that handles the update callback
struct AddItemViewWrapper: View {
    @Environment(\.presentationMode) private var presentationMode
    var groceryList: GroceryList
    var updateParent: () -> Void
    
    var body: some View {
        AddItemView(groceryList: groceryList)
            .onDisappear {
                // When the add item view is dismissed, update the parent
                updateParent()
            }
    }
}
