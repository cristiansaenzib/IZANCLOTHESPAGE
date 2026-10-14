-- IZAN Clothes: cotizaciones/pedidos para el panel de administración
-- Ejecutar en Supabase > SQL Editor > Run.
create table if not exists public.orders (
  id uuid primary key default gen_random_uuid(),
  status text not null default 'pending' check (status in ('pending','sold')),
  total integer not null default 0,
  units integer not null default 0,
  items jsonb not null default '[]'::jsonb,
  wholesale_code text,
  wholesale_name text,
  created_at timestamptz not null default now(),
  sold_at timestamptz
);
alter table public.orders enable row level security;
drop policy if exists "public crear cotizaciones" on public.orders;
drop policy if exists "admin gestionar pedidos" on public.orders;
-- La tienda puede registrar cotizaciones, pero no leerlas ni modificarlas.
create policy "public crear cotizaciones" on public.orders for insert to anon, authenticated
  with check (status = 'pending' and sold_at is null);
-- Solo el correo administrador puede consultar, vender o eliminar pedidos.
create policy "admin gestionar pedidos" on public.orders for all to authenticated
  using ((auth.jwt() ->> 'email') = 'saenz1098@gmail.com')
  with check ((auth.jwt() ->> 'email') = 'saenz1098@gmail.com');
