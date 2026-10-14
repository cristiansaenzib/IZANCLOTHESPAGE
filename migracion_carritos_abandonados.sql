-- IZAN Clothes: guardar datos de contacto y resumen de carritos para retomar ventas.
-- Ejecutar en Supabase > SQL Editor > Run.
create table if not exists public.abandoned_carts (
  id uuid primary key default gen_random_uuid(),
  session_id text not null unique,
  customer_name text not null,
  customer_phone text not null,
  items jsonb not null default '[]'::jsonb,
  total integer not null default 0,
  units integer not null default 0,
  wholesale_code text,
  wholesale_name text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);
alter table public.abandoned_carts enable row level security;
drop policy if exists "admin consultar carritos abandonados" on public.abandoned_carts;
create policy "admin consultar carritos abandonados" on public.abandoned_carts for all to authenticated
  using ((auth.jwt() ->> 'email') = 'saenz1098@gmail.com')
  with check ((auth.jwt() ->> 'email') = 'saenz1098@gmail.com');

-- La tienda llama esta función sin permisos de lectura sobre los datos personales.
create or replace function public.save_abandoned_cart(
  p_session_id text,
  p_customer_name text,
  p_customer_phone text,
  p_items jsonb,
  p_total integer,
  p_units integer,
  p_wholesale_code text default null,
  p_wholesale_name text default null
) returns void
language plpgsql
security definer
set search_path = public
as $$
begin
  if coalesce(length(trim(p_customer_name)), 0) < 2
     or length(trim(p_customer_name)) > 100
     or length(regexp_replace(coalesce(p_customer_phone, ''), '\\D', '', 'g')) < 7
     or length(regexp_replace(coalesce(p_customer_phone, ''), '\\D', '', 'g')) > 15
     or coalesce(length(p_session_id), 0) < 8
     or jsonb_typeof(coalesce(p_items, '[]'::jsonb)) <> 'array'
     or coalesce(p_units, 0) < 1 then
    raise exception 'Datos de contacto o carrito no válidos';
  end if;
  insert into public.abandoned_carts(session_id, customer_name, customer_phone, items, total, units, wholesale_code, wholesale_name, updated_at)
  values (p_session_id, trim(p_customer_name), trim(p_customer_phone), p_items, greatest(coalesce(p_total,0),0), greatest(coalesce(p_units,0),0), p_wholesale_code, p_wholesale_name, now())
  on conflict (session_id) do update set
    customer_name = excluded.customer_name,
    customer_phone = excluded.customer_phone,
    items = excluded.items,
    total = excluded.total,
    units = excluded.units,
    wholesale_code = excluded.wholesale_code,
    wholesale_name = excluded.wholesale_name,
    updated_at = now();
end;
$$;
revoke all on function public.save_abandoned_cart(text,text,text,jsonb,integer,integer,text,text) from public;
grant execute on function public.save_abandoned_cart(text,text,text,jsonb,integer,integer,text,text) to anon, authenticated;
