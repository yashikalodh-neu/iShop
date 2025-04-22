import SwiftUI
import Combine

@main
struct iShopApp: App {
    let persistenceController = PersistenceController.shared
    @State private var isShowingSplash = true
    @Environment(\.scenePhase) private var scenePhase
    private var cancellables = Set<AnyCancellable>()
    
    var body: some Scene {
        WindowGroup {
            ZStack {
                ContentView()
                    .environment(\.managedObjectContext, persistenceController.container.viewContext)
                
                if isShowingSplash {
                    SplashScreen()
                        .transition(.opacity)
                        .zIndex(1)
                        .onAppear {
                            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                                withAnimation {
                                    isShowingSplash = false
                                }
                            }
                        }
                }
            }
            .onChange(of: scenePhase) { _, newPhase in
                if newPhase == .active {
                    // Show splash screen when app becomes active
                    withAnimation {
                        isShowingSplash = true
                    }
                    
                    // Hide splash screen after delay
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                        withAnimation {
                            isShowingSplash = false
                        }
                    }
                }
            }
        }
    }
}
