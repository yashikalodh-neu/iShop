import SwiftUI
import CoreData

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
                
                 //Center hole for donut chart
                Circle()
                    .fill(Color(.systemBackground))
                    .shadow(color: Color.black.opacity(0.1), radius: 2, x: 0, y: 1)
                    .frame(width: min(geometry.size.width, geometry.size.height) * 0.5)
                
//                // Total amount in center
//                VStack {
//                    Text("Total")
//                        .font(.caption)
//                        .foregroundColor(.secondary)
//                    Text("$\(Int(total))")
//                        .font(.title3)
//                        .fontWeight(.bold)
//                }
            }
        }
        .frame(height: 220) // Slightly increased height for better visualization
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

struct BudgetTracker: View {
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.managedObjectContext) private var viewContext
    
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \GroceryList.name, ascending: true)],
        animation: .default)
    private var groceryLists: FetchedResults<GroceryList>
    
    @State private var showingDatePicker = false
    @State private var startDate = Calendar.current.date(byAdding: .day, value: -30, to: Date()) ?? Date()
    @State private var endDate = Date()
    
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
    
    var totalSpending: Double {
        groceryLists.reduce(0) { $0 + $1.totalSpending }
    }
    
    var dateFilteredLists: [GroceryList] {
        let lists = groceryLists.filter { list in
            guard let dateCreated = list.dateCreated else { return false }
            return dateCreated >= startDate && dateCreated <= endDate
        }
        return lists
    }
    
    var dateFilteredSpending: Double {
        return dateFilteredLists.reduce(0) { $0 + $1.totalSpending }
    }
    
    // Group spending by category (in this case, by list)
    var spendingByList: [(name: String, amount: Double, transactions: Int)] {
        let grouped = Dictionary(grouping: dateFilteredLists) { $0.wrappedName }
        
        return grouped.map { (key, lists) in
            let totalAmount = lists.reduce(0) { $0 + $1.totalSpending }
            return (name: key, amount: totalAmount, transactions: lists.count)
        }.sorted { $0.amount > $1.amount }
    }
    
    // Pie chart data with colors
    var pieChartData: [(name: String, amount: Double, color: Color)] {
        let colors: [Color] = [
            .blue, .purple, .orange, .green, .pink, .red, .yellow, .teal
        ]
        
        var result = [(name: String, amount: Double, color: Color)]()
        
        for (index, item) in spendingByList.enumerated() {
            let colorIndex = index % colors.count
            result.append((name: item.name, amount: item.amount, color: colors[colorIndex]))
        }
        
        return result
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
                        Label("Spending Summary", systemImage: "chart.pie.fill")
                            .font(.headline)
                        
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
                                    Text(dateFilteredLists.isEmpty ? "$0.00" : String(format: "$%.2f", dateFilteredSpending / Double(dateFilteredLists.count)))
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
                            ForEach(0..<spendingByList.count, id: \.self) { index in
                                if index > 0 {
                                    Divider()
                                }
                                
                                CategoryRow(
                                    name: spendingByList[index].name,
                                    amount: spendingByList[index].amount,
                                    color: pieChartData[index].color,
                                    transactions: spendingByList[index].transactions
                                )
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
                .id(spendingByList.reduce("", { $0 + $1.name + String($1.amount) }))
            }
            .navigationTitle("Budget Tracker")
            .sheet(isPresented: $showingDatePicker) {
                DateRangePickerView(startDate: $startDate, endDate: $endDate, isPresented: $showingDatePicker)
            }
            .background(Color(.systemGroupedBackground).ignoresSafeArea())
        }
    }
    
    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter
    }()
}
