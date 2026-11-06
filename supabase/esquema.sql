-- Mi Plata — base de datos (proyecto Supabase "mi-plata", aparte de Pack Oeste).
-- Una sola contraseña para entrar. Nadie puede leer ni escribir las tablas directamente:
-- todo pasa por estas funciones, que piden la contraseña o una sesión válida.

create extension if not exists pgcrypto with schema extensions;

create table if not exists public.config  (id int primary key default 1 check (id = 1), pass_hash text not null, cambiada timestamptz not null default now());
create table if not exists public.sesiones(token_hash text primary key, creada timestamptz not null default now(), ultima timestamptz not null default now());
create table if not exists public.datos   (id int primary key default 1 check (id = 1), data jsonb not null, version bigint not null, actualizado timestamptz not null default now());
create table if not exists public.intentos(id bigserial primary key, en timestamptz not null default now());

alter table public.config   enable row level security;
alter table public.sesiones enable row level security;
alter table public.datos    enable row level security;
alter table public.intentos enable row level security;
revoke all on public.config, public.sesiones, public.datos, public.intentos from anon, authenticated;

-- interno: crea una sesión y devuelve su token (en la base solo queda el hash)
create or replace function public._mp_sesion() returns text
language plpgsql security definer set search_path = '' as $$
declare tok text := encode(extensions.gen_random_bytes(32), 'hex');
begin
  insert into public.sesiones(token_hash) values (encode(extensions.digest(tok, 'sha256'), 'hex'));
  return tok;
end $$;

-- interno: ¿el token es válido?
create or replace function public._mp_ok(p_token text) returns boolean
language plpgsql security definer set search_path = '' as $$
begin
  update public.sesiones set ultima = now()
   where token_hash = encode(extensions.digest(coalesce(p_token, ''), 'sha256'), 'hex');
  return found;
end $$;

-- ¿ya se eligió la contraseña?
create or replace function public.mp_estado() returns boolean
language sql security definer set search_path = '' as $$ select exists(select 1 from public.config) $$;

-- primera vez: elegir la contraseña
create or replace function public.mp_crear(p_pass text) returns text
language plpgsql security definer set search_path = '' as $$
begin
  if exists(select 1 from public.config) then raise exception 'ya_existe'; end if;
  if length(coalesce(p_pass, '')) < 6 then raise exception 'corta'; end if;
  insert into public.config(pass_hash) values (extensions.crypt(p_pass, extensions.gen_salt('bf', 10)));
  return public._mp_sesion();
end $$;

-- entrar: devuelve un token de sesión, o null si la contraseña es incorrecta
create or replace function public.mp_entrar(p_pass text) returns text
language plpgsql security definer set search_path = '' as $$
begin
  delete from public.intentos where en < now() - interval '1 day';
  if (select count(*) from public.intentos where en > now() - interval '15 minutes') >= 10 then
    raise exception 'bloqueado';
  end if;
  if not exists(select 1 from public.config where pass_hash = extensions.crypt(coalesce(p_pass, ''), pass_hash)) then
    insert into public.intentos default values;
    return null;
  end if;
  return public._mp_sesion();
end $$;

-- leer los datos
create or replace function public.mp_leer(p_token text) returns jsonb
language plpgsql security definer set search_path = '' as $$
declare r jsonb;
begin
  if not public._mp_ok(p_token) then raise exception 'sesion'; end if;
  select jsonb_build_object('data', data, 'version', version) into r from public.datos where id = 1;
  return coalesce(r, jsonb_build_object('data', null, 'version', 0));
end $$;

-- guardar: solo si nadie guardó en el medio (si no, devuelve -1 y la app vuelve a combinar)
create or replace function public.mp_guardar(p_token text, p_data jsonb, p_version bigint) returns bigint
language plpgsql security definer set search_path = '' as $$
declare v bigint;
begin
  if not public._mp_ok(p_token) then raise exception 'sesion'; end if;
  if p_version = 0 then
    insert into public.datos(id, data, version) values (1, p_data, 1) on conflict (id) do nothing returning version into v;
  else
    update public.datos set data = p_data, version = version + 1, actualizado = now()
     where id = 1 and version = p_version returning version into v;
  end if;
  return coalesce(v, -1);
end $$;

-- cambiar la contraseña (cierra la sesión en los otros dispositivos)
create or replace function public.mp_cambiar(p_token text, p_vieja text, p_nueva text) returns text
language plpgsql security definer set search_path = '' as $$
begin
  if not public._mp_ok(p_token) then raise exception 'sesion'; end if;
  if not exists(select 1 from public.config where pass_hash = extensions.crypt(coalesce(p_vieja, ''), pass_hash)) then return null; end if;
  if length(coalesce(p_nueva, '')) < 6 then raise exception 'corta'; end if;
  update public.config set pass_hash = extensions.crypt(p_nueva, extensions.gen_salt('bf', 10)), cambiada = now();
  delete from public.sesiones;
  return public._mp_sesion();
end $$;

-- salir de este dispositivo
create or replace function public.mp_salir(p_token text) returns void
language sql security definer set search_path = '' as $$
  delete from public.sesiones where token_hash = encode(extensions.digest(coalesce(p_token, ''), 'sha256'), 'hex');
$$;

revoke execute on all functions in schema public from public, anon, authenticated;
grant execute on function public.mp_estado(), public.mp_crear(text), public.mp_entrar(text), public.mp_leer(text),
  public.mp_guardar(text, jsonb, bigint), public.mp_cambiar(text, text, text), public.mp_salir(text) to anon;
