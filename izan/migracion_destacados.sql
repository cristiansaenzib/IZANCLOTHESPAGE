-- IZAN Clothes: etiquetas editoriales para productos
-- Ejecutar una sola vez en Supabase > SQL Editor > Run.
alter table public.products
  add column if not exists is_best_seller boolean not null default false,
  add column if not exists is_last_units boolean not null default false,
  add column if not exists is_new_arrival boolean not null default false;
