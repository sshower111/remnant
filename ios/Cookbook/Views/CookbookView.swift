import SwiftUI

/// The library. First "What can I make?": tap ingredients you have and the recipes that use them
/// come first, each saying how many of its ingredients you have (IngredientSearch, on the phone's
/// copy of every recipe). Then the filters and a photo grid. The search box sits at the bottom,
/// in thumb reach (the user's choice): typing finds recipes by title or ingredient and offers the
/// typed word as an ingredient you have.
struct CookbookView: View {
    @Environment(RecipeStore.self) private var store
    @Environment(\.dynamicTypeSize) private var typeSize
    @State private var path: [Int] = []
    @State private var showSettings = false
    @State private var showAddReel = false
    @State private var filter = Filter.all
    @State private var query = ""
    @FocusState private var searchFocused: Bool

    /// Picked ingredients ("what you have"), one per line; a per-phone convenience.
    @AppStorage("pantry:selected") private var savedPicks = ""
    @State private var ingredients: [PantryIngredient] = []
    /// The recipe just removed (shows the Undo bar).
    @State private var removed: RecipeSummary?
    @State private var removeError: String?

    /// The server's default RECIPE_PANTRY_STAPLES: never scored, so not worth suggesting.
    private static let staples: Set<String> = ["salt", "black pepper", "water", "oil"]

    /// "Cooked" is the API's `tried` mark; "Later" lists posts kept without a recipe yet
    /// (`needs_recipe`).
    enum Filter: String, CaseIterable, Identifiable {
        case all = "All", favorites = "Favorites", cooked = "Cooked", later = "Later"
        var id: Self { self }

        func matches(_ recipe: RecipeSummary) -> Bool {
            switch self {
            case .all, .later: true
            case .favorites: recipe.favorite
            case .cooked: recipe.tried
            }
        }
    }

    private var picks: [String] {
        savedPicks.split(separator: "\n").map(String.init)
    }

    private var trimmedQuery: String {
        query.trimmingCharacters(in: .whitespaces)
    }

    /// The library: every recipe, or with picks, the pantry ranking; Later shows the posts saved
    /// for later instead (no ingredients, so picks don't apply). Typed text keeps the recipes whose
    /// title or ingredients have every word, real ingredients before flavourings ("chicken thigh"
    /// before "chicken powder").
    private var shown: [(recipe: RecipeSummary, match: PantryMatch?)] {
        let recipes = store.recipes ?? []
        let ranked: [(RecipeSummary, PantryMatch?)]
        if filter == .later {
            ranked = store.saved.map { ($0, nil) }
        } else if picks.isEmpty {
            ranked = recipes.map { ($0, nil) }
        } else {
            ranked = IngredientSearch.rank(recipes.map { ($0, recipeIngredients($0)) }, picks: picks,
                                           staples: Self.staples)
                .map { ($0.0, Optional($0.1)) }
        }
        let kept = ranked.filter { filter.matches($0.0) }
        guard !trimmedQuery.isEmpty else { return kept }
        let scored = kept.map { item in
            (item, IngredientSearch.strength(of: query, title: item.0.title, ingredients: recipeIngredients(item.0)))
        }
        return scored.filter { $0.1 == .strong }.map(\.0) + scored.filter { $0.1 == .weak }.map(\.0)
    }

    /// A recipe's ingredients from the phone's copy (every recipe is fetched for offline use).
    private func recipeIngredients(_ recipe: RecipeSummary) -> [Ingredient] {
        store.details[recipe.id]?.ingredients ?? []
    }

    /// Ingredients worth offering: the most used ones, staples and picks left out; while typing,
    /// the ones whose name has every typed word.
    private func suggestions(matching text: String, limit: Int) -> [PantryIngredient] {
        let words = text.lowercased().split(whereSeparator: \.isWhitespace)
        let picked = Set(picks)
        return Array(ingredients.lazy.filter { ingredient in
            !Self.staples.contains(ingredient.name) && !picked.contains(ingredient.name)
                && words.allSatisfy { ingredient.name.contains($0) }
        }.prefix(limit))
    }

    var body: some View {
        NavigationStack(path: $path) {
            // The search bar is below the scroll view, not an inset on it, so the keyboard lifts
            // it (an inset stayed under the keyboard on iOS 27).
            VStack(spacing: 0) {
                library
                bottomBar
            }
            .background(Color.canvas)
            .navigationTitle("Remnant")
            .toolbar {
                ToolbarItemGroup(placement: .topBarTrailing) {
                    Button("Add a reel", systemImage: "plus") { showAddReel = true }
                    Button("Settings", systemImage: "gearshape") { showSettings = true }
                }
            }
            .navigationDestination(for: Int.self) { RecipeDetailView(recipeId: $0) }
        }
        .tint(.ember)
        .task { if store.recipes == nil { await store.load() } }
        .task { await loadIngredients() }
        .task { await store.watchIngestJobs() }
        .sheet(isPresented: $showSettings) { SettingsView() }
        .sheet(isPresented: $showAddReel) { AddReelSheet() }
        // remnant://recipe/<id>, from tapping the Live Activity: show that recipe at its step.
        .onOpenURL { url in
            guard url.scheme == "remnant", url.host() == "recipe", let id = Int(url.lastPathComponent) else { return }
            if path.last != id { path = [id] }
            store.stepToReveal = id
        }
    }

    // MARK: - Library

    private var library: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                if store.isRefreshing {
                    RefreshingChefView().padding(.bottom, Spacing.s)
                }
                summary
                // While typing, results come first; the pantry row is back once the box is cleared.
                if filter != .later, store.recipes?.isEmpty == false, trimmedQuery.isEmpty {
                    pantry.padding(.top, Spacing.l)
                }
                filterPicker.padding(.top, Spacing.l)
                if !store.ingestJobs.isEmpty {
                    VStack(spacing: Spacing.xs) {
                        ForEach(store.ingestJobs) { jobRow($0) }
                    }
                    .padding(.top, Spacing.m)
                }
                content.padding(.top, Spacing.m)
            }
            .padding(.horizontal, Spacing.m)
            .padding(.bottom, Spacing.l)
        }
        .scrollDismissesKeyboard(.immediately)
        .refreshable { await store.refresh() }
    }

    /// "91 recipes from your reels", and an Offline tag when showing the saved copy.
    private var summary: some View {
        VStack(alignment: .leading, spacing: Spacing.xs) {
            Text(subtitle)
                .font(.subheadline)
                .foregroundStyle(Color.textSecondary)
            if let offlineSince = store.offlineSince {
                // The PC is out of reach: everything shown is the phone's saved copy.
                Label("Offline · saved \(offlineSince.formatted(.relative(presentation: .named)))",
                      systemImage: "wifi.slash")
                    .font(.footnote.weight(.medium))
                    .foregroundStyle(Color.textSecondary)
                    .padding(.horizontal, Spacing.s)
                    .padding(.vertical, 6)
                    .background(Color.surface, in: .capsule)
            }
        }
    }

    private var subtitle: String {
        guard let recipes = store.recipes else { return "Your recipes from saved reels" }
        switch filter {
        case .later:
            return store.saved.count == 1 ? "1 reel waiting for its recipe" : "\(store.saved.count) reels waiting for their recipe"
        default:
            return recipes.count == 1 ? "1 recipe from your reels" : "\(recipes.count) recipes from your reels"
        }
    }

    // MARK: - What can I make?

    /// The ingredients you have (tap to remove) and the most used ones (tap to add), in one row.
    private var pantry: some View {
        VStack(alignment: .leading, spacing: Spacing.xs) {
            HStack(alignment: .firstTextBaseline) {
                Text("What can I make?")
                    .font(.headline)
                    .foregroundStyle(Color.textPrimary)
                    .accessibilityAddTraits(.isHeader)
                Spacer()
                if !picks.isEmpty {
                    Button("Clear") { withAnimation(.easeOut(duration: 0.2)) { savedPicks = "" } }
                        .font(.subheadline)
                        .frame(minHeight: minTouch)
                        .contentShape(.rect)
                        .padding(.vertical, -Spacing.s)  // a 44 pt target that doesn't push the hint down
                        .accessibilityLabel("Clear what you have")
                }
            }
            Text(pantryHint)
                .font(.footnote)
                .foregroundStyle(Color.textSecondary)
            ScrollView(.horizontal) {
                HStack(spacing: Spacing.xs) {
                    ForEach(picks, id: \.self) { name in
                        Chip(title: name.capitalizedFirst, isSelected: true) {
                            withAnimation(.easeOut(duration: 0.2)) { removePick(name) }
                        }
                        .accessibilityLabel("\(name.capitalizedFirst), you have it")
                        .accessibilityHint("Removes it")
                    }
                    ForEach(suggestions(matching: "", limit: 12), id: \.name) { ingredient in
                        Chip(title: ingredient.name.capitalizedFirst, systemImage: "plus", count: ingredient.recipeCount) {
                            addPick(ingredient.name)
                        }
                        .accessibilityLabel("Add \(ingredient.name), used in \(ingredient.recipeCount) recipes")
                    }
                }
                .padding(.horizontal, Spacing.m)
            }
            .scrollIndicators(.hidden)
            .padding(.horizontal, -Spacing.m)
        }
    }

    private var pantryHint: String {
        guard !picks.isEmpty else { return "Tap what you have. Recipes that use it come first." }
        let count = shown.count
        return count == 1 ? "1 recipe uses what you have" : "\(count) recipes use what you have"
    }

    // MARK: - Filters

    private var filterPicker: some View {
        Picker("Show", selection: $filter) {
            ForEach(Filter.allCases) { Text($0.rawValue).tag($0) }
        }
        .pickerStyle(.segmented)
        // No animation: an animated feed stuttered on the phone. The list swaps at once.
        .transaction { $0.animation = nil }
        .sensoryFeedback(.selection, trigger: filter)
    }

    // MARK: - Content

    @ViewBuilder
    private var content: some View {
        let shown = shown
        if let error = store.error, store.recipes == nil {
            ChefStateView(animation: .error, title: "Can't reach your PC",
                          message: "Remnant gets recipes from the recipe server on your PC. Check it's on and on the same Wi-Fi. (\(error))") {
                HStack(spacing: Spacing.xs) {
                    Button("Try again", systemImage: "arrow.clockwise") { Task { await store.load() } }
                        .buttonStyle(.primaryPill)
                    Button("Settings") { showSettings = true }
                        .buttonStyle(.secondaryPill)
                }
            }
            .padding(.top, Spacing.xl)
        } else if store.recipes == nil {
            grid { ForEach(0..<4, id: \.self) { _ in RecipeTilePlaceholder() } }
        } else if store.recipes?.isEmpty == true, filter == .all, trimmedQuery.isEmpty {
            emptyLibrary.padding(.top, Spacing.xl)
        } else if shown.isEmpty {
            emptyState.padding(.top, Spacing.xl)
        } else {
            grid {
                ForEach(shown, id: \.recipe.id) { item in
                    RecipeTile(recipe: item.recipe, thumbnailURL: store.thumbnailURL(item.recipe.thumbnailUrl),
                               match: item.match) {
                        Task { await store.toggle(.favorite, for: item.recipe.id) }
                    }
                    .contextMenu { menu(for: item.recipe) }
                }
            }
        }
    }

    /// Two columns of photos; one at the accessibility text sizes.
    private func grid(@ViewBuilder _ tiles: () -> some View) -> some View {
        let count = typeSize.isAccessibilitySize ? 1 : 2
        return LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: Spacing.s, alignment: .top), count: count),
                         alignment: .leading, spacing: Spacing.l, content: tiles)
    }

    @ViewBuilder
    private func menu(for recipe: RecipeSummary) -> some View {
        Button(recipe.favorite ? "Remove from Favorites" : "Add to Favorites",
               systemImage: recipe.favorite ? "heart.slash" : "heart") {
            Task { await store.toggle(.favorite, for: recipe.id) }
        }
        if recipe.ingredientCount > 0 {
            Button(recipe.tried ? "Not Cooked Yet" : "Mark as Cooked",
                   systemImage: recipe.tried ? "arrow.uturn.backward" : "checkmark.circle") {
                Task { await store.toggle(.tried, for: recipe.id) }
            }
        }
        Divider()
        Button("Remove from Library", systemImage: "trash", role: .destructive) { remove(recipe) }
    }

    /// The library has nothing in it yet: how to add the first reels.
    private var emptyLibrary: some View {
        ChefStateView(animation: .empty, title: "Add your first reels",
                      message: "In Instagram, TikTok or YouTube, tap Share, then Remnant. Your PC reads the reel and the recipe lands here in a few minutes.") {
            Button("Paste a link", systemImage: "plus") { showAddReel = true }
                .buttonStyle(.primaryPill)
        }
    }

    @ViewBuilder
    private var emptyState: some View {
        if !trimmedQuery.isEmpty {
            ChefStateView(animation: .empty, title: "No recipes match “\(trimmedQuery)”",
                          message: filter == .later ? "Nothing saved for later matches it."
                                                    : "Try fewer words, or add it to what you have.")
        } else if filter == .later {
            ChefStateView(animation: .empty, title: "Nothing saved for later",
                          message: "When a reel has no recipe yet, save it for later and check again once the creator posts it.")
        } else if filter == .favorites, picks.isEmpty {
            ChefStateView(animation: .empty, title: "No favorites yet",
                          message: "Tap the heart on a recipe to keep it here.")
        } else if filter == .cooked, picks.isEmpty {
            ChefStateView(animation: .empty, title: "Nothing cooked yet",
                          message: "Mark a recipe as cooked once you've made it.")
        } else {
            ChefStateView(animation: .empty, title: "Nothing uses those yet",
                          message: "Try another ingredient, or clear what you have.")
        }
    }

    // MARK: - Reels being added

    /// A reel shared from the share sheet (or pasted, or Check again): being added on the PC, or
    /// just finished. Opens the recipe once there's one to open.
    @ViewBuilder
    private func jobRow(_ job: IngestJob) -> some View {
        let openable = job.status == "done" && job.recipeId.map { id in
            job.recipeStatus == "ready" || store.saved.contains { $0.id == id }
        } == true
        if openable, let id = job.recipeId {
            NavigationLink(value: id) { jobStatus(job) }
                .buttonStyle(.plain)
        } else {
            jobStatus(job)
        }
    }

    private func jobStatus(_ job: IngestJob) -> some View {
        let source = URL(string: job.url)?.host()?.replacing("www.", with: "") ?? "a link"
        let kept = job.recipeId.map { id in store.saved.contains { $0.id == id } } ?? false
        let checkingAgain = job.refresh == true
        let (title, detail): (String, String) = switch (job.status, job.result, job.recipeStatus) {
        case ("queued", _, _): (checkingAgain ? "Waiting to check \(source) again" : "Waiting to add a reel from \(source)",
                                "Your PC reads reels one at a time.")
        case ("running", _, _): (checkingAgain ? "Checking \(source) again…" : "Adding a reel from \(source)…",
                                 "Your PC is reading the video. About two minutes.")
        case ("failed", _, _): ("Couldn't add the reel from \(source)", job.message ?? "Your PC couldn't read it.")
        case (_, _, "ready") where job.result != "skipped" || checkingAgain:
            ("Added \(job.title ?? "a new recipe")", "Tap to open it.")
        case (_, "skipped", _): ("Already in your library: \(job.title ?? source)", "Tap to open it.")
        case _ where kept: ("No recipe yet: \(job.title ?? source)",
                            checkingAgain ? "Still no recipe in the post. It stays in Later."
                                          : "Saved in Later. Check again once the creator posts the recipe.")
        case (_, _, "needs_recipe"): ("No recipe yet: \(job.title ?? source)",
                                      "The post points to a blog or a bio link. Save it for later?")
        default: ("Not a recipe: \(job.title ?? source)",
                  "There's no ingredient list in that post. If the recipe is coming, save it for later.")
        }
        return StatusRow(title: title, detail: detail,
                         onDismiss: job.isActive ? nil : { store.dismissJob(job.id) }) {
            // The chef cooks while the PC reads the video; the error pose if it failed.
            if job.isActive {
                AnimatedChefView(.loading, size: 40)
            } else if job.status == "failed" {
                AnimatedChefView(.error, size: 40)
            } else {
                Image(systemName: "checkmark.circle.fill")
                    .font(.title2)
                    .foregroundStyle(Color.ember)
            }
        } actions: {
            if job.status == "done", let id = job.recipeId, job.recipeStatus != "ready", !kept {
                Button("Save for later", systemImage: "bookmark") {
                    Task { try? await store.setStatus("needs_recipe", for: id) }
                }
                .buttonStyle(.secondaryPill)
            }
        }
        .accessibilityElement(children: .contain)
    }

    // MARK: - Bottom bar

    /// Undo bar, ingredient suggestions and the search box, at the bottom in thumb reach.
    private var bottomBar: some View {
        VStack(alignment: .leading, spacing: Spacing.xs) {
            removedBar
            typedSuggestions
            searchField
        }
        .padding(.horizontal, Spacing.m)
        .padding(.top, Spacing.xs)
        .padding(.bottom, Spacing.xs)
        .background(Color.canvas)
        .overlay(alignment: .top) { Rectangle().fill(Color.hairline).frame(height: 0.5) }
    }

    private var searchField: some View {
        HStack(spacing: Spacing.xs) {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(Color.textSecondary)
                .accessibilityHidden(true)
            TextField("Search recipes or ingredients", text: $query,
                      prompt: Text("Search recipes or ingredients").foregroundStyle(Color.textSecondary))
                .foregroundStyle(Color.textPrimary)
                .focused($searchFocused)
                .submitLabel(.search)
                .autocorrectionDisabled()
                .textInputAutocapitalization(.never)
            if !query.isEmpty {
                Button("Clear search", systemImage: "xmark.circle.fill") { query = "" }
                    .labelStyle(.iconOnly)
                    .foregroundStyle(Color.textSecondary)
                    .frame(width: 32, height: minTouch)
            }
        }
        .padding(.horizontal, Spacing.m)
        .frame(minHeight: minTouch)
        .background(Color.surface, in: .capsule)
    }

    /// While typing: the typed word and matching ingredients, tap to add to what you have (the
    /// server normalizes it: "2 large eggs" -> egg).
    @ViewBuilder
    private var typedSuggestions: some View {
        let typed = trimmedQuery.lowercased()
        let matches = typed.isEmpty ? [] : suggestions(matching: typed, limit: 12)
        let offerTyped = !typed.isEmpty && !picks.contains(typed) && !matches.contains { $0.name == typed }
        if offerTyped || !matches.isEmpty {
            VStack(alignment: .leading, spacing: 2) {
                Text("Add to what you have")
                    .font(.caption)
                    .foregroundStyle(Color.textSecondary)
                ScrollView(.horizontal) {
                    HStack(spacing: Spacing.xs) {
                        ForEach(matches, id: \.name) { ingredient in
                            Chip(title: ingredient.name.capitalizedFirst, systemImage: "plus", count: ingredient.recipeCount) {
                                addPick(ingredient.name)
                            }
                            .accessibilityLabel("Add \(ingredient.name) to what you have")
                        }
                        if offerTyped {
                            Chip(title: "“\(typed)”", systemImage: "plus") { addPick(typed) }
                                .accessibilityLabel("Add \(typed) to what you have")
                        }
                    }
                    .padding(.horizontal, Spacing.m)
                }
                .scrollIndicators(.hidden)
                .padding(.horizontal, -Spacing.m)
            }
        }
    }

    /// "Removed “Title” · Undo" for a few seconds after removing a recipe.
    @ViewBuilder
    private var removedBar: some View {
        if let recipe = removed {
            HStack(spacing: Spacing.s) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Removed")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(Color.textSecondary)
                    Text(recipe.title)
                        .font(.subheadline)
                        .foregroundStyle(Color.textPrimary)
                        .lineLimit(2)
                }
                Spacer(minLength: Spacing.xs)
                Button("Undo") {
                    removed = nil
                    Task { await store.unhide(recipe.id) }
                }
                .buttonStyle(.pill(.selected))
            }
            .padding(.leading, Spacing.m)
            .padding(.trailing, Spacing.xs)
            .padding(.vertical, Spacing.xs)
            .background(Color.surface, in: .rect(cornerRadius: Radius.medium))
            .transition(.move(edge: .bottom).combined(with: .opacity))
            .task(id: recipe.id) {
                try? await Task.sleep(for: .seconds(5))
                withAnimation { removed = nil }
            }
        } else if let removeError {
            Text(removeError)
                .font(.subheadline)
                .foregroundStyle(Color.textPrimary)
                .padding(Spacing.s)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.surface, in: .rect(cornerRadius: Radius.medium))
                .task {
                    try? await Task.sleep(for: .seconds(4))
                    self.removeError = nil
                }
        }
    }

    // MARK: - Actions

    /// Removing hides the recipe on the PC (it stays in the database); Undo brings it back.
    private func remove(_ recipe: RecipeSummary) {
        Task {
            if await store.hide(recipe.id) {
                removed = recipe
                removeError = nil
            } else {
                removeError = "Removing needs your PC, which is out of reach right now."
            }
        }
    }

    private func addPick(_ name: String) {
        query = ""
        guard !name.isEmpty, !picks.contains(name) else { return }
        withAnimation(.easeOut(duration: 0.2)) { savedPicks = (picks + [name]).joined(separator: "\n") }
    }

    private func removePick(_ name: String) {
        savedPicks = picks.filter { $0 != name }.joined(separator: "\n")
    }

    private func loadIngredients() async {
        guard ingredients.isEmpty else { return }
        ingredients = (try? await APIClient.current().ingredients()) ?? []
    }
}

extension String {
    /// "soy sauce" -> "Soy sauce".
    var capitalizedFirst: String { prefix(1).uppercased() + dropFirst() }
}

#Preview {
    CookbookView().environment(RecipeStore())
}
