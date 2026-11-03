-- IZAN Clothes · Rendimiento
-- Ejecuta este archivo UNA vez en Supabase → SQL Editor → Run. No borra ni modifica datos.

-- ===== RENDIMIENTO: índices para listar y filtrar más rápido (seguro de ejecutar varias veces) =====
create index if not exists products_created_at_idx on public.products (created_at desc);
create index if not exists products_category_id_idx on public.products (category_id);
create index if not exists orders_created_at_idx on public.orders (created_at desc);
create index if not exists orders_status_idx on public.orders (status);
do $$ begin
  if to_regclass('public.customers') is not null then
    execute 'create index if not exists customers_created_at_idx on public.customers (created_at desc)';
  end if;
end $$;
