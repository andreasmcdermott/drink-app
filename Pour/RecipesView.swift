import SwiftUI
import PourCore

struct RecipesView: View {
    @Environment(BarStore.self) private var bar
    @State private var search = ""
    @State private var family = "All"
    @State private var onlyFavorites = false
    @State private var onlyAvailable = false
    private let families = ["All", "Gin", "Whiskey", "Rum", "Tequila", "Vodka", "Brandy", "Aperitif", "Bitters", "Alcohol-free"]
    private var filtered: [Recipe] {
        Catalog.recipes.filter {
            (search.isEmpty || $0.name.localizedCaseInsensitiveContains(search) || $0.ingredients.contains { Catalog.name(for: $0.ingredientID).localizedCaseInsensitiveContains(search) }) &&
            (family == "All" || $0.family == family) &&
            (!onlyFavorites || bar.favorites.contains($0.id)) &&
            (!onlyAvailable || bar.match(for: $0).missing(from: bar.pantry).isEmpty)
        }
    }

    var body: some View {
        Screen {
            SectionTitle(title: "Find your next favorite", caption: "\(Catalog.recipes.count) recipes, from the familiar to the fresh.")
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(families, id: \.self) { value in
                        Button { family = value } label: {
                            Text(value).font(.subheadline.weight(.medium)).padding(.horizontal, 16).padding(.vertical, 10)
                                .background(family == value ? Palette.green : .white, in: Capsule())
                                .foregroundStyle(family == value ? .white : Palette.green)
                        }.accessibilityAddTraits(family == value ? .isSelected : [])
                    }
                }
            }
            VStack(spacing: 12) {
                Toggle("Ready to mix", isOn: $onlyAvailable)
                Toggle("Favorites only", isOn: $onlyFavorites)
            }.font(.subheadline)
            if filtered.isEmpty {
                ContentUnavailableView("No recipes found", systemImage: "magnifyingglass", description: Text("Try another search or change your filters."))
            } else {
                Eyebrow(text: "\(filtered.count) recipes")
                ForEach(filtered) { RecipeRow(recipe: $0) }
            }
        }.navigationTitle("The recipe book").searchable(text: $search, prompt: "Search drinks or ingredients")
    }
}
