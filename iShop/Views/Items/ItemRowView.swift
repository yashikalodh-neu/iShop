import SwiftUI

struct ItemRowView: View {
    @ObservedObject var item: GroceryItem
    
    var body: some View {
        HStack {
            VStack(alignment: .leading) {
                Text(item.wrappedName)
                    .fontWeight(item.isAvailable ? .regular : .light)
                    .foregroundColor(item.isAvailable ? .primary : .secondary)
                    .strikethrough(!item.isAvailable)
                
                HStack {
                    Text("Qty: \(item.quantity)")
                        .font(.caption)
                        .foregroundColor(item.isLowStock ? .red : .secondary)
                    
                    if let expirationDate = item.expirationDate {
                        Text("Expires: \(expirationDate, formatter: itemDateFormatter)")
                            .font(.caption)
                            .foregroundColor(item.isExpiringSoon ? .orange : .secondary)
                    }
                }
            }
            
            Spacer()
            
            Text(item.formattedPrice)
                .fontWeight(.medium)
        }
    }
    
    private let itemDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .none
        return formatter
    }()
}
