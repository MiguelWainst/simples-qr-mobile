-- Executar após 002_menu_photos.sql no mesmo projeto Supabase.
begin;

alter table public.restaurants
  add column if not exists logo_url text,
  add column if not exists menu_accent text
    check (menu_accent ~ '^#[0-9A-F]{6}$'),
  add column if not exists menu_title text
    check (length(trim(menu_title)) between 1 and 120);

alter table public.products
  add column if not exists sale_price_cents integer
    check (sale_price_cents >= 0 and sale_price_cents < price_cents),
  add column if not exists flash_ends_at timestamptz
    check (flash_ends_at is null or sale_price_cents is not null),
  add column if not exists is_new boolean not null default false;

commit;
