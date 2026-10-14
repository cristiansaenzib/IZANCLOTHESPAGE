-- IZAN: habilitar talla XXL y tallas configurables por categoría.
-- Ejecutar una sola vez en Supabase > SQL Editor.
alter table public.products
  add column if not exists stock_xxl integer not null default 0 check (stock_xxl >= 0);

alter table public.categories
  add column if not exists sizes text not null default '["S","M","L","XL"]';

alter table public.inventory_movements
  drop constraint if exists inventory_movements_size_check;

alter table public.inventory_movements
  add constraint inventory_movements_size_check
  check (size in ('S','M','L','XL','XXL'));
