# Pour website

A standalone marketing page. Open `index.html` directly in a browser, or serve this directory with any static web server. There are no dependencies, JavaScript, external fonts, trackers, or build steps.

Upload the contents of this directory to a static host. Keep `assets/` alongside `index.html` and `styles.css`; all asset paths are relative, so deployment under a subdirectory works too.

The page currently says "Coming to iPhone". When a public App Store or TestFlight link is available, update the availability text and primary link in `index.html`. Add a canonical URL and an absolute Open Graph image URL once the site's public address is known.

Images are optimized copies of Pour's existing cocktail illustrations, icon, and simulator screenshot. Edit the originals in the app when updating its artwork. The site assets are self-contained and do not depend on the app's directory structure.

`privacy.html` and `support.html` are linked from every page's footer. Support currently uses the public GitHub issue tracker. Replace that contact route in both the site and `Pour/PrivacyView.swift` if a support email is chosen.

Once this directory is hosted, use its public `privacy.html` and `support.html` URLs in App Store Connect. No public hosting address is configured yet. Review the privacy policy's hosting paragraph against the chosen provider and any analytics added later.

The in-app policy is available from the hand icon in My bar and works offline. Keep its text in `Pour/PrivacyView.swift` consistent with `privacy.html` when updating the policy.
