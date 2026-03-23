/**
 * @digia/moengage-plugin
 *
 * Pure TypeScript Digia CEP plugin for MoEngage.
 * Works on Android and iOS via react-native-moengage — no native code needed.
 *
 * ```ts
 * import MoEngage from 'react-native-moengage';
 * import { Digia } from '@digia/engage-react-native';
 * import { DigiaMoEngagePlugin } from '@digia/moengage-plugin';
 *
 * await Digia.initialize({ apiKey: 'YOUR_KEY' });
 * Digia.register(new DigiaMoEngagePlugin({ moEngage: MoEngage }));
 * ```
 */

export { DigiaMoEngagePlugin } from './DigiaMoEngagePlugin';
export type { IMoEngageClient, DigiaMoEngagePluginOptions } from './DigiaMoEngagePlugin';
export type { ICampaignCache } from './CampaignCache';
export { CampaignCache } from './CampaignCache';
export { mapCampaignPayload } from './CampaignPayloadMapper';
export type { DigiaExperienceEvent, IMoEngageInApp } from './MoEngageEventDispatcher';
export type { MoEngageSelfHandledData, MoEngageCampaignData } from './types';
