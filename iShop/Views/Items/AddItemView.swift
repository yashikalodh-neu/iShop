import SwiftUI

struct AddItemView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.presentationMode) var presentationMode
    @EnvironmentObject private var appState: AppState
    
    var groceryList: GroceryList
    var updateParent: (() -> Void)?
    
    @State private var name = ""
    @State private var quantity = 1
    @State private var quantityThreshold = 1
    @State private var price = 0.0
    @State private var isAvailable = true
    @State private var hasExpirationDate = false
    @State private var expirationDate = Date()
    @State private var isLowStockAlertEnabled = false
    
    // Currency formatter
    private let currencyFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencySymbol = "$"
        formatter.minimumFractionDigits = 2
        formatter.maximumFractionDigits = 2
        return formatter
    }()
    
    var body: some View {
        NavigationView {
            Form {
                // Use a completely different approach to avoid generic type errors
                Group {
                    Text("Item Details")
                        .font(.headline)
                        .padding(.top, 5)
                    
                    TextField("Name", text: $name)
                    
                    Stepper("Quantity: \(quantity)", value: $quantity, in: 1...999)
                    
                    Toggle("Enable Low Stock Alert", isOn: $isLowStockAlertEnabled)
                    
                    if isLowStockAlertEnabled {
                        Stepper("Low Stock Alert: \(quantityThreshold)", value: $quantityThreshold, in: 1...100)
                    }
                    
                    HStack {
                        Text("Price")
                        Spacer()
                        TextField("Price", value: $price, formatter: currencyFormatter)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                    }
                    
                    Toggle("Available", isOn: $isAvailable)
                    
                    Toggle("Has Expiration Date", isOn: $hasExpirationDate)
                    
                    if hasExpirationDate {
                        DatePicker("Expiration Date", selection: $expirationDate, displayedComponents: .date)
                    }
                }
            }
            .navigationTitle("Add Item")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        saveItem()
                    }
                    .disabled(name.isEmpty)
                }
            }
        }
    }
    
    private func saveItem() {
        withAnimation {
            let newItem = GroceryItem(context: viewContext)
            let newItemId = UUID()
            newItem.groceryItemId = newItemId
            newItem.name = name
            newItem.quantity = Int16(quantity)
            newItem.quantityThreshold = Int16(isLowStockAlertEnabled ? quantityThreshold : 0)
            newItem.price = price
            newItem.isAvailable = isAvailable
            newItem.expirationDate = hasExpirationDate ? expirationDate : nil
            newItem.dateAdded = Date()
            newItem.parentList = groceryList
            
            // Update the groceryList.items set to include the new item
            groceryList.addToItems(newItem)
            
            do {
                try viewContext.save()
                
                // Schedule notifications
                NotificationManager.shared.scheduleLowStockNotification(for: newItem)
                if hasExpirationDate {
                    NotificationManager.shared.scheduleExpirationNotification(for: newItem)
                }
                
                // Call parent update if provided
                updateParent?()
                
                // Notify the app that data has changed
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    appState.refreshData()
                }
                
                presentationMode.wrappedValue.dismiss()
            } catch {
                print("Error saving new item: \(error)")
            }
        }
    }
}

// Wrapper view to ensure the updateParent callback is properly passed
struct AddItemViewWrapper: View {
    @Environment(\.presentationMode) var presentationMode
    var groceryList: GroceryList
    var updateParent: () -> Void
    
    var body: some View {
        AddItemView(groceryList: groceryList, updateParent: updateParent)
    }
}
