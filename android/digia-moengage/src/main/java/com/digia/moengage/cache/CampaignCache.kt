package com.digia.moengage.cache

import com.moengage.inapp.model.SelfHandledCampaignData

/**
 * In-memory implementation of [ICampaignCache].
 *
 * Backed by a plain [MutableMap]; entries are evicted per-campaign on [remove] (post-dismiss) and
 * globally on [clear] (teardown).
 *
 * Swap this with an LRU or persistent cache by implementing [ICampaignCache] and injecting it into
 * [MoEngagePlugin] — no other code changes required.
 */
class CampaignCache : ICampaignCache {

    private val store = mutableMapOf<String, SelfHandledCampaignData>()

    override fun put(campaignId: String, data: SelfHandledCampaignData) {
        store[campaignId] = data
    }

    override fun get(campaignId: String): SelfHandledCampaignData? = store[campaignId]

    override fun remove(campaignId: String) {
        store.remove(campaignId)
    }

    override fun clear() = store.clear()

    override val count: Int
        get() = store.size

    override val campaignIds: List<String>
        get() = store.keys.toList()
}
