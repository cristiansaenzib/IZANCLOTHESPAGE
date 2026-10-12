-- Ejecutar UNA vez en Supabase -> SQL Editor si ya tenias productos creados con precios por gramaje.
-- Crea la columna de precio unico (detal) y copia el primer precio que tenga valor.
alter table products add column if not exists price integer not null default 0;
update products set price = case
  when price_220 > 0 then price_220
  when price_180 > 0 then price_180
  else price_140 end
where price = 0;
-- Las columnas price_140 / price_180 / price_220 quedan sin uso; puedes dejarlas o borrarlas luego.
-- Los porcentajes y cantidades de Distribuidor/Mayorista se guardan en la tabla settings (key 'tiers') desde el panel admin; no requieren SQL.
