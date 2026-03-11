/**
 * @digia/moengage-react-native
 *
 * Pure TypeScript Digia CEP plugin for MoEngage.
 *
 * Works on Android and iOS via react-native-moengage — no native code needed.
 *
 * ```ts
 * import MoEngage from 'react-native-moengage';
 * import { Digia } from '@digia/engage-react-native';
 * import { DigiaMoEngagePlugin } from '@digia/moengage-react-native';
 *
 * await Digia.initialize({ apiKey: 'YOUR_KEY' });
 *
 * const plugin = new DigiaMoEngagePlugin({ moEngage: MoEngage });
 * plugin.setup();
 * ```
 */

export { DigiaMoEngagePlugin } from './DigiaMoEngagePlugin';
export type { DigiaMoEngagePluginOptions } from './DigiaMoEngagePlugin';
export type { ICampaignCache } from './CampaignCache';
export { CampaignCache } from './CampaignCache';
export { mapCampaignPayload } from './CampaignPayloadMapper';
export type {
    DigiaExperienceEvent,
    IMoEngageInApp,
} from './MoEngageEventDispatcher';
export type {
    InAppPayload,
    MoEngageSelfHandledData,
    MoEngageCampaignData,
} from './types';
