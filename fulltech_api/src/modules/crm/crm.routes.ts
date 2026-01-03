import { Router } from 'express';
import expressAsyncHandler from 'express-async-handler';
import { authMiddleware } from '../../middleware/auth';
import {
  listChats,
  listChatMessages,
  markChatRead,
  postUpload,
  sendMediaMessage,
  sendTextMessage,
  sseStream,
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
crmRouter.get('/chats/:chatId/messages', expressAsyncHandler(listChatMessages));
crmRouter.post('/chats/:chatId/messages/text', expressAsyncHandler(sendTextMessage));
crmRouter.post(
  '/chats/:chatId/messages/media',
  uploadCrmFile,
  expressAsyncHandler(sendMediaMessage),
);
crmRouter.post('/chats/:chatId/mark-read', expressAsyncHandler(markChatRead));

crmRouter.get('/stream', expressAsyncHandler(sseStream));

// Upload helper for media
crmRouter.post('/upload', uploadCrmFile, expressAsyncHandler(postUpload));

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
