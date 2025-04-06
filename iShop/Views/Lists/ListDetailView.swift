import SwiftUI

struct ListDetailView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @ObservedObject var groceryList: GroceryList
    
    @State private var showingAddItem = false
    @State private var showingSortOptions = false
    @State private var sortOption = SortOption.nameAscending
    
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
                    NavigationLink(destination: ItemDetailView(item: item)) {
                        ItemRowView(item: item)
                    }
                }
                .onDelete(perform: deleteItems)
            }
        }
        .navigationTitle(groceryList.wrappedName)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: { showingAddItem = true }) {
                    Label("Add Item", systemImage: "plus")
                }
            }
        }
        .sheet(isPresented: $showingAddItem) {
            AddItemView(groceryList: groceryList)
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
    }
    
    private func deleteItems(offsets: IndexSet) {
        withAnimation {
            let itemsToDelete = offsets.map { sortedItems[$0] }
            
            // Cancel notifications for deleted items
//            itemsToDelete.forEach { item in
//                if let groceryItemId = item.groceryItemId { // If the id is UUID, proceed
//                    NotificationManager.shared.cancelAllNotifications(for: groceryItemId)
//                }
//            }
            
            itemsToDelete.forEach { item in
                if let id = item.groceryItemId {
                    NotificationManager.shared.cancelAllNotifications(for: id)
                }
            }
            
            // Delete the items
            itemsToDelete.forEach(viewContext.delete)
            
            do {
                try viewContext.save()
            } catch {
                // Handle the Core Data error
                print("Error deleting items: \(error)")
            }
        }
    }
}
