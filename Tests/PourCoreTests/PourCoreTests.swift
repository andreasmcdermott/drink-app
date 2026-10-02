import XCTest
@testable import PourCore

final class PourCoreTests: XCTestCase {
    func testMatchingRequiresAllIngredientsButNotGarnishes() throws {
        let oldFashioned = try XCTUnwrap(Catalog.recipes.first { $0.id == "old-fashioned" })
        let pantry: Set<String> = ["bourbon", "syrup", "angostura"]
        XCTAssertTrue(oldFashioned.missing(from: pantry).isEmpty)
        XCTAssertEqual(oldFashioned.missing(from: ["bourbon", "syrup"]), ["angostura"])
        XCTAssertEqual(RecommendationEngine.available(in: [oldFashioned], pantry: []).count, 0)
    }

    func testShoppingMatchesExhaustiveSearchAndNeverCountsExistingRecipes() {
        for pantry: Set<String> in [[], ["gin", "lime", "syrup"], ["bourbon", "campari"], Set(Catalog.ingredients.map(\.id))] {
            for budget in 1...2 {
                let suggestions = RecommendationEngine.shopping(in: Catalog.recipes, pantry: pantry, budget: budget)
                let existing = Set(RecommendationEngine.available(in: Catalog.recipes, pantry: pantry).map(\.id))
                for suggestion in suggestions {
                    XCTAssertLessThanOrEqual(suggestion.ingredientIDs.count, budget)
                    XCTAssertTrue(suggestion.ingredientIDs.isDisjoint(with: pantry))
                    let after = Set(RecommendationEngine.available(in: Catalog.recipes, pantry: pantry.union(suggestion.ingredientIDs)).map(\.id))
                    XCTAssertEqual(Set(suggestion.unlockedRecipes.map(\.id)), after.subtracting(existing))
                    for ingredient in suggestion.ingredientIDs {
                        let without = pantry.union(suggestion.ingredientIDs.subtracting([ingredient]))
                        XCTAssertLessThan(RecommendationEngine.available(in: Catalog.recipes, pantry: without).count, after.count)
                    }
                }
                let candidates = Catalog.ingredients.map(\.id).filter { !pantry.contains($0) }
                var best = 0
                for first in candidates {
                    for second in budget == 2 ? candidates : [first] {
                        let result = RecommendationEngine.available(in: Catalog.recipes, pantry: pantry.union([first, second]))
                        best = max(best, result.count - existing.count)
                    }
                }
                XCTAssertEqual(suggestions.first?.unlockedRecipes.count ?? 0, best)
            }
        }
    }

    func testPairsCanUnlockRecipesThatNeitherItemUnlocksAlone() throws {
        let negroni = try XCTUnwrap(Catalog.recipes.first { $0.id == "negroni" })
        XCTAssertTrue(RecommendationEngine.shopping(in: [negroni], pantry: ["gin"], budget: 1).isEmpty)
        let pair = try XCTUnwrap(RecommendationEngine.shopping(in: [negroni], pantry: ["gin"], budget: 2).first)
        XCTAssertEqual(pair.ingredientIDs, ["campari", "sweet-vermouth"])
        XCTAssertEqual(pair.unlockedRecipes.map(\.id), ["negroni"])
    }

    func testIndependentImperialSpecificationsAndScaling() throws {
        let gin = RecipeIngredient("gin", 50, imperial: .oz(2))
        XCTAssertEqual(gin.formatted(servings: 1, unit: .oz), "2 oz")
        XCTAssertEqual(gin.formatted(servings: 2, unit: .oz), "4 oz")
        XCTAssertEqual(gin.formatted(servings: 2, unit: .ml), "100 ml")
        let lime = RecipeIngredient("lime", 25, imperial: .oz(0.75))
        for (servings, expected) in [(1, "¾ oz"), (2, "1½ oz"), (3, "2¼ oz"), (12, "9 oz")] {
            XCTAssertEqual(lime.formatted(servings: servings, unit: .oz), expected)
        }
        XCTAssertEqual(lime.formatted(servings: 0, unit: .oz), "¾ oz")
        XCTAssertEqual(RecipeIngredient("syrup", 7.5, imperial: .oz(0.25)).formatted(servings: 3, unit: .ml), "22.5 ml")
        XCTAssertEqual(RecipeIngredient("angostura", 2, .dash).formatted(servings: 2, unit: .oz), "4 dashes")
        XCTAssertEqual(RecipeIngredient("angostura", 1, .dash).formatted(servings: 1, unit: .oz), "1 dash")
        XCTAssertEqual(RecipeIngredient("mint", 6, .leaf).formatted(servings: 3, unit: .ml), "18 leaves")
        XCTAssertEqual(RecipeIngredient("fernet", 2.5, imperial: .tsp(0.5)).formatted(servings: 3, unit: .oz), "1½ tsp")
    }

    func testCatalogOuncesUsePracticalMeasuresIncludingVariations() throws {
        for recipe in Catalog.recipes {
            for ingredients in [recipe.ingredients] + recipe.variations.map(\.ingredients) {
                for ingredient in ingredients where ingredient.measure == nil {
                    let imperial = try XCTUnwrap(ingredient.imperial, recipe.name)
                    XCTAssertGreaterThan(imperial.amount, 0)
                    XCTAssertEqual(imperial.amount * 4, (imperial.amount * 4).rounded(), recipe.name)
                    for servings in 1...12 {
                        XCTAssertFalse(ingredient.formatted(servings: servings, unit: .oz).contains("."), recipe.name)
                    }
                }
            }
        }
        let negroni = try XCTUnwrap(Catalog.recipes.first { $0.id == "negroni" })
        XCTAssertEqual(negroni.ingredients.map { $0.formatted(servings: 1, unit: .oz) }, ["1 oz", "1 oz", "1 oz"])
        let sweeter = try XCTUnwrap(Catalog.recipes.first { $0.id == "old-fashioned" }?.variations.first)
        let syrup = try XCTUnwrap(sweeter.ingredients.first { $0.ingredientID == "syrup" })
        XCTAssertEqual(syrup.formatted(servings: 1, unit: .oz), "2½ tsp")
        XCTAssertEqual(syrup.formatted(servings: 2, unit: .oz), "5 tsp")
    }

    func testParserResolvesAliasesAndReportsAmbiguityWithoutGuessing() {
        let result = IngredientParser.parse("I have gin, limes and Cointreau, rum, no vodka", catalog: Catalog.ingredients)
        XCTAssertEqual(result.matched, ["gin", "lime", "triple-sec"])
        XCTAssertEqual(result.unknown, ["rum", "no vodka"])
        let ambiguous = IngredientParser.parse("whiskey, bitters, vermouth", catalog: Catalog.ingredients)
        XCTAssertTrue(ambiguous.matched.isEmpty)
        XCTAssertEqual(ambiguous.unknown.count, 3)
    }

    func testVariationsChangeActualIngredientsAndScale() throws {
        let recipe = try XCTUnwrap(Catalog.recipes.first { $0.id == "old-fashioned" })
        let variation = try XCTUnwrap(recipe.variations.first { $0.id == "orange" })
        XCTAssertFalse(variation.ingredients.contains { $0.ingredientID == "angostura" })
        let bitters = try XCTUnwrap(variation.ingredients.first { $0.ingredientID == "orange-bitters" })
        XCTAssertEqual(bitters.formatted(servings: 2, unit: .ml), "4 dashes")
        XCTAssertFalse(Set(variation.ingredients.map(\.ingredientID)).isSubset(of: ["bourbon", "syrup", "angostura"]))
    }

    func testCatalogIntegrity() {
        let ids = Set(Catalog.ingredients.map(\.id))
        XCTAssertEqual(ids.count, Catalog.ingredients.count)
        XCTAssertEqual(Set(Catalog.recipes.map(\.id)).count, Catalog.recipes.count)
        for recipe in Catalog.recipes {
            XCTAssertFalse(recipe.steps.isEmpty)
            XCTAssertFalse(recipe.ingredients.isEmpty)
            XCTAssertEqual(Set(recipe.variations.map(\.id)).count, recipe.variations.count)
            for ingredients in [recipe.ingredients] + recipe.variations.map(\.ingredients) {
                XCTAssertEqual(Set(ingredients.map(\.ingredientID)).count, ingredients.count)
                for ingredient in ingredients {
                    XCTAssertTrue(ids.contains(ingredient.ingredientID), "Unknown ingredient in \(recipe.name)")
                    XCTAssertGreaterThan(ingredient.amount, 0)
                }
            }
        }
    }
}
