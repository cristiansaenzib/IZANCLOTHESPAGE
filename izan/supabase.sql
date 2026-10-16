-- IZAN Clothes · Esquema completo e idempotente para una base de datos nueva.
-- Puede ejecutarse varias veces. No inserta productos de ejemplo ni borra datos.
-- Supabase → SQL Editor → New query → pegar todo → Run.

create extension if not exists pgcrypto;

create table if not exists public.categories (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  tiers text,
  created_at timestamptz not null default now()
);

create table if not exists public.size_guides (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  note text not null default '',
  measures text not null default '[]',
  sizes text not null default '{}',
  created_at timestamptz not null default now()
);

create table if not exists public.products (
  id uuid primary key default gen_random_uuid(),
  category_id uuid references public.categories(id) on delete restrict,
  name text not null,
  description text not null default '',
  color text not null default '',
  image_path text,
  image_path_back text,
  price integer not null default 0 check (price >= 0),
  price_promo integer not null default 0 check (price_promo >= 0),
  price_dist integer not null default 0 check (price_dist >= 0),
  price_mayor integer not null default 0 check (price_mayor >= 0),
  tiers text,
  size_guide_id uuid references public.size_guides(id) on delete set null,
  is_best_seller boolean not null default false,
  is_last_units boolean not null default false,
  is_new_arrival boolean not null default false,
  stock_s integer not null default 0 check (stock_s >= 0),
  stock_m integer not null default 0 check (stock_m >= 0),
  stock_l integer not null default 0 check (stock_l >= 0),
  stock_xl integer not null default 0 check (stock_xl >= 0),
  sold_out boolean not null default false,
  created_at timestamptz not null default now()
);

-- Completa instalaciones antiguas sin eliminar columnas o datos.
alter table public.products add column if not exists category_id uuid references public.categories(id) on delete restrict;
alter table public.products add column if not exists description text not null default '';
alter table public.products add column if not exists color text not null default '';
alter table public.products add column if not exists image_path text;
alter table public.products add column if not exists image_path_back text;
alter table public.products add column if not exists price integer not null default 0;
alter table public.products add column if not exists price_promo integer not null default 0;
alter table public.products add column if not exists price_dist integer not null default 0;
alter table public.products add column if not exists price_mayor integer not null default 0;
alter table public.products add column if not exists tiers text;
alter table public.products add column if not exists size_guide_id uuid references public.size_guides(id) on delete set null;
alter table public.products add column if not exists is_best_seller boolean not null default false;
alter table public.products add column if not exists is_last_units boolean not null default false;
alter table public.products add column if not exists is_new_arrival boolean not null default false;
alter table public.products add column if not exists stock_s integer not null default 0;
alter table public.products add column if not exists stock_m integer not null default 0;
alter table public.products add column if not exists stock_l integer not null default 0;
alter table public.products add column if not exists stock_xl integer not null default 0;
alter table public.products add column if not exists sold_out boolean not null default false;
alter table public.products add column if not exists created_at timestamptz not null default now();

create table if not exists public.settings (
  key text primary key,
  value text,
  updated_at timestamptz not null default now()
);
alter table public.settings add column if not exists updated_at timestamptz not null default now();

create table if not exists public.wholesale_codes (
  id uuid primary key default gen_random_uuid(),
  code text not null unique,
  client_name text not null default '',
  active boolean not null default true,
  created_at timestamptz not null default now()
);

create table if not exists public.orders (
  id uuid primary key default gen_random_uuid(),
  status text not null default 'pending' check (status in ('pending','sold')),
  total integer not null default 0 check (total >= 0),
  units integer not null default 0 check (units >= 0),
  items jsonb not null default '[]'::jsonb,
  wholesale_code text,
  wholesale_name text,
  customer_name text,
  customer_id_number text,
  customer_phone text,
  customer_address text,
  customer_city text,
  customer_email text,
  created_at timestamptz not null default now(),
  sold_at timestamptz
);
alter table public.orders add column if not exists status text not null default 'pending';
alter table public.orders add column if not exists total integer not null default 0;
alter table public.orders add column if not exists units integer not null default 0;
alter table public.orders add column if not exists items jsonb not null default '[]'::jsonb;
alter table public.orders add column if not exists wholesale_code text;
alter table public.orders add column if not exists wholesale_name text;
alter table public.orders add column if not exists customer_name text;
alter table public.orders add column if not exists customer_id_number text;
alter table public.orders add column if not exists customer_phone text;
alter table public.orders add column if not exists customer_address text;
alter table public.orders add column if not exists customer_city text;
alter table public.orders add column if not exists customer_email text;
alter table public.orders add column if not exists created_at timestamptz not null default now();
alter table public.orders add column if not exists sold_at timestamptz;

create table if not exists public.inventory_movements (
  id uuid primary key default gen_random_uuid(),
  product_id uuid references public.products(id) on delete set null,
  product_name text not null default '',
  size text not null check (size in ('S','M','L','XL')),
  delta integer not null check (delta <> 0),
  before_stock integer not null check (before_stock >= 0),
  after_stock integer not null check (after_stock >= 0),
  reason text not null default 'Ajuste manual',
  source text not null default 'manual',
  created_at timestamptz not null default now()
);
create index if not exists inventory_movements_created_at_idx on public.inventory_movements(created_at desc);

create table if not exists public.abandoned_carts (
  id uuid primary key default gen_random_uuid(),
  session_id text not null unique,
  customer_name text not null default '',
  customer_phone text not null default '',
  items jsonb not null default '[]'::jsonb,
  total integer not null default 0,
  units integer not null default 0,
  wholesale_code text,
  wholesale_name text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

-- RLS: catálogo público de solo lectura; escritura del administrador autenticado.
alter table public.categories enable row level security;
alter table public.size_guides enable row level security;
alter table public.products enable row level security;
alter table public.settings enable row level security;
alter table public.wholesale_codes enable row level security;
alter table public.orders enable row level security;
alter table public.inventory_movements enable row level security;
alter table public.abandoned_carts enable row level security;

-- Las políticas se recrean por nombre para evitar "policy already exists" al reejecutar.
drop policy if exists "lectura publica categorias" on public.categories;
create policy "lectura publica categorias" on public.categories for select to anon, authenticated using (true);
drop policy if exists "admin categorias" on public.categories;
create policy "admin categorias" on public.categories for all to authenticated using ((auth.jwt()->>'email') = 'saenz1098@gmail.com') with check ((auth.jwt()->>'email') = 'saenz1098@gmail.com');

drop policy if exists "lectura publica productos" on public.products;
create policy "lectura publica productos" on public.products for select to anon, authenticated using (true);
drop policy if exists "admin productos" on public.products;
create policy "admin productos" on public.products for all to authenticated using ((auth.jwt()->>'email') = 'saenz1098@gmail.com') with check ((auth.jwt()->>'email') = 'saenz1098@gmail.com');

drop policy if exists "lectura publica ajustes" on public.settings;
create policy "lectura publica ajustes" on public.settings for select to anon, authenticated using (true);
drop policy if exists "admin ajustes" on public.settings;
create policy "admin ajustes" on public.settings for all to authenticated using ((auth.jwt()->>'email') = 'saenz1098@gmail.com') with check ((auth.jwt()->>'email') = 'saenz1098@gmail.com');

drop policy if exists "lectura publica guias" on public.size_guides;
create policy "lectura publica guias" on public.size_guides for select to anon, authenticated using (true);
drop policy if exists "admin guias" on public.size_guides;
create policy "admin guias" on public.size_guides for all to authenticated using ((auth.jwt()->>'email') = 'saenz1098@gmail.com') with check ((auth.jwt()->>'email') = 'saenz1098@gmail.com');

drop policy if exists "admin codigos" on public.wholesale_codes;
create policy "admin codigos" on public.wholesale_codes for all to authenticated using ((auth.jwt()->>'email') = 'saenz1098@gmail.com') with check ((auth.jwt()->>'email') = 'saenz1098@gmail.com');

drop policy if exists "public crear cotizaciones" on public.orders;
create policy "public crear cotizaciones" on public.orders for insert to anon, authenticated with check (status = 'pending' and sold_at is null);
drop policy if exists "admin gestionar pedidos" on public.orders;
create policy "admin gestionar pedidos" on public.orders for all to authenticated using ((auth.jwt()->>'email') = 'saenz1098@gmail.com') with check ((auth.jwt()->>'email') = 'saenz1098@gmail.com');

drop policy if exists "admin inventario historial" on public.inventory_movements;
create policy "admin inventario historial" on public.inventory_movements for all to authenticated using ((auth.jwt()->>'email') = 'saenz1098@gmail.com') with check ((auth.jwt()->>'email') = 'saenz1098@gmail.com');
drop policy if exists "admin consultar carritos abandonados" on public.abandoned_carts;
create policy "admin consultar carritos abandonados" on public.abandoned_carts for all to authenticated using ((auth.jwt()->>'email') = 'saenz1098@gmail.com') with check ((auth.jwt()->>'email') = 'saenz1098@gmail.com');

-- El código público solo puede validar un código, nunca listar códigos de clientes.
create or replace function public.check_wholesale_code(p_code text) returns text
language sql security definer set search_path = public as $$
  select coalesce(nullif(client_name, ''), 'Mayorista')
  from public.wholesale_codes where upper(code) = upper(trim(p_code)) and active limit 1;
$$;
revoke all on function public.check_wholesale_code(text) from public;
grant execute on function public.check_wholesale_code(text) to anon, authenticated;

-- Guardar carritos abandonados mediante función controlada, sin lectura pública de datos personales.
create or replace function public.save_abandoned_cart(
  p_session_id text, p_customer_name text, p_customer_phone text, p_items jsonb,
  p_total integer, p_units integer, p_wholesale_code text default null, p_wholesale_name text default null
) returns void language plpgsql security definer set search_path = public as $$
begin
  if coalesce(length(trim(p_customer_name)),0) < 2 or coalesce(length(trim(p_customer_name)),0) > 100
     or length(regexp_replace(coalesce(p_customer_phone,''), '\D', '', 'g')) < 7
     or length(regexp_replace(coalesce(p_customer_phone,''), '\D', '', 'g')) > 15
     or coalesce(length(p_session_id),0) < 8
     or jsonb_typeof(coalesce(p_items,'[]'::jsonb)) <> 'array' or coalesce(p_units,0) < 1 then
    raise exception 'Datos de contacto o carrito no válidos';
  end if;
  insert into public.abandoned_carts(session_id,customer_name,customer_phone,items,total,units,wholesale_code,wholesale_name,updated_at)
  values (p_session_id,trim(p_customer_name),trim(p_customer_phone),p_items,greatest(coalesce(p_total,0),0),greatest(coalesce(p_units,0),0),p_wholesale_code,p_wholesale_name,now())
  on conflict (session_id) do update set customer_name=excluded.customer_name, customer_phone=excluded.customer_phone,
    items=excluded.items,total=excluded.total,units=excluded.units,wholesale_code=excluded.wholesale_code,
    wholesale_name=excluded.wholesale_name,updated_at=now();
end; $$;
revoke all on function public.save_abandoned_cart(text,text,text,jsonb,integer,integer,text,text) from public;
grant execute on function public.save_abandoned_cart(text,text,text,jsonb,integer,integer,text,text) to anon, authenticated;

-- Bucket de fotos. Público para visualizar productos; solo el administrador puede subir/modificar.
insert into storage.buckets (id,name,public) values ('products','products',true) on conflict (id) do update set public = true;
drop policy if exists "lectura publica fotos" on storage.objects;
create policy "lectura publica fotos" on storage.objects for select to anon, authenticated using (bucket_id='products');
drop policy if exists "admin fotos" on storage.objects;
create policy "admin fotos" on storage.objects for all to authenticated using (bucket_id='products' and (auth.jwt()->>'email')='saenz1098@gmail.com') with check (bucket_id='products' and (auth.jwt()->>'email')='saenz1098@gmail.com');

-- La base queda vacía y lista para comenzar a cargar datos desde admin.html.


-- ===== Gramajes (g/m2) =====
create table if not exists public.fabric_weights (
  id uuid primary key default gen_random_uuid(),
  grams integer not null check (grams > 0),   -- gramaje en g/m2, ej. 180, 220, 270, 310
  name text not null default '',              -- nombre opcional, ej. "Premium", "Heavyweight"
  note text not null default '',
  created_at timestamptz not null default now()
);
alter table public.fabric_weights enable row level security;

drop policy if exists "lectura publica gramajes" on public.fabric_weights;
create policy "lectura publica gramajes" on public.fabric_weights for select to anon, authenticated using (true);

drop policy if exists "admin gramajes" on public.fabric_weights;
create policy "admin gramajes" on public.fabric_weights for all to authenticated
  using ((auth.jwt() ->> 'email') = 'saenz1098@gmail.com')
  with check ((auth.jwt() ->> 'email') = 'saenz1098@gmail.com');

-- Cada producto puede tener un gramaje (si se elimina el gramaje, el producto queda sin gramaje)
alter table public.products
  add column if not exists fabric_weight_id uuid references public.fabric_weights(id) on delete set null;
