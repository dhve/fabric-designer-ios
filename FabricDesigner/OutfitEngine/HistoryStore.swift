import Foundation
import SwiftUI

/// Persists the user's outfit history, likes, and dislikes — used as input
/// to the tournament generator. Backed by UserDefaults so it survives app
/// relaunches without dragging SwiftData into the engine layer.
@MainActor
public final class HistoryStore: ObservableObject {
    @Published public private(set) var history: [[String]] = []
    @Published public private(set) var likes:   [[String]] = []
    @Published public private(set) var dislikes: [[String]] = []

    private let defaults = UserDefaults.standard
    private let historyKey = "fd.history"
    private let likesKey   = "fd.likes"
    private let dislikesKey = "fd.dislikes"
    private let historyCap = 20

    public init() {
        history = decode(historyKey)
        likes   = decode(likesKey)
        dislikes = decode(dislikesKey)
    }

    public func recordGenerated(_ outfit: Outfit) {
        let ids = outfit.items.map(\.id)
        history.insert(ids, at: 0)
        if history.count > historyCap { history = Array(history.prefix(historyCap)) }
        persist(history, key: historyKey)
    }

    public func like(_ outfit: Outfit) {
        let ids = outfit.items.map(\.id).sorted()
        if !likes.contains(ids) {
            likes.append(ids)
            persist(likes, key: likesKey)
        }
    }

    public func dislike(_ outfit: Outfit) {
        let ids = outfit.items.map(\.id).sorted()
        if !dislikes.contains(ids) {
            dislikes.append(ids)
            persist(dislikes, key: dislikesKey)
        }
    }

    public func resetAll() {
        history = []; likes = []; dislikes = []
        defaults.removeObject(forKey: historyKey)
        defaults.removeObject(forKey: likesKey)
        defaults.removeObject(forKey: dislikesKey)
    }

    private func decode(_ key: String) -> [[String]] {
        guard let data = defaults.data(forKey: key),
              let v = try? JSONDecoder().decode([[String]].self, from: data) else { return [] }
        return v
    }

    private func persist(_ value: [[String]], key: String) {
        if let data = try? JSONEncoder().encode(value) {
            defaults.set(data, forKey: key)
        }
    }
}
