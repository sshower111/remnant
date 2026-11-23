import SwiftUI
import UIKit

/// Cook mode, full screen: every step large and in order, the current one lifted on a lighter
/// block with its ingredients and timer, the others dimmed. Next step, the timer and the
/// ingredient list sit at the bottom in thumb reach. The screen stays awake while it's open.
///
/// Progress is the recipe's CookingSession (saved on the phone and shared with the Live
/// Activity, whose ‹ › buttons move the same step).
struct CookModeView: View {
    let recipe: Recipe
    let session: CookingSession
    let onMarkCooked: () -> Void
    @Environment(\.dismiss) private var dismiss
    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.dynamicTypeSize) private var typeSize
    @State private var showIngredients = false

    var body: some View {
        NavigationStack {
            ScrollViewReader { proxy in
                ScrollView {
                    VStack(alignment: .leading, spacing: Spacing.xs) {
                        ProgressView(value: Double(session.progress.done.count), total: Double(max(session.steps.count, 1)))
                            .tint(.ember)
                            .padding(.horizontal, Spacing.xs)
                            .padding(.bottom, Spacing.s)
                            .accessibilityLabel("\(session.progress.done.count) of \(session.steps.count) steps done")
                        ForEach(session.steps.indices, id: \.self) { index in
                            stepRow(index).id(index)
                        }
                        if session.allDone {
                            finished.id("finished").padding(.top, Spacing.l)
                        }
                    }
                    .padding(.horizontal, Spacing.xs)
                    .padding(.bottom, Spacing.xl)
                }
                .onAppear { proxy.scrollTo(session.active, anchor: .center) }
                .onChange(of: session.active) { _, index in
                    withAnimation(reduceMotion ? nil : .snappy(duration: 0.3)) { proxy.scrollTo(index, anchor: .center) }
                }
                .onChange(of: session.allDone) { _, done in
                    guard done else { return }
                    withAnimation(reduceMotion ? nil : .snappy(duration: 0.3)) { proxy.scrollTo("finished", anchor: .center) }
                }
            }
            .background(Color.canvas)
            .safeAreaInset(edge: .bottom, spacing: 0) { bottomBar }
            .navigationTitle(session.allDone ? "Done" : "Step \(session.active + 1) of \(session.steps.count)")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close", systemImage: "xmark") { dismiss() }
                }
                ToolbarItem(placement: .primaryAction) {
                    Menu("More", systemImage: "ellipsis") {
                        Button("Start over", systemImage: "arrow.counterclockwise") {
                            withAnimation { session.startOver() }
                        }
                        .disabled(!session.cookingStarted)
                    }
                }
            }
        }
        .tint(.ember)
        .sheet(isPresented: $showIngredients) {
            IngredientListSheet(title: recipe.title, yieldLabel: recipe.yieldLabel, ingredients: recipe.ingredients,
                                highlighted: session.activeIngredients)
        }
        // Hands are busy: no auto-lock while cooking.
        .onAppear { UIApplication.shared.isIdleTimerDisabled = true }
        .onDisappear { UIApplication.shared.isIdleTimerDisabled = false }
        .onChange(of: scenePhase) { _, phase in
            if phase == .active { session.reload() }  // the Live Activity may have moved the step
        }
        .sensoryFeedback(.success, trigger: session.progress.done.count) { old, new in new > old }
        .accessibilityAction(named: "Next step") { withAnimation { session.select(session.active + 1) } }
        .accessibilityAction(named: "Previous step") { withAnimation { session.select(session.active - 1) } }
    }

    // MARK: - Steps

    private func stepRow(_ index: Int) -> some View {
        let step = session.steps[index]
        let isCurrent = index == session.active && !session.allDone
        let isDone = session.progress.done.contains(index)
        return Button {
            withAnimation(reduceMotion ? nil : .snappy(duration: 0.3)) { session.select(index) }
        } label: {
            HStack(alignment: .firstTextBaseline, spacing: Spacing.s) {
                Group {
                    if isDone && !isCurrent {
                        Image(systemName: "checkmark").font(.headline.weight(.bold))
                    } else {
                        Text(index + 1, format: .number).font(.headline).monospacedDigit()
                    }
                }
                .foregroundStyle(isCurrent ? Color.ember : Color.textSecondary)
                .frame(minWidth: 24, alignment: .leading)

                VStack(alignment: .leading, spacing: Spacing.s) {
                    Text(step.text)
                        .font(isCurrent ? .title2 : .title3)
                        .foregroundStyle(isCurrent ? Color.textPrimary : Color.textSecondary)
                        .multilineTextAlignment(.leading)
                        .lineSpacing(2)
                        .fixedSize(horizontal: false, vertical: true)
                    if isCurrent {
                        let used = step.ingredients.filter(recipe.ingredients.indices.contains)
                        if !used.isEmpty {
                            FlowLayout(spacing: Spacing.xs) {
                                ForEach(used, id: \.self) { ingredientTag(recipe.ingredients[$0]) }
                            }
                            .accessibilityElement(children: .combine)
                            .accessibilityLabel("Uses " + used.map { recipe.ingredients[$0].spoken }.joined(separator: ", "))
                        }
                    }
                }
                Spacer(minLength: 0)
            }
            .padding(Spacing.m)
            .background {
                if isCurrent {
                    RoundedRectangle(cornerRadius: Radius.medium).fill(Color.surfaceRaised)
                }
            }
            .opacity(isDone && !isCurrent ? 0.6 : 1)
            .contentShape(.rect)
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Step \(index + 1)\(isCurrent ? ", current" : isDone ? ", done" : ""). \(step.text)")
        .accessibilityAddTraits(isCurrent ? .isSelected : [])
        .accessibilityHint(isCurrent ? "" : "Makes it the current step")
    }

    private func ingredientTag(_ ingredient: Ingredient) -> some View {
        let quantity = ingredient.quantity
        return (Text(quantity.isEmpty ? "" : quantity + " ").fontWeight(.semibold) + Text(ingredient.label))
            .font(.subheadline)
            .foregroundStyle(Color.textPrimary)
            .padding(.horizontal, Spacing.s)
            .padding(.vertical, 6)
            .background(Color.surface, in: .capsule)
    }

    // MARK: - Finished

    private var finished: some View {
        ChefStateView(animation: .success, title: "All done. Enjoy!",
                      message: "You finished all \(session.steps.count) steps.") {
            VStack(spacing: Spacing.xs) {
                if !recipe.tried {
                    Button("Mark as cooked", systemImage: "checkmark.circle") {
                        onMarkCooked()
                        dismiss()
                    }
                    .buttonStyle(.primaryPill)
                }
                Button("Back to the recipe") { dismiss() }
                    .buttonStyle(.secondaryPill)
            }
        }
    }

    // MARK: - Bottom bar

    /// Ingredients and the step's timer on the left, Next step on the right, all in thumb reach.
    private var bottomBar: some View {
        // One row; at the accessibility text sizes, Next step gets a row of its own.
        let layout = typeSize.isAccessibilitySize
            ? AnyLayout(VStackLayout(alignment: .leading, spacing: Spacing.xs))
            : AnyLayout(HStackLayout(spacing: Spacing.xs))
        return layout {
            HStack(spacing: Spacing.xs) {
                // Icon only when the timer needs the room.
                let compact = !session.allDone && session.activeDuration != nil
                Button { showIngredients = true } label: {
                    if compact {
                        Image(systemName: "list.bullet")
                    } else {
                        Label("Ingredients", systemImage: "list.bullet")
                    }
                }
                .buttonStyle(.secondaryPill)
                .accessibilityLabel("Ingredients")
                if !session.allDone { timerButton }
            }
            if session.allDone {
                Button("Close", systemImage: "xmark") { dismiss() }
                    .buttonStyle(.pill(.secondary, expands: true))
            } else {
                Button {
                    withAnimation(reduceMotion ? nil : .snappy(duration: 0.3)) { session.completeStep() }
                } label: {
                    Label(isLastOpenStep ? "Finish" : "Next step",
                          systemImage: isLastOpenStep ? "checkmark" : "arrow.down")
                }
                .buttonStyle(.pill(.primary, expands: true))
            }
        }
        .padding(.horizontal, Spacing.m)
        .padding(.top, Spacing.xs)
        .padding(.bottom, Spacing.xs)
        .background(Color.canvas)
    }

    /// Completing this step finishes the recipe (every other step is done).
    private var isLastOpenStep: Bool {
        session.steps.indices.allSatisfy { $0 == session.active || session.progress.done.contains($0) }
    }

    /// "12:00" timer for a step that names a time ("bake for 12 minutes"); counts down once started.
    @ViewBuilder
    private var timerButton: some View {
        if let timer = session.timerForActiveStep {
            TimelineView(.periodic(from: .now, by: 1)) { context in
                let remaining = timer.endsAt.timeIntervalSince(context.date)
                Button {
                    session.cancelTimer()
                } label: {
                    Label(remaining <= 0 ? "Time's up" : StepTimer.clock(remaining), systemImage: "timer")
                        .monospacedDigit()
                }
                .buttonStyle(.pill(remaining <= 0 ? .primary : .selected))
                .accessibilityLabel(remaining <= 0 ? "Time's up. Stop timer" : "Timer, \(StepTimer.clock(remaining)) left. Stop timer")
                .sensoryFeedback(.warning, trigger: remaining <= 0) { _, up in up }
            }
        } else if let seconds = session.activeDuration {
            Button {
                session.startTimer()
            } label: {
                Label(StepTimer.label(seconds), systemImage: "timer")
            }
            .buttonStyle(.secondaryPill)
            .accessibilityLabel("Start a \(StepTimer.label(seconds)) timer")
        }
    }
}

extension Ingredient {
    /// "3 tbsp soy sauce", for VoiceOver.
    var spoken: String {
        [quantity, label].filter { !$0.isEmpty }.joined(separator: " ")
    }
}
