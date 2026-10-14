-- Ejecutar una sola vez en Supabase > SQL Editor
-- Añade el campo usado por el filtro de color del catálogo.
alter table public.products
  add column if not exists color text not null default '';
