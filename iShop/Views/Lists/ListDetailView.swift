import SwiftUI

// MARK: - ListDetailView
struct ListDetailView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @ObservedObject var groceryList: GroceryList
    
    @State private var showingAddItem = false
    @State private var showingSortOptions = false
    @State private var showingBatchUpdate = false
    @State private var sortOption = SortOption.nameAscending
    
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
    
    var totalQuantity: Int {
        return sortedItems.reduce(0) { $0 + Int($1.quantity) }
    }
    
    var body: some View {
        List {
            Section {
                VStack(spacing: 16) {
                    // Total spending card
                    HStack(spacing: 0) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Total Spending")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                            
                            Text(groceryList.formattedTotalSpending)
                                .font(.title2)
                                .fontWeight(.bold)
                                .foregroundColor(.blue)
                        }
                        
                        Spacer()
                        
                    }
                    .padding(.vertical, 8)
                    
                    HStack(spacing: 16) {
                        // Available items
                        VStack(alignment: .leading, spacing: 4) {
                            HStack {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(.green)
                                Text("Available")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            
                            Text("\(groceryList.availableItemsCount) of \(groceryList.itemsArray.count)")
                                .font(.callout)
                                .fontWeight(.semibold)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(10)
                        .background(Color.green.opacity(0.1))
                        .cornerRadius(10)
                        
                        // Total quantity
                        VStack(alignment: .leading, spacing: 4) {
                            HStack {
                                Image(systemName: "number.circle.fill")
                                    .foregroundColor(.orange)
                                Text("Total Items")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            
                            Text("\(totalQuantity)")
                                .font(.callout)
                                .fontWeight(.semibold)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(10)
                        .background(Color.orange.opacity(0.1))
                        .cornerRadius(10)
                    }
                }
                .padding(.vertical, 4)
            } header: {
                Text("Summary")
                    .font(.headline)
            }
            
            Section {
                ForEach(sortedItems) { item in
                    RowWithNavigation(item: item, updateParent: updateView)
                        .environment(\.managedObjectContext, viewContext)
                }
                .onDelete(perform: deleteItems)
            } header: {
                HStack {
                    Text("Items")
                        .font(.headline)
                    Spacer()
                    
                    // Sort button
                    Button(action: { showingSortOptions = true }) {
                        HStack(spacing: 4) {
                            Text("Sort")
                                .font(.caption)
                            Image(systemName: "arrow.up.arrow.down")
                                .font(.caption)
                        }
                        .padding(.vertical, 4)
                        .padding(.horizontal, 8)
                        .background(Color.blue.opacity(0.1))
                        .cornerRadius(8)
                    }
                    
                    Button(action: { showingBatchUpdate = true }) {
                        HStack(spacing: 4) {
                            Text("Update")
                                .font(.caption)
                        }
                        .padding(.vertical, 4)
                        .padding(.horizontal, 8)
                        .background(Color.blue.opacity(0.1))
                        .cornerRadius(8)
                    }
                    
                }
            }
        }
        .id(refreshID)
        .listStyle(InsetGroupedListStyle())
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
        // Sheet for adding new items
        .sheet(isPresented: $showingAddItem) {
            AddItemViewWrapper(groceryList: groceryList, updateParent: updateView)
        }
        // Sheet for batch updating items
        .sheet(isPresented: $showingBatchUpdate) {
            BatchUpdateView(groceryList: groceryList, updateParent: updateView)
        }
        // Actions for sorting options
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
        .onReceive(NotificationCenter.default.publisher(for: .NSManagedObjectContextDidSave)) { _ in
            updateView()
        }
    }
    
    func updateView() {
        refreshID = UUID()
        
        viewContext.refresh(groceryList, mergeChanges: true)
    }
    
    // MARK: - Delete Items
    private func deleteItems(offsets: IndexSet) {
        withAnimation {
            let itemsToDelete = offsets.map { sortedItems[$0] }
            
            itemsToDelete.forEach { item in
                if let id = item.groceryItemId {
                    NotificationManager.shared.cancelAllNotifications(for: id)
                }
            }
            
            itemsToDelete.forEach(viewContext.delete)
            
            do {
                try viewContext.save()
                updateView()
            } catch {
                print("Error deleting items: \(error)")
            }
        }
    }
}
