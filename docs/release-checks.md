# Release checks

Run on 2026-10-05 against `6a0a2b0` plus the fixes on this branch, using Xcode with the iOS 26.1 simulator runtime. No iOS 17 or 18 runtime was installed, so the iOS 17 deployment target was built but not run.

| Check | Result | How |
| --- | --- | --- |
| Small screens | Pass | Full UI suite on iPhone SE (3rd generation, 375 × 667 pt) and iPhone 17 Pro. |
| Larger text | Pass after fixes | Accessibility audit and screenshots of every screen at Large (default) and Accessibility XXXL. |
| VoiceOver | Pass after fixes | Accessibility audit plus a review of the element tree on each screen. |
| Saved ingredients after updates | Pass | Installed the first build (`5a3d45a`), saved a shelf, a favorite, and ounces, then installed this build over it. |
| Offline use | Pass | No networking APIs, URLs, or remote images. All 59 illustrations and paper colors are bundled. |

## Fixes

- **Larger text:** at accessibility sizes, recipe ingredients broke words mid-line ("whisk-ey") beside their amounts, and recipe rows squeezed titles beside the artwork. Both now stack vertically. The home headline, wordmark, and small-caps labels used fixed sizes and now scale.
- **VoiceOver:** section titles and recipe names are headings. Each ingredient reads as one item, such as "Rye whiskey, 60 ml". Steps read "Step 1, …" instead of "zero one". Each "I bought" button names its ingredients rather than repeating "I bought this". Decorative basket and arrow icons are hidden.
- **Touch targets:** drink links in Add a little were 18 pt tall and are now at least 44 pt.
- **Contrast:** garnish text on the tinted card was 4.2:1 and now uses the ink color. Secondary text on the background and on every artwork paper color measures at least 4.6:1.

## Updates

Storage keys (`pantry`, `favorites`, `unit`), the bundle identifier, and every ingredient and recipe ID are unchanged since the first commit. After the upgrade, the same 8 ingredients, favorite, and unit were kept. The larger catalog now makes 8 drinks from them instead of 7.

## Automated coverage

`testAccessibilityAuditAtDefaultTextSize` and `testAccessibilityAuditAtLargestTextSize` audit each screen while scrolling. They ignore contrast, clipping, and unattributed text-detection results. Those checks are unreliable under the iOS 26 translucent bars, so contrast is measured from the palette instead. The Recipes screen is audited with Ready to mix enabled, because auditing the full 59-recipe list times out.

The upgrade and offline checks are manual. Repeat them whenever storage keys or catalog IDs change, or when networking is added.
