import SwiftUI

struct SplashScreen: View {
    var body: some View {
        ZStack {
            // Light green background similar to image
            Color(hex: "DAFFD8")
                .ignoresSafeArea()
            
            VStack {
                Image("iShop")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 440, height: 440)
                
                Text("iShop")
                    .font(.custom("HelveticaNeue-Bold", size: 48))
                    .foregroundColor(Color(hex: "1C5D1C")) 
            }
        }
    }
}

// Extension to allow using hex color codes
extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (1, 1, 1, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}
