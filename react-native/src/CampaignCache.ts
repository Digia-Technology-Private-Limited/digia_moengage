import type { MoEngageSelfHandledData } from './types';

export interface ICampaignCache {
    readonly count: number;
    readonly campaignIds: string[];
    put(campaignId: string, data: MoEngageSelfHandledData): void;
    get(campaignId: string): MoEngageSelfHandledData | undefined;
    delete(campaignId: string): void;
    clear(): void;
}

export class CampaignCache implements ICampaignCache {
    private readonly _map = new Map<string, MoEngageSelfHandledData>();

    get count(): number { return this._map.size; }
    get campaignIds(): string[] { return [...this._map.keys()]; }

    put(campaignId: string, data: MoEngageSelfHandledData): void {
        this._map.set(campaignId, data);
    }

    get(campaignId: string): MoEngageSelfHandledData | undefined {
        return this._map.get(campaignId);
    }

    delete(campaignId: string): void {
        this._map.delete(campaignId);
    }

    clear(): void {
        this._map.clear();
    }
}
