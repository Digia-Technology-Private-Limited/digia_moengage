import MoEngageInApp

/// In-memory implementation of `ICampaignCache`.
///
/// Backed by a plain `Dictionary`; entries are evicted per-campaign on
/// `remove(_:)` (post-dismiss) and globally on `clear()` (teardown).
///
/// Swap this with an LRU or persistent cache by implementing `ICampaignCache`
/// and injecting it into `MoEngagePlugin` — no other code changes required.
final class CampaignCache: ICampaignCache {
    private var store: [String: InAppSelfHandledCampaign] = [:]

    func put(campaignId: String, data: InAppSelfHandledCampaign) {
        store[campaignId] = data
    }

    func get(campaignId: String) -> InAppSelfHandledCampaign? {
        store[campaignId]
    }

    func remove(campaignId: String) {
        store.removeValue(forKey: campaignId)
    }

    func clear() {
        store.removeAll()
    }

    var count: Int { store.count }

    var campaignIds: [String] { Array(store.keys) }
}
