import { prisma } from '../prismaClient'; // Adjust the import based on your project structure

/**
 * Resolves empresa_id from multiple sources with fallback chain
 * @param {Object} options
 * @param {Object} options.chat - Chat object that may contain empresa_id
 * @param {Object} options.reqUser - Authenticated user that may contain empresa_id
 * @param {string} options.instance - Instance name for logging
 * @returns {string} Resolved empresa_id
 * @throws {Error} If empresa_id cannot be resolved
 */
function resolveEmpresaId({ chat, reqUser, instance }) {
  if (chat?.empresa_id) {
    return chat.empresa_id;
  }
  if (reqUser?.empresa_id) {
    return reqUser.empresa_id;
  }
  if (process.env.DEFAULT_EMPRESA_ID) {
    return process.env.DEFAULT_EMPRESA_ID;
  }
  
  const error = `[CRITICAL] empresa_id missing for instance ${instance}. Chat: ${chat?.id}, User: ${reqUser?.id}`;
  console.error(error);
  throw new Error(error);
}

/**
 * Gets or creates a chat in the database
 * @param {Object} prisma - Prisma client instance
 * @param {string} remoteJid - Remote JID of the chat
 * @param {string} instance - Instance name
 * @param {string} pushName - Push name of the user
 * @param {Object} reqUser - Authenticated user object
 * @returns {Object} Chat object
 * @throws {Error} If there is an error during the database operation
 */
async function getOrCreateChat(prisma, remoteJid, instance, pushName, reqUser) {
  try {
    let chat = await prisma.crmChat.findFirst({
      where: {
        remoteJid: remoteJid,
        instance: instance,
      },
      include: { empresa: true },
    });

    if (!chat) {
      // Resolve empresa_id before creating chat
      const empresaId = resolveEmpresaId({ chat: null, reqUser, instance });
      
      chat = await prisma.crmChat.create({
        data: {
          remoteJid: remoteJid,
          instance: instance,
          pushName: pushName || remoteJid,
          empresa_id: empresaId, // Always set empresa_id
          unreadCount: 0,
        },
        include: { empresa: true },
      });
      
      console.log(`[Webhook] Created new chat ${chat.id} with empresa_id: ${empresaId}`);
    }

    return chat;
  } catch (error) {
    console.error('[Webhook] Error in getOrCreateChat:', error);
    throw error;
  }
}

/**
 * Handles the message event from the webhook
 * @param {Object} event - The event object from the webhook
 * @param {string} instance - Instance name
 * @param {Object} reqUser - Authenticated user object
 */
async function handleMessageEvent(event, instance, reqUser) {
  try {
    const remoteJid = event.data?.key?.remoteJid;
    const pushName = event.data?.pushName;
    
    if (!remoteJid) {
      console.warn('[Webhook] Skipping message: no remoteJid');
      return;
    }

    const chat = await getOrCreateChat(prisma, remoteJid, instance, pushName, reqUser);
    
    // Resolve empresa_id for message creation
    const empresaId = resolveEmpresaId({ chat, reqUser, instance });

    // Wrap message persistence in try/catch
    try {
      const messageData = {
        chatId: chat.id,
        empresa_id: empresaId, // Always include empresa_id
        key: event.data.key,
        messageType: event.data.messageType,
        fromMe: event.data.key.fromMe,
        messageTimestamp: event.data.messageTimestamp,
        pushName: event.data.pushName,
        body: event.data.message?.conversation || event.data.message?.extendedTextMessage?.text || '',
        status: 'received',
      };

      const savedMessage = await prisma.crmChatMessage.create({
        data: messageData,
      });

      console.log(`[Webhook] Message saved: ${savedMessage.id} with empresa_id: ${empresaId}`);
      
      // Update chat lastMessage
      await prisma.crmChat.update({
        where: { id: chat.id },
        data: {
          lastMessage: messageData.body,
          lastMessageAt: new Date(event.data.messageTimestamp * 1000),
        },
      });
    } catch (msgError) {
      console.error('[Webhook] Error persisting message (non-fatal):', {
        error: msgError.message,
        remoteJid,
        instance,
        empresaId,
      });
      // Don't throw - continue processing other events
    }
  } catch (error) {
    console.error('[Webhook] Error handling message event:', error);
    // Log but don't crash the entire webhook handler
  }
}

export {
  resolveEmpresaId,
  getOrCreateChat,
  handleMessageEvent,
};