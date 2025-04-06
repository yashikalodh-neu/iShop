import SwiftUI

//struct ContentView: View {
//    @Environment(\.managedObjectContext) private var viewContext
//    
//    @FetchRequest(
//        sortDescriptors: [NSSortDescriptor(keyPath: \GroceryList.name, ascending: true)],
//        animation: .default)
//    private var groceryLists: FetchedResults<GroceryList>
//    
//    @State private var showingAddList = false
//    @State private var newListName = ""
//    
//    var body: some View {
//        NavigationView {
//            List {
//                ForEach(groceryLists) { list in
//                    NavigationLink(destination: ListDetailView(groceryList: list)) {
//                        VStack(alignment: .leading) {
//                            Text(list.wrappedName)
//                                .font(.headline)
//                            
//                            HStack {
//                                Text("\(list.itemsArray.count) items")
//                                    .font(.subheadline)
//                                    .foregroundColor(.secondary)
//                                
//                                Spacer()
//                                
//                                Text(list.formattedTotalSpending)
//                                    .font(.subheadline)
//                                    .foregroundColor(.secondary)
//                            }
//                        }
//                    }
//                }
//                .onDelete(perform: deleteLists)
//            }
//            .navigationTitle("iShop")
//            .toolbar {
//                ToolbarItem(placement: .navigationBarTrailing) {
//                    Button(action: { showingAddList = true }) {
//                        Label("Add List", systemImage: "plus")
//                    }
//                }
//            }
//            .sheet(isPresented: $showingAddList) {
//                AddListView { listName in
//                    addList(name: listName)
//                    showingAddList = false
//                }
//            }
//            
//            // Display this when no list is selected (on larger devices)
//            Text("Select a grocery list or create a new one.")
//                .font(.title2)
//                .foregroundColor(.secondary)
//        }
//    }
//    
//    private func addList(name: String) {
//        withAnimation {
//            let newList = GroceryList(context: viewContext)
//            newList.id = UUID()
//            newList.name = name
//            newList.dateCreated = Date()
//            
//            do {
//                try viewContext.save()
//            } catch {
//                // Handle the Core Data error
//                print("Error saving new list: \(error)")
//            }
//        }
//    }
//    
//    private func deleteLists(offsets: IndexSet) {
//        withAnimation {
//            offsets.map { groceryLists[$0] }.forEach(viewContext.delete)
//            
//            do {
//                try viewContext.save()
//            } catch {
//                // Handle the Core Data error
//                print("Error deleting list: \(error)")
//            }
//        }
//    }
//}


struct ContentView: View {
    @Environment(\.managedObjectContext) private var viewContext
    
    var body: some View {
        TabView {
            GroceryListsView()
                .tabItem {
                    Label("Lists", systemImage: "list.bullet")
                }
            
            BudgetTracker()
                .tabItem {
                    Label("Budget", systemImage: "chart.pie")
                }
        }
    }
}
