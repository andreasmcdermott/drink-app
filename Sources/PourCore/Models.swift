import Foundation

public enum IngredientCategory: String, CaseIterable, Sendable {
    case spirits = "Spirits", liqueurs = "Liqueurs & vermouth", citrus = "Fruit & juice"
    case mixers = "Mixers & sweeteners", bitters = "Bitters & extras"
}

public struct Ingredient: Identifiable, Hashable, Sendable {
    public let id: String
    public let name: String
    public let category: IngredientCategory
    public let aliases: [String]

    public init(_ id: String, _ name: String, _ category: IngredientCategory, aliases: [String] = []) {
        self.id = id; self.name = name; self.category = category; self.aliases = aliases
    }
}

/// Counts keep the same measure in both unit systems.
public enum Measure: String, Sendable { case dash, leaf, teaspoon, count }
public enum DisplayUnit: String, CaseIterable, Sendable { case ml = "ml", oz = "oz" }

/// An authored imperial recipe quantity, independent of its metric specification.
public enum ImperialAmount: Hashable, Sendable {
    case oz(Double)
    case tsp(Double)

    public var amount: Double {
        switch self { case .oz(let value), .tsp(let value): return value }
    }
    public var label: String {
        switch self { case .oz: return "oz"; case .tsp: return "tsp" }
    }
}

public struct RecipeIngredient: Identifiable, Hashable, Sendable {
    public var id: String { ingredientID }
    public let ingredientID: String
    /// Milliliters for volumes, otherwise a number of items, dashes, leaves or teaspoons.
    public let amount: Double
    public let measure: Measure?
    public let imperial: ImperialAmount?

    public init(_ ingredientID: String, _ milliliters: Double, imperial: ImperialAmount) {
        self.ingredientID = ingredientID
        self.amount = milliliters
        self.measure = nil
        self.imperial = imperial
    }

    public init(_ ingredientID: String, _ amount: Double, _ measure: Measure) {
        self.ingredientID = ingredientID
        self.amount = amount
        self.measure = measure
        self.imperial = nil
    }

    public func formatted(servings: Int, unit: DisplayUnit) -> String {
        let count = Double(max(1, servings))
        if unit == .oz, let imperial {
            return "\(Self.fraction(imperial.amount * count)) \(imperial.label)"
        }
        let total = amount * count
        let label: String
        switch measure {
        case nil: label = "ml"
        case .dash: label = total == 1 ? "dash" : "dashes"
        case .leaf: label = total == 1 ? "leaf" : "leaves"
        case .teaspoon: label = "tsp"
        case .count: label = ""
        }
        let value = measure == .teaspoon ? Self.fraction(total) : total.formatted(.number.precision(.fractionLength(0...2)))
        return label.isEmpty ? value : "\(value) \(label)"
    }

    private static func fraction(_ value: Double) -> String {
        let eighths = (value * 8).rounded()
        // Preserve an unusual authored quantity rather than silently rounding it.
        guard abs(value * 8 - eighths) < 0.000001 else {
            return value.formatted(.number.precision(.fractionLength(0...2)))
        }
        let whole = Int(eighths) / 8
        let remainder = Int(eighths) % 8
        let glyphs = ["", "⅛", "¼", "⅜", "½", "⅝", "¾", "⅞"]
        return (whole > 0 || remainder == 0 ? String(whole) : "") + glyphs[remainder]
    }
}

/// Self-contained mixing tips derived from two ingredient specifications.
public enum RecipeAdjustments {
    public static func instructions(from current: [RecipeIngredient], to alternative: [RecipeIngredient],
                                    servings: Int, unit: DisplayUnit) -> [String] {
        let removed = current.filter { item in !alternative.contains { $0.ingredientID == item.ingredientID } }
        let added = alternative.filter { item in !current.contains { $0.ingredientID == item.ingredientID } }
        let replacements = added.count == removed.count ? Dictionary(uniqueKeysWithValues:
            zip(added, removed).map { ($0.ingredientID, $1) }) : [:]
        var instructions: [String] = []
        for ingredient in alternative {
            let name = Catalog.name(for: ingredient.ingredientID).lowercased()
            let amount = ingredient.formatted(servings: servings, unit: unit)
            if let previous = current.first(where: { $0.ingredientID == ingredient.ingredientID }) {
                let oldAmount = previous.formatted(servings: servings, unit: unit)
                if amount != oldAmount {
                    instructions.append("Use \(amount) \(name) instead of \(oldAmount).")
                }
            } else if let previous = replacements[ingredient.ingredientID] {
                instructions.append("Use \(amount) \(name) instead of \(Catalog.name(for: previous.ingredientID).lowercased()).")
            } else {
                instructions.append("Add \(amount) \(name).")
            }
        }
        if replacements.isEmpty {
            instructions += removed.map { "Leave out the \(Catalog.name(for: $0.ingredientID).lowercased())." }
        }
        return instructions
    }
}

public struct Variation: Identifiable, Sendable {
    public let id: String
    public let name: String
    public let note: String
    /// Complete ingredient list, so substitutions participate in matching and scaling.
    public let ingredients: [RecipeIngredient]
    /// Alternate method when a substitution changes ingredients or preparation.
    public let steps: [String]?
    /// Extra technique shown alongside the measured ingredient adjustments.
    public let preparationTip: String?

    public init(id: String, name: String, note: String, ingredients: [RecipeIngredient], steps: [String]? = nil,
                preparationTip: String? = nil) {
        self.id = id
        self.name = name
        self.note = note
        self.ingredients = ingredients
        self.steps = steps
        self.preparationTip = preparationTip
    }
}

public struct Recipe: Identifiable, Sendable {
    public let id: String
    public let name: String
    public let subtitle: String
    public let family: String
    public let glass: String
    public let color: String
    public let ingredients: [RecipeIngredient]
    public let steps: [String]
    public let garnish: String?
    public let variations: [Variation]

    public var requiredIDs: Set<String> { Set(ingredients.map(\.ingredientID)) }
    public func missing(from pantry: Set<String>) -> Set<String> { requiredIDs.subtracting(pantry) }
}

public struct ShoppingSuggestion: Identifiable, Sendable {
    public var id: String { ingredientIDs.sorted().joined(separator: "+") }
    public let ingredientIDs: Set<String>
    public let unlockedRecipes: [Recipe]
}

/// One original recipe or a complete, curated variation. Swaps are never combined implicitly.
public struct RecipeMatch: Sendable {
    public let recipe: Recipe
    public let variation: Variation?
    public var ingredients: [RecipeIngredient] { variation?.ingredients ?? recipe.ingredients }
    public func missing(from pantry: Set<String>) -> Set<String> {
        Set(ingredients.map(\.ingredientID)).subtracting(pantry)
    }
}

public enum RecommendationEngine {
    private static func options(for recipe: Recipe) -> [RecipeMatch] {
        [RecipeMatch(recipe: recipe, variation: nil)] + recipe.variations.map {
            RecipeMatch(recipe: recipe, variation: $0)
        }
    }

    /// Prefer the version needing the fewest purchases; the original wins ties,
    /// followed by variations in their curated catalog order.
    public static func bestMatch(for recipe: Recipe, pantry: Set<String>) -> RecipeMatch {
        options(for: recipe).reduce(RecipeMatch(recipe: recipe, variation: nil)) { best, option in
            option.missing(from: pantry).count < best.missing(from: pantry).count ? option : best
        }
    }

    public static func available(in recipes: [Recipe], pantry: Set<String>) -> [Recipe] {
        recipes.filter { bestMatch(for: $0, pantry: pantry).missing(from: pantry).isEmpty }
    }

    /// Each available drink gets one day per cycle, including curated substitutions.
    /// A stable shelf and local date produce the same pick across app launches.
    public static func featured(in recipes: [Recipe], pantry: Set<String>, on date: Date,
                                calendar: Calendar = .current) -> Recipe? {
        let candidates = available(in: recipes, pantry: pantry).sorted { $0.id < $1.id }
        // Count date labels in UTC so a 23- or 25-hour local day still gets one pick.
        var dayCalendar = calendar
        dayCalendar.timeZone = .gmt
        let components = calendar.dateComponents([.era, .year, .month, .day], from: date)
        guard !candidates.isEmpty,
              let localDay = dayCalendar.date(from: components),
              let day = dayCalendar.ordinality(of: .day, in: .era, for: localDay) else { return nil }
        return candidates[(day - 1) % candidates.count]
    }

    /// Evaluate all original and curated versions, but count each newly available
    /// drink once. Do not suggest purchases for drinks already possible with a swap.
    public static func shopping(in recipes: [Recipe], pantry: Set<String>, budget: Int) -> [ShoppingSuggestion] {
        let limit = min(2, max(1, budget))
        let missing = recipes.compactMap { recipe -> (Recipe, [Set<String>])? in
            let needs = options(for: recipe).map { $0.missing(from: pantry) }
            guard !needs.contains(where: \.isEmpty) else { return nil }
            let useful = needs.filter { $0.count <= limit }
            return useful.isEmpty ? nil : (recipe, useful)
        }
        let candidates = Set(missing.flatMap { $0.1.flatMap { $0 } }).sorted()
        var sets = candidates.map { Set([$0]) }
        if limit == 2 {
            for i in candidates.indices {
                for j in candidates.indices where j > i { sets.append(Set([candidates[i], candidates[j]])) }
            }
        }
        func unlocked(by purchase: Set<String>) -> [Recipe] {
            missing.filter { entry in entry.1.contains { $0.isSubset(of: purchase) } }.map(\.0)
        }
        return sets.compactMap { purchase -> ShoppingSuggestion? in
            let recipes = unlocked(by: purchase)
            guard !recipes.isEmpty else { return nil }
            if purchase.count == 2 {
                for item in purchase {
                    if unlocked(by: purchase.subtracting([item])).count == recipes.count { return nil }
                }
            }
            return ShoppingSuggestion(ingredientIDs: purchase, unlockedRecipes: recipes)
        }.sorted {
            if $0.unlockedRecipes.count != $1.unlockedRecipes.count { return $0.unlockedRecipes.count > $1.unlockedRecipes.count }
            if $0.ingredientIDs.count != $1.ingredientIDs.count { return $0.ingredientIDs.count < $1.ingredientIDs.count }
            return $0.id < $1.id
        }
    }
}

public enum IngredientParser {
    /// Conservative list parser: whole catalog names/aliases only. The UI previews
    /// matches before adding and reports unrecognized phrases instead of guessing.
    public static func parse(_ text: String, catalog: [Ingredient]) -> (matched: Set<String>, unknown: [String]) {
        let normalized = text.lowercased().replacingOccurrences(of: "i have ", with: "")
            .replacingOccurrences(of: "i've got ", with: "")
            .replacingOccurrences(of: " and ", with: ",")
        let pieces = normalized.components(separatedBy: CharacterSet(charactersIn: ",;\n"))
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines.union(.punctuationCharacters)) }
            .filter { !$0.isEmpty }
        var matched: Set<String> = []
        var unknown: [String] = []
        for piece in pieces {
            if let ingredient = catalog.first(where: { ([$0.name.lowercased()] + $0.aliases).contains(piece) }) {
                matched.insert(ingredient.id)
            } else { unknown.append(piece) }
        }
        return (matched, unknown)
    }
}
