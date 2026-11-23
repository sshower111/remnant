import SwiftUI
import UIKit

/// One recipe, photo first: the full-bleed photo with the title and creator over it, the actions
/// as pills (Start cooking first), the key facts in labeled columns, then ingredients and steps.
struct RecipeDetailView: View {
    let recipeId: Int
    @Environment(RecipeStore.self) private var store
    @Environment(\.openURL) private var openURL
    @Environment(\.scenePhase) private var scenePhase
    @State private var error: String?
    @State private var showFullCaption = false
    /// Cooking progress; the Live Activity's ‹ › buttons can move it while the app is away.
    @State private var session: CookingSession?
    /// Cook mode, full screen.
    @State private var cooking = false
    /// The whole ingredient list, for shopping.
    @State private var showIngredientList = false
    /// "Check again" sent and not yet confirmed by the PC (no recipe yet posts).
    @State private var checkRequested = false
    @State private var checkError: String?
    /// Watch found no app for the post (e.g. Instagram not installed): offer Safari instead.
    @State private var appMissing: AppMissing?
    /// The photo has scrolled under the bar: the bar gets its background and the title.
    @State private var pastHero = false

    private static let platformNames = ["instagram": "Instagram", "youtube": "YouTube", "tiktok": "TikTok"]

    var body: some View {
        Group {
            if let recipe = store.details[recipeId] {
                content(recipe)
            } else if let error {
                ParseErrorView(title: "Couldn't open this recipe", message: error) {
                    Button("Try again", systemImage: "arrow.clockwise") { Task { await load() } }
                        .buttonStyle(.primaryPill)
                }
                .padding(Spacing.xl)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                ChefLoadingView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .background(Color.canvas)
        .navigationBarTitleDisplayMode(.inline)
        .navigationTitle(pastHero ? (store.details[recipeId]?.title ?? "") : "")
        // A material strip under the bar once the photo is gone. Not .toolbarBackground: that swaps
        // the shared bar appearance and the library's serif large title came back plain.
        .overlay(alignment: .top) {
            Rectangle()
                .fill(.bar)
                .frame(height: 0)
                .ignoresSafeArea(edges: .top)
                .opacity(pastHero ? 1 : 0)
                .animation(.easeOut(duration: 0.15), value: pastHero)
                .allowsHitTesting(false)
                .accessibilityHidden(true)
        }
        .toolbar {
            if let recipe = store.details[recipeId] {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        Task { await store.toggle(.favorite, for: recipeId) }
                    } label: {
                        Image(systemName: recipe.favorite ? "heart.fill" : "heart")
                            .foregroundStyle(recipe.favorite ? Color.ember : Color.textPrimary)
                            .symbolEffect(.bounce, value: recipe.favorite)
                    }
                    .accessibilityLabel(recipe.favorite ? "Remove from favorites" : "Add to favorites")
                    .sensoryFeedback(.selection, trigger: recipe.favorite)
                }
            }
        }
        .alert(item: $appMissing) { missing in
            Alert(title: Text("\(missing.name) isn't installed"),
                  message: Text("The video opens in the \(missing.name) app so you stay signed in. Install it, or open the reel in Safari, which may ask you to sign in."),
                  primaryButton: .default(Text("Open in Safari")) { openURL(missing.url) },
                  secondaryButton: .cancel())
        }
        .fullScreenCover(isPresented: $cooking) {
            if let recipe = store.details[recipeId], let session {
                CookModeView(recipe: recipe, session: session,
                             onMarkCooked: { Task { await store.toggle(.tried, for: recipeId) } })
            }
        }
        .sheet(isPresented: $showIngredientList) {
            if let recipe = store.details[recipeId] {
                IngredientListSheet(title: recipe.title, yieldLabel: recipe.yieldLabel, ingredients: recipe.ingredients)
            }
        }
        // Refresh on every visit (steps may have been re-parsed on the PC); cached copy shows meanwhile.
        .task { await load() }
        // Back to the library: leaving the app no longer starts the island for this recipe.
        .onDisappear {
            if LiveActivityController.onScreen?.id == recipeId, !cooking { LiveActivityController.onScreen = nil }
        }
        .onChange(of: scenePhase) { _, phase in
            if phase == .active { session?.reload() }
        }
        // Opened from the Live Activity: straight into cook mode at its step.
        .onChange(of: store.stepToReveal, initial: true) { _, id in
            guard id == recipeId, let recipe = store.details[recipeId], !recipe.steps.isEmpty else { return }
            store.stepToReveal = nil
            updateSession()
            Task {
                try? await Task.sleep(for: .milliseconds(350))  // let the push finish first
                cooking = true
            }
        }
    }

    private func load() async {
        do {
            try await store.loadRecipe(recipeId)
            error = nil
        } catch {
            if store.details[recipeId] == nil { self.error = error.localizedDescription }
        }
        updateSession()
    }

    /// One session per visit; a fresh one only if a re-parse on the PC changed the steps.
    private func updateSession() {
        guard let recipe = store.details[recipeId] else { return }
        LiveActivityController.onScreen = recipe
        if let session, session.steps == recipe.steps {
            session.reload()
        } else {
            session = CookingSession(recipe: recipe)
        }
    }

    // MARK: - Layout

    private func content(_ recipe: Recipe) -> some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                hero(recipe)
                VStack(alignment: .leading, spacing: Spacing.l) {
                    actions(recipe)
                    if !recipe.ingredients.isEmpty {
                        MetadataColumns(items: facts(recipe))
                    }
                    caption(recipe)
                    if recipe.ingredients.isEmpty {
                        noRecipeYet(recipe)
                    } else {
                        ingredients(recipe)
                        steps(recipe)
                    }
                }
                .padding(.horizontal, Spacing.m)
                .padding(.top, Spacing.m)
                .padding(.bottom, Spacing.xl)
            }
        }
        .ignoresSafeArea(edges: .top)
        // The photo is 5:4 of the width; past its foot (less the bar), the bar takes over.
        .trackingScroll(past: UIScreenWidth.value * 5 / 4 - 120, into: $pastHero)
    }

    /// The photo edge to edge, the title and creator on a scrim at its foot.
    private func hero(_ recipe: Recipe) -> some View {
        Color.surface
            .aspectRatio(4 / 5, contentMode: .fit)
            .overlay {
                Thumbnail(url: store.thumbnailURL(recipe.thumbnailUrl), title: recipe.title, initialSize: 96, maxPoints: 500)
            }
            .overlay(alignment: .bottom) { PhotoScrim().frame(height: 320) }
            .overlay(alignment: .bottomLeading) {
                VStack(alignment: .leading, spacing: Spacing.xxs) {
                    Text(recipe.title)
                        .font(.display)
                        .foregroundStyle(.white)
                        .lineLimit(4)
                        .minimumScaleFactor(0.7)
                        .accessibilityAddTraits(.isHeader)
                    if let uploader = recipe.uploader {
                        Text("by \(uploader)")
                            .font(.subheadline.weight(.medium))
                            .foregroundStyle(.white.opacity(0.85))
                    }
                }
                .padding(.horizontal, Spacing.m)
                .padding(.bottom, Spacing.m)
                .accessibilityElement(children: .combine)
            }
            .clipped()
            .accessibilityElement(children: .contain)
    }

    /// Start cooking (or Resume) first, then Watch, Shopping list and Cooked.
    private func actions(_ recipe: Recipe) -> some View {
        ScrollView(.horizontal) {
            HStack(spacing: Spacing.xs) {
                if !recipe.steps.isEmpty, let session {
                    Button(startTitle(session), systemImage: "frying.pan") { cooking = true }
                        .buttonStyle(.primaryPill)
                }
                watchButton(recipe, primary: recipe.steps.isEmpty && !recipe.ingredients.isEmpty)
                if !recipe.ingredients.isEmpty {
                    Button("Shopping list", systemImage: "checklist") { showIngredientList = true }
                        .buttonStyle(.secondaryPill)
                    Button {
                        Task { await store.toggle(.tried, for: recipeId) }
                    } label: {
                        Label(recipe.tried ? "Cooked" : "Mark as cooked", systemImage: recipe.tried ? "checkmark.circle.fill" : "checkmark.circle")
                    }
                    .buttonStyle(.pill(recipe.tried ? .selected : .secondary))
                    .accessibilityAddTraits(recipe.tried ? .isSelected : [])
                    .sensoryFeedback(.success, trigger: recipe.tried) { _, tried in tried }
                }
            }
            .padding(.horizontal, Spacing.m)
        }
        .scrollIndicators(.hidden)
        .padding(.horizontal, -Spacing.m)
    }

    /// "Start cooking", or "Resume · Step 4" when part-way through.
    private func startTitle(_ session: CookingSession) -> String {
        if session.allDone { return "Cook again" }
        return session.cookingStarted ? "Resume · Step \(session.active + 1)" : "Start cooking"
    }

    private func facts(_ recipe: Recipe) -> [MetadataColumns.Item] {
        var items = [MetadataColumns.Item(label: "Ingredients", value: "\(recipe.ingredients.count)")]
        if !recipe.steps.isEmpty { items.append(.init(label: "Steps", value: "\(recipe.steps.count)")) }
        if let yieldLabel = recipe.yieldLabel { items.append(.init(label: "Makes", value: yieldLabel.capitalizedFirst)) }
        if let platform = recipe.video.platform.flatMap({ Self.platformNames[$0] }) {
            items.append(.init(label: "From", value: platform))
        }
        return items
    }

    @ViewBuilder
    private func caption(_ recipe: Recipe) -> some View {
        let caption = recipe.caption
        if !caption.isEmpty {
            VStack(alignment: .leading, spacing: Spacing.xxs) {
                Text(caption)
                    .font(.subheadline)
                    .foregroundStyle(Color.textSecondary)
                    .lineLimit(showFullCaption ? nil : 3)
                    .fixedSize(horizontal: false, vertical: true)
                Button(showFullCaption ? "Show less" : "Show more") {
                    withAnimation(.easeOut(duration: 0.2)) { showFullCaption.toggle() }
                }
                .font(.subheadline.weight(.semibold))
                .frame(minHeight: minTouch)
                .accessibilityLabel(showFullCaption ? "Show less of the caption" : "Show the whole caption")
            }
        }
    }

    // MARK: - Watch

    /// Watch: starts the Live Activity on the current step, then opens the post in its app
    /// (Instagram etc.), so the step follows along in the Dynamic Island. Only the app: a browser
    /// asks people to sign in, so without the app installed it asks first.
    @ViewBuilder
    private func watchButton(_ recipe: Recipe, primary: Bool) -> some View {
        if let url = URL(string: recipe.video.url) {
            let platform = recipe.video.platform.flatMap { Self.platformNames[$0] }
            Button {
                Task {
                    await LiveActivityController.start(recipe)
                    let opened = await UIApplication.shared.open(url, options: [.universalLinksOnly: true])
                    if !opened {
                        await LiveActivityController.endAll()  // still here: no island needed
                        appMissing = AppMissing(name: platform ?? "the post's app", url: url)
                    }
                }
            } label: {
                Label("Watch", systemImage: "play.rectangle")
            }
            .buttonStyle(.pill(primary ? .primary : .secondary))
            .accessibilityLabel(platform.map { "Watch on \($0)" } ?? "Watch the video")
        }
    }

    struct AppMissing: Identifiable {
        let name: String
        let url: URL
        var id: String { url.absoluteString }
    }

    // MARK: - Ingredients and steps

    private func ingredients(_ recipe: Recipe) -> some View {
        VStack(alignment: .leading, spacing: Spacing.s) {
            SectionHeader(title: "Ingredients") {
                if let yieldLabel = recipe.yieldLabel {
                    Text(yieldLabel)
                        .font(.subheadline)
                        .foregroundStyle(Color.textSecondary)
                }
            }
            IngredientRow(ingredients: recipe.ingredients)
                .padding(.horizontal, -Spacing.m)
            if let page = recipe.recipePageUrl.flatMap(URL.init(string:)) {
                Link(destination: page) {
                    Label("Full recipe on the creator's site", systemImage: "arrow.up.right")
                        .font(.subheadline.weight(.medium))
                        .frame(minHeight: minTouch)
                }
            }
        }
    }

    /// Every step, numbered; tap one to cook from there. Ticked-off steps are dimmed.
    @ViewBuilder
    private func steps(_ recipe: Recipe) -> some View {
        VStack(alignment: .leading, spacing: Spacing.s) {
            SectionHeader("Steps")
            if recipe.steps.isEmpty {
                Text("This reel doesn't describe the method. Watch it to follow along.")
                    .font(.body)
                    .foregroundStyle(Color.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            } else {
                VStack(alignment: .leading, spacing: 0) {
                    ForEach(recipe.steps.indices, id: \.self) { index in
                        stepRow(recipe.steps[index], index: index, count: recipe.steps.count)
                        if index < recipe.steps.count - 1 {
                            Rectangle().fill(Color.hairline).frame(height: 0.5).padding(.leading, 40)
                        }
                    }
                }
            }
        }
    }

    private func stepRow(_ step: Step, index: Int, count: Int) -> some View {
        let done = session?.progress.done.contains(index) == true
        return Button {
            session?.select(index)
            cooking = true
        } label: {
            HStack(alignment: .firstTextBaseline, spacing: Spacing.s) {
                Group {
                    if done {
                        Image(systemName: "checkmark")
                            .font(.subheadline.weight(.bold))
                            .foregroundStyle(Color.ember)
                    } else {
                        Text(index + 1, format: .number)
                            .font(.subheadline.weight(.semibold))
                            .monospacedDigit()
                            .foregroundStyle(Color.textSecondary)
                    }
                }
                .frame(width: 28, alignment: .leading)
                Text(step.text)
                    .font(.body)
                    .foregroundStyle(done ? Color.textSecondary : Color.textPrimary)
                    .multilineTextAlignment(.leading)
                    .fixedSize(horizontal: false, vertical: true)
                Spacer(minLength: 0)
            }
            .padding(.vertical, Spacing.s)
            .contentShape(.rect)
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Step \(index + 1) of \(count)\(done ? ", done" : ""). \(step.text)")
        .accessibilityHint("Starts cooking from this step")
    }

    // MARK: - No recipe yet

    /// A post kept without a recipe (Later): Check again re-reads it on the PC, for when the
    /// creator adds the recipe to the caption or links it. Recipes posted only in the comments
    /// still can't be read (yt-dlp gets few comments signed out; see CLAUDE.md).
    private func noRecipeYet(_ recipe: Recipe) -> some View {
        let checking = store.ingestJobs.contains { $0.isActive && $0.recipeId == recipe.id }
            || checkRequested
        let kept = recipe.status == "needs_recipe"
        return VStack(alignment: .leading, spacing: Spacing.s) {
            SectionHeader("No recipe yet")
            Text(kept
                 ? "Saved in Later. Once the creator adds the recipe to the caption or links it, check again."
                 : "This reel has no ingredient list. If the recipe is coming, save it for later and check again then.")
                .font(.body)
                .foregroundStyle(Color.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
            if let note = checkError {
                Label(note, systemImage: "exclamationmark.triangle")
                    .font(.footnote)
                    .foregroundStyle(Color.textPrimary)
            }
            HStack(spacing: Spacing.xs) {
                Button {
                    checkError = nil
                    checkRequested = true
                    Task {
                        do { try await store.checkAgain(recipe) } catch {
                            checkError = store.offlineSince != nil
                                ? "Checking again needs the recipe server, which is out of reach right now."
                                : "Couldn't reach the recipe server: \(error.localizedDescription)"
                        }
                        checkRequested = false
                    }
                } label: {
                    if checking {
                        HStack(spacing: Spacing.xs) {
                            AnimatedChefView(.loading, size: 28)
                            Text("Checking…")
                        }
                    } else {
                        Label("Check again", systemImage: "arrow.clockwise")
                    }
                }
                .buttonStyle(.primaryPill)
                .disabled(checking)

                Button(kept ? "Remove from Later" : "Save for later", systemImage: kept ? "bookmark.slash" : "bookmark") {
                    Task { try? await store.setStatus(kept ? "not_recipe" : "needs_recipe", for: recipe.id) }
                }
                .buttonStyle(.secondaryPill)
            }
        }
    }
}


private enum UIScreenWidth {
    @MainActor static var value: CGFloat {
        (UIApplication.shared.connectedScenes.first as? UIWindowScene)?.screen.bounds.width ?? 390
    }
}

private extension View {
    /// Sets `flag` once the scroll view has scrolled further than `offset` (iOS 18+; on iOS 17 the
    /// bar stays clear).
    @ViewBuilder
    func trackingScroll(past offset: CGFloat, into flag: Binding<Bool>) -> some View {
        if #available(iOS 18.0, *) {
            onScrollGeometryChange(for: Bool.self) { geometry in
                geometry.contentOffset.y + geometry.contentInsets.top > offset
            } action: { _, past in
                flag.wrappedValue = past
            }
        } else {
            self
        }
    }
}
