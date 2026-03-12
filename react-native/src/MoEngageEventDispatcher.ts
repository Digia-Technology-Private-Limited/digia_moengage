/**
 * MoEngageEventDispatcher
 *
 * Dispatches Digia DigiaExperienceEvents to the corresponding MoEngage
 * self-handled in-app lifecycle APIs via react-native-moengage.
 *
 * Uses discriminated-union exhaustiveness so that adding a new event type in
 * the future will produce a TypeScript compile error here rather than a silent
 * runtime miss.
 *
 * Mirrors:
 *   android: com.digia.moengage.event.MoEngageEventDispatcher
 *   flutter:  digia_moengage_plugin/lib/src/event/moengage_event_dispatcher.dart
 */
import type { ICampaignCache } from './CampaignCache';

// DigiaExperienceEvent discriminated union (mirrors the sealed class in Kotlin/Dart)
export type DigiaExperienceEvent =
    | { type: 'impressed' }
    | { type: 'clicked'; elementId?: string }
    | { type: 'dismissed' };

export interface IMoEngageInApp {
    /** Report the campaign as shown to MoEngage analytics. */
    selfHandledShown(data: unknown): void;
    /** Report a click event on the campaign. */
    selfHandledClicked(data: unknown): void;
    /** Report the campaign as dismissed. */
    selfHandledDismissed(data: unknown): void;
}

export class MoEngageEventDispatcher {
    private readonly _moEngage: IMoEngageInApp;
    private readonly _cache: ICampaignCache;

    constructor(moEngage: IMoEngageInApp, cache: ICampaignCache) {
        this._moEngage = moEngage;
        this._cache = cache;
    }

    /**
     * Resolves cached SelfHandledCampaignData for campaignId and forwards
     * event to the appropriate MoEngage lifecycle API.
     *
     * Returns true on successful dispatch, false when campaignId is absent
     * from the cache (guard against stale events).
     */
    dispatch(event: DigiaExperienceEvent, campaignId: string): boolean {
        const data = this._cache.get(campaignId);
        if (!data) {
            return false;
        }

        switch (event.type) {
            case 'impressed':
                this._moEngage.selfHandledShown(data);
                break;

            case 'clicked':
                this._moEngage.selfHandledClicked(data);
                break;

            case 'dismissed':
                this._moEngage.selfHandledDismissed(data);
                // Campaign lifecycle is complete — evict the entry.
                this._cache.remove(campaignId);
                break;

            default: {
                // Exhaustiveness check — triggers a compile error if a new
                // event type is added to the union without being handled here.
                const _exhaustive: never = event;
                return false;
            }
        }

        return true;
    }
}
