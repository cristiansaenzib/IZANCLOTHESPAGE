-- Ejecutar UNA vez en Supabase -> SQL Editor (crea los gramajes y el vinculo con los productos).
-- Si cambiaste el correo admin en supabase.sql, cambialo tambien aqui.
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
