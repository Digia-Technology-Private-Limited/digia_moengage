/**
 * CampaignPayloadMapper
 *
 * Translates a MoEngage SelfHandledCampaignData object into a Digia
 * InAppPayload by:
 *   - parsing the marketer-authored JSON from campaign.payload,
 *   - merging it with campaign metadata (ID + name), and
 *   - writing the identifiers needed for lifecycle correlation into cepContext.
 *
 * Parsing failures are gracefully degraded — an empty payload map is used
 * so the campaign still reaches the rendering engine.
 *
 * Mirrors:
 *   android: com.digia.moengage.mapper.CampaignPayloadMapper
 *   flutter:  digia_moengage_plugin/lib/src/mapper/campaign_payload_mapper.dart
 */
import type { InAppPayload, MoEngageSelfHandledData } from './types';

export function mapCampaignPayload(data: MoEngageSelfHandledData): InAppPayload {
    const campaignId = data.campaignData.campaignId;
    const campaignName = data.campaignData.campaignName;

    return {
        id: campaignId,
        content: buildContent(data),
        cepContext: {
            campaignId,
            campaignName,
        },
    };
}

function buildContent(data: MoEngageSelfHandledData): Record<string, unknown> {
    let payloadMap: Record<string, unknown> = {};

    try {
        const decoded: unknown = JSON.parse(data.campaign.payload);
        if (decoded !== null && typeof decoded === 'object' && !Array.isArray(decoded)) {
            payloadMap = decoded as Record<string, unknown>;
        }
    } catch {
        // Parsing failure is gracefully degraded — proceed with empty map.
    }

    return {
        campaignId: data.campaignData.campaignId,
        campaignName: data.campaignData.campaignName,
        ...payloadMap,
    };
}
