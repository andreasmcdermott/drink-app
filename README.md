# Pour

A native iPhone cocktail app built with SwiftUI. Requires iOS 17 or later and Xcode 16 or later (verified with Xcode 26.1.1).

## Run

1. Open `Pour.xcodeproj` in Xcode.
2. Select the **Pour** scheme and an iPhone simulator.
3. Press **Run** (⌘R).

To run on your iPhone, choose your Apple development team under **Signing & Capabilities**, change `com.example.pour` to a unique bundle identifier, and select your connected phone. No server, API key, or third-party packages are needed.

## Features

- **For you:** recipes you can make with your saved ingredients, plus drinks one ingredient away.
- **My bar:** a searchable ingredient shelf. Type a comma-separated list, or dictate using the iPhone keyboard microphone. Recognized ingredients are shown before adding; ambiguous or unknown names are reported.
- **Recipes:** 38 recipes, including 19 gin drinks, with ingredients, instructions, optional garnishes, search, spirit filters, and favorites.
- **Add a little:** ranked purchases of one or up to two ingredients, with links to every newly available drink. “I bought this” adds the purchase to your shelf.
- **Recipe details:** 1–12 servings, milliliters or US fluid ounces, and curated variations for selected recipes. Changing a variation updates the quantities and missing-ingredient check.

The ingredient shelf, favorites, and measurement preference persist locally. The app works offline and does not send ingredient data anywhere.

The gin collection includes Clover Club, White Lady, Gin & It, French 75, Aviation, Last Word, Bramble, Southside, Gin Basil Smash, Hanky Panky, Corpse Reviver No. 2, and Martinez alongside the original seven gin recipes. Clover Club includes an aquafaba variation; Gin & It includes an orange-bitters variation. Egg white and aquafaba are measured by volume so they scale with servings.

## Recommendation rules

A recipe is available when every required ingredient is on the shelf. Ice and water are assumed; optional garnishes never block a match. Possession is tracked, not remaining bottle volume.

Shopping recommendations evaluate every useful one- and two-ingredient purchase. They count only original recipes that become newly available, rank by that count, prefer fewer purchases on ties, and discard pairs if either ingredient contributes no additional recipes. Variations are checked on the recipe screen but do not inflate shopping counts. Prices and bottle sizes are not modeled.

Measurements scale before display conversion. One US fluid ounce equals 29.5735295625 ml; ounce displays round to two decimal places. Mint leaves and bitters dashes scale without volume conversion. Multi-serving recipes advise mixing in small batches.

The ingredient parser uses explicit names and aliases. It does not infer brands or parse arbitrary conversation. For example, “limes” matches lime juice, while “rum” asks for a more specific entry such as “white rum.” Recipe variants are hand-authored; there is no generated substitution engine.

## Code

- `Pour/`: SwiftUI screens, local persistence, and bundled cocktail illustrations.
- `Sources/PourCore/`: catalog, ingredient parser, measurements, and recommendation engine. This Swift package can be tested without an iOS simulator.
- `Tests/PourCoreTests/`: catalog integrity, matching, exhaustive purchase-ranking checks, parsing, scaling, and variations.
- `PourUITests/`: an iPhone flow covering ingredient entry, recommendations, serving changes, favorites, persistence across relaunch, and adding a purchase. UI tests use an isolated preferences suite.
- `scripts/generate-icon.mjs`: optional, dependency-free icon generator; the generated icon is already included.
- `Pour/Assets.xcassets/Cocktails/`: one painted illustration per recipe, generated with the built-in image generation tool and bundled for offline use. The shared `CocktailArt` view displays these in recipe rows, featured cards, and detail screens.
- `docs/artwork-prompts.json`: the shared art direction and individual drink prompts. Clover Club is the style reference for the rest of the collection.

## Verify

```sh
swift test
xcodebuild -project Pour.xcodeproj -scheme Pour \
  -destination 'generic/platform=iOS Simulator' build CODE_SIGNING_ALLOWED=NO
```

Run the UI test with **Product → Test** (⌘U) using an iPhone simulator, or:

```sh
xcodebuild -project Pour.xcodeproj -scheme Pour \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro' test CODE_SIGNING_ALLOWED=NO
```

This is an initial working app. App Store signing, distribution, cloud sync, and a larger recipe catalog are not configured.

## Simulator previews

Captured from the passing iPhone 17 Pro UI test: [recommendations](docs/screenshots/for-you.png), [scaled recipe](docs/screenshots/recipe.png), and [shopping suggestions](docs/screenshots/shopping.png).
