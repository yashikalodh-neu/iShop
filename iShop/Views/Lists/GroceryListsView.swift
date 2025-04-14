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
        
        var title: String {
            return self.rawValue
        }
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
        
        for list in groceryLists {
            guard let creationDate = list.dateCreated else {
                continue
            }
            
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
    
    // Check if we should show the "not found" message
    private var shouldShowNotFoundMessage: Bool {
        !searchText.isEmpty && groceryLists.isEmpty
    }
    
    var body: some View {
        NavigationView {
            VStack {
                SearchBar(text: $searchText)
                    .padding(.horizontal)
                
                if shouldShowNotFoundMessage {
                    // Not found message view
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
                } else {
                    let groupedLists = groupListsByDateSection()
                    
                    List {
                        ForEach(DateSection.allCases, id: \.self) { section in
                            if let lists = groupedLists[section], !lists.isEmpty {
                                Section(header: Text(section.title)) {
                                    ForEach(lists) { list in
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
                                                
                                                Text(formatDate(list.dateCreated))
                                                    .font(.caption)
                                                    .foregroundColor(.secondary)
                                            }
                                        }
                                    }
                                    .onDelete { indexSet in
                                        deleteLists(lists: lists, at: indexSet)
                                    }
                                }
                            }
                        }
                    }
                    .listStyle(InsetGroupedListStyle())
                }
                
                Spacer()
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
    
    private func formatDate(_ date: Date?) -> String {
        guard let date = date else { return "No date" }
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter.string(from: date)
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
    
    private func deleteLists(lists: [GroceryList], at offsets: IndexSet) {
        withAnimation {
            offsets.map { lists[$0] }.forEach(viewContext.delete)
            
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
