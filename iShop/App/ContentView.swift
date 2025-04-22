import SwiftUI

struct ContentView: View {
    @Environment(\.managedObjectContext) private var viewContext
    
    var body: some View {
        TabView {
            GroceryListsView()
                .tabItem {
                    Label("Lists", systemImage: "list.bullet")
                }
            
            BudgetTracker()
                .tabItem {
                    Label("Budget", systemImage: "chart.pie")
                }
        }
    }
}
