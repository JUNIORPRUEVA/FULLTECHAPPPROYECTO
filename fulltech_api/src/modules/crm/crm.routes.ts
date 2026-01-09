import { Router } from 'express';
import expressAsyncHandler from 'express-async-handler';
import { authMiddleware } from '../../middleware/auth';
import { requireRole } from '../../middleware/requireRole';
import {
  createQuickReply,
  deleteQuickReply,
  listQuickReplies,
  updateQuickReply,
} from './crm_quick_replies.controller';
import {
  convertChatToCustomer,
  deleteChatMessage,
  deletePurchasedClient,
  deleteChat,
  editChatMessage,
  getChat,
  getPurchasedClient,
  listChats,
  listChatMessages,
  listChatStats,
  listPurchasedClients,
  markChatRead,
  patchChat,
  postChatStatus,
  postUpload,
  recordMediaMessage,
  sendOutboundTextMessage,
  sendMediaMessage,
  sendTextMessage,
  sseStream,
  updatePurchasedClient,
  uploadCrmFile,
} from './crm_whatsapp.controller';
import {
  convertThreadToCustomer,
  createTaskForThread,
  createThread,
  deleteTask,
  getThread,
  listMessages,
  listTasks,
  listThreads,
  patchTask,
  patchThread,
  postMessage,
  sendMessage,
} from './crm.controller';

export const crmRouter = Router();

crmRouter.use(authMiddleware);

// =====================
// WhatsApp-like CRM (new)
// =====================

crmRouter.get('/chats', expressAsyncHandler(listChats));
crmRouter.get('/chats/stats', expressAsyncHandler(listChatStats));
// NEW: Purchased clients endpoint (status = "compro" only)
crmRouter.get('/purchased-clients', expressAsyncHandler(listPurchasedClients));
crmRouter.get('/purchased-clients/:clientId', expressAsyncHandler(getPurchasedClient));
crmRouter.patch('/purchased-clients/:clientId', expressAsyncHandler(updatePurchasedClient));
crmRouter.delete('/purchased-clients/:clientId', expressAsyncHandler(deletePurchasedClient));
crmRouter.get('/chats/:chatId', expressAsyncHandler(getChat));
crmRouter.get('/chats/:chatId/messages', expressAsyncHandler(listChatMessages));
crmRouter.patch('/chats/:chatId/messages/:messageId', expressAsyncHandler(editChatMessage));
crmRouter.delete('/chats/:chatId/messages/:messageId', expressAsyncHandler(deleteChatMessage));
crmRouter.post('/chats/:chatId/status', expressAsyncHandler(postChatStatus));
crmRouter.patch('/chats/:chatId', expressAsyncHandler(patchChat));
crmRouter.delete(
  '/chats/:chatId',
  requireRole(['admin', 'administrador']),
  expressAsyncHandler(deleteChat),
);
crmRouter.post('/chats/:chatId/convert-to-customer', expressAsyncHandler(convertChatToCustomer));
crmRouter.patch('/chats/:chatId/read', expressAsyncHandler(markChatRead));
crmRouter.post('/chats/:chatId/messages/text', expressAsyncHandler(sendTextMessage));
crmRouter.post('/chats/outbound/text', expressAsyncHandler(sendOutboundTextMessage));
crmRouter.post(
  '/chats/:chatId/messages/media',
  uploadCrmFile,
  expressAsyncHandler(sendMediaMessage),
);

// Record-only helper for client direct Evolution sends.
crmRouter.post(
  '/chats/:chatId/messages/media-record',
  expressAsyncHandler(recordMediaMessage),
);

crmRouter.get('/stream', expressAsyncHandler(sseStream));

// Upload helper for media
crmRouter.post('/upload', uploadCrmFile, expressAsyncHandler(postUpload));

// Quick Replies (templates) - restricted
crmRouter.get('/quick-replies', expressAsyncHandler(listQuickReplies));
crmRouter.post(
  '/quick-replies',
  requireRole(['admin', 'administrador']),
  expressAsyncHandler(createQuickReply),
);
crmRouter.put(
  '/quick-replies/:id',
  requireRole(['admin', 'administrador']),
  expressAsyncHandler(updateQuickReply),
);
crmRouter.delete(
  '/quick-replies/:id',
  requireRole(['admin', 'administrador']),
  expressAsyncHandler(deleteQuickReply),
);

// Threads
crmRouter.get('/threads', expressAsyncHandler(listThreads));
crmRouter.get('/threads/:id', expressAsyncHandler(getThread));
crmRouter.post('/threads', expressAsyncHandler(createThread));
crmRouter.patch('/threads/:id', expressAsyncHandler(patchThread));

// Convert lead -> customer
crmRouter.post('/threads/:id/convert-to-customer', expressAsyncHandler(convertThreadToCustomer));

// Messages
crmRouter.get('/threads/:id/messages', expressAsyncHandler(listMessages));
crmRouter.post('/threads/:id/messages', expressAsyncHandler(postMessage));

// Send via Evolution API
crmRouter.post('/threads/:id/send', expressAsyncHandler(sendMessage));

// Tasks
crmRouter.get('/tasks', expressAsyncHandler(listTasks));
crmRouter.post('/threads/:id/tasks', expressAsyncHandler(createTaskForThread));
crmRouter.patch('/tasks/:id', expressAsyncHandler(patchTask));
crmRouter.delete('/tasks/:id', expressAsyncHandler(deleteTask));
