/**
 * ICampaignCache
 *
 * Abstracts the in-memory store that keeps MoEngage SelfHandledCampaignData
 * alive between the time a campaign is received and the time lifecycle events
 * (shown / clicked / dismissed) are reported back to MoEngage.
 *
 * Mirrors:
 *   android: com.digia.moengage.cache.ICampaignCache
 *   flutter:  digia_moengage_plugin/lib/src/cache/i_campaign_cache.dart
 */
import type { MoEngageSelfHandledData } from './types';

export interface ICampaignCache {
    put(campaignId: string, data: MoEngageSelfHandledData): void;
    get(campaignId: string): MoEngageSelfHandledData | undefined;
    remove(campaignId: string): void;
    clear(): void;
    readonly count: number;
    readonly campaignIds: string[];
}

/**
 * CampaignCache
 *
 * Default in-memory implementation of ICampaignCache backed by a plain Map.
 * Entries are evicted per-campaign on remove() (post-dismiss) and
 * globally on clear() (teardown).
 *
 * Mirrors:
 *   android: com.digia.moengage.cache.CampaignCache
 *   flutter:  digia_moengage_plugin/lib/src/cache/campaign_cache.dart
 */
export class CampaignCache implements ICampaignCache {
    private readonly _store = new Map<string, MoEngageSelfHandledData>();

    put(campaignId: string, data: MoEngageSelfHandledData): void {
        this._store.set(campaignId, data);
    }

    get(campaignId: string): MoEngageSelfHandledData | undefined {
        return this._store.get(campaignId);
    }

    remove(campaignId: string): void {
        this._store.delete(campaignId);
    }

    clear(): void {
        this._store.clear();
    }

    get count(): number {
        return this._store.size;
    }

    get campaignIds(): string[] {
        return Array.from(this._store.keys());
    }
}
