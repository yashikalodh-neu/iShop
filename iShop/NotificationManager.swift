// NotificationManager.swift
import Foundation
import UserNotifications

class NotificationManager {
    static let shared = NotificationManager()
    
    private init() {}
    
    // Request authorization for notifications
    func requestAuthorization() {
        let options: UNAuthorizationOptions = [.alert, .sound, .badge]
        UNUserNotificationCenter.current().requestAuthorization(options: options) { success, error in
            if let error = error {
                print("Error requesting notification authorization: \(error)")
            } else if success {
                print("Notification authorization granted")
                // Register notification categories if needed
                self.registerCategories()
            }
        }
    }
    
    // Register custom categories for notification actions
    private func registerCategories() {
        // Define actions
        let markAsUsed = UNNotificationAction(identifier: "MARK_AS_USED",
                                           title: "Mark as Used",
                                           options: .foreground)
        
        let addToList = UNNotificationAction(identifier: "ADD_TO_LIST",
                                          title: "Add to Shopping List",
                                          options: .foreground)
        
        // Create categories
        let lowStockCategory = UNNotificationCategory(identifier: "LOW_STOCK",
                                                   actions: [markAsUsed, addToList],
                                                   intentIdentifiers: [],
                                                   options: [])
        
        let expiringCategory = UNNotificationCategory(identifier: "EXPIRING",
                                                   actions: [markAsUsed],
                                                   intentIdentifiers: [],
                                                   options: [])
        
        // Register categories
        UNUserNotificationCenter.current().setNotificationCategories([lowStockCategory, expiringCategory])
    }
    
    // Schedule low stock notification
    func scheduleLowStockNotification(for item: GroceryItem) {
        guard let id = item.groceryItemId else { return }
        // Cancel any existing notification for this item
        cancelNotification(for: item.wrappedId, notificationType: "lowStock")
        
        // Only schedule if quantity is below threshold
        guard item.isLowStock else { return }
        
        let content = UNMutableNotificationContent()
        content.title = "Low Stock Alert"
        content.body = "\(item.wrappedName) is running low. You have \(item.quantity) left."
        content.sound = .default
        content.categoryIdentifier = "LOW_STOCK"
        content.userInfo = ["itemId": item.wrappedId.uuidString]
        
        // Trigger after a short delay
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 5, repeats: false)
        
        let request = UNNotificationRequest(identifier: "lowStock-\(item.wrappedId.uuidString)",
                                        content: content,
                                        trigger: trigger)
        
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Error scheduling low stock notification: \(error)")
            }
        }
    }
    
    // Schedule expiration notification
    func scheduleExpirationNotification(for item: GroceryItem) {
        // Cancel any existing notification for this item
        cancelNotification(for: item.wrappedId, notificationType: "expiration")
        
        // Only schedule if there's an expiration date
        guard let expirationDate = item.expirationDate else { return }
        
        // Calculate notification date (2 days before expiration)
        let notificationDate = Calendar.current.date(byAdding: .day, value: -2, to: expirationDate)
        
        // Skip if notification date is in the past
        guard let notificationDate = notificationDate, notificationDate > Date() else { return }
        
        let content = UNMutableNotificationContent()
        content.title = "Expiration Alert"
        content.body = "\(item.wrappedName) expires in 2 days. Use it soon!"
        content.sound = .default
        content.categoryIdentifier = "EXPIRING"
        content.userInfo = ["itemId": item.wrappedId.uuidString]
        
        // Create date components for the trigger
        let dateComponents = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: notificationDate)
        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: false)
        
        let request = UNNotificationRequest(identifier: "expiration-\(item.wrappedId.uuidString)",
                                        content: content,
                                        trigger: trigger)
        
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Error scheduling expiration notification: \(error)")
            }
        }
    }
    
    // Cancel a specific notification
    func cancelNotification(for itemId: UUID, notificationType: String) {
        let identifier = "\(notificationType)-\(itemId.uuidString)"
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [identifier])
    }
    
    // Cancel all notifications for an item
    func cancelAllNotifications(for id: UUID) {
        let identifiers = ["lowStock-\(id.uuidString)", "expiration-\(id.uuidString)"]
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: identifiers)
    }
    
    // Handle notification response
    func handleNotificationResponse(_ response: UNNotificationResponse, completion: @escaping () -> Void) {
        // Get the item ID from the notification
        guard let itemIdString = response.notification.request.content.userInfo["itemId"] as? String,
              let itemId = UUID(uuidString: itemIdString) else {
            completion()
            return
        }
        
        // Handle different action types
        switch response.actionIdentifier {
        case "MARK_AS_USED":
            // This would be handled in the app to mark the item as used
            print("User wants to mark item as used: \(itemId)")
            
        case "ADD_TO_LIST":
            // This would be handled in the app to add item to shopping list
            print("User wants to add item to shopping list: \(itemId)")
            
        default:
            // Default action is to open the app
            break
        }
        
        completion()
    }
}
