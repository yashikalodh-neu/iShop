import SwiftUI

//MARK: - Grocery List Extension
extension GroceryList: Identifiable {
    public var id: UUID {
        groceryListId ?? UUID()
    }
}

//MARK: - Grocery List View
struct GroceryListsView: View {
    @Environment(\.managedObjectContext) private var viewContext
    
    @State private var searchText = ""
    
    // Pre-computed predicate property
    private var groceryListsPredicate: NSPredicate? {
        searchText.isEmpty ? nil : NSPredicate(format: "name CONTAINS[cd] %@", searchText)
    }
    
    // Fetch request as a property with initial predicate
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \GroceryList.dateCreated, ascending: false)],
        animation: .default)
    private var groceryLists: FetchedResults<GroceryList>
    
    @State private var showingAddList = false
    
    // Sections for date grouping
    enum DateSection: String, CaseIterable {
        case today = "Today"
        case week = "Previous 7 Days"
        case month = "Previous 30 Days"
        case older = "Older"
    }
    
    // Simplified method to check if we should show the "not found" message
    private var shouldShowNotFoundMessage: Bool {
        !searchText.isEmpty && groceryLists.isEmpty
    }
    
    private var groupedLists: [DateSection: [GroceryList]] {
        groupListsByDateSection()
    }
    
    var body: some View {
        NavigationView {
            VStack {
                // Search bar
                SearchBar(text: $searchText)
                    .padding(.horizontal)
                
                GroceryListContentView(
                    shouldShowNotFoundMessage: shouldShowNotFoundMessage,
                    groupedLists: groupedLists,
                    onDelete: deleteLists
                )
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
            
            Text("Select a grocery list or create a new one.")
                .font(.title2)
                .foregroundColor(.secondary)
        }
        .onChange(of: searchText) { _, _ in
            updateFetchRequest()
        }
    }
    
    // MARK: - Update Fetch Request
    private func updateFetchRequest() {
        groceryLists.nsPredicate = groceryListsPredicate
    }
    
    // Group lists by date sections
    private func groupListsByDateSection() -> [DateSection: [GroceryList]] {
        let calendar = Calendar.current
        let now = Date()
        let today = calendar.startOfDay(for: now)
        let oneWeekAgo = calendar.date(byAdding: .day, value: -7, to: today)!
        let oneMonthAgo = calendar.date(byAdding: .day, value: -30, to: today)!
        
        var sectionsDict: [DateSection: [GroceryList]] = [:]
        
        for section in DateSection.allCases {
            sectionsDict[section] = []
        }
        
        // Categorize each list
        for list in groceryLists {
            guard let creationDate = list.dateCreated else { continue }
            let startOfCreationDate = calendar.startOfDay(for: creationDate)
            
            if calendar.isDate(startOfCreationDate, inSameDayAs: today) {
                sectionsDict[.today]?.append(list)
            } else if startOfCreationDate >= oneWeekAgo {
                sectionsDict[.week]?.append(list)
            } else if startOfCreationDate >= oneMonthAgo {
                sectionsDict[.month]?.append(list)
            } else {
                sectionsDict[.older]?.append(list)
            }
        }
        
        return sectionsDict
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
                print("Error saving new list: \(error)")
            }
        }
    }
    
    private func deleteLists(lists: [GroceryList], at offsets: IndexSet) {
        withAnimation {
            offsets.map { lists[$0] }.forEach(viewContext.delete)
            
            do {
                try viewContext.save()
            } catch {
                print("Error deleting list: \(error)")
            }
        }
    }
}

// MARK: - Grocery List Content View
struct GroceryListContentView: View {
    let shouldShowNotFoundMessage: Bool
    let groupedLists: [GroceryListsView.DateSection: [GroceryList]]
    let onDelete: ([GroceryList], IndexSet) -> Void
    
    var body: some View {
        if shouldShowNotFoundMessage {
            NotFoundView()
        } else {
            GroceryListSectionsView(groupedLists: groupedLists, onDelete: onDelete)
                .listStyle(InsetGroupedListStyle())
        }
    }
}

// View for when no lists are found
struct NotFoundView: View {
    var body: some View {
        VStack(spacing: 20) {
            Spacer()
            
            Image(systemName: "magnifyingglass")
                .font(.system(size: 50))
                .foregroundColor(.gray)
            
            Text("No matching lists found")
                .font(.headline)
                .foregroundColor(.secondary)
            
            Spacer()
        }
        .frame(maxWidth: .infinity)
        .padding()
    }
}

// MARK: - Views for list section
struct GroceryListSectionsView: View {
    let groupedLists: [GroceryListsView.DateSection: [GroceryList]]
    let onDelete: ([GroceryList], IndexSet) -> Void
    
    var body: some View {
        List {
            ForEach(GroceryListsView.DateSection.allCases, id: \.self) { section in
                if let lists = groupedLists[section], !lists.isEmpty {
                    Section(header: Text(section.rawValue)) {
                        ForEach(lists) { list in
                            GroceryListRow(list: list)
                        }
                        .onDelete { indexSet in
                            onDelete(lists, indexSet)
                        }
                    }
                }
            }
        }
    }
}

// MARK: - Individual Row
struct GroceryListRow: View {
    // Change from let to @ObservedObject to make it reactive to changes
    @ObservedObject var list: GroceryList
    
    // Computed properties to force view updates
    private var itemCount: Int {
        list.itemsArray.count
    }
    
    private var totalSpending: String {
        list.formattedTotalSpending
    }
    
    var body: some View {
        NavigationLink(destination: ListDetailView(groceryList: list)) {
            VStack(alignment: .leading) {
                Text(list.wrappedName)
                    .font(.headline)
                
                HStack {
                    // Use the computed property instead of direct access
                    Text("\(itemCount) items")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    Text(totalSpending)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                Text(formatDate(list.dateCreated))
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .id("list-\(list.id)-items-\(itemCount)-total-\(totalSpending)")
        }
    }
    
    private func formatDate(_ date: Date?) -> String {
        guard let date = date else { return "No date" }
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter.string(from: date)
    }
}

// MARK: - Search Bar
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
