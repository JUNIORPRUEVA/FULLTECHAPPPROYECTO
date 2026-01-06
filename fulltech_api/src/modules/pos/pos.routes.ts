import { Router } from 'express';
import expressAsyncHandler from 'express-async-handler';

import { authMiddleware } from '../../middleware/auth';
import { requireRole } from '../../middleware/requireRole';
import {
  cancelPosSale,
  createPosSale,
  createPurchase,
  getCredit,
  getPosSale,
  getPurchase,
  inventoryAdjust,
  listCredit,
  listInventoryMovements,
  listPosProducts,
  listPosSales,
  listPurchases,
  nextFiscalNcf,
  payPosSale,
  reportCreditAging,
  reportInventoryLowStock,
  reportPurchasesSummary,
  reportSalesSummary,
  reportTopProducts,
  receivePurchase,
} from './pos.controller';

export const posRouter = Router();

posRouter.use(authMiddleware);

// Products
posRouter.get('/products', expressAsyncHandler(listPosProducts));

// Sales
posRouter.post('/sales', requireRole(['admin', 'vendedor']), expressAsyncHandler(createPosSale));
posRouter.get('/sales', expressAsyncHandler(listPosSales));
posRouter.get('/sales/:id', expressAsyncHandler(getPosSale));
posRouter.post('/sales/:id/pay', requireRole(['admin', 'vendedor']), expressAsyncHandler(payPosSale));
posRouter.post('/sales/:id/cancel', requireRole(['admin', 'administrador']), expressAsyncHandler(cancelPosSale));

// Fiscal
posRouter.post('/fiscal/next-ncf', requireRole(['admin', 'vendedor']), expressAsyncHandler(nextFiscalNcf));

// Purchases
posRouter.post('/purchases', requireRole(['admin', 'vendedor']), expressAsyncHandler(createPurchase));
posRouter.get('/purchases', expressAsyncHandler(listPurchases));
posRouter.get('/purchases/:id', expressAsyncHandler(getPurchase));
posRouter.post('/purchases/:id/receive', requireRole(['admin', 'vendedor']), expressAsyncHandler(receivePurchase));

// Inventory
posRouter.post('/inventory/adjust', requireRole(['admin', 'vendedor']), expressAsyncHandler(inventoryAdjust));
posRouter.get('/inventory/movements', expressAsyncHandler(listInventoryMovements));

// Credit
posRouter.get('/credit', expressAsyncHandler(listCredit));
posRouter.get('/credit/:id', expressAsyncHandler(getCredit));

// Reports
posRouter.get('/reports/sales-summary', expressAsyncHandler(reportSalesSummary));
posRouter.get('/reports/top-products', expressAsyncHandler(reportTopProducts));
posRouter.get('/reports/inventory-low-stock', expressAsyncHandler(reportInventoryLowStock));
posRouter.get('/reports/purchases-summary', expressAsyncHandler(reportPurchasesSummary));
posRouter.get('/reports/credit-aging', expressAsyncHandler(reportCreditAging));
