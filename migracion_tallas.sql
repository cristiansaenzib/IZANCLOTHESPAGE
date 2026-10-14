-- Ejecutar UNA vez en Supabase -> SQL Editor si ya habias creado las tablas antes de agregar tallas.
alter table products
  add column if not exists stock_s  integer not null default 0,
  add column if not exists stock_m  integer not null default 0,
  add column if not exists stock_l  integer not null default 0,
  add column if not exists stock_xl integer not null default 0;
