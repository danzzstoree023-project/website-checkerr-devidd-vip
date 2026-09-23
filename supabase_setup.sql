-- DANZZ ID CHECKER v3 - Customer accounts
create extension if not exists pgcrypto;

create table if not exists public.customer_accounts (
  id uuid primary key default gen_random_uuid(),
  username text not null unique,
  password_hash text not null,
  display_name text default '',
  contact text default '',
  plan text default 'custom',
  starts_at timestamptz not null default now(),
  expires_at timestamptz not null,
  enabled boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index if not exists customer_accounts_username_idx on public.customer_accounts(lower(username));
create index if not exists customer_accounts_expires_idx on public.customer_accounts(expires_at);

alter table public.customer_accounts enable row level security;

-- Admin CRUD: authenticated users can manage accounts.
-- For a single-admin project this is sufficient. Tighten with auth.uid() later if more admins are added.
drop policy if exists "customer_admin_select" on public.customer_accounts;
drop policy if exists "customer_admin_insert" on public.customer_accounts;
drop policy if exists "customer_admin_update" on public.customer_accounts;
drop policy if exists "customer_admin_delete" on public.customer_accounts;
create policy "customer_admin_select" on public.customer_accounts for select to authenticated using (true);
create policy "customer_admin_insert" on public.customer_accounts for insert to authenticated with check (true);
create policy "customer_admin_update" on public.customer_accounts for update to authenticated using (true) with check (true);
create policy "customer_admin_delete" on public.customer_accounts for delete to authenticated using (true);

-- Customer login: only returns safe fields, never the password hash.
drop function if exists public.customer_login(text,text);
create or replace function public.customer_login(p_username text, p_password_hash text)
returns table(id uuid, username text, display_name text, contact text, plan text, starts_at timestamptz, expires_at timestamptz, enabled boolean)
language sql
security definer
set search_path = public
as $$
  select c.id,c.username,c.display_name,c.contact,c.plan,c.starts_at,c.expires_at,c.enabled
  from public.customer_accounts c
  where lower(c.username)=lower(trim(p_username))
    and c.password_hash=p_password_hash
  limit 1;
$$;
grant execute on function public.customer_login(text,text) to anon, authenticated;

-- Ensure the existing feature table can be read by the public checker.
alter table if exists public.website_features enable row level security;
drop policy if exists "public_read_features" on public.website_features;
create policy "public_read_features" on public.website_features for select to anon, authenticated using (true);
-- DANZZ v3: passwordless customer access links
-- Run this AFTER your existing v3 Supabase setup SQL.

alter table public.customer_accounts
  add column if not exists access_token text unique;

create index if not exists customer_accounts_access_token_idx
  on public.customer_accounts(access_token);

-- Public checker validates only an unexpired, enabled token.
drop function if exists public.customer_access_login(text);
create or replace function public.customer_access_login(p_access_token text)
returns table(
  id uuid,
  username text,
  display_name text,
  contact text,
  plan text,
  starts_at timestamptz,
  expires_at timestamptz,
  enabled boolean
)
language sql
security definer
set search_path = public
as $$
  select c.id,c.username,c.display_name,c.contact,c.plan,c.starts_at,c.expires_at,c.enabled
  from public.customer_accounts c
  where c.access_token = trim(p_access_token)
    and c.enabled = true
    and c.starts_at <= now()
    and c.expires_at > now()
  limit 1;
$$;

grant execute on function public.customer_access_login(text) to anon, authenticated;


-- Website features (self-contained setup)
create table if not exists public.website_features (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  description text default '',
  icon text default '🧩',
  enabled boolean not null default true,
  sort_order integer not null default 0,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);
create index if not exists website_features_sort_idx on public.website_features(sort_order, created_at);
alter table public.website_features enable row level security;
drop policy if exists "public_read_features" on public.website_features;
create policy "public_read_features" on public.website_features for select to anon, authenticated using (true);
drop policy if exists "feature_admin_insert" on public.website_features;
drop policy if exists "feature_admin_update" on public.website_features;
drop policy if exists "feature_admin_delete" on public.website_features;
create policy "feature_admin_insert" on public.website_features for insert to authenticated with check (true);
create policy "feature_admin_update" on public.website_features for update to authenticated using (true) with check (true);
create policy "feature_admin_delete" on public.website_features for delete to authenticated using (true);

-- Optional feature entry for the Website Checker Feature Manager.
insert into public.website_features(name, description, icon, enabled, sort_order)
select 'Bulk Full Info', 'Single/Bulk Device ID Full Account Info via authorized API', '🎮', true, 10
where not exists (select 1 from public.website_features where lower(name)=lower('Bulk Full Info'));
