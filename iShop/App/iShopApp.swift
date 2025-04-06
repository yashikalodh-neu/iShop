//
//  iShopApp.swift
//  iShop
//
//  Created by Yashika Lodh on 4/4/25.
//

import SwiftUI

@main
struct iShopApp: App {
    let persistenceController = PersistenceController.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
        }
    }
}
