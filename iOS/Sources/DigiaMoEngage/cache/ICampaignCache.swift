import MoEngageInApps

/// Abstraction for MoEngage self-handled campaign data caching.
///
/// Decouples lifecycle-event correlation from any particular storage
/// strategy. An in-memory map, an LRU cache, or a persistent store may be
/// injected without touching `MoEngagePlugin` or `MoEngageEventDispatcher`.
public protocol ICampaignCache: AnyObject {
    /// Stores `data` keyed by `campaignId`.
    func put(campaignId: String, data: MoEngageInAppSelfHandledCampaign)

    /// Returns the cached `MoEngageInAppSelfHandledCampaign` for `campaignId`,
    /// or `nil` when absent.
    func get(campaignId: String) -> MoEngageInAppSelfHandledCampaign?

    /// Removes the entry for `campaignId` (call after campaign lifecycle ends).
    func remove(campaignId: String)

    /// Evicts all entries (call during plugin teardown).
    func clear()

    /// Number of currently cached campaigns.
    var count: Int { get }

    /// Read-only list of currently cached campaign IDs (for diagnostics).
    var campaignIds: [String] { get }
}
