# iShop - Inventory and Budget Management App for Groceries

## 📱 Overview

iShop is a SwiftUI-based iOS application designed to help users manage their grocery lists, track spending, and monitor item availability. With an intuitive interface and powerful features, iShop transforms how you shop and manage household items.

## ✨ Features

### 📋 Grocery List Management
- Create multiple grocery lists
- Search and filter lists by name
- Organize lists by date created (Today, Previous 7 Days, Previous 30 Days, Older)

### 📦 Item Tracking
- Add items with detailed information (name, quantity, price, availability)
- Track expiration dates for perishable items
- Set up low stock alerts
- Sort items by name, price, or expiration date

### 💰 Budget Tracking
- Monitor total spending across all grocery lists
- View spending summaries with interactive pie charts
- Analyze spending by category
- Filter financial data by custom date ranges

### 🔄 Batch Updates
- Update multiple items simultaneously
- Toggle availability status for all items with one tap
- Adjust quantities in bulk

## 🏗️ Architecture

iShop is built with:
- **SwiftUI** - For the user interface
- **Core Data** - For data persistence
- **Combine** - For reactive programming patterns
- **MVVM Pattern** - For clean architecture and separation of concerns

## 📐 App Structure

### Core Components

#### GroceryList View
Displays all grocery lists with date-based sections and search functionality.

```swift
struct GroceryListsView: View {
    // Manages lists with date-based grouping
    // Features search capabilities and add/delete operations
}
```

#### ListDetail View
Shows details of a specific grocery list with item management.

```swift
struct ListDetailView: View {
    // Displays list items with sorting options
    // Shows spending summary and item statistics
}
```

#### Budget Tracker
Visualizes spending data with interactive charts.

```swift
struct BudgetTracker: View {
    // Presents pie charts for spending visualization
    // Features date filtering and category breakdown
}
```

#### Batch Update
Allows updating multiple items simultaneously.

```swift
struct BatchUpdateView: View {
    // Enables bulk editing of items
    // Features toggling all items at once
}
```

## 🔧 Installation

1. Clone the repository
   ```bash
   git clone https://github.com/yourusername/iShop.git
   ```

2. Open the project in Xcode
   ```bash
   cd iShop
   open iShop.xcodeproj
   ```

3. Select your development team and run on your device or simulator

## 🔄 Data Model

The app uses Core Data with the following main entities:

- **GroceryList**
  - `groceryListId`: UUID
  - `name`: String
  - `dateCreated`: Date
  - `items`: Relationship to GroceryItem

- **GroceryItem**
  - `groceryItemId`: UUID
  - `name`: String
  - `quantity`: Int16
  - `quantityThreshold`: Int16
  - `price`: Double
  - `isAvailable`: Bool
  - `expirationDate`: Date (optional)
  - `dateAdded`: Date
  - `parentList`: Relationship to GroceryList

## 🛠️ Technologies & Patterns

- **SwiftUI** - Modern declarative UI framework
- **Core Data** - Persistent storage solution
- **Combine** - Reactive programming framework
- **MVVM** - Architecture pattern for clean code organization
- **DateFormatter** - For consistent date formatting
- **NumberFormatter** - For currency formatting
- **Environment Objects** - For dependency injection
- **FetchRequest** - For Core Data integration with SwiftUI
- **Notifications** - For expiration and low stock alerts

## 🧩 Key Components

### AppState
Manages global state and data refresh events across the app.

### NotificationManager
Handles scheduling of alerts for expiration dates and low stock conditions.

### Custom Views
- **PieChartView** - Custom visualization for spending data
- **SearchBar** - Reusable search component
- **CategoryRow** - Displays category data in budget tracker

## 🔮 Future Enhancements

- [ ] iCloud sync for sharing lists across devices
- [ ] Barcode scanning for quick item addition
- [ ] Shopping history and trends analysis
- [ ] Meal planning integration
- [ ] Smart suggestions based on purchase history
- [ ] Apple Watch companion app

## 📄 License

This project is licensed under the MIT License.
