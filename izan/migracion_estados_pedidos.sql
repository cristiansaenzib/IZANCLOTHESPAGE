-- IZAN: estados Pendiente, Apartado, Vendido y Cancelado.
-- Ejecutar una sola vez en Supabase > SQL Editor.

alter table public.orders add column if not exists cancelled_at timestamptz;

alter table public.orders drop constraint if exists orders_status_check;
alter table public.orders add constraint orders_status_check
  check (status in ('pending', 'reserved', 'sold', 'cancelled'));

-- Cotizaciones nuevas desde la tienda solo pueden entrar como pendientes.
drop policy if exists "public crear cotizaciones" on public.orders;
create policy "public crear cotizaciones" on public.orders
  for insert to anon, authenticated
  with check (status = 'pending' and sold_at is null);

-- Solo el administrador autorizado puede consultar y cambiar estados.
drop policy if exists "admin gestionar pedidos" on public.orders;
create policy "admin gestionar pedidos" on public.orders
  for all to authenticated
  using ((auth.jwt() ->> 'email') = 'saenz1098@gmail.com')
  with check ((auth.jwt() ->> 'email') = 'saenz1098@gmail.com');

-- Devuelve únicamente cantidades agregadas de apartados; no expone datos personales ni cotizaciones.
create or replace function public.get_reserved_stock()
returns table (product_id uuid, size text, quantity bigint)
language sql
security definer
set search_path = public
as $$
  select
    (item ->> 'product_id')::uuid as product_id,
    lower(item ->> 'size') as size,
    sum((item ->> 'quantity')::bigint) as quantity
  from public.orders o
  cross join lateral jsonb_array_elements(coalesce(o.items, '[]'::jsonb)) as items(item)
  where o.status = 'reserved'
    and item ? 'product_id'
    and lower(coalesce(item ->> 'size', '')) in ('s','m','l','xl','xxl')
    and coalesce(item ->> 'quantity', '') ~ '^[0-9]+$'
  group by (item ->> 'product_id')::uuid, lower(item ->> 'size');
$$;
revoke all on function public.get_reserved_stock() from public;
grant execute on function public.get_reserved_stock() to anon, authenticated;
