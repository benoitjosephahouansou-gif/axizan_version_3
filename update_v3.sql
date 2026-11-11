-- =====================================================================
-- FREE SHOP v3 : thème par boutique + lien automatique par produit
--                + commande sans e-mail
-- À lancer UNE FOIS dans Supabase > SQL Editor > Run,
-- APRÈS schema_v2.sql. Sans risque : rien n'est supprimé, relançable.
-- =====================================================================

do $$ begin
  if to_regclass('public.shops') is null then
    raise exception 'Lance d''abord schema_v2.sql, puis relance ce fichier.';
  end if;
end $$;

-- ---------- 1) Thème de la boutique ----------
alter table shops add column if not exists theme text not null default 'vert';
alter table shops drop constraint if exists shops_theme_check;
alter table shops add constraint shops_theme_check
  check (theme in ('vert','noir-or','ivoire','bleu-nuit'));

-- ---------- 2) Lien automatique par produit ----------
-- Transforme un nom en texte d'adresse : « Théière en céramique » -> theiere-en-ceramique
create or replace function make_slug(t text) returns text
language sql immutable as $$
  select coalesce(nullif(trim(both '-' from regexp_replace(
    lower(translate(coalesce(t,''),
      'ÀÁÂÃÄÅÇÈÉÊËÌÍÎÏÑÒÓÔÕÖÙÚÛÜÝàáâãäåçèéêëìíîïñòóôõöùúûüýÿœæ',
      'AAAAAACEEEEIIIINOOOOOUUUUYaaaaaaceeeeiiiinooooouuuuyyoa')),
    '[^a-z0-9]+', '-', 'g')), ''), 'produit')
$$;

alter table products add column if not exists slug text;

-- Donne un lien à chaque produit déjà existant
do $$
declare r record; base text; cand text; n int;
begin
  for r in select id, shop_id, name from products where slug is null order by created_at loop
    base := left(make_slug(r.name), 50); cand := base; n := 1;
    while exists (select 1 from products where shop_id = r.shop_id and slug = cand and id <> r.id) loop
      n := n + 1; cand := base || '-' || n;
    end loop;
    update products set slug = cand where id = r.id;
  end loop;
end $$;

-- Donne automatiquement un lien à chaque nouveau produit. Le lien ne change plus ensuite,
-- même si tu modifies le nom, pour que les liens déjà partagés continuent de marcher.
create or replace function set_product_slug() returns trigger
language plpgsql as $$
declare base text; cand text; n int := 1;
begin
  if new.slug is null or new.slug = '' then
    base := left(make_slug(new.name), 50); cand := base;
    while exists (select 1 from products where shop_id = new.shop_id and slug = cand and id <> new.id) loop
      n := n + 1; cand := base || '-' || n;
    end loop;
    new.slug := cand;
  end if;
  return new;
end $$;

drop trigger if exists products_slug on products;
create trigger products_slug before insert on products
  for each row execute function set_product_slug();

create unique index if not exists products_slug_uq on products (shop_id, slug);

-- ---------- 3) Commande sans e-mail ----------
-- La version précédente (avec p_email) est remplacée. La colonne « email » reste dans la table
-- pour garder tes anciennes commandes, mais elle n'est plus demandée aux clients.
drop function if exists place_order(uuid,text,text,text,text,text,jsonb,text);

create or replace function place_order(
  p_shop uuid, p_name text, p_phone text, p_address text,
  p_note text, p_items jsonb, p_visitor text default null
) returns json
language plpgsql security definer set search_path = public as $$
declare
  shop shops%rowtype;
  it jsonb;
  prod products%rowtype;
  q int;
  lines jsonb := '[]'::jsonb;
  total numeric := 0;
  qty_total int := 0;
  summary text := '';
  new_order orders%rowtype;
begin
  select * into shop from shops where id = p_shop and active = true;
  if not found then raise exception 'Boutique introuvable'; end if;

  if coalesce(trim(p_name),'') = '' or length(p_name) > 100 then raise exception 'Nom invalide'; end if;
  if coalesce(trim(p_phone),'') = '' or length(p_phone) > 25 or p_phone !~ '^[0-9+ ()-]{8,25}$' then
    raise exception 'Téléphone invalide';
  end if;
  if p_items is null or jsonb_typeof(p_items) <> 'array'
     or jsonb_array_length(p_items) = 0 or jsonb_array_length(p_items) > 20 then
    raise exception 'Panier invalide';
  end if;

  for it in select * from jsonb_array_elements(p_items) loop
    q := coalesce((it->>'qty')::int, 0);
    if q < 1 or q > 50 then raise exception 'Quantité invalide'; end if;
    select * into prod from products
      where id = (it->>'id')::uuid and shop_id = p_shop and active = true;
    if not found then raise exception 'Produit indisponible'; end if;
    lines := lines || jsonb_build_object('id', prod.id, 'name', prod.name, 'price', prod.price, 'qty', q);
    total := total + prod.price * q;
    qty_total := qty_total + q;
    summary := summary || case when summary = '' then '' else ', ' end || q || ' x ' || prod.name;
  end loop;
  if qty_total > 50 then raise exception 'Quantité invalide'; end if;

  insert into orders (shop_id, customer_name, phone, address, note,
                      product_id, product_name, unit_price, quantity, total, items)
  values (p_shop, trim(p_name), trim(p_phone), nullif(trim(p_address),''),
          nullif(left(trim(coalesce(p_note,'')),500),''),
          null, left('[' || shop.name || '] ' || summary, 300),
          round(total / qty_total), qty_total, total, lines)
  returning * into new_order;

  if p_visitor is not null and length(p_visitor) between 8 and 64 then
    update abandoned_carts set status = 'commande', updated_at = now()
      where shop_id = p_shop and visitor_id = p_visitor;
  end if;

  return json_build_object('order_number', new_order.order_number, 'total', new_order.total);
end $$;
revoke all on function place_order(uuid,text,text,text,text,jsonb,text) from public;
grant execute on function place_order(uuid,text,text,text,text,jsonb,text) to anon, authenticated;
