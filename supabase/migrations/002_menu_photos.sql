-- Execute uma vez no SQL Editor do mesmo projeto Supabase.
-- Pode ser executado novamente. Não altera os registros existentes.
begin;
alter table public.restaurants add column if not exists image_url text;
alter table public.products add column if not exists image_url text;

insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values ('menu-photos', 'menu-photos', true, 5242880,
  array['image/jpeg', 'image/png', 'image/webp'])
on conflict (id) do update set public = true,
  file_size_limit = excluded.file_size_limit,
  allowed_mime_types = excluded.allowed_mime_types;

-- Fotos de cardápios são públicas. Cada usuário escreve apenas na própria pasta.
drop policy if exists menu_photos_insert on storage.objects;
create policy menu_photos_insert on storage.objects for insert to authenticated
with check (bucket_id = 'menu-photos' and (storage.foldername(name))[1] = (select auth.uid())::text);
drop policy if exists menu_photos_select on storage.objects;
create policy menu_photos_select on storage.objects for select to authenticated
using (bucket_id = 'menu-photos' and (storage.foldername(name))[1] = (select auth.uid())::text);
drop policy if exists menu_photos_delete on storage.objects;
create policy menu_photos_delete on storage.objects for delete to authenticated
using (bucket_id = 'menu-photos' and (storage.foldername(name))[1] = (select auth.uid())::text);
commit;
