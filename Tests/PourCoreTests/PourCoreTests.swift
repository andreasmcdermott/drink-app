import XCTest
@testable import PourCore

final class PourCoreTests: XCTestCase {
    func testFreshRaspberryCosmopolitanMatchingAndScaledTips() throws {
        let recipe = try XCTUnwrap(Catalog.recipes.first { $0.id == "gin-cosmopolitan" })
        let parsed = IngredientParser.parse("gin, orange liqueur, lemon, simple syrup, raspberries", catalog: Catalog.ingredients)
        XCTAssertTrue(parsed.unknown.isEmpty)
        let match = RecommendationEngine.bestMatch(for: recipe, pantry: parsed.matched)
        XCTAssertEqual(match.variation?.id, "fresh-raspberries")
        XCTAssertTrue(match.missing(from: parsed.matched).isEmpty)
        XCTAssertFalse(match.ingredients.contains { $0.ingredientID == "raspberry-syrup" })
        let berries = try XCTUnwrap(match.ingredients.first { $0.ingredientID == "raspberries" })
        for unit in DisplayUnit.allCases {
            XCTAssertEqual(berries.formatted(servings: 1, unit: unit), "5")
            XCTAssertEqual(berries.formatted(servings: 2, unit: unit), "10")
            let tips = RecipeAdjustments.instructions(from: recipe.ingredients, to: match.ingredients, servings: 2, unit: unit)
            XCTAssertTrue(tips.contains("Add 10 fresh raspberries."))
            XCTAssertTrue(tips.contains("Add \(unit == .ml ? "45 ml" : "1½ oz") simple syrup."))
            XCTAssertTrue(tips.contains("Leave out the raspberry syrup."))
        }
        XCTAssertEqual(RecommendationEngine.available(in: [recipe], pantry: parsed.matched).map(\.id), [recipe.id])
        XCTAssertNil(RecommendationEngine.bestMatch(for: recipe, pantry: parsed.matched.union(["raspberry-syrup"])).variation)
        XCTAssertFalse(try XCTUnwrap(match.variation?.preparationTip).isEmpty)
    }

    func testFeaturedDrinkCyclesThroughEveryAvailableRecipeWithoutRepeating() throws {
        let pantry = Set(Catalog.ingredients.map(\.id))
        let calendar = Calendar(identifier: .gregorian)
        let start = try XCTUnwrap(calendar.date(from: DateComponents(year: 2026, month: 10, day: 5)))
        var picks: [String] = []
        for offset in 0..<Catalog.recipes.count {
            let date = try XCTUnwrap(calendar.date(byAdding: .day, value: offset, to: start))
            let pick = try XCTUnwrap(RecommendationEngine.featured(in: Catalog.recipes, pantry: pantry, on: date, calendar: calendar))
            picks.append(pick.id)
            XCTAssertEqual(RecommendationEngine.featured(in: Catalog.recipes.reversed(), pantry: pantry, on: date, calendar: calendar)?.id, pick.id)
        }
        XCTAssertEqual(Set(picks), Set(Catalog.recipes.map(\.id)))
    }

    func testFeaturedDrinkUsesLocalDaysAcrossDaylightSavingChanges() throws {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = try XCTUnwrap(TimeZone(identifier: "America/Los_Angeles"))
        let pantry = Set(Catalog.ingredients.map(\.id))
        for (month, day) in [(3, 8), (11, 1)] {
            let morning = try XCTUnwrap(calendar.date(from: DateComponents(year: 2026, month: month, day: day, hour: 0, minute: 1)))
            let evening = try XCTUnwrap(calendar.date(from: DateComponents(year: 2026, month: month, day: day, hour: 23, minute: 59)))
            let tomorrow = try XCTUnwrap(calendar.date(byAdding: .minute, value: 2, to: evening))
            let first = try XCTUnwrap(RecommendationEngine.featured(in: Catalog.recipes, pantry: pantry, on: morning, calendar: calendar))
            XCTAssertEqual(RecommendationEngine.featured(in: Catalog.recipes, pantry: pantry, on: evening, calendar: calendar)?.id, first.id)
            XCTAssertNotEqual(RecommendationEngine.featured(in: Catalog.recipes, pantry: pantry, on: tomorrow, calendar: calendar)?.id, first.id)
        }
    }

    func testFeaturedDrinkOnlyUsesMakeableRecipesAndIncludesSwaps() throws {
        let date = Date(timeIntervalSince1970: 1_791_216_000)
        let calendar = Calendar(identifier: .gregorian)
        XCTAssertNil(RecommendationEngine.featured(in: Catalog.recipes, pantry: [], on: date))
        XCTAssertEqual(RecommendationEngine.featured(in: Catalog.recipes, pantry: ["gin", "lime", "syrup"], on: date)?.id, "gimlet")
        let pantry: Set<String> = ["gin", "lime", "syrup", "rye", "angostura"]
        let expected: Set<String> = ["gimlet", "old-fashioned"]
        var picks: Set<String> = []
        for offset in 0..<2 {
            let day = try XCTUnwrap(calendar.date(byAdding: .day, value: offset, to: date))
            let recipe = try XCTUnwrap(RecommendationEngine.featured(in: Catalog.recipes, pantry: pantry, on: day, calendar: calendar))
            picks.insert(recipe.id)
            let match = RecommendationEngine.bestMatch(for: recipe, pantry: pantry)
            XCTAssertTrue(match.missing(from: pantry).isEmpty)
            if recipe.id == "old-fashioned" { XCTAssertEqual(match.variation?.id, "rye") }
        }
        XCTAssertEqual(picks, expected)
    }

    func testMatchingRequiresAllIngredientsButNotGarnishes() throws {
        let oldFashioned = try XCTUnwrap(Catalog.recipes.first { $0.id == "old-fashioned" })
        let pantry: Set<String> = ["bourbon", "syrup", "angostura"]
        XCTAssertTrue(oldFashioned.missing(from: pantry).isEmpty)
        XCTAssertEqual(oldFashioned.missing(from: ["bourbon", "syrup"]), ["angostura"])
        XCTAssertEqual(RecommendationEngine.available(in: [oldFashioned], pantry: []).count, 0)
    }

    func testShoppingMatchesExhaustiveSearchAndNeverCountsExistingRecipes() {
        for pantry: Set<String> in [[], ["gin", "lime", "syrup"], ["bourbon", "campari"], ["rye", "syrup"], ["gin", "lemon", "raspberry-syrup"], Set(Catalog.ingredients.map(\.id))] {
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
        XCTAssertEqual(syrup.formatted(servings: 1, unit: .oz), "½ oz")
        XCTAssertEqual(syrup.formatted(servings: 2, unit: .oz), "1 oz")
    }

    func testCuratedWhiskeySwapsUnlockRecipesAndPreferOriginals() throws {
        let whiskeyRecipes = Catalog.recipes.filter { $0.family == "Whiskey" }
        let pantry: Set<String> = ["rye", "syrup", "angostura", "lemon", "campari", "sweet-vermouth"]
        let available = RecommendationEngine.available(in: whiskeyRecipes, pantry: pantry)
        XCTAssertEqual(Set(available.map(\.id)), ["old-fashioned", "whiskey-sour", "boulevardier", "manhattan"])
        for id in ["old-fashioned", "whiskey-sour", "boulevardier"] {
            let recipe = try XCTUnwrap(available.first { $0.id == id })
            let match = RecommendationEngine.bestMatch(for: recipe, pantry: pantry)
            XCTAssertEqual(match.variation?.id, "rye")
            XCTAssertTrue(match.missing(from: pantry).isEmpty)
            XCTAssertTrue(match.ingredients.contains { $0.ingredientID == "rye" })
            XCTAssertFalse(match.ingredients.contains { $0.ingredientID == "bourbon" })
            XCTAssertNil(RecommendationEngine.bestMatch(for: recipe, pantry: pantry.union(["bourbon"])).variation)
        }
        let oldFashioned = try XCTUnwrap(available.first { $0.id == "old-fashioned" })
        let match = RecommendationEngine.bestMatch(for: oldFashioned, pantry: pantry)
        XCTAssertTrue(try XCTUnwrap(match.variation?.steps?.first).contains("rye whiskey"))
        let rye = try XCTUnwrap(match.ingredients.first { $0.ingredientID == "rye" })
        XCTAssertEqual(rye.formatted(servings: 2, unit: .oz), "4 oz")
        XCTAssertEqual(rye.formatted(servings: 2, unit: .ml), "120 ml")
        let manhattan = try XCTUnwrap(available.first { $0.id == "manhattan" })
        XCTAssertEqual(RecommendationEngine.bestMatch(for: manhattan, pantry: ["bourbon", "sweet-vermouth", "angostura"]).variation?.id, "bourbon")
    }

    func testOnlyCompleteCuratedVariationsAreSuggested() throws {
        let recipe = try XCTUnwrap(Catalog.recipes.first { $0.id == "old-fashioned" })
        XCTAssertTrue(RecommendationEngine.available(in: [recipe], pantry: ["gin", "syrup", "angostura"]).isEmpty)
        // Rye and orange bitters are separate curated versions, not a combined recipe.
        XCTAssertTrue(RecommendationEngine.available(in: [recipe], pantry: ["rye", "syrup", "orange-bitters"]).isEmpty)
        let closest = RecommendationEngine.bestMatch(for: recipe, pantry: ["rye", "syrup"])
        XCTAssertEqual(closest.variation?.id, "rye")
        XCTAssertEqual(closest.missing(from: ["rye", "syrup"]), ["angostura"])
        XCTAssertEqual(RecommendationEngine.bestMatch(for: recipe, pantry: ["bourbon", "syrup", "orange-bitters"]).variation?.id, "orange")
        let clover = try XCTUnwrap(Catalog.recipes.first { $0.id == "clover-club" })
        let eggFree: Set<String> = ["gin", "lemon", "raspberry-syrup", "aquafaba"]
        XCTAssertEqual(RecommendationEngine.available(in: [clover], pantry: eggFree).map(\.id), ["clover-club"])
        XCTAssertEqual(RecommendationEngine.bestMatch(for: clover, pantry: eggFree).variation?.id, "egg-free")
    }

    func testShoppingUnlocksVariationsWithoutDoubleCounting() throws {
        let recipes = Catalog.recipes.filter { ["old-fashioned", "whiskey-sour"].contains($0.id) }
        let pantry: Set<String> = ["rye", "syrup"]
        let singles = RecommendationEngine.shopping(in: recipes, pantry: pantry, budget: 1)
        let bitters = try XCTUnwrap(singles.first { $0.ingredientIDs == ["angostura"] })
        XCTAssertEqual(bitters.unlockedRecipes.map(\.id), ["old-fashioned"])
        let pairs = RecommendationEngine.shopping(in: recipes, pantry: pantry, budget: 2)
        let pair = try XCTUnwrap(pairs.first { $0.ingredientIDs == ["angostura", "lemon"] })
        XCTAssertEqual(Set(pair.unlockedRecipes.map(\.id)), ["old-fashioned", "whiskey-sour"])
        let oldFashioned = try XCTUnwrap(recipes.first { $0.id == "old-fashioned" })
        XCTAssertTrue(RecommendationEngine.shopping(in: [oldFashioned], pantry: pantry.union(["angostura"]), budget: 2).isEmpty)
        let bothSpirits: Set<String> = ["bourbon", "rye", "syrup"]
        let purchase = try XCTUnwrap(RecommendationEngine.shopping(in: [oldFashioned], pantry: bothSpirits, budget: 1).first { $0.ingredientIDs == ["angostura"] })
        XCTAssertEqual(purchase.unlockedRecipes.count, 1)
        XCTAssertNil(RecommendationEngine.bestMatch(for: oldFashioned, pantry: bothSpirits.union(purchase.ingredientIDs)).variation)
    }

    func testMixingTipsIncludeAmountsForSelectedUnitsAndServings() throws {
        let recipe = try XCTUnwrap(Catalog.recipes.first { $0.id == "old-fashioned" })
        let sweeter = try XCTUnwrap(recipe.variations.first { $0.id == "sweeter" })
        XCTAssertEqual(RecipeAdjustments.instructions(from: recipe.ingredients, to: sweeter.ingredients, servings: 1, unit: .oz),
                       ["Use ½ oz simple syrup instead of ¼ oz."])
        XCTAssertEqual(RecipeAdjustments.instructions(from: recipe.ingredients, to: sweeter.ingredients, servings: 2, unit: .ml),
                       ["Use 25 ml simple syrup instead of 15 ml."])
        XCTAssertEqual(RecipeAdjustments.instructions(from: recipe.ingredients, to: sweeter.ingredients, servings: 2, unit: .oz),
                       ["Use 1 oz simple syrup instead of ½ oz."])
        XCTAssertTrue(RecipeAdjustments.instructions(from: recipe.ingredients, to: recipe.ingredients, servings: 1, unit: .oz).isEmpty)
    }

    func testVariationsKeepTheSameImperialUnitAsTheOriginalIngredient() throws {
        for recipe in Catalog.recipes {
            for variation in recipe.variations {
                for ingredient in variation.ingredients {
                    if let original = recipe.ingredients.first(where: { $0.ingredientID == ingredient.ingredientID }) {
                        XCTAssertEqual(ingredient.imperial?.label, original.imperial?.label,
                                       "\(recipe.name): \(variation.name), \(ingredient.ingredientID)")
                    }
                }
            }
        }
        let daiquiri = try XCTUnwrap(Catalog.recipes.first { $0.id == "daiquiri" })
        let dry = try XCTUnwrap(daiquiri.variations.first { $0.id == "dry" })
        XCTAssertEqual(RecipeAdjustments.instructions(from: daiquiri.ingredients, to: dry.ingredients, servings: 1, unit: .oz),
                       ["Use ¼ oz simple syrup instead of ½ oz."])
    }

    func testMixingTipsDescribeSwapsRelativeToDisplayedRecipe() throws {
        let recipe = try XCTUnwrap(Catalog.recipes.first { $0.id == "old-fashioned" })
        let rye = try XCTUnwrap(recipe.variations.first { $0.id == "rye" })
        XCTAssertEqual(RecipeAdjustments.instructions(from: rye.ingredients, to: recipe.ingredients, servings: 2, unit: .oz),
                       ["Use 4 oz bourbon instead of rye whiskey."])
        let sweeter = try XCTUnwrap(recipe.variations.first { $0.id == "sweeter" })
        XCTAssertEqual(RecipeAdjustments.instructions(from: rye.ingredients, to: sweeter.ingredients, servings: 1, unit: .ml),
                       ["Use 60 ml bourbon instead of rye whiskey.", "Use 12.5 ml simple syrup instead of 7.5 ml."])
    }

    func testMixingTipsDescribeAdditionsAndRemovals() throws {
        let margarita = try XCTUnwrap(Catalog.recipes.first { $0.id == "margarita" })
        let softer = try XCTUnwrap(margarita.variations.first)
        XCTAssertEqual(RecipeAdjustments.instructions(from: margarita.ingredients, to: softer.ingredients, servings: 2, unit: .oz),
                       ["Add 2 tsp agave syrup."])
        XCTAssertEqual(RecipeAdjustments.instructions(from: softer.ingredients, to: margarita.ingredients, servings: 1, unit: .ml),
                       ["Leave out the agave syrup."])
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
