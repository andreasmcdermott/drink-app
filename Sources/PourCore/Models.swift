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
public enum Measure: String, Sendable { case dash, leaf, teaspoon }
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
    /// Milliliters for volumes, otherwise the number of dashes, leaves or teaspoons.
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
        }
        let value = measure == .teaspoon ? Self.fraction(total) : total.formatted(.number.precision(.fractionLength(0...2)))
        return "\(value) \(label)"
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

public struct Variation: Identifiable, Sendable {
    public let id: String
    public let name: String
    public let note: String
    /// Complete ingredient list, so substitutions participate in matching and scaling.
    public let ingredients: [RecipeIngredient]
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

public enum RecommendationEngine {
    public static func available(in recipes: [Recipe], pantry: Set<String>) -> [Recipe] {
        recipes.filter { $0.missing(from: pantry).isEmpty }
    }

    /// Rank all useful purchases of up to two ingredients, including combinations that
    /// unlock separate recipes. Omit pairs when either item contributes no extra recipes.
    public static func shopping(in recipes: [Recipe], pantry: Set<String>, budget: Int) -> [ShoppingSuggestion] {
        let limit = min(2, max(1, budget))
        let missing = recipes.map { ($0, $0.missing(from: pantry)) }.filter { !$0.1.isEmpty }
        let candidates = Set(missing.filter { $0.1.count <= limit }.flatMap { $0.1 }).sorted()
        var sets = candidates.map { Set([$0]) }
        if limit == 2 {
            for i in candidates.indices {
                for j in candidates.indices where j > i { sets.append(Set([candidates[i], candidates[j]])) }
            }
        }
        return sets.compactMap { purchase -> ShoppingSuggestion? in
            let unlocked = missing.filter { $0.1.isSubset(of: purchase) }.map(\.0)
            guard !unlocked.isEmpty else { return nil }
            if purchase.count == 2 {
                for item in purchase {
                    let reduced = purchase.subtracting([item])
                    if missing.filter({ $0.1.isSubset(of: reduced) }).count == unlocked.count { return nil }
                }
            }
            return ShoppingSuggestion(ingredientIDs: purchase, unlockedRecipes: unlocked)
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
