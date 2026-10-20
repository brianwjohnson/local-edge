create table public.sharpeners (
  id uuid primary key default gen_random_uuid(),
  owner_id uuid not null references auth.users(id) on delete cascade,
  slug text not null unique check (slug ~ '^[a-z0-9]+(-[a-z0-9]+)*$'),
  name text not null,
  bio text,
  machine text,
  neighborhood text not null,
  city text not null,
  region text,
  country_code char(2) not null default 'US',
  timezone text not null default 'America/Chicago',
  latitude numeric(9,6),
  longitude numeric(9,6),
  is_published boolean not null default false,
  is_open boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  check ((latitude is null) = (longitude is null)),
  check (latitude is null or latitude between -90 and 90),
  check (longitude is null or longitude between -180 and 180)
);

create index sharpeners_owner_id_idx on public.sharpeners(owner_id);
create index sharpeners_discovery_idx on public.sharpeners(country_code, region, city, neighborhood) where is_published;

create table public.shop_hours (
  id uuid primary key default gen_random_uuid(),
  sharpener_id uuid not null references public.sharpeners(id) on delete cascade,
  day_of_week smallint not null check (day_of_week between 0 and 6),
  opens_at time not null,
  closes_at time not null,
  is_closed boolean not null default false,
  unique (sharpener_id, day_of_week, opens_at),
  check (is_closed or closes_at > opens_at)
);

create table public.shop_services (
  id uuid primary key default gen_random_uuid(),
  sharpener_id uuid not null references public.sharpeners(id) on delete cascade,
  name text not null,
  description text,
  base_price_cents integer not null check (base_price_cents >= 0),
  currency char(3) not null default 'USD',
  estimated_minutes integer check (estimated_minutes is null or estimated_minutes > 0),
  is_active boolean not null default true,
  sort_order integer not null default 0,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (sharpener_id, id)
);

create index shop_services_discovery_idx on public.shop_services(sharpener_id, is_active, sort_order);

create table public.service_tags (
  id uuid primary key default gen_random_uuid(),
  service_id uuid not null references public.shop_services(id) on delete cascade,
  tag_group text not null,
  tag_value text not null,
  unique (service_id, tag_group, tag_value)
);

create index service_tags_search_idx on public.service_tags(tag_group, tag_value, service_id);

create table public.service_option_groups (
  id uuid primary key default gen_random_uuid(),
  service_id uuid not null references public.shop_services(id) on delete cascade,
  name text not null,
  selection_type text not null check (selection_type in ('single', 'multiple', 'toggle')),
  is_required boolean not null default false,
  min_selections integer not null default 0 check (min_selections >= 0),
  max_selections integer check (max_selections is null or max_selections >= min_selections),
  sort_order integer not null default 0,
  check (selection_type <> 'toggle' or (min_selections <= 1 and coalesce(max_selections, 1) <= 1))
);

create table public.service_option_choices (
  id uuid primary key default gen_random_uuid(),
  option_group_id uuid not null references public.service_option_groups(id) on delete cascade,
  label text not null,
  price_delta_cents integer not null default 0,
  is_active boolean not null default true,
  sort_order integer not null default 0,
  unique (option_group_id, id)
);

create table public.shop_policies (
  id uuid primary key default gen_random_uuid(),
  sharpener_id uuid not null references public.sharpeners(id) on delete cascade,
  policy_type text not null check (policy_type in ('terms', 'cancellation', 'payment', 'dropoff', 'pickup', 'custom')),
  title text not null,
  body text not null,
  version integer not null default 1 check (version > 0),
  requires_acceptance boolean not null default false,
  is_active boolean not null default true,
  updated_at timestamptz not null default now(),
  unique (sharpener_id, policy_type, version)
);

create unique index shop_policies_one_active_type_idx
  on public.shop_policies(sharpener_id, policy_type) where is_active;

create table public.dropoff_locations (
  id uuid primary key default gen_random_uuid(),
  sharpener_id uuid not null references public.sharpeners(id) on delete cascade,
  name text not null,
  address text not null,
  instructions text,
  latitude numeric(9,6),
  longitude numeric(9,6),
  is_active boolean not null default true,
  created_at timestamptz not null default now(),
  unique (sharpener_id, id),
  check ((latitude is null) = (longitude is null)),
  check (latitude is null or latitude between -90 and 90),
  check (longitude is null or longitude between -180 and 180)
);

create table public.bookings (
  id uuid primary key default gen_random_uuid(),
  sharpener_id uuid not null references public.sharpeners(id) on delete restrict,
  customer_id uuid references auth.users(id) on delete set null,
  customer_name text not null,
  customer_email text not null,
  customer_phone text,
  dropoff_location_id uuid,
  fulfillment_method text not null check (fulfillment_method in ('shop_dropoff', 'public_dropoff', 'arranged')),
  status text not null default 'requested' check (status in ('requested', 'confirmed', 'in_progress', 'ready_for_pickup', 'completed', 'declined', 'cancelled')),
  requested_for timestamptz,
  customer_note text,
  subtotal_cents integer not null default 0 check (subtotal_cents >= 0),
  tax_cents integer not null default 0 check (tax_cents >= 0),
  total_cents integer not null default 0 check (total_cents >= 0),
  currency char(3) not null default 'USD',
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  completed_at timestamptz,
  unique (sharpener_id, id),
  foreign key (sharpener_id, dropoff_location_id)
    references public.dropoff_locations(sharpener_id, id) on delete restrict,
  check (fulfillment_method <> 'public_dropoff' or dropoff_location_id is not null),
  check (customer_id is not null or (length(trim(customer_name)) > 0 and length(trim(customer_email)) > 0))
);

create index bookings_shop_status_idx on public.bookings(sharpener_id, status, created_at desc);
create index bookings_customer_idx on public.bookings(customer_id, created_at desc);

create table public.booking_items (
  id uuid primary key default gen_random_uuid(),
  booking_id uuid not null references public.bookings(id) on delete cascade,
  service_id uuid references public.shop_services(id) on delete set null,
  service_name_snapshot text not null,
  quantity integer not null default 1 check (quantity > 0),
  unit_price_cents integer not null check (unit_price_cents >= 0),
  created_at timestamptz not null default now()
);

create table public.booking_item_options (
  id uuid primary key default gen_random_uuid(),
  booking_item_id uuid not null references public.booking_items(id) on delete cascade,
  option_group_id uuid references public.service_option_groups(id) on delete set null,
  choice_id uuid references public.service_option_choices(id) on delete set null,
  group_name_snapshot text not null,
  choice_label_snapshot text not null,
  price_delta_cents integer not null default 0
);

create table public.booking_policy_acceptances (
  id uuid primary key default gen_random_uuid(),
  booking_id uuid not null references public.bookings(id) on delete cascade,
  policy_id uuid references public.shop_policies(id) on delete set null,
  policy_type text not null,
  title_snapshot text not null,
  version_snapshot integer not null,
  body_snapshot text not null,
  accepted_at timestamptz not null default now(),
  unique (booking_id, policy_type, version_snapshot)
);

create table public.booking_events (
  id uuid primary key default gen_random_uuid(),
  booking_id uuid not null references public.bookings(id) on delete cascade,
  actor_id uuid references auth.users(id) on delete set null,
  from_status text,
  to_status text not null,
  note text,
  created_at timestamptz not null default now()
);

create index booking_events_timeline_idx on public.booking_events(booking_id, created_at);

create table public.payments (
  id uuid primary key default gen_random_uuid(),
  booking_id uuid not null references public.bookings(id) on delete restrict,
  provider text not null,
  provider_payment_id text,
  status text not null check (status in ('pending', 'requires_action', 'processing', 'succeeded', 'failed', 'partially_refunded', 'refunded')),
  amount_cents integer not null check (amount_cents > 0),
  currency char(3) not null default 'USD',
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (provider, provider_payment_id)
);

create index payments_booking_idx on public.payments(booking_id, created_at desc);

create table public.reviews (
  id uuid primary key default gen_random_uuid(),
  booking_id uuid not null unique references public.bookings(id) on delete restrict,
  sharpener_id uuid not null references public.sharpeners(id) on delete restrict,
  customer_id uuid not null references auth.users(id) on delete restrict,
  rating smallint not null check (rating between 1 and 5),
  body text,
  is_visible boolean not null default true,
  created_at timestamptz not null default now()
);

create index reviews_shop_idx on public.reviews(sharpener_id, created_at desc) where is_visible;

create table public.shop_notifications (
  id uuid primary key default gen_random_uuid(),
  recipient_id uuid not null references auth.users(id) on delete cascade,
  sharpener_id uuid references public.sharpeners(id) on delete cascade,
  booking_id uuid references public.bookings(id) on delete cascade,
  notification_type text not null,
  payload jsonb not null default '{}'::jsonb,
  read_at timestamptz,
  created_at timestamptz not null default now()
);

create index shop_notifications_inbox_idx on public.shop_notifications(recipient_id, created_at desc) where read_at is null;

create table public.waitlist_signups (
  id uuid primary key default gen_random_uuid(),
  email text not null,
  interest text not null default 'customer' check (interest in ('customer', 'sharpener')),
  created_at timestamptz not null default now()
);

create unique index waitlist_signups_email_interest_idx on public.waitlist_signups(lower(email), interest);

create view public.shop_public_stats as
select
  s.id as sharpener_id,
  coalesce(completed.total_sharpenings, 0)::bigint as total_sharpenings,
  coalesce(ratings.review_count, 0)::bigint as review_count,
  ratings.average_rating
from public.sharpeners s
left join lateral (
  select sum(bi.quantity)::bigint as total_sharpenings
  from public.bookings b
  join public.booking_items bi on bi.booking_id = b.id
  where b.sharpener_id = s.id and b.status = 'completed'
) completed on true
left join lateral (
  select count(*)::bigint as review_count, round(avg(r.rating), 2) as average_rating
  from public.reviews r
  where r.sharpener_id = s.id and r.is_visible
) ratings on true
where s.is_published or s.owner_id = auth.uid();

create function public.validate_booking_state_change()
returns trigger
language plpgsql
as $$
begin
  if tg_op = 'INSERT' and new.status <> 'requested' then
    raise exception 'New bookings must start in requested state';
  end if;

  if tg_op = 'UPDATE' and old.status = new.status then
    return new;
  end if;

  if tg_op = 'UPDATE' and not (
    (old.status = 'requested' and new.status in ('confirmed', 'declined', 'cancelled')) or
    (old.status = 'confirmed' and new.status in ('in_progress', 'cancelled')) or
    (old.status = 'in_progress' and new.status in ('ready_for_pickup', 'cancelled')) or
    (old.status = 'ready_for_pickup' and new.status in ('completed', 'cancelled'))
  ) then
    raise exception 'Invalid booking status transition: % -> %', old.status, new.status;
  end if;

  if new.status = 'completed' and new.completed_at is null then
    new.completed_at := now();
  end if;

  return new;
end;
$$;

create function public.record_booking_state_change()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare
  shop_owner_id uuid;
begin
  select owner_id into shop_owner_id from public.sharpeners where id = new.sharpener_id;

  if tg_op = 'UPDATE' and old.status = new.status then
    return new;
  end if;

  insert into public.booking_events (booking_id, actor_id, from_status, to_status)
  values (new.id, auth.uid(), case when tg_op = 'UPDATE' then old.status else null end, new.status);

  if tg_op = 'INSERT' then
    insert into public.shop_notifications (recipient_id, sharpener_id, booking_id, notification_type, payload)
    values (shop_owner_id, new.sharpener_id, new.id, 'booking_requested', jsonb_build_object('status', new.status));
  elsif new.customer_id is not null then
    if auth.uid() = shop_owner_id then
      insert into public.shop_notifications (recipient_id, sharpener_id, booking_id, notification_type, payload)
      values (new.customer_id, new.sharpener_id, new.id, 'booking_status_changed', jsonb_build_object('status', new.status));
    else
      insert into public.shop_notifications (recipient_id, sharpener_id, booking_id, notification_type, payload)
      values (shop_owner_id, new.sharpener_id, new.id, 'booking_status_changed', jsonb_build_object('status', new.status));
    end if;
  end if;

  return new;
end;
$$;

create trigger bookings_validate_state_change
before insert or update of status on public.bookings
for each row execute function public.validate_booking_state_change();

create trigger bookings_record_state_change
after insert or update of status on public.bookings
for each row execute function public.record_booking_state_change();

alter table public.sharpeners enable row level security;
alter table public.shop_hours enable row level security;
alter table public.shop_services enable row level security;
alter table public.service_tags enable row level security;
alter table public.service_option_groups enable row level security;
alter table public.service_option_choices enable row level security;
alter table public.shop_policies enable row level security;
alter table public.dropoff_locations enable row level security;
alter table public.bookings enable row level security;
alter table public.booking_items enable row level security;
alter table public.booking_item_options enable row level security;
alter table public.booking_policy_acceptances enable row level security;
alter table public.booking_events enable row level security;
alter table public.payments enable row level security;
alter table public.reviews enable row level security;
alter table public.shop_notifications enable row level security;
alter table public.waitlist_signups enable row level security;

create policy "Published shops are discoverable" on public.sharpeners
  for select using (is_published or auth.uid() = owner_id);
create policy "Owners create shops" on public.sharpeners
  for insert with check (auth.uid() = owner_id);
create policy "Owners update shops" on public.sharpeners
  for update using (auth.uid() = owner_id) with check (auth.uid() = owner_id);
create policy "Owners delete shops" on public.sharpeners
  for delete using (auth.uid() = owner_id);

create policy "Shop hours are public for published shops" on public.shop_hours
  for select using (exists (select 1 from public.sharpeners s where s.id = sharpener_id and (s.is_published or s.owner_id = auth.uid())));
create policy "Owners manage shop hours" on public.shop_hours
  for all using (exists (select 1 from public.sharpeners s where s.id = sharpener_id and s.owner_id = auth.uid()))
  with check (exists (select 1 from public.sharpeners s where s.id = sharpener_id and s.owner_id = auth.uid()));

create policy "Active services are discoverable" on public.shop_services
  for select using (is_active and exists (select 1 from public.sharpeners s where s.id = sharpener_id and s.is_published) or exists (select 1 from public.sharpeners s where s.id = sharpener_id and s.owner_id = auth.uid()));
create policy "Owners manage services" on public.shop_services
  for all using (exists (select 1 from public.sharpeners s where s.id = sharpener_id and s.owner_id = auth.uid()))
  with check (exists (select 1 from public.sharpeners s where s.id = sharpener_id and s.owner_id = auth.uid()));

create policy "Tags are discoverable for published services" on public.service_tags
  for select using (exists (select 1 from public.shop_services v join public.sharpeners s on s.id = v.sharpener_id where v.id = service_id and v.is_active and s.is_published));
create policy "Owners manage service tags" on public.service_tags
  for all using (exists (select 1 from public.shop_services v join public.sharpeners s on s.id = v.sharpener_id where v.id = service_id and s.owner_id = auth.uid()))
  with check (exists (select 1 from public.shop_services v join public.sharpeners s on s.id = v.sharpener_id where v.id = service_id and s.owner_id = auth.uid()));

create policy "Service options are public for published shops" on public.service_option_groups
  for select using (exists (select 1 from public.shop_services v join public.sharpeners s on s.id = v.sharpener_id where v.id = service_id and v.is_active and s.is_published) or exists (select 1 from public.shop_services v join public.sharpeners s on s.id = v.sharpener_id where v.id = service_id and s.owner_id = auth.uid()));
create policy "Owners manage service option groups" on public.service_option_groups
  for all using (exists (select 1 from public.shop_services v join public.sharpeners s on s.id = v.sharpener_id where v.id = service_id and s.owner_id = auth.uid()))
  with check (exists (select 1 from public.shop_services v join public.sharpeners s on s.id = v.sharpener_id where v.id = service_id and s.owner_id = auth.uid()));

create policy "Service choices are public for published shops" on public.service_option_choices
  for select using (is_active and exists (select 1 from public.service_option_groups g join public.shop_services v on v.id = g.service_id join public.sharpeners s on s.id = v.sharpener_id where g.id = option_group_id and v.is_active and s.is_published) or exists (select 1 from public.service_option_groups g join public.shop_services v on v.id = g.service_id join public.sharpeners s on s.id = v.sharpener_id where g.id = option_group_id and s.owner_id = auth.uid()));
create policy "Owners manage service choices" on public.service_option_choices
  for all using (exists (select 1 from public.service_option_groups g join public.shop_services v on v.id = g.service_id join public.sharpeners s on s.id = v.sharpener_id where g.id = option_group_id and s.owner_id = auth.uid()))
  with check (exists (select 1 from public.service_option_groups g join public.shop_services v on v.id = g.service_id join public.sharpeners s on s.id = v.sharpener_id where g.id = option_group_id and s.owner_id = auth.uid()));

create policy "Active policies are public for published shops" on public.shop_policies
  for select using (is_active and exists (select 1 from public.sharpeners s where s.id = sharpener_id and s.is_published) or exists (select 1 from public.sharpeners s where s.id = sharpener_id and s.owner_id = auth.uid()));
create policy "Owners manage shop policies" on public.shop_policies
  for all using (exists (select 1 from public.sharpeners s where s.id = sharpener_id and s.owner_id = auth.uid()))
  with check (exists (select 1 from public.sharpeners s where s.id = sharpener_id and s.owner_id = auth.uid()));

create policy "Active dropoff locations are public" on public.dropoff_locations
  for select using (is_active and exists (select 1 from public.sharpeners s where s.id = sharpener_id and s.is_published) or exists (select 1 from public.sharpeners s where s.id = sharpener_id and s.owner_id = auth.uid()));
create policy "Owners manage dropoff locations" on public.dropoff_locations
  for all using (exists (select 1 from public.sharpeners s where s.id = sharpener_id and s.owner_id = auth.uid()))
  with check (exists (select 1 from public.sharpeners s where s.id = sharpener_id and s.owner_id = auth.uid()));

create policy "Customers and shop owners can read bookings" on public.bookings
  for select using (auth.uid() = customer_id or exists (select 1 from public.sharpeners s where s.id = sharpener_id and s.owner_id = auth.uid()));

create policy "Booking participants can read booking items" on public.booking_items
  for select using (exists (select 1 from public.bookings b where b.id = booking_id and (b.customer_id = auth.uid() or exists (select 1 from public.sharpeners s where s.id = b.sharpener_id and s.owner_id = auth.uid()))));

create policy "Booking participants can read selected options" on public.booking_item_options
  for select using (exists (select 1 from public.booking_items i join public.bookings b on b.id = i.booking_id where i.id = booking_item_id and (b.customer_id = auth.uid() or exists (select 1 from public.sharpeners s where s.id = b.sharpener_id and s.owner_id = auth.uid()))));

create policy "Booking participants can read accepted policies" on public.booking_policy_acceptances
  for select using (exists (select 1 from public.bookings b where b.id = booking_id and (b.customer_id = auth.uid() or exists (select 1 from public.sharpeners s where s.id = b.sharpener_id and s.owner_id = auth.uid()))));

create policy "Booking participants can read status history" on public.booking_events
  for select using (exists (select 1 from public.bookings b where b.id = booking_id and (b.customer_id = auth.uid() or exists (select 1 from public.sharpeners s where s.id = b.sharpener_id and s.owner_id = auth.uid()))));

create policy "Booking participants can read payments" on public.payments
  for select using (exists (select 1 from public.bookings b where b.id = booking_id and (b.customer_id = auth.uid() or exists (select 1 from public.sharpeners s where s.id = b.sharpener_id and s.owner_id = auth.uid()))));

create policy "Visible reviews are public" on public.reviews
  for select using (is_visible);
create policy "Customers review completed bookings" on public.reviews
  for insert with check (
    customer_id = auth.uid() and
    exists (select 1 from public.bookings b where b.id = reviews.booking_id and b.customer_id = auth.uid() and b.sharpener_id = reviews.sharpener_id and b.status = 'completed')
  );

create policy "Users read their notifications" on public.shop_notifications
  for select using (recipient_id = auth.uid());
create policy "Users mark their notifications read" on public.shop_notifications
  for update using (recipient_id = auth.uid()) with check (recipient_id = auth.uid());

create policy "Anyone can join the email waitlist" on public.waitlist_signups
  for insert with check (length(trim(email)) > 3);
