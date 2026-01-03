import { Router } from 'express';
import expressAsyncHandler from 'express-async-handler';
import { authMiddleware } from '../../middleware/auth';
import { requireRole } from '../../middleware/requireRole';
import {
  createCategoriaProducto,
  createProducto,
  deleteCategoriaProducto,
  deleteProducto,
  getCategoriaProducto,
  getProducto,
  incrementProductoSearch,
  addProductoItem,
  deleteProductoItem,
  listProductoItems,
  listCategoriasProducto,
  listProductos,
  updateProductoItem,
  updateCategoriaProducto,
  updateProducto,
} from './catalog.controller';

export const catalogRouter = Router();

catalogRouter.use(authMiddleware);

// Categorías
catalogRouter.get('/categories', expressAsyncHandler(listCategoriasProducto));
catalogRouter.post(
  '/categories',
  requireRole(['admin']),
  expressAsyncHandler(createCategoriaProducto),
);
catalogRouter.get('/categories/:id', expressAsyncHandler(getCategoriaProducto));
catalogRouter.put(
  '/categories/:id',
  requireRole(['admin']),
  expressAsyncHandler(updateCategoriaProducto),
);
catalogRouter.delete(
  '/categories/:id',
  requireRole(['admin']),
  expressAsyncHandler(deleteCategoriaProducto),
);

// Productos
catalogRouter.get('/products', expressAsyncHandler(listProductos));
catalogRouter.post('/products', requireRole(['admin']), expressAsyncHandler(createProducto));
catalogRouter.get('/products/:id', expressAsyncHandler(getProducto));
catalogRouter.put('/products/:id', requireRole(['admin']), expressAsyncHandler(updateProducto));
catalogRouter.delete(
  '/products/:id',
  requireRole(['admin']),
  expressAsyncHandler(deleteProducto),
);

// Items de servicios/paquetes
catalogRouter.get('/products/:id/items', expressAsyncHandler(listProductoItems));
catalogRouter.post(
  '/products/:id/items',
  requireRole(['admin']),
  expressAsyncHandler(addProductoItem),
);
catalogRouter.put(
  '/products/:id/items/:itemId',
  requireRole(['admin']),
  expressAsyncHandler(updateProductoItem),
);
catalogRouter.delete(
  '/products/:id/items/:itemId',
  requireRole(['admin']),
  expressAsyncHandler(deleteProductoItem),
);

catalogRouter.post(
  '/products/:id/increment-search',
  expressAsyncHandler(incrementProductoSearch),
);
