-- Ejecutar UNA vez en Supabase -> SQL Editor.
-- Agrega la foto trasera de cada producto (la foto frontal sigue siendo image_path).
-- En la tienda, la trasera aparece sola cuando el cliente pasa el mouse sobre el producto.
alter table public.products
  add column if not exists image_path_back text;
