-- GMV semanal promedio por EAN — fuente: RP_SILVER_DB_PROD.TURBO_CORE.CL_ORDER_DISCOUNTS
--
-- Resultado: mapa EAN → promedio de GMV semanal (CLP con IVA) usado en GMV_DATA
-- del index.html para calcular dealImpactScore = (discountPct / 100) * GMV_DATA[ean]
--
-- Lógica:
--   1. Filtrar últimas 13 semanas ISO completas (lunes-domingo) anteriores a la fecha de ejecución
--   2. Solo líneas de orden que cuentan para GMV (COUNT_TO_GMV = TRUE)
--   3. Sumar TOTAL_PRICE_W_IVA por EAN por semana
--   4. Promediar esas sumas semanales por EAN

WITH weeks AS (
  SELECT
    DATE_TRUNC('week', DATEADD('week', -n, CURRENT_DATE()))::DATE AS week_start,
    DATEADD('day', 6, DATE_TRUNC('week', DATEADD('week', -n, CURRENT_DATE())))::DATE AS week_end
  FROM (
    SELECT ROW_NUMBER() OVER (ORDER BY SEQ4()) AS n
    FROM TABLE(GENERATOR(ROWCOUNT => 13))
  )
  -- Excluir la semana en curso (solo semanas completas)
  WHERE DATE_TRUNC('week', DATEADD('week', -n, CURRENT_DATE())) < DATE_TRUNC('week', CURRENT_DATE())
),
weekly_gmv AS (
  SELECT
    od.EAN,
    w.week_start,
    SUM(od.TOTAL_PRICE_W_IVA) AS gmv_week
  FROM RP_SILVER_DB_PROD.TURBO_CORE.CL_ORDER_DISCOUNTS od
  JOIN weeks w
    ON od.CREATED_AT::DATE BETWEEN w.week_start AND w.week_end
  WHERE od.COUNT_TO_GMV = TRUE
    AND od.EAN IS NOT NULL
    AND od.COUNTRY = 'CL'
  GROUP BY od.EAN, w.week_start
)
SELECT
  EAN,
  ROUND(AVG(gmv_week), 0) AS avg_weekly_gmv_clp
FROM weekly_gmv
GROUP BY EAN
HAVING AVG(gmv_week) > 0
ORDER BY avg_weekly_gmv_clp DESC;

-- Nota: el resultado se transforma en el objeto JS GMV_DATA = { '7802000001234': 450000, ... }
-- embebido en index.html. Para actualizar GMV_DATA, correr esta query y reemplazar
-- el bloque const GMV_DATA = {...} en el segundo <script> tag del HTML.
