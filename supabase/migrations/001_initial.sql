-- Aplicar uma vez em um projeto Supabase novo. Não contém segredos.
create table public.restaurants (
  id uuid primary key default gen_random_uuid(),
  owner_id uuid not null references auth.users(id) on delete cascade,
  name text not null check (length(trim(name)) between 2 and 120),
  slug text not null unique check (slug ~ '^[a-z0-9]+(-[a-z0-9]+)*$'),
  description text not null default '',
  published boolean not null default false,
  updated_at timestamptz not null default now()
);
create table public.categories (
  id uuid primary key default gen_random_uuid(),
  restaurant_id uuid not null references public.restaurants(id) on delete cascade,
  name text not null check (length(trim(name)) between 1 and 80),
  position integer not null default 0,
  unique (id, restaurant_id)
);
create table public.products (
  id uuid primary key default gen_random_uuid(),
  restaurant_id uuid not null references public.restaurants(id) on delete cascade,
  category_id uuid not null,
  name text not null check (length(trim(name)) between 1 and 120),
  description text not null default '',
  price_cents integer not null check (price_cents >= 0),
  available boolean not null default true,
  updated_at timestamptz not null default now(),
  foreign key (category_id, restaurant_id) references public.categories(id, restaurant_id)
);
create index on public.restaurants(owner_id);
create index on public.categories(restaurant_id);
create index on public.products(restaurant_id, category_id);
alter table public.restaurants enable row level security;
alter table public.categories enable row level security;
alter table public.products enable row level security;
create policy restaurant_public on public.restaurants for select to anon, authenticated
  using (published or owner_id = (select auth.uid()));
create policy restaurant_owner on public.restaurants for all to authenticated
  using (owner_id = (select auth.uid())) with check (owner_id = (select auth.uid()));
create policy category_public on public.categories for select to anon, authenticated
  using (exists (select 1 from public.restaurants r where r.id = restaurant_id and (r.published or r.owner_id = (select auth.uid()))));
create policy category_owner on public.categories for all to authenticated
  using (exists (select 1 from public.restaurants r where r.id = restaurant_id and r.owner_id = (select auth.uid())))
  with check (exists (select 1 from public.restaurants r where r.id = restaurant_id and r.owner_id = (select auth.uid())));
create policy product_public on public.products for select to anon, authenticated
  using (exists (select 1 from public.restaurants r where r.id = restaurant_id and ((r.published and available) or r.owner_id = (select auth.uid()))));
create policy product_owner on public.products for all to authenticated
  using (exists (select 1 from public.restaurants r where r.id = restaurant_id and r.owner_id = (select auth.uid())))
  with check (exists (select 1 from public.restaurants r where r.id = restaurant_id and r.owner_id = (select auth.uid())));
grant select on public.restaurants, public.categories, public.products to anon;
grant select, insert, update, delete on public.restaurants, public.categories, public.products to authenticated;
