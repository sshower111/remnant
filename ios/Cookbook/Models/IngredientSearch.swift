import Foundation

/// Finds recipes by what's in them, on the phone's copy of every recipe (RecipeStore.details),
/// so it's instant and works offline. "beef" finds beef, beef slice and ground beef;
/// "chicken" also finds cuts that don't say chicken (drumstick, wing). Flavourings made from
/// the ingredient (chicken powder, beef stock) still count, but rank after the real thing.
enum IngredientSearch {
    enum Strength: Int, Comparable {
        case none, weak, strong
        static func < (a: Self, b: Self) -> Bool { a.rawValue < b.rawValue }
    }

    /// Cuts and products named without their animal.
    private static let cuts: [String: [String]] = [
        "chicken": ["drumstick", "drumette", "wing", "thigh"],
        "beef": ["steak", "brisket", "short rib", "oxtail", "sirloin", "ribeye", "rib eye", "flank", "chuck",
                 "tenderloin"],
        "pork": ["bacon", "ham", "pancetta", "prosciutto", "lard", "trotter", "spare rib", "sparerib", "char siu",
                 "lap cheong", "chinese sausage"],
    ]

    /// Words that make an ingredient a flavouring, broth or by-product rather than the thing itself.
    private static let flavorings: Set<String> = [
        "powder", "bouillon", "stock", "broth", "cube", "granule", "seasoning", "sauce", "extract", "essence",
        "paste", "fat", "lard", "oil", "carcass", "bone", "flavor", "flavour",
    ]

    /// How well `term` (one word or phrase, as typed) describes this ingredient.
    static func strength(of term: String, for ingredient: Ingredient) -> Strength {
        let term = term.lowercased().trimmingCharacters(in: .whitespaces)
        guard !term.isEmpty else { return .none }
        let names = [ingredient.name.lowercased(), ingredient.rawName.lowercased()]
        let named = names.contains { contains(term, in: $0) }
            || (cuts[singular(term)] ?? []).contains { cut in names.contains { contains(cut, in: $0) } }
        guard named else { return .none }
        // A flavouring word the search didn't ask for: "chicken powder" for "chicken".
        let words = Set(ingredient.name.lowercased().split(separator: " ").map { singular(String($0)) })
        let asked = Set(term.split(separator: " ").map { singular(String($0)) })
        return words.subtracting(asked).isDisjoint(with: flavorings) ? .strong : .weak
    }

    /// How well a typed search fits a recipe: every word must be in the title or an ingredient;
    /// the weakest word decides.
    static func strength(of query: String, title: String, ingredients: [Ingredient]) -> Strength {
        let words = query.lowercased().split(whereSeparator: \.isWhitespace).map(String.init)
        guard !words.isEmpty else { return .strong }
        let title = title.lowercased()
        return words.map { word in
            if title.contains(word) { return .strong }
            return ingredients.map { strength(of: word, for: $0) }.max() ?? .none
        }.min() ?? .none
    }

    /// The pantry ranking for picked ingredients ("what you have"): recipes using at least one,
    /// those using the most first (real ingredients before flavourings), then the ones needing
    /// the fewest others. Staples (salt, water...) are never counted.
    static func rank(_ recipes: [(RecipeSummary, [Ingredient])], picks: [String], staples: Set<String>)
        -> [(RecipeSummary, PantryMatch)] {
        let scored = recipes.compactMap { recipe, ingredients -> (RecipeSummary, PantryMatch, Int)? in
            let names = Array(Set(ingredients.map(\.name)).subtracting(staples)).sorted()
            let used = picks.map { pick in ingredients.map { strength(of: pick, for: $0) }.max() ?? .none }
            let matched = used.filter { $0 > .none }.count
            guard matched > 0 else { return nil }
            let have = Set(ingredients.filter { ingredient in
                picks.contains { strength(of: $0, for: ingredient) > .none }
            }.map(\.name))
            let match = PantryMatch(recipeId: recipe.id, matched: matched,
                                    missing: names.filter { !have.contains($0) })
            return (recipe, match, used.filter { $0 == .strong }.count)
        }
        return scored.sorted { a, b in
            if a.2 != b.2 { return a.2 > b.2 }
            if a.1.matched != b.1.matched { return a.1.matched > b.1.matched }
            if a.1.missingCount != b.1.missingCount { return a.1.missingCount < b.1.missingCount }
            return a.0.title.localizedCaseInsensitiveCompare(b.0.title) == .orderedAscending
        }.map { ($0.0, $0.1) }
    }

    /// `phrase` as a whole word or phrase in `text`, plurals allowed ("egg" isn't in "eggplant").
    private static func contains(_ phrase: String, in text: String) -> Bool {
        let stem = NSRegularExpression.escapedPattern(for: singular(phrase))
        return text.range(of: "\\b\(stem)(?:s|es)?\\b", options: .regularExpression) != nil
    }

    /// "wings" -> "wing", "tomatoes" -> "tomato"; very short words and "-ss" are left alone.
    private static func singular(_ word: String) -> String {
        if word.count > 4, word.hasSuffix("oes") { return String(word.dropLast(2)) }
        if word.count > 3, word.hasSuffix("s"), !word.hasSuffix("ss") { return String(word.dropLast()) }
        return word
    }
}
