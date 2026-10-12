-- Ejecutar UNA vez en Supabase -> SQL Editor (despues de migracion_precios.sql si venias de gramajes).
alter table categories add column if not exists tiers text;
alter table products
  add column if not exists price_dist  integer not null default 0,
  add column if not exists price_mayor integer not null default 0,
  add column if not exists tiers text;
-- Las reglas (cantidades y %) y la forma de contar se guardan en la tabla settings desde el panel admin.
