import SwiftUI

struct AddListView: View {
    @Environment(\.presentationMode) var presentationMode
    @State private var listName = ""
    
    var onSave: (String) -> Void
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("List Details")) {
                    TextField("List Name", text: $listName)
                }
            }
            .navigationTitle("New List")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        if !listName.isEmpty {
                            onSave(listName)
                        }
                    }
                    .disabled(listName.isEmpty)
                }
            }
        }
    }
}
