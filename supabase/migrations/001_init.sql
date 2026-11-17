-- S-Book index: schema, row-level security and write functions.
-- Identity: each browser holds a random secret; only its SHA-256 hash is stored.
-- Reads are public; every write goes through a SECURITY DEFINER function that
-- resolves the secret to a member and checks ownership / admin rights.

create extension if not exists pgcrypto with schema extensions;

create table if not exists public.members (
  id uuid primary key default gen_random_uuid(),
  secret_hash text not null unique,
  created_at timestamptz not null default now()
);

create table if not exists public.readers (
  id uuid primary key references public.members(id) on delete cascade,
  nickname text not null check (char_length(nickname) between 1 and 40),
  updated_at timestamptz not null default now()
);

create table if not exists public.profiles (
  id uuid primary key references public.members(id) on delete cascade,
  i numeric not null check (i in (0.3, 0.8, 1.0)),
  answers jsonb,
  updated_at timestamptz not null default now()
);

create table if not exists public.ratings (
  id uuid primary key default gen_random_uuid(),
  title text not null check (char_length(title) between 1 and 120),
  inputs jsonb not null check (pg_column_size(inputs) < 8000),
  score numeric,
  raw_score numeric,
  veto boolean not null default false,
  created_by uuid references public.members(id) on delete set null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);
create index if not exists ratings_created_by_idx on public.ratings(created_by);

create table if not exists public.likes (
  member_id uuid not null references public.members(id) on delete cascade,
  rating_id uuid not null references public.ratings(id) on delete cascade,
  created_at timestamptz not null default now(),
  primary key (member_id, rating_id)
);

create table if not exists public.admins (
  member_id uuid primary key references public.members(id) on delete cascade
);

-- Row-level security: public read where it should be, no direct writes anywhere.
alter table public.members  enable row level security;
alter table public.readers  enable row level security;
alter table public.profiles enable row level security;
alter table public.ratings  enable row level security;
alter table public.likes    enable row level security;
alter table public.admins   enable row level security;

drop policy if exists "public read" on public.readers;
create policy "public read" on public.readers for select to anon, authenticated using (true);
drop policy if exists "public read" on public.ratings;
create policy "public read" on public.ratings for select to anon, authenticated using (true);
drop policy if exists "public read" on public.likes;
create policy "public read" on public.likes for select to anon, authenticated using (true);
-- members, profiles, admins: no policies -> not readable or writable by the API.

-- ---------- Helpers (not callable from the API) ----------
create or replace function public._member(p_secret text)
returns uuid language sql stable security definer set search_path = public, extensions as $$
  select id from public.members
  where p_secret is not null and length(p_secret) >= 32
    and secret_hash = encode(extensions.digest(p_secret, 'sha256'), 'hex');
$$;

create or replace function public._require_member(p_secret text)
returns uuid language plpgsql stable security definer set search_path = public, extensions as $$
declare m uuid;
begin
  m := public._member(p_secret);
  if m is null then raise exception 'unknown member' using errcode = '28000'; end if;
  return m;
end $$;

create or replace function public._is_admin(p_member uuid)
returns boolean language sql stable security definer set search_path = public as $$
  select exists (select 1 from public.admins where member_id = p_member);
$$;

revoke all on function public._member(text) from public, anon, authenticated;
revoke all on function public._require_member(text) from public, anon, authenticated;
revoke all on function public._is_admin(uuid) from public, anon, authenticated;

-- ---------- API functions ----------
create or replace function public.register(p_secret text)
returns uuid language plpgsql volatile security definer set search_path = public, extensions as $$
declare m uuid;
begin
  if p_secret is null or length(p_secret) < 32 or length(p_secret) > 200 then
    raise exception 'invalid secret' using errcode = '22023';
  end if;
  m := public._member(p_secret);
  if m is not null then return m; end if;
  insert into public.members(secret_hash) values (encode(extensions.digest(p_secret, 'sha256'), 'hex'))
  returning id into m;
  return m;
end $$;

create or replace function public.get_me(p_secret text)
returns jsonb language plpgsql stable security definer set search_path = public, extensions as $$
declare m uuid; r jsonb;
begin
  m := public._member(p_secret);
  if m is null then return null; end if;
  select jsonb_build_object(
    'id', m,
    'is_admin', public._is_admin(m),
    'nickname', (select nickname from public.readers where id = m),
    'i', (select i from public.profiles where id = m),
    'answers', (select answers from public.profiles where id = m)
  ) into r;
  return r;
end $$;

create or replace function public.save_profile(p_secret text, p_nickname text, p_i numeric, p_answers jsonb)
returns void language plpgsql volatile security definer set search_path = public, extensions as $$
declare m uuid;
begin
  m := public._require_member(p_secret);
  if p_answers is not null and pg_column_size(p_answers) > 2000 then
    raise exception 'answers too large' using errcode = '22023';
  end if;
  insert into public.readers(id, nickname, updated_at) values (m, trim(p_nickname), now())
    on conflict (id) do update set nickname = excluded.nickname, updated_at = now();
  insert into public.profiles(id, i, answers, updated_at) values (m, p_i, p_answers, now())
    on conflict (id) do update set i = excluded.i, answers = excluded.answers, updated_at = now();
end $$;

create or replace function public.save_rating(
  p_secret text, p_id uuid, p_title text, p_inputs jsonb, p_score numeric, p_raw numeric, p_veto boolean)
returns uuid language plpgsql volatile security definer set search_path = public, extensions as $$
declare m uuid; rid uuid;
begin
  m := public._require_member(p_secret);
  if jsonb_typeof(p_inputs) <> 'object' then raise exception 'inputs must be an object' using errcode = '22023'; end if;
  if p_id is null then
    insert into public.ratings(title, inputs, score, raw_score, veto, created_by)
    values (trim(p_title), p_inputs, p_score, p_raw, coalesce(p_veto, false), m)
    returning id into rid;
  else
    update public.ratings
       set title = trim(p_title), inputs = p_inputs, score = p_score, raw_score = p_raw,
           veto = coalesce(p_veto, false), updated_at = now()
     where id = p_id and (created_by = m or public._is_admin(m))
    returning id into rid;
    if rid is null then raise exception 'not allowed' using errcode = '42501'; end if;
  end if;
  return rid;
end $$;

create or replace function public.delete_rating(p_secret text, p_id uuid)
returns void language plpgsql volatile security definer set search_path = public, extensions as $$
declare m uuid; n int;
begin
  m := public._require_member(p_secret);
  delete from public.ratings where id = p_id and (created_by = m or public._is_admin(m));
  get diagnostics n = row_count;
  if n = 0 then raise exception 'not allowed' using errcode = '42501'; end if;
end $$;

create or replace function public.set_like(p_secret text, p_rating uuid, p_on boolean)
returns void language plpgsql volatile security definer set search_path = public, extensions as $$
declare m uuid;
begin
  m := public._require_member(p_secret);
  if p_on then
    if exists (select 1 from public.ratings where id = p_rating and created_by = m) then
      raise exception 'cannot like own rating' using errcode = '42501';
    end if;
    insert into public.likes(member_id, rating_id) values (m, p_rating) on conflict do nothing;
  else
    delete from public.likes where member_id = m and rating_id = p_rating;
  end if;
end $$;

revoke all on function public.register(text) from public;
revoke all on function public.get_me(text) from public;
revoke all on function public.save_profile(text, text, numeric, jsonb) from public;
revoke all on function public.save_rating(text, uuid, text, jsonb, numeric, numeric, boolean) from public;
revoke all on function public.delete_rating(text, uuid) from public;
revoke all on function public.set_like(text, uuid, boolean) from public;
grant execute on function public.register(text) to anon, authenticated;
grant execute on function public.get_me(text) to anon, authenticated;
grant execute on function public.save_profile(text, text, numeric, jsonb) to anon, authenticated;
grant execute on function public.save_rating(text, uuid, text, jsonb, numeric, numeric, boolean) to anon, authenticated;
grant execute on function public.delete_rating(text, uuid) to anon, authenticated;
grant execute on function public.set_like(text, uuid, boolean) to anon, authenticated;
