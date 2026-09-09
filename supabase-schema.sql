-- MyVillage Govt starter database
-- Run this in Supabase Dashboard > SQL Editor > New query
create extension if not exists pgcrypto;

create table if not exists public.villages (
  id uuid primary key default gen_random_uuid(),
  pincode text not null,
  name text not null,
  district text default 'Srikakulam',
  state text default 'Andhra Pradesh',
  created_at timestamptz not null default now(),
  unique (pincode, name)
);

create table if not exists public.resident_profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  full_name text,
  villager_id text unique,
  phone text,
  address text,
  ward_no text,
  village_id uuid references public.villages(id),
  is_admin boolean not null default false,
  created_at timestamptz not null default now()
);

create table if not exists public.complaints (
  id uuid primary key default gen_random_uuid(),
  resident_id uuid not null references public.resident_profiles(id) on delete cascade,
  village_id uuid not null references public.villages(id),
  ward_no text not null,
  address text not null,
  title text not null,
  description text not null,
  status text not null default 'Submitted' check (status in ('Submitted','Under review','In progress','Resolved','Closed')),
  resolution_notes text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.shops (
  id uuid primary key default gen_random_uuid(),
  village_id uuid not null references public.villages(id),
  name text not null,
  owner_name text,
  phone text,
  address text,
  is_registered boolean not null default true,
  created_at timestamptz not null default now()
);

create table if not exists public.products (
  id uuid primary key default gen_random_uuid(),
  shop_id uuid not null references public.shops(id) on delete cascade,
  name text not null,
  category text,
  price numeric(12,2),
  available_quantity integer not null default 0,
  is_available boolean not null default true,
  updated_at timestamptz not null default now()
);

create table if not exists public.service_directory (
  id uuid primary key default gen_random_uuid(),
  village_id uuid not null references public.villages(id),
  service_type text not null check (service_type in ('medical','ambulance','blood','auto','cab','boat','education','tourism')),
  name text not null,
  phone text,
  details text,
  price_note text,
  is_active boolean not null default true,
  created_at timestamptz not null default now()
);

-- Seed the initial village choices
insert into public.villages (pincode, name) values
  ('532406', 'Port Kalingapatnam'),
  ('532401', 'Kalingapatnam')
on conflict (pincode, name) do nothing;

alter table public.villages enable row level security;
alter table public.resident_profiles enable row level security;
alter table public.complaints enable row level security;
alter table public.shops enable row level security;
alter table public.products enable row level security;
alter table public.service_directory enable row level security;

create policy "Anyone can view villages" on public.villages for select using (true);
create policy "Residents can view own profile" on public.resident_profiles for select using (auth.uid() = id);
create policy "Residents can create own profile" on public.resident_profiles for insert with check (auth.uid() = id);
create policy "Residents can update own profile" on public.resident_profiles for update using (auth.uid() = id);
create policy "Residents can view own complaints" on public.complaints for select using (auth.uid() = resident_id);
create policy "Residents can submit complaints" on public.complaints for insert with check (auth.uid() = resident_id);
create policy "Anyone can view registered shops" on public.shops for select using (is_registered = true);
create policy "Anyone can view available products" on public.products for select using (is_available = true);
create policy "Anyone can view active services" on public.service_directory for select using (is_active = true);

-- Admin policies can be expanded after the first admin profile is created.
