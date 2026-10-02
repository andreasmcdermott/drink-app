import SwiftUI
import PourCore

enum Palette {
    static let background = Color(hex: 0xF6F3EB)
    static let green = Color(hex: 0x264A3A)
    static let ink = Color(hex: 0x263B31)
    static let secondary = Color(hex: 0x677065)
    static let gold = Color(hex: 0xCDA766)
    static func paper(_ recipe: Recipe) -> Color { Color("paper-\(recipe.id)") }
    static func drink(_ name: String) -> Color {
        Color(hex: ["amber": 0xD19239, "red": 0xB94530, "lime": 0xCCD59A,
                    "lemon": 0xE5CA76, "clear": 0xDAE7D5, "orange": 0xEE963E,
                    "pink": 0xDE9D99, "coffee": 0x674332][name] ?? 0xD19239)
    }
}

extension Color {
    init(hex: UInt32) {
        self.init(.sRGB, red: Double((hex >> 16) & 255) / 255,
                  green: Double((hex >> 8) & 255) / 255, blue: Double(hex & 255) / 255, opacity: 1)
    }
}

struct Screen<Content: View>: View {
    @ViewBuilder var content: Content
    var body: some View {
        ScrollView { VStack(alignment: .leading, spacing: 24) { content }.padding(24) }
            .background(Palette.background).foregroundStyle(Palette.ink)
    }
}

struct Eyebrow: View {
    let text: String
    var body: some View {
        Text(text.uppercased()).font(.system(size: 11, weight: .bold, design: .monospaced))
            .tracking(2).foregroundStyle(Palette.secondary)
    }
}

struct SectionTitle: View {
    let title: String
    var caption: String? = nil
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title).font(.system(.title2, design: .serif, weight: .medium))
            if let caption { Text(caption).font(.subheadline).foregroundStyle(Palette.secondary) }
        }
    }
}

struct Pill: View {
    let text: String
    var body: some View {
        Text(text).font(.caption.weight(.medium)).padding(.horizontal, 10).padding(.vertical, 6)
            .background(Palette.green.opacity(0.08), in: Capsule()).foregroundStyle(Palette.green)
    }
}

struct PrimaryButton: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label.font(.subheadline.weight(.semibold)).frame(maxWidth: .infinity).padding(16)
            .background(Palette.green.opacity(configuration.isPressed ? 0.8 : 1), in: RoundedRectangle(cornerRadius: 16))
            .foregroundStyle(.white)
    }
}

/// Recipe-specific artwork bundled with the app for offline use.
struct CocktailArt: View {
    let recipe: Recipe
    var body: some View {
        Image("cocktail-\(recipe.id)")
            .resizable()
            .scaledToFit()
            .frame(maxWidth: .infinity)
            .accessibilityHidden(true)
    }
}

struct RecipeRow: View {
    @Environment(BarStore.self) private var bar
    let recipe: Recipe
    var body: some View {
        NavigationLink { RecipeDetailView(recipe: recipe) } label: {
            HStack(spacing: 16) {
                CocktailArt(recipe: recipe).frame(width: 78, height: 86)
                    .background(Palette.paper(recipe))
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                VStack(alignment: .leading, spacing: 7) {
                    Text(recipe.name).font(.system(.headline, design: .serif)).foregroundStyle(Palette.ink)
                    Text("\(recipe.family) · \(recipe.ingredients.count) ingredients").font(.caption).foregroundStyle(Palette.secondary)
                    let missing = recipe.missing(from: bar.pantry).count
                    Text(missing == 0 ? "Ready to mix" : "\(missing) ingredient\(missing == 1 ? "" : "s") missing")
                        .font(.caption.weight(.medium)).foregroundStyle(missing == 0 ? Palette.green : Palette.secondary)
                }
                Spacer(minLength: 0)
                Image(systemName: "chevron.right").font(.caption.weight(.semibold)).foregroundStyle(Palette.secondary)
            }.padding(12).background(.white.opacity(0.75), in: RoundedRectangle(cornerRadius: 22))
        }.buttonStyle(.plain)
    }
}
