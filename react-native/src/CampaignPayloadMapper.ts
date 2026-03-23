import type { InAppPayload } from '@digia-engage/core';
import type { MoEngageSelfHandledData } from './types';

/**
 * Maps a MoEngage self-handled campaign into a Digia InAppPayload.
 *
 * The marketer-authored JSON from the MoEngage dashboard is parsed and merged
 * with campaign metadata.  Parsing failures degrade gracefully to an empty map
 * so the campaign still reaches the rendering engine.
 */
export function mapCampaignPayload(data: MoEngageSelfHandledData): InAppPayload {
    const campaignId = data.campaignData.campaignId;
    const campaignName = data.campaignData.campaignName;

    let payloadMap: Record<string, unknown> = {};
    try {
        const parsed: unknown = JSON.parse(data.campaign.payload);
        if (parsed !== null && typeof parsed === 'object' && !Array.isArray(parsed)) {
            payloadMap = parsed as Record<string, unknown>;
        }
    } catch {
        // graceful degradation — render with metadata only
    }

    return {
        id: campaignId,
        content: {
            campaignId,
            campaignName,
            ...payloadMap,
        },
        cepContext: { campaignId, campaignName },
    };
}
