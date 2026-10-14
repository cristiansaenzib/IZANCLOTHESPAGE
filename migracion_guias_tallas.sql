-- Ejecutar UNA vez en Supabase -> SQL Editor (crea las guias de tallas y el vinculo con los productos).
-- Si cambiaste el correo admin en supabase.sql, cambialo tambien aqui.
create table if not exists public.size_guides (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  note text not null default '',
  measures text not null default '[]',   -- nombres de las medidas (JSON), ej. ["Ancho","Largo","Manga"]
  sizes text not null default '{}',      -- valores por talla (JSON), ej. {"S":["52","70","20"],"M":[...]}
  created_at timestamptz not null default now()
);
alter table public.size_guides enable row level security;

drop policy if exists "lectura publica guias" on public.size_guides;
create policy "lectura publica guias" on public.size_guides for select using (true);

drop policy if exists "admin guias" on public.size_guides;
create policy "admin guias" on public.size_guides for all to authenticated
  using ((auth.jwt() ->> 'email') = 'saenz1098@gmail.com')
  with check ((auth.jwt() ->> 'email') = 'saenz1098@gmail.com');

-- Cada producto puede tener una guia (si se elimina la guia, el producto queda sin guia)
alter table public.products
  add column if not exists size_guide_id uuid references public.size_guides(id) on delete set null;
