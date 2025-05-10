import SwiftUI

//MARK: - Batch Update View
struct BatchUpdateView: View {
    @Environment(\.presentationMode) private var presentationMode
    @Environment(\.managedObjectContext) private var viewContext
    var groceryList: GroceryList
    var updateParent: () -> Void
    
    @State private var items: [GroceryItem]
    @State private var isEdited = false
    
    init(groceryList: GroceryList, updateParent: @escaping () -> Void) {
        self.groceryList = groceryList
        self.updateParent = updateParent
        
        _items = State(initialValue: groceryList.itemsArray.sorted { $0.wrappedName < $1.wrappedName })
    }
    
    var body: some View {
        NavigationView {
            List {
                Section {
                    ForEach(items.indices, id: \.self) { index in
                        BatchUpdateRow(
                            item: $items[index],
                            updateEdited: { isEdited = true }
                        )
                    }
                } header: {
                    HStack {
                        Text("Update Items")
                            .font(.headline)
                        Spacer()
                        Button(action: toggleAllAvailability) {
                            HStack {
                                Image(systemName: "checkmark.circle")
                                Text("Toggle All")
                                    .font(.caption)
                            }
                            .padding(.vertical, 4)
                            .padding(.horizontal, 8)
                            .background(Color.green.opacity(0.1))
                            .cornerRadius(8)
                        }
                    }
                }
            }
            .listStyle(InsetGroupedListStyle())
            .navigationTitle("Batch Update")
            .navigationBarItems(
                leading: Button("Cancel") {
                    presentationMode.wrappedValue.dismiss()
                },
                trailing: Button("Save") {
                    saveChanges()
                }
                .disabled(!isEdited)
            )
            .toolbar {
                ToolbarItem(placement: .bottomBar) {
                    HStack {
                        Spacer()
                        Text("\(items.count) items")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Spacer()
                    }
                }
            }
        }
    }
    
    private func toggleAllAvailability() {
        withAnimation {
            let allAvailable = !items.contains { !$0.isAvailable }
            
            for index in items.indices {
                items[index].isAvailable = !allAvailable
            }
            
            isEdited = true
        }
    }
    
    private func saveChanges() {
        do {
            try viewContext.save()
            updateParent()
            presentationMode.wrappedValue.dismiss()
        } catch {
            print("Error saving batch updates: \(error)")
        }
    }
}

//MARK: - Batch Update Row
struct BatchUpdateRow: View {
    @Binding var item: GroceryItem
    var updateEdited: () -> Void
    
    var body: some View {
        HStack(spacing: 12) {
            Button(action: toggleAvailability) {
                Image(systemName: item.isAvailable ? "checkmark.circle.fill" : "circle")
                    .foregroundColor(item.isAvailable ? .green : .gray)
                    .font(.system(size: 20))
            }
            .buttonStyle(BorderlessButtonStyle())
            
            Text(item.wrappedName)
                .fontWeight(.medium)
                .strikethrough(!item.isAvailable, color: .red)
            
            Spacer()
            
            HStack(spacing: 8) {
                Button(action: decrementQuantity) {
                    ZStack {
                        Circle()
                            .fill(Color.blue.opacity(0.1))
                            .frame(width: 28, height: 28)
                        
                        Image(systemName: "minus")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(.blue)
                    }
                }
                .buttonStyle(BorderlessButtonStyle())
                .disabled(item.quantity <= 1)
                
                Text("\(Int(item.quantity))")
                    .frame(minWidth: 24)
                    .font(.system(size: 16, weight: .medium))
                
                Button(action: incrementQuantity) {
                    ZStack {
                        Circle()
                            .fill(Color.blue.opacity(0.1))
                            .frame(width: 28, height: 28)
                        
                        Image(systemName: "plus")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(.blue)
                    }
                }
                .buttonStyle(BorderlessButtonStyle())
            }
        }
        .padding(.vertical, 4)
    }
    
    private func toggleAvailability() {
        withAnimation {
            item.isAvailable.toggle()
            updateEdited()
        }
    }
    
    private func incrementQuantity() {
        withAnimation {
            item.quantity += 1
            updateEdited()
        }
    }
    
    private func decrementQuantity() {
        withAnimation {
            if item.quantity > 1 {
                item.quantity -= 1
                updateEdited()
            }
        }
    }
}
