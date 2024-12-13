-- 1

-- При появлении книги у магазина в заказе-бронировании,
-- уменьшить количество оставшихся экземпляров в наличии,
-- создав новую версию, и изменив valid_to старой версии

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
				select shop_id, book_id, old_book_number - new.book_number, price
				from book_in_shop_old_info;
		end if;
		return new;
	end;
$$ language plpgsql;

create or replace trigger tg_01_quantity_book_in_booking
before insert on bookmetrics.book_in_booking	
for each row execute function bookmetrics.book_in_shop_quantity_update();

-- 2

-- Логгируем изменения цены
-- Например, полезно, чтобы показать покупателю динимаку цен продавца

create table bookmetrics.price_changes (
	book_id integer references bookmetrics.book(book_id) not null,
	shop_id integer references bookmetrics.shop(shop_id) not null,
	price integer,
	modification_time timestamp
);

create or replace function bookmetrics.change_price()
returns trigger as $$
	declare
		old_price decimal(10, 2);
	begin
		old_price := (select price 
					from bookmetrics.book_in_shop
					where book_id = new.book_id and 
						shop_id = new.shop_id and
						current_timestamp between valid_from and valid_to
					limit 1);
		if old_price != new.price then
			insert into bookmetrics.price_changes (book_id, shop_id, price, modification_time)
			values (new.book_id, new.shop_id, new.price, current_timestamp);
		end if;
		return new;
	end;
$$ language plpgsql;

create or replace trigger tg_02_quantity_book_in_booking
after insert on bookmetrics.book_in_shop	
for each row execute function bookmetrics.change_price();

-- checks

-- end checks
			
-- 3
		
-- При появлении новой записи со старыми shop_id, book_id,
-- заканчиваем жизнь каждой старой версии

create or replace function bookmetrics.cancel_old_versions()
returns trigger as $$
	begin
		update bookmetrics.book_in_shop set valid_to = current_timestamp
			where book_id = new.book_id and
				shop_id = new.shop_id and
				record_id != new.record_id and
				current_timestamp between valid_from and valid_to;			
		return new;
	end;
$$ language plpgsql;

			
create or replace trigger tg_03_cancel_old_versions
after insert on bookmetrics.book_in_shop
for each row execute function bookmetrics.cancel_old_versions();

-- checks

-- 1

--insert into bookmetrics.booking (shop_id, customer_id) values (1, 1);
--	
--select * from bookmetrics.booking;
--select * from bookmetrics.book_in_booking;
--select * from bookmetrics.book_in_shop;
-- 
--insert into bookmetrics.book_in_booking (booking_id, book_in_shop_id, book_number)
--values (7, 2, 3);
--
---- 2
--
--select * from bookmetrics.book_in_shop;
--
--insert into bookmetrics.book_in_shop(shop_id, book_id, book_number, price)
--values (1, 1, 10, 300);
--
--select * from bookmetrics.price_changes;
--
---- 3
--
--insert into bookmetrics.book_in_shop(shop_id, book_id, book_number, price)
--values (1, 1, 10, 380);
--
--select * from bookmetrics.price_changes;
--
--select * from bookmetrics.book_in_shop;

-- end checks