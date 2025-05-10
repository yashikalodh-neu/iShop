import SwiftUI

// MARK: - ItemRowView
struct ItemRowView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @ObservedObject var item: GroceryItem
    
    var body: some View {
        HStack(spacing: 12) {
            // Item status indicator (checkbox)
            Button(action: toggleItemStatus) {
                Image(systemName: item.isAvailable ? "checkmark.circle.fill" : "circle")
                    .foregroundColor(item.isAvailable ? .green : .gray)
                    .font(.system(size: 20))
            }
            .buttonStyle(BorderlessButtonStyle())
            
            // Item details
            VStack(alignment: .leading, spacing: 4) {
                Text(item.wrappedName)
                    .fontWeight(.medium)
                    .font(.system(size: 16))
                    .strikethrough(!item.isAvailable, color: .red)
                
                if let expirationDate = item.expirationDate {
                    Text("Expires: \(expirationDate, formatter: dateFormatter)")
                        .font(.caption)
                        .foregroundColor(isExpiringSoon(date: expirationDate) ? .orange : .gray)
                }
            }
            
            Spacer()
            
            // Quantity with low stock indicator
            Text("Qty: \(item.quantity)")
                .font(.system(size: 14))
                .foregroundColor(isLowStock(item: item) ? .red : .primary)
                .padding(.horizontal, 8)
            
            // Price display
            Text(String(format: "$%.2f", item.price))
                .font(.system(size: 16, weight: .semibold))
                .frame(minWidth: 60)
                .foregroundColor(.black.opacity(0.8))
        }
        .padding(.vertical, 4)
    }
    
    // Date formatter for expiration dates
    private var dateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .none
        return formatter
    }
    
    // Check if item is expiring within 3 days
    private func isExpiringSoon(date: Date) -> Bool {
        let thresholdDays: Double = 3
        return date.timeIntervalSinceNow <= (thresholdDays * 24 * 60 * 60)
    }
    
    // Check if quantity is below the threshold AND low stock alert is enabled
    private func isLowStock(item: GroceryItem) -> Bool {
        return item.quantityThreshold > 0 && item.quantity <= item.quantityThreshold
    }
    
    private func toggleItemStatus() {
        withAnimation {
            item.isAvailable.toggle()
            
            do {
                try viewContext.save()
            } catch {
                print("Error toggling item status: \(error)")
            }
        }
    }
    
    private func incrementQuantity() {
        withAnimation {
            item.quantity += 1
            
            do {
                try viewContext.save()
            } catch {
                print("Error incrementing quantity: \(error)")
            }
        }
    }
    
    private func decrementQuantity() {
        withAnimation {
            if item.quantity > 1 {
                item.quantity -= 1
                
                do {
                    try viewContext.save()
                } catch {
                    print("Error decrementing quantity: \(error)")
                }
            }
        }
    }
}

// MARK: - RowWithNavigation
struct RowWithNavigation: View {
    @Environment(\.managedObjectContext) private var viewContext
    @ObservedObject var item: GroceryItem
    var updateParent: () -> Void
    
    var body: some View {
        NavigationLink(destination: ItemDetailViewWrapper(item: item, updateParent: updateParent)) {
            ItemRowView(item: item)
                .environment(\.managedObjectContext, viewContext)
                .onChange(of: item.quantity) { oldValue, newValue in
                    // Update the view when quantity changes
                    updateParent()
                }
        }
        .buttonStyle(PlainButtonStyle()) // This helps with button tap propagation
    }
}


// MARK: - Wrapper Views
struct ItemDetailViewWrapper: View {
    @ObservedObject var item: GroceryItem
    var updateParent: () -> Void
    
    var body: some View {
        ItemDetailView(item: item)
            .onDisappear {
                updateParent()
            }
    }
}
