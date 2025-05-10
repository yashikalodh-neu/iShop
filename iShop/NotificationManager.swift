// NotificationManager.swift
import Foundation
import UserNotifications

//MARK: - Notification Manager
class NotificationManager {
    static let shared = NotificationManager()
    
    private init() {}
    
    func requestAuthorization() {
        let options: UNAuthorizationOptions = [.alert, .sound, .badge]
        UNUserNotificationCenter.current().requestAuthorization(options: options) { success, error in
            if let error = error {
                print("Error requesting notification authorization: \(error)")
            } else if success {
                print("Notification authorization granted")
                self.registerCategories()
            }
        }
    }
    
    private func registerCategories() {
        let markAsUsed = UNNotificationAction(identifier: "MARK_AS_USED",
                                           title: "Mark as Used",
                                           options: .foreground)
        
        let addToList = UNNotificationAction(identifier: "ADD_TO_LIST",
                                          title: "Add to Shopping List",
                                          options: .foreground)
        
        let lowStockCategory = UNNotificationCategory(identifier: "LOW_STOCK",
                                                   actions: [markAsUsed, addToList],
                                                   intentIdentifiers: [],
                                                   options: [])
        
        let expiringCategory = UNNotificationCategory(identifier: "EXPIRING",
                                                   actions: [markAsUsed],
                                                   intentIdentifiers: [],
                                                   options: [])
        
        UNUserNotificationCenter.current().setNotificationCategories([lowStockCategory, expiringCategory])
    }
    
    // Schedule low stock notification
    func scheduleLowStockNotification(for item: GroceryItem) {
        guard let id = item.groceryItemId else { return }
        cancelNotification(for: item.wrappedId, notificationType: "lowStock")
        
        guard item.isLowStock else { return }
        
        let content = UNMutableNotificationContent()
        content.title = "Low Stock Alert"
        content.body = "\(item.wrappedName) is running low. You have \(item.quantity) left."
        content.sound = .default
        content.categoryIdentifier = "LOW_STOCK"
        content.userInfo = ["itemId": item.wrappedId.uuidString]
        
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
        cancelNotification(for: item.wrappedId, notificationType: "expiration")
        
        guard let expirationDate = item.expirationDate else { return }
        
        let notificationDate = Calendar.current.date(byAdding: .day, value: -2, to: expirationDate)
        
        guard let notificationDate = notificationDate, notificationDate > Date() else { return }
        
        let content = UNMutableNotificationContent()
        content.title = "Expiration Alert"
        content.body = "\(item.wrappedName) expires in 2 days. Use it soon!"
        content.sound = .default
        content.categoryIdentifier = "EXPIRING"
        content.userInfo = ["itemId": item.wrappedId.uuidString]
        
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
    
    func cancelNotification(for itemId: UUID, notificationType: String) {
        let identifier = "\(notificationType)-\(itemId.uuidString)"
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [identifier])
    }
    
    func cancelAllNotifications(for id: UUID) {
        let identifiers = ["lowStock-\(id.uuidString)", "expiration-\(id.uuidString)"]
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: identifiers)
    }
    
    func handleNotificationResponse(_ response: UNNotificationResponse, completion: @escaping () -> Void) {
        guard let itemIdString = response.notification.request.content.userInfo["itemId"] as? String,
              let itemId = UUID(uuidString: itemIdString) else {
            completion()
            return
        }
        
        switch response.actionIdentifier {
        case "MARK_AS_USED":
            print("User wants to mark item as used: \(itemId)")
            
        case "ADD_TO_LIST":
            print("User wants to add item to shopping list: \(itemId)")
            
        default:
            break
        }
        
        completion()
    }
}
