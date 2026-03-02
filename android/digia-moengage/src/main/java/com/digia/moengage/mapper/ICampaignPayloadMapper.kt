package com.digia.moengage.mapper

import com.digia.engage.InAppPayload
import com.moengage.inapp.model.SelfHandledCampaignData

/**
 * Abstraction for translating MoEngage campaign data into a Digia [InAppPayload].
 *
 * Isolates the transformation concern so that mapping logic can evolve (e.g. different JSON
 * schemas) without touching the plugin orchestrator.
 *
 * **DIP**: [MoEngagePlugin] depends on this interface, not the concrete [CampaignPayloadMapper],
 * enabling substitution and test doubles.
 */
interface ICampaignPayloadMapper {

    /** Translates [data] from MoEngage into a Digia [InAppPayload]. */
    fun map(data: SelfHandledCampaignData): InAppPayload
}
