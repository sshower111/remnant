import Foundation

// Decoded from the server's JSON exactly as documented in docs/ios/api.md
// (snake_case keys, converted by APIClient's decoder). Anything the API can
// send as null is optional.

nonisolated struct RecipeSummary: Codable, Identifiable, Hashable {
    let id: Int
    let title: String
    let uploader: String?
    let yieldLabel: String?
    let status: String?
    let ingredientCount: Int
    let stepCount: Int
    var favorite: Bool
    var tried: Bool
    let thumbnailUrl: String?
    let platform: String?        // "instagram" | "youtube" | "tiktok" | null
}

nonisolated struct Recipe: Codable, Identifiable {
    let id: Int
    let title: String
    let uploader: String?
    let description: String?
    let yieldLabel: String?
    let status: String?
    var favorite: Bool
    var tried: Bool
    let thumbnailUrl: String?
    let recipePageUrl: String?
    let video: Video
    let ingredients: [Ingredient]
    let steps: [Step]
}

nonisolated struct Video: Codable {
    let url: String
    let platform: String?
    let embedUrl: String?
}

nonisolated struct Ingredient: Codable, Hashable {
    let name: String             // canonical, e.g. "butter"
    let rawName: String          // as written, e.g. "unsalted butter": show this
    let amount: Double?
    let unit: String?
}

nonisolated struct Step: Codable, Hashable {
    let text: String
    let shortText: String?       // model-written island version (~50 chars); nil until shortened
    let ingredients: [Int]       // indexes into Recipe.ingredients
}

nonisolated struct Marks: Codable {
    let favorite: Bool
    let tried: Bool
    let hidden: Bool?            // removed with a swipe
    let status: String?          // ready | needs_recipe | not_recipe
}

nonisolated struct PantryIngredient: Codable, Hashable {
    let name: String
    let recipeCount: Int
}

/// How a recipe fits the picked ingredients (worked out on the phone: IngredientSearch.rank).
nonisolated struct PantryMatch: Identifiable {
    var id: Int { recipeId }
    let recipeId: Int
    /// How many of the picks the recipe uses.
    let matched: Int
    /// Its other ingredients, staples left out.
    let missing: [String]
    var missingCount: Int { missing.count }
}

/// A post shared from the phone, being added on the PC (POST/GET /api/ingest).
nonisolated struct IngestJob: Codable, Identifiable, Hashable {
    let id: String
    let url: String
    let status: String              // queued | running | done | failed
    let createdAt: String
    let finishedAt: String?
    let recipeId: Int?
    let title: String?
    let result: String?             // added | updated | skipped
    let recipeStatus: String?       // ready | needs_recipe | not_recipe
    let message: String?
    let refresh: Bool?              // "Check again" on a post already stored

    var isActive: Bool { status == "queued" || status == "running" }
}
