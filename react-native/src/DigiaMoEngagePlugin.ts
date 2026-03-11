/**
 * DigiaMoEngagePlugin
 *
 * Pure TypeScript Digia CEP plugin for MoEngage.
 *
 * Bridges MoEngage's Self-Handled In-App campaign system into Digia's
 * rendering engine using react-native-moengage.  No native code required —
 * works on both Android and iOS.
 *
 * ─── Architecture ────────────────────────────────────────────────────────────
 *
 *   ┌─────────────────────────────────────────────┐
 *   │  MoEngage SDK (react-native-moengage)        │
 *   │  setSelfHandledInAppHandler(cb)              │
 *   │  getSelfHandledInApp()  ←── forwardScreen()  │
 *   └──────────────┬──────────────────────────────┘
 *                  │ SelfHandledCampaignData
 *                  ▼
 *   ┌─────────────────────────────┐
 *   │  CampaignPayloadMapper      │  maps to InAppPayload
 *   └──────────────┬──────────────┘
 *                  │ InAppPayload
 *                  ▼
 *   ┌──────────────────────────────────────┐
 *   │  Digia.triggerCampaign()             │  pushes into native Compose overlay
 *   └──────────────────────────────────────┘
 *
 *   ┌────────────────────────────────────────────────────────┐
 *   │  DeviceEventEmitter 'digiaOverlayEvent'                │
 *   │  (emitted by RNEventBridgePlugin in DigiaModule.kt)    │
 *   └──────────────┬─────────────────────────────────────────┘
 *                  │ { type, campaignId }
 *                  ▼
 *   ┌──────────────────────────────────────┐
 *   │  MoEngageEventDispatcher             │
 *   │  selfHandledShown / Clicked /        │
 *   │  Dismissed → MoEngage analytics      │
 *   └──────────────────────────────────────┘
 *
 * ─── Usage ───────────────────────────────────────────────────────────────────
 *
 *   ```ts
 *   import MoEngage from 'react-native-moengage';
 *   import { Digia } from '@digia/engage-react-native';
 *   import { DigiaMoEngagePlugin } from '@digia/moengage-react-native';
 *
 *   // 1. Initialise Digia first
 *   await Digia.initialize({ apiKey: 'YOUR_KEY' });
 *
 *   // 2. Register the plugin — Digia calls setup() internally
 *   Digia.register(new DigiaMoEngagePlugin({ moEngage: MoEngage }));
 *
 *   // 3. Screen tracking is automatic via Digia.setCurrentScreen()
 *   Digia.setCurrentScreen('HomeScreen'); // also calls plugin.forwardScreen()
 *
 *   // 4. Unregister when done (calls teardown() internally)
 *   Digia.unregister('moengage');
 *   ```
 * ─────────────────────────────────────────────────────────────────────────────
 *
 * Mirrors:
 *   android: com.digia.moengage.MoEngagePlugin
 *   flutter:  digia_moengage_plugin/lib/src/moengage_plugin.dart
 */

import { DeviceEventEmitter, EmitterSubscription } from 'react-native';
import { Digia, type DigiaPlugin } from '@digia/engage-react-native';
import { CampaignCache, type ICampaignCache } from './CampaignCache';
import { mapCampaignPayload } from './CampaignPayloadMapper';
import {
    MoEngageEventDispatcher,
    type DigiaExperienceEvent,
    type IMoEngageInApp,
} from './MoEngageEventDispatcher';
import type { MoEngageSelfHandledData } from './types';

// ── react-native-moengage minimal interface ───────────────────────────────────
// We only declare the methods we actually use, keeping this package
// loosely coupled to the exact MoEngage SDK version.

interface MoEngageInstance extends IMoEngageInApp {
    setSelfHandledInAppHandler(
        handler: ((data: MoEngageSelfHandledData) => void) | null
    ): void;
    getSelfHandledInApp(): void;
    setCurrentContext(contexts: string[]): void;
}

// ── Options ───────────────────────────────────────────────────────────────────

export interface DigiaMoEngagePluginOptions {
    /**
     * The react-native-moengage instance.
     * Import the default export from 'react-native-moengage' and pass it here.
     *
     * ```ts
     * import MoEngage from 'react-native-moengage';
     * new DigiaMoEngagePlugin({ moEngage: MoEngage });
     * ```
     */
    moEngage: MoEngageInstance;

    /**
     * Custom cache implementation.  Defaults to an in-memory CampaignCache.
     */
    cache?: ICampaignCache;
}

// ── DigiaMoEngagePlugin ───────────────────────────────────────────────────────

export class DigiaMoEngagePlugin implements DigiaPlugin {
    readonly identifier = 'moengage';

    private readonly _moEngage: MoEngageInstance;
    private readonly _cache: ICampaignCache;
    private readonly _dispatcher: MoEngageEventDispatcher;

    private _overlayEventSub: EmitterSubscription | null = null;
    private _isSetup = false;

    constructor(options: DigiaMoEngagePluginOptions) {
        this._moEngage = options.moEngage;
        this._cache = options.cache ?? new CampaignCache();
        this._dispatcher = new MoEngageEventDispatcher(this._moEngage, this._cache);
    }

    // ── DigiaPlugin interface (managed by Digia.register / Digia.setCurrentScreen) ──

    /** @internal Called by Digia.register() — do not call manually. */
    setup(): void {
        if (this._isSetup) return;
        this._isSetup = true;

        this._moEngage.setSelfHandledInAppHandler(this._onSelfHandledInApp);

        // Subscribe to Digia overlay lifecycle events emitted by RNEventBridgePlugin
        // (DigiaModule.kt) so shown / clicked / dismissed are reported to MoEngage.
        this._overlayEventSub = DeviceEventEmitter.addListener(
            'digiaOverlayEvent',
            this._onOverlayEvent,
        );

        this._moEngage.getSelfHandledInApp();
    }

    /** @internal Called by Digia.setCurrentScreen() — do not call manually. */
    forwardScreen(name: string): void {
        this._moEngage.setCurrentContext([name]);
        this._moEngage.getSelfHandledInApp();
    }

    /** @internal Called by Digia.unregister() — do not call manually. */
    teardown(): void {
        this._moEngage.setSelfHandledInAppHandler(null);
        this._overlayEventSub?.remove();
        this._overlayEventSub = null;
        this._cache.clear();
        this._isSetup = false;
    }

    /**
     * Returns diagnostic information about the plugin's current state.
     */
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

    // ── Private handlers ────────────────────────────────────────────────────────

    /**
     * Called by react-native-moengage when a self-handled in-app campaign is
     * available.  Maps it to a Digia InAppPayload and pushes it into the Digia
     * rendering engine.
     */
    private _onSelfHandledInApp = (data: MoEngageSelfHandledData): void => {
        const payload = mapCampaignPayload(data);

        // Cache the raw MoEngage data so lifecycle events can be reported later.
        this._cache.put(payload.id, data);

        // Hand off to Digia — the Compose overlay will render it.
        Digia.triggerCampaign(payload.id, payload.content, payload.cepContext);
    };

    /**
     * Called when the Digia native bridge emits an overlay lifecycle event.
     *
     * The event shape is:
     *   { type: 'impressed' | 'clicked' | 'dismissed', campaignId: string, elementId?: string }
     *
     * Forwards the event to MoEngage so its analytics pipeline records it.
     */
    private _onOverlayEvent = (event: {
        type: string;
        campaignId: string;
        elementId?: string;
    }): void => {
        const { type, campaignId, elementId } = event;

        let digiaEvent: DigiaExperienceEvent;
        switch (type) {
            case 'impressed':
                digiaEvent = { type: 'impressed' };
                break;
            case 'clicked':
                digiaEvent = { type: 'clicked', elementId };
                break;
            case 'dismissed':
                digiaEvent = { type: 'dismissed' };
                break;
            default:
                return;
        }

        this._dispatcher.dispatch(digiaEvent, campaignId);
    };
}
