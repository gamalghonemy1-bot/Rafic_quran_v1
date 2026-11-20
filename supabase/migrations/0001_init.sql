-- رفيقي القرآني - المرحلة 1
-- نفّذ هذا الملف كاملاً في Supabase: SQL Editor > New query > Run

-- ملف المستخدم
create table if not exists public.profiles (
  id uuid primary key references auth.users (id) on delete cascade,
  display_name text not null default '',
  created_at timestamptz not null default now()
);

-- إعدادات الورد (صف واحد لكل مستخدم)
create table if not exists public.wird_settings (
  user_id uuid primary key references auth.users (id) on delete cascade,
  wird_time time not null default '05:00',
  ayat_per_day int not null default 3 check (ayat_per_day between 3 and 5),
  -- 1 = الاثنين ... 7 = الأحد
  active_days int[] not null default '{1,2,3,4,5,6,7}',
  next_surah int not null default 1 check (next_surah between 1 and 114),
  next_ayah int not null default 1 check (next_ayah >= 1),
  updated_at timestamptz not null default now()
);

-- سجل الأيام: ورد كل يوم وحالته
create table if not exists public.wird_days (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users (id) on delete cascade,
  day date not null,
  surah int not null check (surah between 1 and 114),
  from_ayah int not null check (from_ayah >= 1),
  to_ayah int not null check (to_ayah >= from_ayah),
  status text not null default 'pending' check (status in ('pending', 'completed')),
  completed_at timestamptz,
  created_at timestamptz not null default now(),
  unique (user_id, day)
);

create index if not exists wird_days_user_day_idx on public.wird_days (user_id, day desc);

-- أمان الصفوف: كل مستخدم يرى ويعدّل بياناته فقط
alter table public.profiles enable row level security;
alter table public.wird_settings enable row level security;
alter table public.wird_days enable row level security;

drop policy if exists "own profile" on public.profiles;
create policy "own profile" on public.profiles
  for all using (auth.uid() = id) with check (auth.uid() = id);

drop policy if exists "own settings" on public.wird_settings;
create policy "own settings" on public.wird_settings
  for all using (auth.uid() = user_id) with check (auth.uid() = user_id);

drop policy if exists "own days" on public.wird_days;
create policy "own days" on public.wird_days
  for all using (auth.uid() = user_id) with check (auth.uid() = user_id);

-- إنشاء ملف المستخدم تلقائياً عند التسجيل
create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  insert into public.profiles (id, display_name)
  values (new.id, coalesce(new.raw_user_meta_data ->> 'display_name', ''))
  on conflict (id) do nothing;
  return new;
end;
$$;

drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created
  after insert on auth.users
  for each row execute function public.handle_new_user();

-- إتمام الورد: يسجّل الإنجاز ويقدّم الموضع التالي في عملية واحدة.
-- لا يتقدّم الموضع إلا إذا كان الورد "pending" (فالضغط المزدوج لا يكرر التقدّم).
create or replace function public.complete_wird(
  p_day date,
  p_next_surah int,
  p_next_ayah int
)
returns void
language plpgsql
security invoker
as $$
begin
  update public.wird_days
     set status = 'completed', completed_at = now()
   where user_id = auth.uid() and day = p_day and status = 'pending';

  if found then
    update public.wird_settings
       set next_surah = p_next_surah,
           next_ayah = p_next_ayah,
           updated_at = now()
     where user_id = auth.uid();
  end if;
end;
$$;
