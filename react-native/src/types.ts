/**
 * Types shared across the @digia/moengage-react-native package.
 *
 * These mirror the contracts established by the Android + Flutter
 * implementations of the plugin:
 *   android: com.digia.moengage.MoEngagePlugin
 *   flutter:  digia_moengage_plugin/lib/src/moengage_plugin.dart
 */

// ── MoEngage self-handled data shape ─────────────────────────────────────────
// react-native-moengage surfaces campaign data through these callback shapes.

export interface MoEngageCampaignData {
    campaignId: string;
    campaignName: string;
}

export interface MoEngageSelfHandledCampaign {
    /** Raw marketer-authored JSON string from the MoEngage dashboard. */
    payload: string;
}

export interface MoEngageSelfHandledData {
    campaignData: MoEngageCampaignData;
    campaign: MoEngageSelfHandledCampaign;
}

// ── Digia InAppPayload (JS-side representation) ───────────────────────────────

export interface InAppPayload {
    id: string;
    content: Record<string, unknown>;
    cepContext: Record<string, unknown>;
}
