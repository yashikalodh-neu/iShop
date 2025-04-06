import SwiftUI

struct AddItemView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.presentationMode) var presentationMode
    
    var groceryList: GroceryList
    
    @State private var name = ""
    @State private var quantity = 1
    @State private var quantityThreshold = 1
    @State private var price = 0.0
    @State private var isAvailable = true
    @State private var hasExpirationDate = false
    @State private var expirationDate = Date()
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Item Details")) {
                    TextField("Name", text: $name)
                    
                    Stepper("Quantity: \(quantity)", value: $quantity, in: 1...999)
                    
                    Stepper("Low Stock Alert: \(quantityThreshold)", value: $quantityThreshold, in: 1...100)
                    
                    HStack {
                        Text("Price")
                        Spacer()
                        TextField("Price", value: $price, formatter: NumberFormatter.currencyFormatter)
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
            newItem.quantityThreshold = Int16(quantityThreshold)
            newItem.price = price
            newItem.isAvailable = isAvailable
            newItem.expirationDate = hasExpirationDate ? expirationDate : nil
            newItem.dateAdded = Date()
            newItem.parentList = groceryList
            
            do {
                try viewContext.save()
                
                // Schedule notifications
                if let id = newItem.groceryItemId {
                    NotificationManager.shared.scheduleLowStockNotification(for: newItem)
                    if hasExpirationDate {
                        NotificationManager.shared.scheduleExpirationNotification(for: newItem)
                    }
                }
                
                presentationMode.wrappedValue.dismiss()
            } catch {
                // Handle the Core Data error
                print("Error saving new item: \(error)")
                            }
                        }
                    }
                }

                // Extensions
                extension NumberFormatter {
                    static var currencyFormatter: NumberFormatter {
                        let formatter = NumberFormatter()
                        formatter.numberStyle = .currency
                        formatter.currencySymbol = "$"
                        formatter.minimumFractionDigits = 2
                        formatter.maximumFractionDigits = 2
                        return formatter
                    }
                }

                extension GroceryList: Identifiable {
                    public var id: UUID {
                        wrappedId
                    }
                }

