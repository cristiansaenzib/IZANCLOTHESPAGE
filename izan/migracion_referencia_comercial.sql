-- Agrega el campo para referencia comercial editable por el administrador.
ALTER TABLE public.products ADD COLUMN IF NOT EXISTS reference text;
