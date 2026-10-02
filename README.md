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
- **Recipe details:** 1–12 servings, milliliters or US fluid ounces, and curated variations for selected recipes. “Make it your own” offers plain-text adjustments with amounts in the chosen units and serving count.

The ingredient shelf, favorites, and measurement preference persist locally. The app works offline and does not send ingredient data anywhere.

The gin collection includes Clover Club, White Lady, Gin & It, French 75, Aviation, Last Word, Bramble, Southside, Gin Basil Smash, Hanky Panky, Corpse Reviver No. 2, and Martinez alongside the original seven gin recipes. Clover Club includes an aquafaba variation; Gin & It includes an orange-bitters variation. Egg white and aquafaba are measured by volume so they scale with servings.

## Recommendation rules

A recipe is available when every required ingredient for its original version or a curated variation is on the shelf. Recommendations prefer the version needing the fewest missing ingredients, with the original winning ties. Ice and water are assumed; optional garnishes never block a match. Possession is tracked, not remaining bottle volume.

Shopping recommendations evaluate every useful one- and two-ingredient purchase. They count each newly available drink once across its original and curated variations, rank by that count, prefer fewer purchases on ties, and discard pairs if either ingredient contributes no additional recipes. Drinks already possible with a substitution are excluded. Prices and bottle sizes are not modeled.

Every volume ingredient has independently authored metric and imperial quantities. Switching units selects that recipe specification, then scales it by servings. Ounces use familiar fractions such as ¾ oz and 1½ oz; small pours use teaspoons. The two specifications are practical recipe proportions, not exact conversions. Mint leaves and bitters dashes scale without volume conversion. Multi-serving recipes advise mixing in small batches.

The ingredient parser uses explicit names and aliases. It does not infer brands or parse arbitrary conversation. For example, “limes” matches lime juice, while “rum” asks for a more specific entry such as “white rum.” Recipe variants are hand-authored and never combined automatically. Rye can replace bourbon in the Old Fashioned, Whiskey Sour, and Boulevardier; the Manhattan already offers bourbon in place of rye. Other supported variations include orange bitters in an Old Fashioned and aquafaba in a Clover Club. Suggested versions are labeled in discovery, recipe lists, and shopping results, and open with the selected ingredients and instructions. “Make it your own” shows each adjustment as a self-contained tip without undoing other swaps. When viewing a substitution, a separate tip explains how to make the original. Reading tips does not change the ingredient list or instructions.

## Code

- `Pour/`: SwiftUI screens, local persistence, and bundled cocktail illustrations.
- `Sources/PourCore/`: catalog, ingredient parser, measurements, and recommendation engine. This Swift package can be tested without an iOS simulator.
- `Tests/PourCoreTests/`: catalog integrity, matching, exhaustive purchase-ranking checks, parsing, scaling, and variations.
- `PourUITests/`: an iPhone flow covering ingredient entry, recommendations, serving changes, favorites, persistence across relaunch, and adding a purchase. UI tests use an isolated preferences suite.
- `docs/app-icon-prompt.md`: prompt for the ChatGPT-generated Clover Club icon, bundled as an opaque 1024 × 1024 PNG.
- `Pour/Assets.xcassets/Cocktails/`: one painted illustration per recipe, generated with the built-in image generation tool and bundled for offline use. The shared `CocktailArt` view displays these without edge fading. Each artwork container uses a color sampled from that illustration’s paper border. Run `swift scripts/generate-paper-colors.swift` after replacing cocktail artwork to refresh those asset colors.
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

Captured from the passing iPhone 17 Pro UI test: [recommendations](docs/screenshots/for-you.png), [scaled recipe](docs/screenshots/recipe.png), [ounce measurements](docs/screenshots/recipe-ounces.png), and [shopping suggestions](docs/screenshots/shopping.png).

Substitution flow: [suggested rye swap](docs/screenshots/substitution-suggestion.png) and [scaled rye recipe](docs/screenshots/substitution-recipe.png).

Recipe tips: [text-only mixing suggestions](docs/screenshots/mixing-tips.png).
