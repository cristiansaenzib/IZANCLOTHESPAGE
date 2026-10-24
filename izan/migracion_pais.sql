-- IZAN Clothes: país del cliente (formulario con indicativo, país y lista de ciudades).
-- Ejecutar en Supabase > SQL Editor > Run. Es idempotente.
-- Requiere haber ejecutado antes migracion_clientes.sql (o el supabase.sql completo).

alter table public.orders add column if not exists customer_country text;
alter table public.customers add column if not exists country text;

-- Se reemplaza la función anterior (8 parámetros) por una que también guarda el país.
drop function if exists public.save_customer(text,text,text,text,text,text,boolean,text);

create or replace function public.save_customer(
  p_email text,
  p_name text,
  p_id_number text,
  p_phone text,
  p_address text,
  p_city text,
  p_marketing_consent boolean default false,
  p_consent_text text default null,
  p_country text default null
) returns void
language plpgsql
security definer
set search_path = public
as $$
declare
  v_email text := lower(trim(coalesce(p_email, '')));
  v_consent boolean := coalesce(p_marketing_consent, false);
begin
  if v_email !~ '^[^@\s]+@[^@\s]+\.[^@\s]+$'
     or length(v_email) > 150
     or coalesce(length(trim(p_name)), 0) < 2
     or length(trim(p_name)) > 120
     or length(coalesce(p_id_number, '')) > 30
     or length(coalesce(p_phone, '')) > 30
     or length(coalesce(p_address, '')) > 180
     or length(coalesce(p_city, '')) > 100
     or length(coalesce(p_country, '')) > 60
     or length(coalesce(p_consent_text, '')) > 600 then
    raise exception 'Datos del cliente no válidos';
  end if;

  insert into public.customers(email, name, id_number, phone, address, city, country, marketing_consent, consent_at, consent_text, source)
  values (
    v_email, trim(p_name), nullif(trim(coalesce(p_id_number, '')), ''), nullif(trim(coalesce(p_phone, '')), ''),
    nullif(trim(coalesce(p_address, '')), ''), nullif(trim(coalesce(p_city, '')), ''), nullif(trim(coalesce(p_country, '')), ''),
    v_consent, case when v_consent then now() end, case when v_consent then p_consent_text end, 'web'
  )
  on conflict (lower(email)) do update set
    name = excluded.name,
    id_number = coalesce(excluded.id_number, public.customers.id_number),
    phone = coalesce(excluded.phone, public.customers.phone),
    address = coalesce(excluded.address, public.customers.address),
    city = coalesce(excluded.city, public.customers.city),
    country = coalesce(excluded.country, public.customers.country),
    marketing_consent = public.customers.marketing_consent or excluded.marketing_consent,
    consent_at = case
      when public.customers.marketing_consent then public.customers.consent_at
      when excluded.marketing_consent then now()
      else public.customers.consent_at end,
    consent_text = case
      when public.customers.marketing_consent then public.customers.consent_text
      when excluded.marketing_consent then excluded.consent_text
      else public.customers.consent_text end,
    updated_at = now();
end;
$$;
revoke all on function public.save_customer(text,text,text,text,text,text,boolean,text,text) from public;
grant execute on function public.save_customer(text,text,text,text,text,text,boolean,text,text) to anon, authenticated;
