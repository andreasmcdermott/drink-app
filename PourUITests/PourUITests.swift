import XCTest

@MainActor
final class PourUITests: XCTestCase {
    func testShelfRecipeScalingFavoritesAndPersistence() {
        let app = XCUIApplication()
        app.launchArguments = ["--ui-testing", "--reset-test-data"]
        app.launch()
        XCTAssertTrue(app.buttons["Add my ingredients"].waitForExistence(timeout: 10))
        capture("Welcome", app)
        app.buttons["Add my ingredients"].tap()
        app.buttons["Type a list of ingredients"].tap()
        let entry = app.textViews["Ingredient list"]
        XCTAssertTrue(entry.waitForExistence(timeout: 5))
        entry.tap()
        entry.typeText("gin, limes, simple syrup")
        app.buttons["Add 3 ingredients"].tap()
        app.tabBars.buttons["For you"].tap()
        XCTAssertTrue(app.staticTexts["You have 3 ingredients and 1 drink ready to make."].waitForExistence(timeout: 5))
        capture("Your shelf recommendations", app)
        app.buttons.containing(.staticText, identifier: "Fresh Lime Gimlet").firstMatch.tap()
        let stepper = app.steppers["servings"]
        if !stepper.isHittable { app.swipeUp() }
        stepper.buttons["servings-Increment"].tap()
        XCTAssertTrue(app.staticTexts["120 ml"].exists)
        XCTAssertTrue(app.staticTexts["50 ml"].exists)
        app.segmentedControls.buttons["oz"].tap()
        XCTAssertTrue(app.staticTexts["4 oz"].exists)
        XCTAssertTrue(app.staticTexts["1½ oz"].firstMatch.exists)
        stepper.buttons["servings-Decrement"].tap()
        XCTAssertTrue(app.staticTexts["2 oz"].exists)
        XCTAssertTrue(app.staticTexts["¾ oz"].firstMatch.exists)
        capture("Ounce recipe", app)
        stepper.buttons["servings-Increment"].tap()
        app.segmentedControls.buttons["ml"].tap()
        XCTAssertTrue(app.staticTexts["120 ml"].exists)
        XCTAssertTrue(app.staticTexts["50 ml"].exists)
        app.buttons["Save to favorites"].tap()
        capture("Scaled recipe", app)
        app.terminate()
        app.launchArguments = ["--ui-testing"]
        app.launch()
        XCTAssertTrue(app.staticTexts["You have 3 ingredients and 1 drink ready to make."].waitForExistence(timeout: 10))
        app.tabBars.buttons["Recipes"].tap()
        app.switches["Favorites only"].tap()
        XCTAssertTrue(app.staticTexts["Fresh Lime Gimlet"].exists)
        XCTAssertFalse(app.staticTexts["Old Fashioned"].exists)
        app.tabBars.buttons["Add a little"].tap()
        XCTAssertTrue(app.staticTexts["Dry vermouth"].waitForExistence(timeout: 5))
        capture("Shopping suggestions", app)
        app.buttons["I bought this · add to my bar"].firstMatch.tap()
        app.tabBars.buttons["For you"].tap()
        XCTAssertTrue(app.staticTexts["You have 4 ingredients and 2 drinks ready to make."].waitForExistence(timeout: 5))
    }

    func testSuggestedRyeSwapShowsStaticMixingTips() {
        let app = XCUIApplication()
        app.launchArguments = ["--ui-testing", "--reset-test-data"]
        app.launch()
        XCTAssertTrue(app.buttons["Add my ingredients"].waitForExistence(timeout: 10))
        app.buttons["Add my ingredients"].tap()
        app.buttons["Type a list of ingredients"].tap()
        let entry = app.textViews["Ingredient list"]
        XCTAssertTrue(entry.waitForExistence(timeout: 5))
        entry.tap()
        entry.typeText("rye, simple syrup, angostura")
        app.buttons["Add 3 ingredients"].tap()
        app.tabBars.buttons["For you"].tap()
        XCTAssertTrue(app.staticTexts["You have 3 ingredients and 1 drink ready to make."].waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["Rye Old Fashioned"].firstMatch.exists)
        capture("Suggested rye substitution", app)
        app.buttons.containing(.staticText, identifier: "Old Fashioned").firstMatch.tap()
        XCTAssertTrue(app.staticTexts["Rye whiskey"].waitForExistence(timeout: 5))
        app.segmentedControls.buttons["oz"].tap()
        let stepper = app.steppers["servings"]
        if !stepper.isHittable { app.swipeUp() }
        stepper.buttons["servings-Increment"].tap()
        XCTAssertTrue(app.staticTexts["4 oz"].exists)
        capture("Rye recipe quantities", app)
        for _ in 0..<4 {
            if app.staticTexts["Add rye whiskey, simple syrup, and bitters to a rocks glass."].isHittable { break }
            app.swipeUp()
        }
        XCTAssertTrue(app.staticTexts["Add rye whiskey, simple syrup, and bitters to a rocks glass."].exists)
        let originalTip = app.staticTexts["Use 4 oz bourbon instead of rye whiskey."]
        for _ in 0..<4 {
            if originalTip.isHittable { break }
            app.swipeDown()
        }
        XCTAssertTrue(originalTip.isHittable)
        XCTAssertTrue(app.staticTexts["Use 1 oz simple syrup instead of ½ oz."].exists)
        XCTAssertFalse(app.buttons["variation-original"].exists)
        capture("Simple mixing tips", app)
        // Reading the tips leaves the recommended rye recipe intact.
        for _ in 0..<4 {
            if app.staticTexts["Rye whiskey"].isHittable { break }
            app.swipeDown()
        }
        XCTAssertTrue(app.staticTexts["Rye whiskey"].exists)
        XCTAssertFalse(app.staticTexts["Bourbon"].exists)
        app.tabBars.buttons["Recipes"].tap()
        app.switches["Ready to mix"].tap()
        XCTAssertTrue(app.buttons["recipe-old-fashioned"].exists)
        XCTAssertTrue(app.staticTexts["Rye Old Fashioned"].exists)
        app.buttons["recipe-old-fashioned"].tap()
        XCTAssertTrue(app.staticTexts["Rye whiskey"].waitForExistence(timeout: 5))
    }

    private func capture(_ name: String, _ app: XCUIApplication) {
        let attachment = XCTAttachment(screenshot: app.screenshot())
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
    }
}
