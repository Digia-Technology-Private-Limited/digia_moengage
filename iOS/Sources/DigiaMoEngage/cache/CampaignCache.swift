import MoEngageInApps

/// In-memory implementation of `ICampaignCache`.
///
/// Backed by a plain `Dictionary`; entries are evicted per-campaign on
/// `remove(_:)` (post-dismiss) and globally on `clear()` (teardown).
///
/// Swap this with an LRU or persistent cache by implementing `ICampaignCache`
/// and injecting it into `MoEngagePlugin` — no other code changes required.
public final class CampaignCache: ICampaignCache {
    public init() {}

    private var store: [String: MoEngageInAppSelfHandledCampaign] = [:]

    public func put(campaignId: String, data: MoEngageInAppSelfHandledCampaign) {
        store[campaignId] = data
    }

    public func get(campaignId: String) -> MoEngageInAppSelfHandledCampaign? {
        store[campaignId]
    }

    public func remove(campaignId: String) {
        store.removeValue(forKey: campaignId)
    }

    public func clear() {
        store.removeAll()
    }

    public var count: Int { store.count }

    public var campaignIds: [String] { Array(store.keys) }
}
