begin;

create table public.perfis (
  id uuid primary key references auth.users(id) on delete cascade,
  nome text not null check (char_length(btrim(nome)) between 1 and 120),
  cidade text,
  latitude double precision,
  longitude double precision,
  constraint perfis_cidade_valida check (
    (cidade is null and latitude is null and longitude is null)
    or (
      cidade is not null and char_length(btrim(cidade)) between 1 and 250
      and latitude is not null and latitude between -90 and 90
      and longitude is not null and longitude between -180 and 180
    )
  )
);

alter table public.perfis enable row level security;
revoke all on table public.perfis from public, anon, authenticated;
grant select, insert, update on table public.perfis to authenticated;

create policy "Usuário consulta seu perfil" on public.perfis
  for select to authenticated using ((select auth.uid()) = id);

create policy "Usuário cria seu perfil" on public.perfis
  for insert to authenticated with check ((select auth.uid()) = id);

create policy "Usuário atualiza seu perfil" on public.perfis
  for update to authenticated using ((select auth.uid()) = id)
  with check ((select auth.uid()) = id);

commit;
