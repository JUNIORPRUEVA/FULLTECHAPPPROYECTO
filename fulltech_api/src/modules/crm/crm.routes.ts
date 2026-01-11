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
  clearBoughtInboxFlag,
  editChatMessage,
  getChat,
  getPurchasedClient,
  listBoughtChats,
  listBoughtInbox,
  listChats,
  listChatMessages,
  listChatStats,
  listPurchasedClients,
  markChatRead,
  patchChat,
  patchPostSaleState,
  postChatStatus,
  sendOutboundTextMessage,
  sendTextMessage,
  sseStream,
  updatePurchasedClient,
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
import { listCrmOperationsItems } from './crm_operations.controller';
import {
  createInstance,
  deleteInstance,
  getActiveInstance,
  getInstance,
  listInstances,
  listUsersForTransfer,
  testConnection,
  transferChat,
  updateInstance,
} from './crm_instances.controller';

export const crmRouter = Router();

crmRouter.use(authMiddleware);

// =====================
// CRM Instances (Multi-Instance Support)
// =====================

crmRouter.get('/instances', expressAsyncHandler(listInstances));
crmRouter.get('/instances/active', expressAsyncHandler(getActiveInstance));
crmRouter.get('/instances/:id', expressAsyncHandler(getInstance));
crmRouter.post('/instances', expressAsyncHandler(createInstance));
crmRouter.patch('/instances/:id', expressAsyncHandler(updateInstance));
crmRouter.delete('/instances/:id', expressAsyncHandler(deleteInstance));
crmRouter.post('/instances/test-connection', expressAsyncHandler(testConnection));

// Chat transfer
crmRouter.post('/chats/:chatId/transfer', expressAsyncHandler(transferChat));
crmRouter.get('/users/transfer-list', expressAsyncHandler(listUsersForTransfer));

// =====================
// WhatsApp-like CRM (new)
// =====================

crmRouter.get('/chats', expressAsyncHandler(listChats));
crmRouter.get('/chats/stats', expressAsyncHandler(listChatStats));
// Bought clients flow
crmRouter.get('/chats/bought', expressAsyncHandler(listBoughtChats));
crmRouter.get('/chats/bought/inbox', expressAsyncHandler(listBoughtInbox));
crmRouter.patch('/chats/:chatId/bought/inbox/clear', expressAsyncHandler(clearBoughtInboxFlag));
crmRouter.patch('/chats/:chatId/post-sale-state', expressAsyncHandler(patchPostSaleState));
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

// CRM → Operations helper list (filtered by current user)
crmRouter.get('/operations/items', expressAsyncHandler(listCrmOperationsItems));

crmRouter.get('/stream', expressAsyncHandler(sseStream));

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
