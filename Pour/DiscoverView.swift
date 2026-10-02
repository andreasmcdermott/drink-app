import SwiftUI
import PourCore

struct DiscoverView: View {
    @Environment(BarStore.self) private var bar
    let openBar: () -> Void
    private var almost: [Recipe] {
        Catalog.recipes.filter { $0.missing(from: bar.pantry).count == 1 }
    }

    var body: some View {
        Screen {
            HStack(alignment: .firstTextBaseline) {
                Text("pour").font(.system(size: 38, weight: .semibold, design: .serif)).tracking(-2)
                Circle().fill(Palette.gold).frame(width: 8, height: 8)
                Spacer()
                Eyebrow(text: "Your home bar")
            }.padding(.top, 8)
            VStack(alignment: .leading, spacing: 10) {
                Text("Good drinks.\nAlready on hand.")
                    .font(.system(size: 38, weight: .regular, design: .serif)).tracking(-1)
                    .fixedSize(horizontal: false, vertical: true)
                Text(bar.pantry.isEmpty ? "A few ingredients. A world of possibilities. Start with what’s on your shelf." : "You have \(bar.pantry.count) ingredients and \(bar.available.count) drink\(bar.available.count == 1 ? "" : "s") ready to make.")
                    .font(.subheadline).foregroundStyle(Palette.secondary).lineSpacing(4)
            }
            if bar.pantry.isEmpty {
                VStack(spacing: 12) {
                    CocktailArt(recipe: Catalog.recipes[0]).frame(height: 175)
                    Text("Let’s stock your shelf").font(.system(.title2, design: .serif))
                    Text("Choose your spirits, mixers, and extras. We’ll find the recipes that fit.")
                        .font(.subheadline).foregroundStyle(Palette.secondary).multilineTextAlignment(.center)
                    Button("Add my ingredients", action: openBar).buttonStyle(PrimaryButton()).padding(.top, 8)
                }.padding(24).background(Palette.paper(Catalog.recipes[0]), in: RoundedRectangle(cornerRadius: 28))
            } else if let featured = bar.available.first {
                NavigationLink { RecipeDetailView(recipe: featured) } label: {
                    VStack(alignment: .leading, spacing: 12) {
                        HStack { Eyebrow(text: "Tonight’s first pour"); Spacer(); Image(systemName: "arrow.up.right") }
                        CocktailArt(recipe: featured).frame(height: 185)
                        Text(featured.name).font(.system(.largeTitle, design: .serif))
                        Text(featured.subtitle).font(.subheadline).foregroundStyle(Palette.secondary)
                        Pill(text: "Everything’s on your shelf")
                    }.padding(24).background(Palette.paper(featured), in: RoundedRectangle(cornerRadius: 28))
                }.buttonStyle(.plain)
            } else {
                ContentUnavailableView("Your first drink is close", systemImage: "wineglass", description: Text("Add more ingredients to My bar, or see Add a little for useful purchases."))
            }
            if !bar.available.isEmpty {
                SectionTitle(title: "Ready when you are", caption: "Made with what you already have.")
                ForEach(bar.available) { RecipeRow(recipe: $0) }
            }
            if !almost.isEmpty {
                SectionTitle(title: "One ingredient away", caption: "A small addition opens up something new.")
                ForEach(almost.prefix(5)) { RecipeRow(recipe: $0) }
            }
            if bar.pantry.isEmpty {
                SectionTitle(title: "Meet the classics", caption: "A few good places to start.")
                ForEach(Catalog.recipes.prefix(3)) { RecipeRow(recipe: $0) }
            }
            Text("Ice and water are assumed. Garnishes are optional.")
                .font(.caption).foregroundStyle(Palette.secondary)
        }.toolbar(.hidden, for: .navigationBar)
    }
}
