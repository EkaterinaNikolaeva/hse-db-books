-- 1

-- При появлении книги у магазина в заказе-бронировании,
-- уменьшить количество оставшихся экземпляров в наличии

create or replace function bookmetrics.book_in_shop_quantity_update()
returns trigger as $$
	declare
		booking_date timestamp;
		old_book_number integer;
	begin
		booking_date := (select b.booking_date 
						from bookmetrics.booking as b
						where b.booking_id = new.booking_id);
	    if not exists (
	        select 1
	        from bookmetrics.book_in_shop as book_in_shop
	        where book_in_shop.record_id = new.book_in_shop_id
	        	and booking_date between book_in_shop.valid_from and book_in_shop.valid_to
	    ) then
	        raise exception 'Incorrect record id';
	    end if;
		old_book_number := coalesce((select book_number
							from bookmetrics.book_in_shop as book_in_shop
							where book_in_shop.record_id = new.book_in_shop_id and 
							booking_date between book_in_shop.valid_from and book_in_shop.valid_to), 0);
		if old_book_number < new.book_number then
			raise exception 'There are not enough such books in this shop';
		else
			with book_in_shop_old_info as (
				select shop_id, book_id, book_number, price 
				from bookmetrics.book_in_shop as book_in_shop
				where book_in_shop.record_id = new.book_in_shop_id and 
							booking_date between book_in_shop.valid_from and book_in_shop.valid_to
			)
			insert into bookmetrics.book_in_shop (shop_id, book_id, book_number, price)
				select shop_id, shop_id, old_book_number - new.book_number, price
				from book_in_shop_old_info;
			update bookmetrics.book_in_shop set valid_to = current_timestamp 
				where record_id = new.book_in_shop_id;
		end if;
		return null;
	end;
$$ language plpgsql;

create or replace trigger tg_quantity_book_in_booking
after insert on bookmetrics.book_in_booking	
for each row execute function bookmetrics.book_in_shop_quantity_update();

-- checks

insert into bookmetrics.booking (shop_id, customer_id) values 
	(1, 1);
	
select * from bookmetrics.booking;
select * from bookmetrics.book_in_booking;
select * from bookmetrics.book_in_shop;

insert into bookmetrics.book_in_booking (booking_id, book_in_shop_id, book_number)
values (7, 2, 3);

-- end checks