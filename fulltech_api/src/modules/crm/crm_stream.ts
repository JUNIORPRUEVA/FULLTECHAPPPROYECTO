import { EventEmitter } from 'events';

export type CrmStreamEvent =
  | { type: 'chat.updated'; chatId: string }
  | { type: 'chat.deleted'; chatId: string }
  | { type: 'message.new'; chatId: string; messageId: string }
  | { type: 'message.updated'; chatId: string; messageId: string }
  | { type: 'message.status'; chatId: string; remoteMessageId: string; status: string };

const emitter = new EventEmitter();

export function onCrmEvent(listener: (evt: CrmStreamEvent) => void) {
  emitter.on('evt', listener);
  return () => emitter.off('evt', listener);
}

export function emitCrmEvent(evt: CrmStreamEvent) {
  emitter.emit('evt', evt);
}
