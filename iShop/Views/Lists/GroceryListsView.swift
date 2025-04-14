import SwiftUI

struct GroceryListsView: View {
    @Environment(\.managedObjectContext) private var viewContext
    
    @State private var searchText = ""
    
    private var groceryListsPredicate: NSPredicate? {
        if searchText.isEmpty {
            return nil
        } else {
            return NSPredicate(format: "name CONTAINS[cd] %@", searchText)
        }
    }
    
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \GroceryList.name, ascending: true)],
        animation: .default)
    private var groceryLists: FetchedResults<GroceryList>
    
    @State private var showingAddList = false
    
    var body: some View {
        NavigationView {
            VStack {
                SearchBar(text: $searchText)
                    .padding(.horizontal)
                
                List {
                    ForEach(groceryLists) { list in
                        NavigationLink(destination: ListDetailView(groceryList: list)) {
                            VStack(alignment: .leading) {
                                Text(list.wrappedName)
                                    .font(.headline)
                                
                                HStack {
                                    Text("\(list.itemsArray.count) items")
                                        .font(.subheadline)
                                        .foregroundColor(.secondary)
                                    
                                    Spacer()
                                    
                                    Text(list.formattedTotalSpending)
                                        .font(.subheadline)
                                        .foregroundColor(.secondary)
                                }
                            }
                        }
                    }
                    .onDelete(perform: deleteLists)
                }
                .navigationTitle("iShop")
                .toolbar {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button(action: { showingAddList = true }) {
                            Label("Add List", systemImage: "plus")
                        }
                    }
                }
                .sheet(isPresented: $showingAddList) {
                    AddListView { listName in
                        addList(name: listName)
                        showingAddList = false
                    }
                }
            }
            
            // Display this when no list is selected (on larger devices)
            Text("Select a grocery list or create a new one.")
                .font(.title2)
                .foregroundColor(.secondary)
        }
        .onChange(of: searchText) { oldValue, newValue in
            updateFetchRequest()
        }
    }
    
    private func updateFetchRequest() {
        groceryLists.nsPredicate = groceryListsPredicate
    }
    
    private func addList(name: String) {
        withAnimation {
            let newList = GroceryList(context: viewContext)
            newList.groceryListId = UUID()
            newList.name = name
            newList.dateCreated = Date()
            
            do {
                try viewContext.save()
            } catch {
                // Handle the Core Data error
                print("Error saving new list: \(error)")
            }
        }
    }
    
    private func deleteLists(offsets: IndexSet) {
        withAnimation {
            offsets.map { groceryLists[$0] }.forEach(viewContext.delete)
            
            do {
                try viewContext.save()
            } catch {
                // Handle the Core Data error
                print("Error deleting list: \(error)")
            }
        }
    }
}

// Custom SearchBar view
struct SearchBar: View {
    @Binding var text: String
    
    var body: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.gray)
            
            TextField("Search Lists", text: $text)
                .foregroundColor(.primary)
            
            if !text.isEmpty {
                Button(action: {
                    text = ""
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.gray)
                        .padding(4)
                }
            }
        }
        .padding(8)
        .background(Color(.systemGray6))
        .cornerRadius(10)
    }
}
