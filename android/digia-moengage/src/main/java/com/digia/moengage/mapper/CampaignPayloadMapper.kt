package com.digia.moengage.mapper

import android.util.Log
import com.digia.engage.InAppPayload
import com.google.gson.Gson
import com.google.gson.JsonSyntaxException
import com.moengage.inapp.model.SelfHandledCampaignData

/**
 * Default implementation of [ICampaignPayloadMapper].
 *
 * Translates a [SelfHandledCampaignData] into a Digia [InAppPayload] by:
 * - parsing the marketer-authored JSON from [SelfHandledCampaignData.campaign.payload],
 * - merging it with campaign metadata (ID + name), and
 * - writing the identifiers needed for lifecycle correlation into [InAppPayload.cepContext].
 *
 * Parsing failures are gracefully degraded — an empty payload map is used so the campaign still
 * reaches the rendering engine.
 */
class CampaignPayloadMapper : ICampaignPayloadMapper {

    private val tag = "CampaignPayloadMapper"
    private val gson = Gson()

    override fun map(data: SelfHandledCampaignData): InAppPayload {
        val campaignId = data.campaignData.campaignId
        val campaignName = data.campaignData.campaignName

        return InAppPayload(
                id = campaignId,
                content = buildContent(data),
                cepContext = mapOf("campaignId" to campaignId, "campaignName" to campaignName)
        )
    }

    // ─── Private ──────────────────────────────────────────────────────────────

    /** Merges campaign metadata with the raw marketer JSON from the dashboard. */
    private fun buildContent(data: SelfHandledCampaignData): Map<String, Any?> {
        val payloadMap = mutableMapOf<String, Any?>()

        try {
            val decoded = gson.fromJson(data.campaign.payload, Map::class.java)
            if (decoded is Map<*, *>) {
                @Suppress("UNCHECKED_CAST") payloadMap.putAll(decoded as Map<String, Any?>)
            }
        } catch (e: JsonSyntaxException) {
            Log.w(tag, "Could not parse campaign payload JSON: $e")
        }

        return buildMap {
            put("campaignId", data.campaignData.campaignId)
            put("campaignName", data.campaignData.campaignName)
            putAll(payloadMap)
        }
    }
}
