/**
 * DigiaMoEngagePlugin
 *
 * Pure TypeScript Digia CEP plugin for MoEngage.
 *
 * Receives MoEngage self-handled in-app campaigns via react-native-moengage,
 * maps them to InAppPayload, then delivers them into the Digia rendering engine
 * via the DigiaDelegate passed by Digia.register().
 *
 * Overlay lifecycle events (impressed / clicked / dismissed) received from the
 * native RNEventBridgePlugin are forwarded to MoEngage analytics.
 *
 * Works on Android and iOS — no native code in this package.
 *
 * Usage:
 * ```ts
 * import MoEngage from 'react-native-moengage';
 * import { Digia } from '@digia/engage-react-native';
 * import { DigiaMoEngagePlugin } from '@digia/moengage-plugin';
 *
 * await Digia.initialize({ apiKey: 'YOUR_KEY' });
 * Digia.register(new DigiaMoEngagePlugin({ moEngage: MoEngage }));
 * ```
 *
 * Mirrors: com.digia.moengage.MoEngagePlugin (Android)
 */

import type { DigiaDelegate, DigiaPlugin } from '@digia-engage/core';
import { DeviceEventEmitter, type EmitterSubscription } from 'react-native';
import { CampaignCache, type ICampaignCache } from './CampaignCache';
import { mapCampaignPayload } from './CampaignPayloadMapper';
import {
    MoEngageEventDispatcher,
    type DigiaExperienceEvent,
    type IMoEngageInApp,
} from './MoEngageEventDispatcher';
import type { MoEngageSelfHandledData } from './types';

/** Full MoEngage client interface required by DigiaMoEngagePlugin. */
export interface IMoEngageClient extends IMoEngageInApp {
    setEventListener(event: string, callback: (data: any) => void): void;
    removeEventListener(event: string): void;
    getSelfHandledInApp(): void;
    setCurrentContext(contexts: string[]): void;
}

export interface DigiaMoEngagePluginOptions {
    moEngage: IMoEngageClient;
}





export class DigiaMoEngagePlugin implements DigiaPlugin {
    readonly identifier = 'moengage';

    private readonly _cache: ICampaignCache;
    private readonly _dispatcher: MoEngageEventDispatcher;

    private readonly _moEngage: IMoEngageClient;
    private _delegate: DigiaDelegate | null = null;
    private _overlayEventSub: EmitterSubscription | null = null;
    private _isSetup = false;

    constructor({ moEngage }: DigiaMoEngagePluginOptions) {
        this._moEngage = moEngage;
        this._cache = new CampaignCache();
        this._dispatcher = new MoEngageEventDispatcher(moEngage, this._cache);
    }

    /** @internal Called by Digia.register() — do not call manually. */
    setup(delegate: DigiaDelegate): void {
        if (this._isSetup) return;
        this._isSetup = true;
        this._delegate = delegate;

        this._moEngage.setEventListener('inAppCampaignSelfHandled', this._onSelfHandledInApp);

        // Subscribe to overlay lifecycle events emitted by RNEventBridgePlugin
        // (DigiaModule.kt) so MoEngage analytics are reported correctly.
        this._overlayEventSub = DeviceEventEmitter.addListener(
            'digiaOverlayEvent',
            this._onOverlayEvent,
        );

        // this._moEngage.getSelfHandledInApp();
    }

    /** @internal Called by Digia.setCurrentScreen() — do not call manually. */
    forwardScreen(name: string): void {
        this._moEngage.setCurrentContext([name]);
        this._moEngage.getSelfHandledInApp();
    }

    /** @internal Called by Digia.unregister() — do not call manually. */
    teardown(): void {
        this._moEngage.removeEventListener('inAppCampaignSelfHandled');
        this._overlayEventSub?.remove();
        this._overlayEventSub = null;
        this._cache.clear();
        this._delegate = null;
        this._isSetup = false;
    }

    healthCheck(): { isHealthy: boolean; metadata: Record<string, unknown> } {
        return {
            isHealthy: this._isSetup,
            metadata: {
                identifier: this.identifier,
                isSetup: this._isSetup,
                cachedCampaigns: this._cache.count,
                cachedCampaignIds: this._cache.campaignIds,
            },
        };
    }

    // ── Private ───────────────────────────────────────────────────────────────

    private _onSelfHandledInApp = (
        data: MoEngageSelfHandledData | null | undefined,
    ): void => {
        if (!data) return;
        const payload = mapCampaignPayload(data);
        this._cache.put(payload.id, data);
        // calling delegate.onCampaignTriggered(payload).
        this._delegate?.onCampaignTriggered(payload);
    };

    private _onOverlayEvent = (event: {
        type: string;
        campaignId: string;
        elementId?: string;
    }): void => {
        const { type, campaignId, elementId } = event;

        let digiaEvent: DigiaExperienceEvent;
        switch (type) {
            case 'impressed': digiaEvent = { type: 'impressed' }; break;
            case 'clicked': digiaEvent = { type: 'clicked', elementId }; break;
            case 'dismissed': digiaEvent = { type: 'dismissed' }; break;
            default: return;
        }

        this._dispatcher.dispatch(digiaEvent, campaignId);
    };
}
