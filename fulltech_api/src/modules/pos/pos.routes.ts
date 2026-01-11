import { Router } from 'express';
import expressAsyncHandler from 'express-async-handler';

import { authMiddleware } from '../../middleware/auth';
import { requirePermission } from '../../middleware/requirePermission';
import {
  cancelPosSale,
  createPosSale,
  createPurchase,
  createFiscalSequence,
  getCredit,
  getCurrentCashbox,
  getPosSale,
  getPurchase,
  inventoryAdjust,
  listCredit,
  listFiscalSequences,
  listInventoryMovements,
  listPosCashboxClosures,
  listPosProducts,
  listPosSales,
  listPurchases,
  nextFiscalNcf,
  openCashbox,
  payPosSale,
  postCashboxMovement,
  reportCreditAging,
  reportInventoryLowStock,
  reportPurchasesSummary,
  reportSalesSummary,
  reportTopProducts,
  receivePurchase,
  closeCashbox,
  updateFiscalSequence,
  deleteFiscalSequence,
} from './pos.controller';
import {
  createPosSupplier,
  deletePosSupplier,
  listPosSuppliers,
  updatePosSupplier,
} from './pos.controller';

export const posRouter = Router();

posRouter.use(authMiddleware);

// Cashbox (Caja)
posRouter.get('/caja/actual', requirePermission('pos.sell'), expressAsyncHandler(getCurrentCashbox));
posRouter.post('/caja/abrir', requirePermission('pos.cashbox.manage'), expressAsyncHandler(openCashbox));
posRouter.post('/caja/movimiento', requirePermission('pos.cashbox.manage'), expressAsyncHandler(postCashboxMovement));
posRouter.post('/caja/cerrar', requirePermission('pos.cashbox.manage'), expressAsyncHandler(closeCashbox));
posRouter.get('/caja/cierres', requirePermission('pos.cashbox.manage'), expressAsyncHandler(listPosCashboxClosures));

// Products
posRouter.get('/products', expressAsyncHandler(listPosProducts));

// Sales
posRouter.post('/sales', requirePermission('pos.sell'), expressAsyncHandler(createPosSale));
posRouter.get('/sales', expressAsyncHandler(listPosSales));
posRouter.get('/sales/:id', expressAsyncHandler(getPosSale));
posRouter.post('/sales/:id/pay', requirePermission('pos.sell'), expressAsyncHandler(payPosSale));
posRouter.post('/sales/:id/cancel', requirePermission('pos.sell'), expressAsyncHandler(cancelPosSale));

// Fiscal
posRouter.get('/fiscal/sequences', requirePermission('pos.sell'), expressAsyncHandler(listFiscalSequences));
posRouter.post('/fiscal/sequences', requirePermission('pos.sell'), expressAsyncHandler(createFiscalSequence));
posRouter.patch('/fiscal/sequences/:id', requirePermission('pos.sell'), expressAsyncHandler(updateFiscalSequence));
posRouter.delete('/fiscal/sequences/:id', requirePermission('pos.sell'), expressAsyncHandler(deleteFiscalSequence));
posRouter.post('/fiscal/next-ncf', requirePermission('pos.sell'), expressAsyncHandler(nextFiscalNcf));

// Purchases
posRouter.post('/purchases', requirePermission('pos.purchases.manage'), expressAsyncHandler(createPurchase));
posRouter.get('/purchases', expressAsyncHandler(listPurchases));
posRouter.get('/purchases/:id', expressAsyncHandler(getPurchase));
posRouter.post('/purchases/:id/receive', requirePermission('pos.purchases.manage'), expressAsyncHandler(receivePurchase));

// Suppliers
posRouter.get('/suppliers', authMiddleware, expressAsyncHandler(listPosSuppliers));
posRouter.post('/suppliers', requirePermission('pos.purchases.manage'), expressAsyncHandler(createPosSupplier));
posRouter.patch('/suppliers/:id', requirePermission('pos.purchases.manage'), expressAsyncHandler(updatePosSupplier));
posRouter.delete('/suppliers/:id', requirePermission('pos.purchases.manage'), expressAsyncHandler(deletePosSupplier));

// Inventory
posRouter.post('/inventory/adjust', requirePermission('pos.inventory.adjust'), expressAsyncHandler(inventoryAdjust));
posRouter.get('/inventory/movements', expressAsyncHandler(listInventoryMovements));

// Credit
posRouter.get('/credit', expressAsyncHandler(listCredit));
posRouter.get('/credit/:id', expressAsyncHandler(getCredit));

// Reports
posRouter.get('/reports/sales-summary', requirePermission('pos.reports.view'), expressAsyncHandler(reportSalesSummary));
posRouter.get('/reports/top-products', requirePermission('pos.reports.view'), expressAsyncHandler(reportTopProducts));
posRouter.get('/reports/inventory-low-stock', requirePermission('pos.reports.view'), expressAsyncHandler(reportInventoryLowStock));
posRouter.get('/reports/purchases-summary', requirePermission('pos.reports.view'), expressAsyncHandler(reportPurchasesSummary));
posRouter.get('/reports/credit-aging', requirePermission('pos.reports.view'), expressAsyncHandler(reportCreditAging));
