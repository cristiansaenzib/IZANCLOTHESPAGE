-- IZAN: historial de movimientos de inventario.
-- Ejecutar una sola vez en Supabase > SQL Editor antes de usar el historial.
create table if not exists public.inventory_movements (
  id uuid primary key default gen_random_uuid(),
  product_id uuid references public.products(id) on delete set null,
  product_name text not null default '',
  size text not null check (size in ('S','M','L','XL')),
  delta integer not null check (delta <> 0),
  before_stock integer not null check (before_stock >= 0),
  after_stock integer not null check (after_stock >= 0),
  reason text not null,
  source text not null default 'manual',
  created_at timestamptz not null default now()
);
create index if not exists inventory_movements_created_at_idx on public.inventory_movements(created_at desc);
alter table public.inventory_movements enable row level security;
drop policy if exists "admin inventario historial" on public.inventory_movements;
create policy "admin inventario historial" on public.inventory_movements for all to authenticated
  using ((auth.jwt() ->> 'email') = 'saenz1098@gmail.com')
  with check ((auth.jwt() ->> 'email') = 'saenz1098@gmail.com');
