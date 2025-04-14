import SwiftUI

struct DateRangePickerView: View {
    @Binding var startDate: Date
    @Binding var endDate: Date
    @Binding var isPresented: Bool
    var onDismiss: (() -> Void)? = nil
    
    // Temporary dates for the picker
    @State private var tempStartDate: Date
    @State private var tempEndDate: Date
    
    init(startDate: Binding<Date>, endDate: Binding<Date>, isPresented: Binding<Bool>, onDismiss: (() -> Void)? = nil) {
        self._startDate = startDate
        self._endDate = endDate
        self._isPresented = isPresented
        self.onDismiss = onDismiss
        
        // Initialize temporary dates with current values
        self._tempStartDate = State(initialValue: startDate.wrappedValue)
        self._tempEndDate = State(initialValue: endDate.wrappedValue)
    }
    
    var body: some View {
        NavigationView {
            VStack {
                Form {
                    Section(header: Text("Start Date")) {
                        DatePicker("", selection: $tempStartDate, displayedComponents: .date)
                            .datePickerStyle(GraphicalDatePickerStyle())
                            .labelsHidden()
                    }
                    
                    Section(header: Text("End Date")) {
                        DatePicker("", selection: $tempEndDate, in: tempStartDate..., displayedComponents: .date)
                            .datePickerStyle(GraphicalDatePickerStyle())
                            .labelsHidden()
                    }
                }
            }
            .navigationTitle("Select Date Range")
            .navigationBarItems(
                leading: Button("Cancel") {
                    isPresented = false
                },
                trailing: Button("Apply") {
                    startDate = tempStartDate
                    endDate = tempEndDate
                    isPresented = false
                    onDismiss?()
                }
            )
        }
    }
}

