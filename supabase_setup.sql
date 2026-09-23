alter table public.customer_accounts
  add column if not exists access_token text unique;

create unique index if not exists customer_accounts_access_token_idx
  on public.customer_accounts(access_token);

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
  select
    c.id,
    c.username,
    c.display_name,
    c.contact,
    c.plan,
    c.starts_at,
    c.expires_at,
    c.enabled
  from public.customer_accounts c
  where c.access_token = trim(p_access_token)
    and c.enabled = true
    and c.starts_at <= now()
    and c.expires_at > now()
  limit 1;
$$;

grant execute on function public.customer_access_login(text)
to anon, authenticated;