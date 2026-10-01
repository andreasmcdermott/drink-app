import SwiftUI
import PourCore

struct PantryView: View {
    @Environment(BarStore.self) private var bar
    @State private var search = ""
    @State private var entry = ""
    @State private var showEntry = false
    @State private var showClear = false
    private var parsed: (matched: Set<String>, unknown: [String]) {
        IngredientParser.parse(entry, catalog: Catalog.ingredients)
    }

    var body: some View {
        Screen {
            SectionTitle(title: "What’s on your shelf?", caption: "\(bar.pantry.count) ingredients · \(bar.available.count) drinks ready to mix")
            Button { showEntry = true } label: {
                Label("Type a list of ingredients", systemImage: "text.bubble")
            }.buttonStyle(PrimaryButton())
            Text("Tap to add or remove an ingredient. Your shelf is saved on this iPhone.")
                .font(.subheadline).foregroundStyle(Palette.secondary)
            ForEach(IngredientCategory.allCases, id: \.self) { category in
                let items = Catalog.ingredients.filter {
                    $0.category == category && (search.isEmpty || ([$0.name] + $0.aliases).contains { $0.localizedCaseInsensitiveContains(search) })
                }
                if !items.isEmpty {
                    VStack(alignment: .leading, spacing: 10) {
                        Eyebrow(text: category.rawValue)
                        ForEach(items) { ingredient in
                            Button { bar.toggle(ingredient.id) } label: {
                                HStack {
                                    Text(ingredient.name).font(.body)
                                    Spacer()
                                    Image(systemName: bar.pantry.contains(ingredient.id) ? "checkmark.circle.fill" : "plus.circle")
                                        .font(.title3)
                                }.padding(15)
                                    .foregroundStyle(bar.pantry.contains(ingredient.id) ? Palette.green : Palette.ink)
                                    .background(bar.pantry.contains(ingredient.id) ? Palette.green.opacity(0.09) : .white.opacity(0.8), in: RoundedRectangle(cornerRadius: 14))
                            }.buttonStyle(.plain)
                                .accessibilityLabel("\(ingredient.name), \(bar.pantry.contains(ingredient.id) ? "on your shelf" : "not on your shelf")")
                                .accessibilityHint("Double tap to \(bar.pantry.contains(ingredient.id) ? "remove" : "add")")
                        }
                    }
                }
            }
            Text("Simple syrup means equal parts sugar and water. Add fresh lemons or limes as their juice. Ice and water don’t need to be added.")
                .font(.footnote).foregroundStyle(Palette.secondary)
            if !bar.pantry.isEmpty {
                Button("Clear my shelf", role: .destructive) { showClear = true }.font(.footnote)
            }
        }.navigationTitle("My bar")
            .searchable(text: $search, prompt: "Find an ingredient")
            .confirmationDialog("Remove all ingredients from your shelf?", isPresented: $showClear, titleVisibility: .visible) {
                Button("Clear shelf", role: .destructive) { bar.pantry.removeAll() }
            }
            .sheet(isPresented: $showEntry) {
                NavigationStack {
                    Screen {
                        SectionTitle(title: "Tell us what you have", caption: "Separate ingredients with commas or “and”. For example: gin, limes, simple syrup.")
                        TextEditor(text: $entry).frame(height: 110).padding(12)
                            .scrollContentBackground(.hidden).background(.white, in: RoundedRectangle(cornerRadius: 16))
                            .accessibilityLabel("Ingredient list")
                        if !parsed.matched.isEmpty {
                            Eyebrow(text: "Recognized ingredients")
                            ForEach(parsed.matched.sorted(), id: \.self) { id in
                                Label(Catalog.name(for: id), systemImage: "checkmark.circle.fill")
                            }
                        }
                        if !parsed.unknown.isEmpty {
                            Text("Couldn’t match: \(parsed.unknown.joined(separator: ", ")). Try a specific name, such as white rum or sweet vermouth.")
                                .font(.subheadline).foregroundStyle(Palette.secondary)
                        }
                        Button("Add \(parsed.matched.count) ingredients") {
                            bar.pantry.formUnion(parsed.matched); entry = ""; showEntry = false
                        }.buttonStyle(PrimaryButton()).disabled(parsed.matched.isEmpty)
                        Text("Use the iPhone keyboard’s microphone to dictate your list.").font(.footnote).foregroundStyle(Palette.secondary)
                    }.navigationTitle("Add ingredients").navigationBarTitleDisplayMode(.inline)
                        .toolbar { ToolbarItem(placement: .cancellationAction) { Button("Cancel") { showEntry = false } } }
                }
            }
    }
}
