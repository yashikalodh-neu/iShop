import SwiftUI

struct ItemDetailView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.presentationMode) var presentationMode
    
    @ObservedObject var item: GroceryItem
    
    @State private var name: String
    @State private var quantity: Int
    @State private var quantityThreshold: Int
    @State private var price: Double
    @State private var isAvailable: Bool
    @State private var expirationDate: Date?
    @State private var isLowStockAlertEnabled: Bool
    
    // DateFormatter for display
    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter
    }()
    
    init(item: GroceryItem) {
        self.item = item
        
        // Initialize state with current values
        _name = State(initialValue: item.wrappedName)
        _quantity = State(initialValue: Int(item.quantity))
        _quantityThreshold = State(initialValue: Int(item.quantityThreshold))
        _price = State(initialValue: item.price)
        _isAvailable = State(initialValue: item.isAvailable)
        _expirationDate = State(initialValue: item.expirationDate)
        _isLowStockAlertEnabled = State(initialValue: item.quantityThreshold > 0)
    }
    
    var body: some View {
        Form {
            Section(header: Text("Item Details")) {
                TextField("Name", text: $name)
                
                Stepper("Quantity: \(quantity)", value: $quantity, in: 0...999)
                
//                Stepper("Low Stock Alert: \(quantityThreshold)", value: $quantityThreshold, in: 1...100)
//                    .foregroundColor(quantity <= quantityThreshold ? .red : .primary)
                Toggle("Enable Low Stock Alert", isOn: $isLowStockAlertEnabled)
                if isLowStockAlertEnabled {
                                    Stepper("Low Stock Alert: \(quantityThreshold)", value: $quantityThreshold, in: 1...100)
                                        .foregroundColor(quantity <= quantityThreshold ? .red : .primary)
                                }
                
                HStack {
                    Text("Price")
                    Spacer()
                    TextField("Price", value: $price, formatter: NumberFormatter.currencyFormatter)
                        .keyboardType(.decimalPad)
                        .multilineTextAlignment(.trailing)
                }
                
                Toggle("Available", isOn: $isAvailable)
                
                DatePicker("Expiration Date", selection: Binding(
                    get: { expirationDate ?? Date() },
                    set: { expirationDate = $0 }
                ), displayedComponents: .date)
                
                Button(action: {
                    expirationDate = nil
                }) {
                    Text("Clear Expiration Date")
                        .foregroundColor(.red)
                }
                .disabled(expirationDate == nil)
            }
            
            Section {
                Button(action: saveItem) {
                    Text("Save Changes")
                        .frame(maxWidth: .infinity)
                        .foregroundColor(.white)
                }
                .listRowBackground(Color.blue)
            }
        }
        .navigationTitle(item.wrappedName)
    }
    
    private func saveItem() {
        withAnimation {
            // Update item properties
            item.name = name
            item.quantity = Int16(quantity)
            item.quantityThreshold = Int16(isLowStockAlertEnabled ? quantityThreshold : 0)
            item.price = price
            item.isAvailable = isAvailable
            item.expirationDate = expirationDate
            
            do {
                try viewContext.save()
                
                // Schedule or update notifications
//                if let id = item.id {
                    NotificationManager.shared.scheduleLowStockNotification(for: item)
                    NotificationManager.shared.scheduleExpirationNotification(for: item)
//                }
                
                // Go back to the list view
                presentationMode.wrappedValue.dismiss()
            } catch {
                // Handle the Core Data error
                print("Error saving item: \(error)")
            }
        }
    }
}
