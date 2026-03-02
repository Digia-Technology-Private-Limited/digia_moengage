package com.digia.moengage.event

import android.content.Context
import android.util.Log
import com.digia.engage.DigiaExperienceEvent
import com.digia.moengage.cache.ICampaignCache
import com.moengage.inapp.MoEInAppHelper

/**
 * Dispatches [DigiaExperienceEvent]s to the corresponding MoEngage self-handled in-app lifecycle
 * APIs.
 *
 * ## Strategy pattern Event dispatch is a dedicated responsibility, isolated here so that
 * [MoEngagePlugin] is **closed for modification** when new event types are added. Only this class
 * is updated — the plugin orchestrator is unchanged.
 *
 * Kotlin's sealed-class exhaustive `when` provides compile-time safety: adding a new
 * [DigiaExperienceEvent] subtype causes a compile error here rather than a silent runtime miss.
 *
 * ## Dependencies
 * - [MoEInAppHelper]: MoEngage lifecycle APIs (shown / clicked / dismissed).
 * - [ICampaignCache]: resolves the cached [SelfHandledCampaignData] required by the MoEngage APIs,
 * and evicts entries post-dismiss.
 */
class MoEngageEventDispatcher(
        private val context: Context,
        private val cache: ICampaignCache,
) {
    private val tag = "MoEngageEventDispatcher"

    /**
     * Resolves cached [SelfHandledCampaignData] for [campaignId] and forwards [event] to the
     * appropriate MoEngage lifecycle API.
     *
     * Returns `true` on successful dispatch, `false` when [campaignId] is absent from the cache
     * (guard against stale events).
     */
    fun dispatch(event: DigiaExperienceEvent, campaignId: String): Boolean {
        val data = cache.get(campaignId)
        if (data == null) {
            Log.w(tag, "no cached data for campaignId=$campaignId")
            return false
        }

        when (event) {
            is DigiaExperienceEvent.Impressed -> {
                MoEInAppHelper.getInstance().selfHandledShown(context, data)
                Log.v(tag, "dispatched: selfHandledShown — campaignId=$campaignId")
            }
            is DigiaExperienceEvent.Clicked -> {
                MoEInAppHelper.getInstance().selfHandledClicked(context, data)
                Log.v(tag, "dispatched: selfHandledClicked — campaignId=$campaignId")
            }
            is DigiaExperienceEvent.Dismissed -> {
                MoEInAppHelper.getInstance().selfHandledDismissed(context, data)
                // Campaign lifecycle is complete — evict the entry.
                cache.remove(campaignId)
                Log.v(tag, "dispatched: selfHandledDismissed — campaignId=$campaignId")
            }
        }

        return true
    }
}
