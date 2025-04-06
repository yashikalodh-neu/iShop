import SwiftUI
import CoreData

struct BudgetTracker: View {
    @Environment(\.managedObjectContext) private var viewContext
    
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \GroceryList.name, ascending: true)],
        animation: .default)
    private var groceryLists: FetchedResults<GroceryList>
    
    @State private var showingDatePicker = false
    @State private var startDate = Calendar.current.date(byAdding: .day, value: -30, to: Date()) ?? Date()
    @State private var endDate = Date()
    
    var totalSpending: Double {
        groceryLists.reduce(0) { $0 + $1.totalSpending }
    }
    
    var dateFilteredLists: [GroceryList] {
        return groceryLists.filter { list in
            guard let dateCreated = list.dateCreated else { return false }
            return dateCreated >= startDate && dateCreated <= endDate
        }
    }
    
    var dateFilteredSpending: Double {
        return dateFilteredLists.reduce(0) { $0 + $1.totalSpending }
    }
    
    // Group spending by category (in this case, by list)
    var spendingByList: [(name: String, amount: Double)] {
        return dateFilteredLists.map { list in
            (name: list.wrappedName, amount: list.totalSpending)
        }.sorted { $0.amount > $1.amount }
    }
    
    var body: some View {
        NavigationView {
            List {
                Section(header: Text("Date Range")) {
                    HStack {
                        Text("From: \(startDate, formatter: dateFormatter)")
                        Spacer()
                        Button("Change") {
                            showingDatePicker = true
                        }
                    }
                    
                    Text("To: \(endDate, formatter: dateFormatter)")
                }
                
                Section(header: Text("Summary")) {
                    HStack {
                        Text("Total Spending")
                        Spacer()
                        Text(String(format: "$%.2f", dateFilteredSpending))
                            .fontWeight(.bold)
                    }
                    
                    HStack {
                        Text("Number of Lists")
                        Spacer()
                        Text("\(dateFilteredLists.count)")
                    }
                    
                    HStack {
                        Text("Average per List")
                        Spacer()
                        Text(dateFilteredLists.isEmpty ? "$0.00" : String(format: "$%.2f", dateFilteredSpending / Double(dateFilteredLists.count)))
                    }
                }
                
                Section(header: Text("Spending by List")) {
                    if spendingByList.isEmpty {
                        Text("No data available for selected date range")
                            .foregroundColor(.secondary)
                    } else {
                        ForEach(spendingByList, id: \.name) { list in
                            HStack {
                                Text(list.name)
                                Spacer()
                                Text(String(format: "$%.2f", list.amount))
                            }
                        }
                    }
                }
            }
            .navigationTitle("Budget Tracker")
            .sheet(isPresented: $showingDatePicker) {
                DateRangePickerView(startDate: $startDate, endDate: $endDate, isPresented: $showingDatePicker)
            }
        }
    }
    
    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter
    }()
}
