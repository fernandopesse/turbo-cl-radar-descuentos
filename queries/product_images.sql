-- Mapa productId → URL de foto — fuente: RP_SILVER_DB_PROD.TURBO_SUPPLY.CL_PRODUCT_NEW_CATALOG
--
-- Resultado: mapa RETAILER_PRODUCT_ID → MP_PHOTO_URL usado para mostrar fotos
-- en Calendario Promos Top (Tab 2).
--
-- Nota de implementación actual (junio 2026):
--   Este mapa ya NO está hardcodeado en el HTML. Se sirve dinámicamente desde
--   la pestaña "ImagesDash" del Google Sheet comercial, que Code.gs expone como
--   payload.imageMap en la respuesta JSONP. El HTML lo almacena en
--   window.SHEET_IMAGE_MAP y lo usa en el lookup de imágenes.
--
-- La query original que pobló EAN_IMAGES (mapa estático, ya reemplazado):

SELECT DISTINCT
  CAST(RETAILER_PRODUCT_ID AS VARCHAR)  AS product_id,   -- = d.productId en el JS (Content Portal ID)
  MP_PHOTO_URL                          AS image_url
FROM RP_SILVER_DB_PROD.TURBO_SUPPLY.CL_PRODUCT_NEW_CATALOG
WHERE RETAILER_ID   = 161               -- Turbo Chile
  AND MP_PHOTO_URL  IS NOT NULL
  AND TRIM(MP_PHOTO_URL) != ''
  AND RETAILER_PRODUCT_ID IS NOT NULL
ORDER BY RETAILER_PRODUCT_ID;

-- Columnas relevantes de la tabla:
--   RETAILER_PRODUCT_ID  → Content Portal ID (coincide con d.productId del calendario)
--   MASTER_PRODUCT_ID    → ID global de producto
--   EAN                  → código de barras (puede ser PLU para frescos, ej: 300012000024)
--   NAME                 → nombre del producto
--   MP_PHOTO_URL         → URL CDN de la foto (images.rappi.cl/products/uuid.png)
--   RETAILER_ID = 161    → Turbo Chile
--
-- El mapa hoy se mantiene en la pestaña ImagesDash del spreadsheet comercial
-- (ID: 1VgL5k6ZtL6DgPjymjVxg_6D-HeajXvqUz3ZZDLNk4JA).
