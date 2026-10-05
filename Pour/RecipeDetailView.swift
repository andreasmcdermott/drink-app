import SwiftUI
import PourCore

struct RecipeDetailView: View {
    @Environment(BarStore.self) private var bar
    let recipe: Recipe
    @State private var servings = 1
    private let variationID: String?
    init(recipe: Recipe, initialVariationID: String? = nil) {
        self.recipe = recipe
        variationID = initialVariationID
    }

    private var variation: Variation? { recipe.variations.first { $0.id == variationID } }
    private var ingredients: [RecipeIngredient] { variation?.ingredients ?? recipe.ingredients }
    private var steps: [String] { variation?.steps ?? recipe.steps }
    private var missing: [RecipeIngredient] { ingredients.filter { !bar.pantry.contains($0.ingredientID) } }

    var body: some View {
        @Bindable var bar = bar
        Screen {
            CocktailArt(recipe: recipe).frame(height: 230).frame(maxWidth: .infinity)
                .background(Palette.paper(recipe))
                .clipShape(RoundedRectangle(cornerRadius: 28))
            VStack(alignment: .leading, spacing: 12) {
                Eyebrow(text: "\(recipe.family) / \(recipe.glass) glass")
                Text(recipe.name).font(.system(.largeTitle, design: .serif))
                Text(recipe.subtitle).foregroundStyle(Palette.secondary)
                if let variation {
                    Text(variation.name).font(.headline).foregroundStyle(Palette.green)
                    Text(variation.note).font(.subheadline).foregroundStyle(Palette.secondary)
                }
                Pill(text: missing.isEmpty ? "Ready to mix" : "\(missing.count) ingredient\(missing.count == 1 ? "" : "s") missing")
            }
            VStack(alignment: .leading, spacing: 20) {
                HStack {
                    Text("Ingredients").font(.system(.title2, design: .serif))
                    Spacer()
                    Picker("Measurement unit", selection: $bar.unit) {
                        ForEach(DisplayUnit.allCases, id: \.self) { Text($0.rawValue).tag($0) }
                    }.pickerStyle(.segmented).frame(width: 110)
                }
                Stepper("\(servings) drink\(servings == 1 ? "" : "s")", value: $servings, in: 1...12)
                    .font(.subheadline.weight(.medium))
                    .accessibilityIdentifier("servings")
                ForEach(ingredients) { ingredient in
                    HStack(alignment: .firstTextBaseline, spacing: 12) {
                        Image(systemName: bar.pantry.contains(ingredient.ingredientID) ? "checkmark.circle.fill" : "circle.dashed")
                            .foregroundStyle(Palette.secondary).accessibilityHidden(true)
                        VStack(alignment: .leading, spacing: 3) {
                            Text(Catalog.name(for: ingredient.ingredientID))
                            if !bar.pantry.contains(ingredient.ingredientID) { Text("Not on your shelf").font(.caption).foregroundStyle(Palette.secondary) }
                        }
                        Spacer(minLength: 0)
                        Text(ingredient.formatted(servings: servings, unit: bar.unit)).fontWeight(.medium).monospacedDigit()
                    }.font(.subheadline)
                }
                if servings > 1 {
                    Text("Amounts are for all \(servings) drinks. Shake or stir in small batches, then divide evenly between glasses. Add fresh ice to each batch.")
                        .font(.footnote).foregroundStyle(Palette.secondary)
                }
            }.padding(20).background(.white.opacity(0.8), in: RoundedRectangle(cornerRadius: 22))
            if !recipe.variations.isEmpty {
                VStack(alignment: .leading, spacing: 12) {
                    SectionTitle(title: "Make it your own", caption: "Amounts for \(servings) drink\(servings == 1 ? "" : "s").")
                    if variation != nil {
                        suggestion(name: "The original", alternative: recipe.ingredients)
                    }
                    ForEach(recipe.variations.filter { $0.id != variationID }) { option in
                        suggestion(name: option.name, alternative: option.ingredients, baseline: recipe.ingredients)
                    }
                }
            }
            SectionTitle(title: "Let’s make it")
            ForEach(Array(steps.enumerated()), id: \.offset) { index, step in
                HStack(alignment: .top, spacing: 16) {
                    Text(String(format: "%02d", index + 1)).font(.system(.body, design: .serif)).foregroundStyle(Palette.secondary)
                    Text(step).font(.body).lineSpacing(4)
                }
            }
            if let garnish = recipe.garnish {
                VStack(alignment: .leading, spacing: 8) {
                    Eyebrow(text: "Finishing touch · optional")
                    Text(garnish).font(.subheadline).foregroundStyle(Palette.secondary)
                }.padding(18).frame(maxWidth: .infinity, alignment: .leading)
                    .background(Palette.green.opacity(0.06), in: RoundedRectangle(cornerRadius: 18))
            }
        }.navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button { bar.toggleFavorite(recipe.id) } label: {
                        Image(systemName: bar.favorites.contains(recipe.id) ? "heart.fill" : "heart")
                    }.accessibilityLabel(bar.favorites.contains(recipe.id) ? "Remove from favorites" : "Save to favorites")
                }
            }
    }

    private func suggestion(name: String, alternative: [RecipeIngredient], baseline: [RecipeIngredient]? = nil) -> some View {
        // Each tip describes its own change without undoing another suggested swap.
        let instructions = RecipeAdjustments.instructions(from: baseline ?? ingredients, to: alternative,
                                                         servings: servings, unit: bar.unit)
        return VStack(alignment: .leading, spacing: 4) {
            Text(name).font(.subheadline.weight(.semibold))
            Text(instructions.joined(separator: " "))
                .font(.subheadline).foregroundStyle(Palette.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}
