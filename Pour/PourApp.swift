import SwiftUI
import PourCore

@main
struct PourApp: App {
    @State private var bar = BarStore()
    var body: some Scene {
        WindowGroup {
            RootView().environment(bar).tint(Palette.green).preferredColorScheme(.light)
        }
    }
}

@Observable
final class BarStore {
    private let defaults: UserDefaults
    var pantry: Set<String> { didSet { defaults.set(pantry.sorted(), forKey: "pantry") } }
    var favorites: Set<String> { didSet { defaults.set(favorites.sorted(), forKey: "favorites") } }
    var unit: DisplayUnit { didSet { defaults.set(unit.rawValue, forKey: "unit") } }

    init(defaults suppliedDefaults: UserDefaults = .standard) {
        var defaults = suppliedDefaults
        #if DEBUG
        if ProcessInfo.processInfo.arguments.contains("--ui-testing") {
            defaults = UserDefaults(suiteName: "com.example.pour.ui-tests")!
            if ProcessInfo.processInfo.arguments.contains("--reset-test-data") {
                defaults.removePersistentDomain(forName: "com.example.pour.ui-tests")
            }
        }
        #endif
        self.defaults = defaults
        pantry = Set(defaults.stringArray(forKey: "pantry") ?? [])
        favorites = Set(defaults.stringArray(forKey: "favorites") ?? [])
        unit = DisplayUnit(rawValue: defaults.string(forKey: "unit") ?? "ml") ?? .ml
    }

    var available: [Recipe] { RecommendationEngine.available(in: Catalog.recipes, pantry: pantry) }
    func toggle(_ ingredient: String) {
        if pantry.contains(ingredient) { pantry.remove(ingredient) } else { pantry.insert(ingredient) }
    }
    func toggleFavorite(_ recipe: String) {
        if favorites.contains(recipe) { favorites.remove(recipe) } else { favorites.insert(recipe) }
    }
}

struct RootView: View {
    @State private var selection = 0
    var body: some View {
        TabView(selection: $selection) {
            NavigationStack { DiscoverView(openBar: { selection = 1 }) }
                .tabItem { Label("For you", systemImage: "sparkles") }.tag(0)
            NavigationStack { PantryView() }
                .tabItem { Label("My bar", systemImage: "cabinet") }.tag(1)
            NavigationStack { RecipesView() }
                .tabItem { Label("Recipes", systemImage: "book.closed") }.tag(2)
            NavigationStack { ShoppingView() }
                .tabItem { Label("Add a little", systemImage: "basket") }.tag(3)
        }
    }
}
