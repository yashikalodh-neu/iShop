import SwiftUI
import Combine

//MARK: - iShop App
@main
struct iShopApp: App {
    let persistenceController = PersistenceController.shared
    @State private var isShowingSplash = true
    @Environment(\.scenePhase) private var scenePhase
    private var cancellables = Set<AnyCancellable>()
    
    // Add the AppState as a StateObject
    @StateObject private var appState = AppState()
    
    var body: some Scene {
        WindowGroup {
            ZStack {
                ContentView()
                    .environment(\.managedObjectContext, persistenceController.container.viewContext)
                    // Inject the AppState into the environment
                    .environmentObject(appState)
                
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

//MARK: - AppState
class AppState: ObservableObject {
    @Published var dataChanged = UUID()
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        // Listen for Core Data changes globally
        NotificationCenter.default.publisher(for: .NSManagedObjectContextDidSave)
            .receive(on: RunLoop.main)
            .sink { [weak self] _ in
                print("Core Data save detected in AppState")
                self?.refreshData()
            }
            .store(in: &cancellables)
    }
    
    func refreshData() {
        DispatchQueue.main.async {
            print("AppState refreshing data...")
            self.dataChanged = UUID()
            print("New data ID: \(self.dataChanged)")
        }
    }
}
