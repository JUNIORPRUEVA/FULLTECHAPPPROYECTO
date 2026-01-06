# POS/TPV – Base de datos (nube + local) y sincronización

Este documento describe el diseño mínimo para que el módulo POS/TPV funcione con **PostgreSQL (nube)** y con **persistencia local (offline)**, y logre **sincronización inmediata** cuando hay internet y **subida automática** cuando vuelve la conectividad.

## Nube (PostgreSQL / Prisma)

El backend (Express + Prisma) ya contiene las tablas del módulo POS separadas del módulo de ventas existente, bajo el prefijo `pos_*`.

Tablas principales (alto nivel):
- `pos_sales` + `pos_sale_items`: ventas y sus líneas.
- `pos_purchase_orders` + `pos_purchase_items`: compras.
- `pos_stock_movements`: movimientos de inventario (incluye entradas/salidas por venta, compra, ajustes y devoluciones por cancelación).
- `pos_credit_accounts`: cuentas por cobrar/ventas a crédito.
- `pos_fiscal_sequences`: secuencias fiscales para NCF.
- `pos_suppliers`: suplidores.

Productos:
- Los productos se obtienen desde la tabla de catálogo existente (modelo Prisma `Producto`).
- Endpoint de lectura: `GET /api/pos/products` (filtra por `empresa_id`).

## Local (offline)

Se usa el `LocalDb` existente como almacenamiento offline, sin crear un motor nuevo:

### 1) Cache local de productos
- **Store**: `pos_products_<empresaId>`
- **Contenido**: snapshot JSON por producto (id → JSON)
- **Objetivo**: permitir que el GridView del TPV muestre productos incluso si falla la red.

### 2) Outbox (cola) de operaciones POS
- **Tabla/cola existente**: `sync_queue` (accedida por `LocalDb.enqueueSync()`)
- **module**: `pos`
- **op**: `checkout`
- **payload**: JSON con `{ sale: {...}, payment: {...} }`

Este outbox es “durable”: si el usuario cobra sin internet, la venta queda guardada localmente y será subida luego.

## Flujo de sincronización

### Online
1. TPV intenta crear la venta (`POST /api/pos/sales`).
2. TPV paga la venta (`POST /api/pos/sales/:id/pay`).
3. Se guarda `lastPaidSale` para permitir “Imprimir último ticket”.

### Offline
1. Si ocurre error de red durante el cobro, el TPV **no bloquea** al usuario.
2. Se encola un item `sync_queue` con `module=pos`, `op=checkout` y el payload de venta+pago.
3. El ticket se limpia para continuar vendiendo.

### Reintento automático (cuando vuelve internet)
- `AutoSync` (ya existente) se ejecuta:
  - al volver conectividad,
  - al reanudar la app,
  - periódicamente.
- Se invoca `posRepository.syncPending()`:
  - toma items `module=pos/op=checkout`.
  - ejecuta `createSale` → obtiene `saleId`.
  - ejecuta `paySale` con ese `saleId`.
  - marca el item como enviado o error.

## Notas
- Los endpoints POS del cliente deben ser **rutas relativas** (`pos/...`) para respetar el `baseUrl` que ya termina en `/api`.
- Para “todos los productos”, el backend soporta `take` y `skip` en `GET /api/pos/products` y el TPV paginará internamente.
