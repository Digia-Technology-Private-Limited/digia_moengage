import type { ICampaignCache } from './CampaignCache';
import type { MoEngageSelfHandledData } from './types';

export type DigiaExperienceEvent =
    | { type: 'impressed' }
    | { type: 'clicked'; elementId?: string }
    | { type: 'dismissed' };

/** Minimal interface for the react-native-moengage self-handled in-app API. */
export interface IMoEngageInApp {
    selfHandledShown(data: MoEngageSelfHandledData): void;
    selfHandledClicked(
        data: MoEngageSelfHandledData,
        widgetData?: { id: string },
    ): void;
    selfHandledDismissed(data: MoEngageSelfHandledData): void;
}

/**
 * Routes Digia overlay lifecycle events to MoEngage analytics.
 *
 * Mirrors com.digia.moengage.event.MoEngageEventDispatcher on Android.
 */
export class MoEngageEventDispatcher {
    constructor(
        private readonly _moEngage: IMoEngageInApp,
        private readonly _cache: ICampaignCache,
    ) {}

    dispatch(event: DigiaExperienceEvent, campaignId: string): void {
        const data = this._cache.get(campaignId);
        if (!data) return;

        switch (event.type) {
            case 'impressed':
                this._moEngage.selfHandledShown(data);
                break;
            case 'clicked':
                this._moEngage.selfHandledClicked(
                    data,
                    event.elementId ? { id: event.elementId } : undefined,
                );
                break;
            case 'dismissed':
                this._moEngage.selfHandledDismissed(data);
                this._cache.delete(campaignId);
                break;
        }
    }
}
