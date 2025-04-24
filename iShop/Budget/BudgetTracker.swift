import SwiftUI
import CoreData
import Combine

struct PieSlice: Shape {
    let startAngle: Double
    let endAngle: Double
    
    func path(in rect: CGRect) -> Path {
        let center = CGPoint(x: rect.midX, y: rect.midY)
        let radius = min(rect.width, rect.height) / 2
        var path = Path()
        
        path.move(to: center)
        path.addArc(center: center,
                    radius: radius,
                    startAngle: Angle(degrees: startAngle - 90),
                    endAngle: Angle(degrees: endAngle - 90),
                    clockwise: false)
        path.closeSubpath()
        
        return path
    }
}

struct PieChartView: View {
    var slices: [(name: String, amount: Double, color: Color)]
    var total: Double
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                ForEach(0..<slices.count, id: \.self) { i in
                    if slices[i].amount > 0 {
                        PieSlice(
                            startAngle: self.startAngle(for: i),
                            endAngle: self.endAngle(for: i)
                        )
                        .fill(slices[i].color)
                        .shadow(color: slices[i].color.opacity(0.3), radius: 4, x: 0, y: 2)
                    }
                }
                
                // Center hole for donut chart
                Circle()
                    .fill(Color(.systemBackground))
                    .shadow(color: Color.black.opacity(0.1), radius: 2, x: 0, y: 1)
                    .frame(width: min(geometry.size.width, geometry.size.height) * 0.5)
            }
        }
        .frame(height: 220)
        .aspectRatio(1, contentMode: .fit)
    }
    
    private func startAngle(for index: Int) -> Double {
        let prior = slices.prefix(index).reduce(0) { $0 + $1.amount }
        return (prior / total) * 360
    }
    
    private func endAngle(for index: Int) -> Double {
        let including = slices.prefix(index + 1).reduce(0) { $0 + $1.amount }
        return (including / total) * 360
    }
}

struct CategoryRow: View {
    var name: String
    var amount: Double
    var color: Color
    var transactions: Int
    
    var body: some View {
        HStack(spacing: 12) {
            Circle()
                .fill(color)
                .frame(width: 12, height: 12)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(name)
                    .font(.system(size: 16, weight: .medium))
                
                Text("\(transactions) transaction\(transactions == 1 ? "" : "s")")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Text(String(format: "$%.2f", amount))
                .font(.system(size: 16, weight: .semibold))
        }
        .padding(.vertical, 8)
    }
}

class BudgetTrackerViewModel: ObservableObject {
    @Published var startDate = Calendar.current.date(byAdding: .day, value: -30, to: Date()) ?? Date()
    @Published var endDate = Date()
    @Published var refreshID = UUID()
    @Published var groceryLists: [GroceryList] = []
    
    private var viewContext: NSManagedObjectContext
    private var cancellables = Set<AnyCancellable>()
    
    init(viewContext: NSManagedObjectContext) {
        self.viewContext = viewContext
        
        // Listen for Core Data changes, but don't refresh automatically
        NotificationCenter.default.publisher(for: .NSManagedObjectContextDidSave)
            .sink { [weak self] _ in
                print("Core Data change detected in BudgetTracker")
                // We don't auto-refresh here, we'll do it when the tab becomes active
            }
            .store(in: &cancellables)
    }
    
    // Explicitly fetch data from Core Data
    func loadData() {
        print("BudgetTrackerViewModel: Loading data...")
        let fetchRequest: NSFetchRequest<GroceryList> = GroceryList.fetchRequest()
        fetchRequest.sortDescriptors = [NSSortDescriptor(keyPath: \GroceryList.name, ascending: true)]
        
        do {
            let fetchedLists = try viewContext.fetch(fetchRequest)
            DispatchQueue.main.async {
                self.groceryLists = fetchedLists
                print("BudgetTrackerViewModel: Loaded \(fetchedLists.count) lists")
                self.refreshID = UUID() // Force UI update
            }
        } catch {
            print("Error fetching grocery lists: \(error)")
        }
    }
    
    func manualRefresh() {
        print("BudgetTrackerViewModel: Manual refresh triggered")
        loadData()
    }
}


struct BudgetTracker: View {
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.managedObjectContext) private var viewContext
    @EnvironmentObject private var appState: AppState
    
    // State variables
    @State private var showingDatePicker = false
    @State private var startDate = Calendar.current.date(byAdding: .day, value: -30, to: Date()) ?? Date()
    @State private var endDate = Date()
    @State private var refreshID = UUID()
    @State private var allLists: [GroceryList] = []
    
    // Color theme
    private var accentColor: Color {
        Color.blue
    }
    
    private var cardBackgroundColor: Color {
        colorScheme == .dark ? Color(UIColor.systemGray6) : Color.white
    }
    
    private var shadowColor: Color {
        colorScheme == .dark ? Color.black.opacity(0.3) : Color.black.opacity(0.1)
    }
    
    // Computed properties
    var dateFilteredLists: [GroceryList] {
        // Use calendar for more reliable date comparison
        let calendar = Calendar.current
        let startOfStartDate = calendar.startOfDay(for: startDate)
        let endOfEndDate = calendar.date(bySettingHour: 23, minute: 59, second: 59, of: endDate) ?? endDate
        
        return allLists.filter { list in
            guard let dateCreated = list.dateCreated else { return false }
            return dateCreated >= startOfStartDate && dateCreated <= endOfEndDate
        }
    }
    
    var dateFilteredSpending: Double {
        return dateFilteredLists.reduce(0) { $0 + $1.totalSpending }
    }
    
    // Group spending by category (in this case, by list)
    // FIXED: Now properly combines lists with identical names using a Dictionary
    var spendingByList: [(name: String, amount: Double, transactions: Int)] {
        // First, extract all the lists in the filtered date range
        let filteredLists = dateFilteredLists
        
        // Create a dictionary to combine data for lists with the same name
        var combinedData: [String: (amount: Double, transactions: Int)] = [:]
        
        // Iterate through each list and aggregate data by name
        for list in filteredLists {
            let name = list.wrappedName
            let amount = list.totalSpending
            let transactions = list.itemsArray.count
            
            // If we already have an entry for this name, add to it
            if var existing = combinedData[name] {
                existing.amount += amount
                existing.transactions += transactions
                combinedData[name] = existing
            } else {
                // Otherwise create a new entry
                combinedData[name] = (amount: amount, transactions: transactions)
            }
        }
        
        // Convert the dictionary to an array of tuples
        let result = combinedData.map { (name, data) in
            return (name: name, amount: data.amount, transactions: data.transactions)
        }
        
        // Sort by amount (highest first)
        return result.sorted { $0.amount > $1.amount }
    }
    
    // Pie chart data with colors
    var pieChartData: [(name: String, amount: Double, color: Color)] {
        let colors: [Color] = [
            .blue, .purple, .orange, .green, .pink, .red, .yellow, .teal
        ]
        
        return spendingByList.enumerated().map { index, item in
            let colorIndex = index % colors.count
            return (name: item.name, amount: item.amount, color: colors[colorIndex])
        }
    }
    
    // Fresh fetch from Core Data
    private func loadData() {
        let fetchRequest: NSFetchRequest<GroceryList> = GroceryList.fetchRequest()
        fetchRequest.sortDescriptors = [NSSortDescriptor(keyPath: \GroceryList.name, ascending: true)]
        
        do {
            // Force the context to refresh from the persistent store
            viewContext.refreshAllObjects()
            
            let fetchedLists = try viewContext.fetch(fetchRequest)
            
            allLists = fetchedLists
            refreshID = UUID() // Force view refresh
        } catch {
            print("Error fetching grocery lists: \(error)")
        }
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 16) {
                    // Date selector card
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Label("Date Range", systemImage: "calendar")
                                .font(.headline)
                            Spacer()
                            Button(action: {
                                showingDatePicker = true
                            }) {
                                Image(systemName: "chevron.right")
                                    .foregroundColor(.secondary)
                            }
                        }
                        
                        Divider()
                        
                        HStack {
                            VStack(alignment: .leading) {
                                Text("From")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                Text(startDate, formatter: dateFormatter)
                                    .font(.subheadline)
                            }
                            
                            Spacer()
                            
                            VStack(alignment: .trailing) {
                                Text("To")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                Text(endDate, formatter: dateFormatter)
                                    .font(.subheadline)
                            }
                        }
                        .padding(.top, 4)
                    }
                    .padding()
                    .background(cardBackgroundColor)
                    .cornerRadius(16)
                    .shadow(color: shadowColor, radius: 4, x: 0, y: 2)
                    .padding(.horizontal)
                    
                    // Summary card with pie chart
                    VStack(alignment: .leading, spacing: 16) {
                        HStack {
                            Label("Spending Summary", systemImage: "chart.pie.fill")
                                .font(.headline)
                                
                            Spacer()
                                
                            // Add refresh button
//                            Button(action: loadData) {
//                                Image(systemName: "arrow.clockwise")
//                                    .foregroundColor(.blue)
//                            }
                        }
                        
                        if !spendingByList.isEmpty {
                            PieChartView(
                                slices: pieChartData,
                                total: dateFilteredSpending
                            )
                            .padding(.vertical, 8)
                            
                            // Stats grid
                            HStack(spacing: 20) {
                                VStack {
                                    Text("Total")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                    Text(String(format: "$%.2f", dateFilteredSpending))
                                        .font(.headline)
                                }
                                .frame(maxWidth: .infinity)
                                
                                Divider()
                                    .frame(height: 30)
                                
                                VStack {
                                    Text("Lists")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                    Text("\(dateFilteredLists.count)")
                                        .font(.headline)
                                }
                                .frame(maxWidth: .infinity)
                                
                                Divider()
                                    .frame(height: 30)
                                
                                VStack {
                                    Text("Average")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                    let avgAmount = dateFilteredLists.isEmpty
                                        ? 0.0
                                        : dateFilteredSpending / Double(dateFilteredLists.count)
                                    Text(String(format: "$%.2f", avgAmount))
                                        .font(.headline)
                                }
                                .frame(maxWidth: .infinity)
                            }
                            .padding(.vertical, 8)
                        } else {
                            Text("No data available for selected date range")
                                .foregroundColor(.secondary)
                                .frame(maxWidth: .infinity, minHeight: 200)
                                .multilineTextAlignment(.center)
                        }
                    }
                    .padding()
                    .background(cardBackgroundColor)
                    .cornerRadius(16)
                    .shadow(color: shadowColor, radius: 4, x: 0, y: 2)
                    .padding(.horizontal)
                    
                    // Categories breakdown
                    VStack(alignment: .leading, spacing: 16) {
                        Label("Spending by Category", systemImage: "list.bullet")
                            .font(.headline)
                        
                        if spendingByList.isEmpty {
                            Text("No data available for selected date range")
                                .foregroundColor(.secondary)
                                .frame(maxWidth: .infinity, minHeight: 100)
                                .multilineTextAlignment(.center)
                        } else {
                            // Use a ForEach with the name as the identifier to ensure uniqueness
                            ForEach(spendingByList, id: \.name) { item in
                                VStack {
                                    if spendingByList.first?.name != item.name {
                                        Divider()
                                    }
                                    
                                    // Find the matching color for this item
                                    let color = pieChartData.first(where: { $0.name == item.name })?.color ?? .gray
                                    
                                    CategoryRow(
                                        name: item.name,
                                        amount: item.amount,
                                        color: color,
                                        transactions: item.transactions
                                    )
                                }
                            }
                        }
                    }
                    .padding()
                    .background(cardBackgroundColor)
                    .cornerRadius(16)
                    .shadow(color: shadowColor, radius: 4, x: 0, y: 2)
                    .padding(.horizontal)
                    
                    // Bottom spacer
                    Spacer(minLength: 20)
                }
                .padding(.vertical)
                .id(refreshID) // Force view refresh
            }
            .navigationTitle("Budget Tracker")
            .sheet(isPresented: $showingDatePicker) {
                DateRangePickerView(
                    startDate: $startDate,
                    endDate: $endDate,
                    isPresented: $showingDatePicker,
                    onDismiss: {
                        // Refresh when date range changes
                        loadData()
                    }
                )
            }
            .background(Color(.systemGroupedBackground).ignoresSafeArea())
            .onAppear {
                // Load data when view appears
                loadData()
            }
            .onChange(of: appState.dataChanged) { _, _ in
                // First, reset Core Data context cache
                viewContext.refreshAllObjects()
                
                // Then load fresh data after a small delay
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    loadData()
                }
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: loadData) {
                        Label("Refresh", systemImage: "arrow.clockwise")
                    }
                }
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
