-- Snapshot WMS de promociones cargadas — fuente: FIVETRAN.CL_AMYSQL_TURBO_EMERGENCY_ORDER_TURBO_PROMOTION_ENGINE
--
-- Contexto (estado actual junio 2026):
--   El Tab 2 "Verificado en WMS" fue refactorizado para usar datos en vivo desde
--   Google Sheets (misma fuente que Tab 1). El snapshot estático de WMS ya no
--   se usa activamente. Estas queries documentan cómo se construía antes.
--
-- Supply_Data 2026_Q1Q2 y Q3Q4: eran archivos intermedios generados por estas
-- queries para cruzar el calendario comercial contra el estado de carga en WMS.

-- ─── 1. Promociones activas en el motor WMS ────────────────────────────────
SELECT
  p.ID                    AS promotion_id,
  p.NAME                  AS promotion_name,
  p.START_DATE,
  p.END_DATE,
  p.DISCOUNT_PERCENTAGE   AS discount_pct,
  p.STATUS,
  pi.PRODUCT_ID           AS product_id,
  pi.EAN,
  pi.STORE_PRODUCT_ID     AS sync_id
FROM FIVETRAN.CL_AMYSQL_TURBO_EMERGENCY_ORDER_TURBO_PROMOTION_ENGINE p
LEFT JOIN FIVETRAN.CL_AMYSQL_TURBO_EMERGENCY_ORDER_TURBO_PROMOTION_ENGINE_ITEM pi
  ON pi.PROMOTION_ID = p.ID
WHERE p.START_DATE >= '2026-01-01'
  AND p.STATUS NOT IN ('CANCELLED', 'DRAFT')
ORDER BY p.START_DATE DESC, p.ID;

-- ─── 2. Cruce calendario comercial (Google Sheets) vs WMS ─────────────────
-- El cruce se hace en el cliente (JavaScript) comparando:
--   - d.ean / d.productId del calendario (Google Sheets via Apps Script)
--   - EAN / PRODUCT_ID de la tabla WMS
--
-- wmsStatus resultante:
--   'cargado'      → EAN encontrado en WMS con descuento que coincide (±1pp)
--   'smart_only'   → encontrado pero solo en canal SMART (no full)
--   'no_encontrado'→ EAN no aparece en WMS para ese período

-- ─── 3. Query GMV como referencia para cruce (misma base que gmv_data.sql) ─
-- Ver queries/gmv_data.sql para el cálculo de GMV semanal por EAN.

-- Nota sobre "Supply_Data 2026_Q1Q2 / Q3Q4":
--   Eran snapshots manuales en Excel/CSV generados corriendo las queries
--   anteriores para períodos específicos y cruzándolos con el calendario
--   comercial. No existían como archivos Python — el proceso era:
--   1. Correr query WMS en Snowflake → exportar CSV
--   2. Correr query calendario desde Apps Script → exportar JSON
--   3. Claude procesaba ambos y generaba el bloque const WEEKS = {...} del HTML
