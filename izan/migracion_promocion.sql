-- IZAN Clothes: precio de promoción por producto
-- Ejecutar UNA vez en Supabase > SQL Editor > Run.
-- price_promo = precio promocional (0 = sin promoción). Solo se muestra si es menor al precio detal.
alter table public.products
  add column if not exists price_promo integer not null default 0;
