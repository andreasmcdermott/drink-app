import SwiftUI
import PourCore

struct ShoppingView: View {
    @Environment(BarStore.self) private var bar
    @State private var budget = 1
    var body: some View {
        let suggestions = RecommendationEngine.shopping(in: Catalog.recipes, pantry: bar.pantry, budget: budget)
        Screen {
            SectionTitle(title: "A little goes a long way", caption: "The best additions to your bar, ranked by the new drinks they unlock.")
            Picker("Maximum ingredients to buy", selection: $budget) {
                Text("Buy 1 ingredient").tag(1)
                Text("Buy up to 2").tag(2)
            }.pickerStyle(.segmented)
            if bar.pantry.isEmpty {
                Label("Add what you own in My bar for suggestions that fit your shelf.", systemImage: "info.circle")
                    .font(.subheadline).foregroundStyle(Palette.secondary)
            }
            if suggestions.isEmpty {
                ContentUnavailableView(bar.available.count == Catalog.recipes.count ? "Your bar has it all" : "No matches yet",
                                       systemImage: "basket",
                                       description: Text(bar.available.count == Catalog.recipes.count ? "You can make every recipe in the collection." : "Try buying up to two ingredients, or add more of what you already own in My bar."))
            }
            ForEach(Array(suggestions.prefix(15).enumerated()), id: \.element.id) { index, suggestion in
                VStack(alignment: .leading, spacing: 16) {
                    HStack {
                        Eyebrow(text: index == 0 ? "Most possibilities" : "Another good addition")
                        Spacer()
                        Image(systemName: "basket").foregroundStyle(Palette.green)
                    }
                    Text(suggestion.ingredientIDs.sorted().map(Catalog.name(for:)).joined(separator: " + "))
                        .font(.system(.title2, design: .serif))
                    Pill(text: "Unlocks \(suggestion.unlockedRecipes.count) new drink\(suggestion.unlockedRecipes.count == 1 ? "" : "s")")
                    ForEach(suggestion.unlockedRecipes) { recipe in
                        NavigationLink { RecipeDetailView(recipe: recipe) } label: {
                            HStack { Text(recipe.name); Spacer(); Image(systemName: "arrow.up.right").font(.caption) }
                        }.font(.subheadline)
                    }
                    Divider()
                    Button {
                        bar.pantry.formUnion(suggestion.ingredientIDs)
                    } label: {
                        Label("I bought \(suggestion.ingredientIDs.count == 1 ? "this" : "these") · add to my bar", systemImage: "checkmark")
                            .font(.subheadline.weight(.medium)).frame(maxWidth: .infinity, alignment: .leading).padding(.vertical, 6)
                    }
                }.padding(22).background(.white.opacity(0.85), in: RoundedRectangle(cornerRadius: 24))
            }
            Text("Based on the original recipes in this collection. Recipe variations aren’t included in these counts.")
                .font(.caption).foregroundStyle(Palette.secondary)
        }.navigationTitle("Add a little")
    }
}
