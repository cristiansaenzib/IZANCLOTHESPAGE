-- Agrega datos opcionales de contacto a las cotizaciones existentes.
-- Ejecutar en Supabase > SQL Editor > Run antes de publicar la tienda actualizada.
alter table public.orders add column if not exists customer_name text;
alter table public.orders add column if not exists customer_phone text;
