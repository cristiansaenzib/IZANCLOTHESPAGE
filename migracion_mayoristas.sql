-- Ejecutar UNA vez en Supabase -> SQL Editor (crea los codigos de mayorista).
-- Si cambiaste el correo admin en supabase.sql, cambialo tambien aqui.
create table if not exists wholesale_codes (
  id uuid primary key default gen_random_uuid(),
  code text not null unique,
  client_name text not null default '',
  active boolean not null default true,
  created_at timestamptz not null default now()
);
alter table wholesale_codes enable row level security;
-- Sin lectura publica: nadie puede listar los codigos. Solo el admin gestiona la tabla.
create policy "admin codigos" on wholesale_codes for all to authenticated
  using ((auth.jwt() ->> 'email') = 'saenz1098@gmail.com')
  with check ((auth.jwt() ->> 'email') = 'saenz1098@gmail.com');
-- La tienda solo puede PREGUNTAR si un codigo es valido (devuelve el nombre del cliente o null).
create or replace function check_wholesale_code(p_code text) returns text
  language sql security definer set search_path = public as $$
  select coalesce(nullif(client_name, ''), 'Mayorista') from wholesale_codes
  where upper(code) = upper(trim(p_code)) and active limit 1 $$;
grant execute on function check_wholesale_code(text) to anon, authenticated;
