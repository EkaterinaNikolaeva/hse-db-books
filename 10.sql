-- получить актуальный book_in_shop_id по book_id и shop_id

create or replace function bookmetrics.get_actual_book_in_shop_id(
    p_book_id integer,
    p_shop_id integer
) 
returns integer as $$
declare
    answer integer;
begin
    select record_id into answer
    from bookmetrics.book_in_shop
    where book_id = p_book_id
      and shop_id = p_shop_id
      and now() between valid_from and valid_to;

    if answer is null then
        raise exception 'there are no actual books in the shop for the given ids';
    end if;

    return answer;
end;
$$
language plpgsql;


-- удалить все записи в book_in_shop у которых valid_to меньше переданного
-- вместе с этим удаляются и связи с booking в таблице book_in_booking

create or replace procedure bookmetrics.delete_old_records(
    p_timestamp timestamp,
    p_shop_id integer default null,
    p_book_id integer default null
)
language plpgsql
as $$
begin
    delete from bookmetrics.book_in_booking
    using bookmetrics.book_in_shop
    where bookmetrics.book_in_booking.book_in_shop_id = bookmetrics.book_in_shop.record_id
      and bookmetrics.book_in_shop.valid_to < p_timestamp
      and (p_shop_id is null or bookmetrics.book_in_shop.shop_id = p_shop_id)
      and (p_book_id is null or bookmetrics.book_in_shop.book_id = p_book_id);

    delete from bookmetrics.book_in_shop
    where valid_to < p_timestamp
      and (p_shop_id is null or shop_id = p_shop_id)
      and (p_book_id is null or book_id = p_book_id);
end;
$$;


-- сделать новый booking

create or replace procedure bookmetrics.add_new_booking(
    p_customer_login varchar,
    p_shop_id integer,
    p_book_ids integer[],
    p_book_numbers integer[],
    p_booking_date timestamp
)
language plpgsql
as $$
declare
    v_customer_id integer;
    v_booking_id integer;
    i integer;
begin
    select customer_id into v_customer_id
    from bookmetrics.customer
    where login = p_customer_login;

    if v_customer_id is null then
        raise exception 'customer with login % does not exist', p_customer_login;
    end if;

    insert into bookmetrics.booking (shop_id, customer_id, booking_date)
    values (p_shop_id, v_customer_id, p_booking_date)
    returning booking_id into v_booking_id;

    for i in 1..array_length(p_book_ids, 1)
    loop
        insert into bookmetrics.book_in_booking (booking_id, book_in_shop_id, book_number)
        values (v_booking_id, bookmetrics.get_actual_book_in_shop_id(p_book_ids[i], p_shop_id), p_book_numbers[i]);
    end loop;
end;
$$;