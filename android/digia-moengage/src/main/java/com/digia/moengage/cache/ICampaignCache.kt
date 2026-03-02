package com.digia.moengage.cache

import com.moengage.inapp.model.SelfHandledCampaignData

/**
 * Abstraction for MoEngage self-handled campaign data caching.
 *
 * Decouples lifecycle-event correlation from any particular storage strategy — an in-memory map, an
 * LRU cache, or a persistent store may be injected without touching [MoEngagePlugin] or
 * [MoEngageEventDispatcher].
 *
 * **DIP**: dependants reference this interface, not the concrete [CampaignCache].
 */
interface ICampaignCache {

    /** Stores [data] keyed by [campaignId]. */
    fun put(campaignId: String, data: SelfHandledCampaignData)

    /** Returns the cached [SelfHandledCampaignData] for [campaignId], or `null` when absent. */
    fun get(campaignId: String): SelfHandledCampaignData?

    /** Removes the entry for [campaignId] (call after campaign lifecycle ends). */
    fun remove(campaignId: String)

    /** Evicts all entries (call during plugin teardown). */
    fun clear()

    /** Number of currently cached campaigns. */
    val count: Int

    /** Read-only list of currently cached campaign IDs (for diagnostics). */
    val campaignIds: List<String>
}
