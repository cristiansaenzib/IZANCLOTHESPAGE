-- IZAN Clothes: guardar los datos de envío en cada cotización.
-- Ejecutar en Supabase > SQL Editor antes de publicar la versión actualizada.
alter table public.orders add column if not exists customer_id_number text;
alter table public.orders add column if not exists customer_address text;
alter table public.orders add column if not exists customer_city text;
alter table public.orders add column if not exists customer_email text;
