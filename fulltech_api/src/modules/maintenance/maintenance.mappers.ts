type MaybeDate = Date | string | null | undefined;

function toIso(value: MaybeDate): string | null {
  if (!value) return null;
  if (value instanceof Date) return value.toISOString();
  return new Date(value).toISOString();
}

export function mapProductBasicInfo(p: any) {
  if (!p) return null;
  return {
    id: p.id,
    nombre: p.nombre,
    imagenUrl: p.imagen_url ?? p.imagenUrl ?? null,
    precioVenta: p.precio_venta ?? p.precioVenta ?? null,
  };
}

export function mapUserBasicInfo(u: any) {
  if (!u) return null;
  return {
    id: u.id,
    nombreCompleto: u.nombre_completo ?? u.nombreCompleto,
    email: u.email ?? null,
  };
}

export function mapMaintenanceRecord(m: any) {
  return {
    id: m.id,
    empresaId: m.empresa_id,
    productoId: m.producto_id,
    createdByUserId: m.created_by_user_id,
    maintenanceType: m.maintenance_type,
    statusBefore: m.status_before ?? null,
    statusAfter: m.status_after,
    issueCategory: m.issue_category ?? null,
    description: m.description,
    internalNotes: m.internal_notes ?? null,
    cost: m.cost != null ? Number(m.cost) : null,
    warrantyCaseId: m.warranty_case_id ?? null,
    attachmentUrls: m.attachment_urls ?? [],
    createdAt: toIso(m.created_at)!,
    updatedAt: toIso(m.updated_at)!,
    deletedAt: toIso(m.deleted_at),
    producto: mapProductBasicInfo(m.producto),
    createdBy: mapUserBasicInfo(m.created_by),
  };
}

export function mapWarrantyCase(w: any) {
  return {
    id: w.id,
    empresaId: w.empresa_id,
    productoId: w.producto_id,
    createdByUserId: w.created_by_user_id,
    warrantyStatus: w.warranty_status,
    supplierName: w.supplier_name ?? null,
    supplierTicket: w.supplier_ticket ?? null,
    sentDate: toIso(w.sent_date),
    receivedDate: toIso(w.received_date),
    closedAt: toIso(w.closed_at),
    problemDescription: w.problem_description,
    resolutionNotes: w.resolution_notes ?? null,
    attachmentUrls: w.attachment_urls ?? [],
    createdAt: toIso(w.created_at)!,
    updatedAt: toIso(w.updated_at)!,
    deletedAt: toIso(w.deleted_at),
    producto: mapProductBasicInfo(w.producto),
    createdBy: mapUserBasicInfo(w.created_by),
  };
}

export function mapInventoryAudit(a: any) {
  return {
    id: a.id,
    empresaId: a.empresa_id,
    createdByUserId: a.created_by_user_id,
    auditFromDate: toIso(a.audit_from_date)!,
    auditToDate: toIso(a.audit_to_date)!,
    weekLabel: a.week_label,
    notes: a.notes ?? null,
    status: a.status,
    createdAt: toIso(a.created_at)!,
    updatedAt: toIso(a.updated_at)!,
    createdBy: mapUserBasicInfo(a.created_by),
    totalItems: a.totalItems ?? a.total_items ?? null,
    totalDiferencias: a.totalDiferencias ?? a.total_diferencias ?? null,
  };
}

export function mapInventoryAuditItem(i: any) {
  return {
    id: i.id,
    auditId: i.audit_id,
    productoId: i.producto_id,
    expectedQty: i.expected_qty,
    countedQty: i.counted_qty,
    diffQty: i.diff_qty,
    reason: i.reason ?? null,
    explanation: i.explanation ?? null,
    actionTaken: i.action_taken,
    createdAt: toIso(i.created_at)!,
    producto: mapProductBasicInfo(i.producto),
  };
}
