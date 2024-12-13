-- NUMBER 3

-- 0

drop schema if exists bookmetrics cascade;
create schema bookmetrics;

-- 1

drop table if exists bookmetrics.author cascade;

create table bookmetrics.author (
	author_id serial primary key,
	"name" text not null
);

-- 2

drop table if exists bookmetrics.shop cascade;

create table bookmetrics.shop (
	shop_id serial primary key,
	"name" text not null,
	address text,
	login varchar(100) not null unique,
	"password" varchar(128) not null,
	contacts text not null
);


--3 

drop table if exists bookmetrics.customer cascade;

create table bookmetrics.customer (
	customer_id serial primary key,
	"name" text,
	mails text,
	login varchar(100) not null unique,
	"password" varchar(128) not null,
	contacts text
);

-- 4

drop table if exists bookmetrics.book cascade;

create table bookmetrics.book (
	book_id serial primary key,
	title text not null,
	isbn varchar(13) not null check (regexp_match(isbn, '^\d{10}$') is not null or regexp_match(isbn, '^\d{13}$') is not null),
	edition text
);

-- 5

drop table if exists bookmetrics.author_x_book cascade;

create table bookmetrics.author_x_book (
	record_id serial primary key,
	author_id integer references bookmetrics.author(author_id) not null,
	book_id integer references bookmetrics.book(book_id) not null
);

-- 6

drop table if exists bookmetrics.book_in_shop cascade;

create table bookmetrics.book_in_shop (
	record_id serial primary key,
	shop_id integer references bookmetrics.shop(shop_id) not null,
	book_id integer references bookmetrics.book(book_id) not null,
	book_number integer check (book_number >= 0) not null,
	price decimal(10, 2) check (price >= 0) not null,
	valid_from timestamp default now()::timestamp,
 	valid_to timestamp default '5999-01-01 00:00:00'
);


-- 7

drop table if exists bookmetrics.booking cascade;

create table bookmetrics.booking (
	booking_id serial primary key,
	shop_id integer references bookmetrics.shop(shop_id) not null,
	customer_id integer references bookmetrics.customer(customer_id) not null,
	booking_date timestamp default now()::timestamp not null
);

-- 8

drop table if exists bookmetrics.book_in_booking cascade;

create table bookmetrics.book_in_booking (
	record_id serial primary key,
	booking_id integer references bookmetrics.booking(booking_id) not null,
	book_in_shop_id integer references bookmetrics.book_in_shop(record_id) not null,
	book_number integer check (book_number >= 0) default 1 not null
);

-- selects

select * from bookmetrics.shop;
select * from bookmetrics.author;
select * from bookmetrics.customer;
select * from bookmetrics.book;
select * from bookmetrics.author_x_book;
select * from bookmetrics.book_in_shop;
select * from bookmetrics.booking;
select * from bookmetrics.book_in_booking;

-- NUMBER 9

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

-- NUMBER 10

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

-- NUMBER 4

-- 1

insert into bookmetrics.author (name) values 
	('Александр Сергеевич Грибоедов'),
	('Николай Васильевич Гоголь'),
	('Александр Сергеевич Пушкин'),
	('Михаил Юрьевич Лермонтов'),
	('Иван Александрович Гончаров'),
	('Николай Семенович Лесков'),
	('Фёдор Михайлович Достоевский'),
	('Антон Павлович Чехов'),
	('Александр Иванович Куприн'),
	('Лев Николаевич Толстой');

-- 2

insert into bookmetrics.shop (name, address, login, password, contacts) values 
	('Буквоед', 'г. Санкт-Петербург, пр-т Невский, д. 46, Лит. А', 'shop1', 'password1', 'spb_nevsky_shop@bookvoed.ru'),
	('Буквоед', 'г. Санкт-Петербург, пр-т Московский, д. 109, Лит. А', 'shop2', 'password2', 'spb_moskovsky_shop@bookvoed.ru'),
	('Буквоед', 'г. Санкт-Петербург, ул. Комсомола, д. 41', 'shop3', 'password3', 'spb_komsomol@bookvoed.ru'),
	('Читай-город', 'г. Москва, пл. Манежная, д. 1, стр. 2', 'shop4', 'password4', 'msk_manezhnaya@bookvoed.ru'),
	('Читай-город', 'г. Москва, ул. Таганская, д. 1, стр. 1', 'shop5', 'password5', 'msk_taganskaya@bookvoed.ru'),
	('Читай-город', 'г. Москва, ул. Земляной Вал, д. 33', 'shop6', 'password6', 'msk_earthen_rampart@bookvoed.ru'),
	('Читай-город', 'г. Новосибирск, ул. Военная, д. 5', 'shop7', 'password7', 'nsk_voennaya@bookvoed.ru'),
	('Читай-город', 'г. Новосибирск, пр-т Красный, д. 31', 'shop8', 'password8', 'nsk_krasny@bookvoed.ru'),
	('Читай-город', 'г. Новосибирск, пл. Карла Маркса, д. 7', 'shop9', 'password9', 'nsk_karl_marks@bookvoed.ru'),
	('Дом Книги «Зингер»', 'г. Санкт-Петербург, пр-т Невский, д. 28', 'shop10', 'password10', '+7 (812) 667 84 25'),
	('Книжная лавка Ходасевич', 'г. Москва, ул. Покровка, д. 6', 'shop11', 'password11', 'xodacevich@ya.ru'),
	('Фаланстер', 'г. Москва, ул. Тверская, д. 17', 'shop12', 'password12', 'shop@falanster.ru');

-- 3

insert into bookmetrics.customer (name, mails, login, password, contacts) values 
	('Иван Иванов', 'ivan@example.com', 'ivan', 'ivanpassword', ''),
	('Селезнева Мария', 'maria@example.com', 'maria', 'mariapassword', ''),
	('Титов Артём', 'artem@example.com', 'artem', 'artempassword', ''),
	('Пахомов Захар', 'zahar@example.com', 'zahar', 'zaharpassword', ''),
	('Маслова Дарья', 'darya@example.com', 'darya', 'daryapassword', '');

-- 4

insert into bookmetrics.book (title, isbn, edition) values 
	('Горе от ума', '9785170947164', 'Эксклюзив: Русская классика'),
	('Ревизор', '9785171049652', 'Эксклюзив: Русская классика'),
	('Капитанская дочка', '9785170928071', 'Эксклюзив: Русская классика'),
	('Герой нашего времени','9785170921645','Эксклюзив: Русская классика'),
	('Обломов', '9785171514266', 'Эксклюзив: Русская классика'),
	('Леди Макбет Мценского уезда','9785171359041','Эксклюзив: Русская классика'),
	('Преступление и наказание','9785170906307','Эксклюзив: Русская классика'),
	('Вишневый сад','9785171489496','Эксклюзив: Русская классика'),
	('Яма','9785170904808','Эксклюзив: Русская классика'),
	('Война и мир. Книга 1','9785170904686','Эксклюзив: Русская классика'),
	('Война и мир. Книга 2','9785171556976','Эксклюзив: Русская классика');


-- 5

insert into bookmetrics.author_x_book (author_id, book_id) values 
	(1, 1),  -- Грибоедов - Горе от ума
	(2, 2),  -- Гоголь - Ревизор
	(3, 3),  -- Пушкин - Капитанская дочка
	(4, 4),  -- Лермонтов - Герой нашего времени
	(5, 5),  -- Гончаров - Обломов
	(6, 6),  -- Лесков - Леди Макбет Мценского уезда
	(7, 7),  -- Достоевский - Преступление и наказание
	(8, 8),  -- Чехов - Вишневый сад
	(9, 9),  -- Куприн - Яма
	(10, 10), -- Толстой - Война и мир. Книга 1
	(10, 11); -- Толстой - Война и мир. Книга 2

-- 6

insert into bookmetrics.book_in_shop (shop_id, book_id, book_number, price) values 

-- Буквоед
	(1, 1, 10, 325.00),  -- Горе от ума
	(1, 2, 5, 380.00),   -- Ревизор
	(1, 3, 7, 270.00),   -- Капитанская дочка
	(1, 4, 6, 290.00),   -- Герой нашего времени
	(1, 5, 8, 350.00),   -- Обломов
	(1, 6, 4, 400.00),   -- Леди Макбет Мценского уезда
	(1, 7, 9, 450.00),   -- Преступление и наказание
	(1, 8, 3, 340.00),   -- Вишневый сад
	(1, 9, 12, 300.00),  -- Яма
	(1, 10, 11, 500.00), -- Война и мир. Книга 1
	(1, 11, 10, 520.00), -- Война и мир. Книга 2

	(2, 1, 15, 335.00),  
	(2, 2, 7, 370.00),
	(2, 3, 5, 260.00),
	(2, 4, 8, 280.00),
	(2, 5, 6, 340.00),
	(2, 6, 5, 390.00),
	(2, 7, 4, 440.00),
	(2, 8, 3, 330.00),
	(2, 9, 10, 290.00),
	(2, 10, 9, 510.00),
	(2, 11, 8, 530.00),

	(3, 1, 12, 340.00),
	(3, 2, 6, 375.00),
	(3, 3, 4, 265.00),
	(3, 4, 7, 295.00),
	(3, 5, 5, 345.00),
	(3, 6, 8, 405.00),
	(3, 7, 9, 455.00),
	(3, 8, 2, 345.00),
	(3, 9, 11, 305.00),
	(3, 10, 10, 510.00),

-- Читай-город (Москва)
	(4, 1, 14, 345.00),
	(4, 2, 8, 380.00),
	(4, 3, 6, 270.00),
	(4, 4, 9, 300.00),
	(4, 5, 7, 355.00),
	(4, 6, 6, 415.00),
	(4, 7, 5, 465.00),
	(4, 8, 4, 355.00),
	(4, 9, 13, 310.00),
	(4, 10, 11, 525.00),
	(4, 11, 13, 535.00),

	(5, 1, 13, 350.00),
	(5, 2, 12, 380.00),
	(5, 3, 10, 280.00),
	(5, 4, 8, 300.00),
	(5, 5, 9, 360.00),
	(5, 6, 7, 420.00),
	(5, 7, 6, 470.00),
	(5, 8, 5, 370.00),
	(5, 9, 14, 320.00),
	(5, 10, 12, 530.00),
	(5, 11, 14, 540.00),

	(6, 1, 15, 355.00),
	(6, 2, 9, 385.00),
	(6, 3, 7, 285.00),
	(6, 4, 6, 305.00),
	(6, 5, 7, 365.00),
	(6, 6, 8, 425.00),
	(6, 7, 9, 475.00),
	(6, 8, 10, 375.00),
	(6, 9, 15, 325.00),
	(6, 10, 13, 535.00),
	(6, 11, 15, 545.00),

-- Читай-город (Новосибирск)
	(7, 1, 16, 360.00),
	(7, 2, 10, 390.00),
	(7, 3, 8, 290.00),
	(7, 4, 7, 310.00),
	(7, 5, 9, 370.00),
	(7, 6, 11, 430.00),
	(7, 7, 12, 480.00),
	(7, 8, 13, 410.00),
	(7, 9, 14, 330.00),
	(7, 10, 15, 540.00),
	(7, 11, 16, 550.00),

	(8, 1, 17, 365.00),
	(8, 2, 11, 390.00),
	(8, 3, 9, 300.00),
	(8, 4, 8, 320.00),
	(8, 5, 10, 380.00),
	(8, 6, 12, 435.00),
	(8, 7, 13, 480.00),
	(8, 8, 14, 420.00),
	(8, 9, 15, 340.00),
	(8, 10, 16, 560.00),
	(8, 11, 17, 570.00),

	(9, 1, 18, 370.00),
	(9, 2, 12, 395.00),
	(9, 3, 10, 310.00),
	(9, 4, 9, 330.00),
	(9, 5, 11, 390.00),
	(9, 6, 13, 440.00),
	(9, 7, 14, 490.00),
	(9, 8, 15, 425.00),
	(9, 9, 16, 350.00),
	(9, 10, 17, 570.00),
	(9, 11, 18, 570.00),

-- Дом Книги «Зингер»
	(10, 1, 5, 325.00),
	(10, 2, 5, 380.00),
	(10, 3, 5, 270.00),
	(10, 4, 5, 290.00),
	(10, 5, 5, 350.00),
	(10, 6, 5, 340.00),
	(10, 7, 5, 410.00),
	(10, 8, 5, 300.00),
	(10, 9, 5, 280.00),
	(10, 10, 5, 450.00),
	(10, 11, 5, 450.00),

-- Книжная лавка Ходасевич
	(11, 1, 5, 325.00),
	(11, 2, 5, 380.00),
	(11, 3, 5, 270.00),
	(11, 4, 5, 290.00),
	(11, 5, 5, 350.00),
	(11, 6, 5, 340.00),
	(11, 7, 5, 410.00),
	(11, 8, 5, 300.00),
	(11, 9, 5, 280.00),
	(11, 10, 5, 450.00),
	(11, 11, 5, 450.00),

-- Фаланстер
	(12, 1, 5, 325.00),
	(12, 2, 5, 380.00),
	(12, 3, 5, 270.00),
	(12, 4, 5, 290.00),
	(12, 5, 5, 350.00),
	(12, 6, 5, 340.00),
	(12, 7, 5, 410.00),
	(12, 8, 5, 300.00),
	(12, 9, 5, 280.00),
	(12, 10, 5, 450.00),
	(12, 11, 5, 450.00);


-- 7, 8

CALL bookmetrics.add_new_booking(
    'ivan',
    1,
    ARRAY[2, 3],
    ARRAY[1, 1],
    '2025-12-01'
);

CALL bookmetrics.add_new_booking(
    'ivan',
    2,
    ARRAY[1, 4],
    ARRAY[1, 2],
    '2025-12-02'
);


CALL bookmetrics.add_new_booking(
    'maria',
    2,
    ARRAY[1, 2],
    ARRAY[1, 1, 1],
    '2025-12-01'
);


CALL bookmetrics.add_new_booking(
    'artem',
    3,
    ARRAY[5],
    ARRAY[1],
    '2025-12-03'
);

CALL bookmetrics.add_new_booking(
    'zahar',
    4,
    ARRAY[10, 11],
    ARRAY[2, 3],
    '2025-12-04'
);

-- select

select * from bookmetrics.shop;
select * from bookmetrics.author;
select * from bookmetrics.customer;
select * from bookmetrics.book;
select * from bookmetrics.author_x_book;
select * from bookmetrics.book_in_shop;
select * from bookmetrics.booking;
select * from bookmetrics.book_in_booking;

-- NUMBER 5

--create table bookmetrics.book (
--   book_id serial primary key,
--   title varchar(255) not null,
--   isbn varchar(13) not null check (regexp_match(isbn, '^\d{10}$') is not null or regexp_match(isbn, '^\d{13}$') is not null),
--   edition varchar(255)
-- );

-- 1
insert into bookmetrics.book (title, isbn, edition)
values (
        'Идиот',
        '9785040986842',
        'Эксклюзив: Русская классика'
    );

insert into bookmetrics.book (title, isbn, edition)
values (
        'Идиот',
        '0000000986842',
        'Эксклюзив: Русская классика'
    );

select title from bookmetrics.book where isbn = '9785040986842';

update bookmetrics.book
set
    edition = 'Эксмо, Редакция 1'
where
    isbn = '9785040986842';

delete from bookmetrics.book where isbn = '0000000986842';

-- 2
-- create table bookmetrics.shop (
--   shop_id serial primary key,
--   "name" varchar(128) not null,
--   address varchar(128),
--   login varchar(100) not null unique,
--   "password" varchar(128) not null,
--   contacts varchar(128) not null
-- );
insert into bookmetrics.shop (
        "name",
        address,
        login,
        "password",
        contacts
    )
values (
        'Мир Книг',
        'Проспект Литературы, дом 15',
        'bookstore_user',
        'password123',
        'not_mail'
    );

select
    "name" as shop_name,
    address,
    login,
    contacts
from bookmetrics.shop
order by "name";

update bookmetrics.shop
set
    address = 'г. Москва, ул. Новый адрес, д. 394'
where
    "name" = 'Мир Книг';

delete from bookmetrics.shop
where
    contacts not like '%@%'
    and contacts !~ '^[0-9\s()+-]+$';

-- NUMBER 6

-- 1 -- общее количество книг и их сумарная стоимость в каждом магазине

select s.shop_id,
       s.name as shop_name,
       sum(bis.book_number) as total_books,
       sum(bis.price * bis.book_number) as total_value
from bookmetrics.shop as s
join bookmetrics.book_in_shop as bis on s.shop_id = bis.shop_id
group by s.shop_id,
         s.name
order by s.shop_id;

-- 2 -- все покупатели купившие больше трёх книг

select c.customer_id,
       c.name as customer_name,
       sum(bib.book_number) as total_books
from bookmetrics.booking as b
join bookmetrics.book_in_booking as bib on b.booking_id = bib.booking_id
join bookmetrics.customer as c on b.customer_id = c.customer_id
group by c.customer_id,
         c.name
having sum(bib.book_number) > 3;

-- 3 -- список актуальных (записи с valid_to >= now()) книг с рейтингом по цене

select b.book_id,
       b.title,
       bs.shop_id,
       s.name as shop_name,
       bs.price,
       dense_rank() over (partition by b.book_id
                          order by bs.price) as price_rank
from bookmetrics.book b
join bookmetrics.book_in_shop bs on b.book_id = bs.book_id
join bookmetrics.shop s on bs.shop_id = s.shop_id
where bs.valid_to >= now()
order by b.book_id,
         price_rank;

-- 4 -- динамика минимальной цены на книги (версия для каждого дня), для большей частоты поменять interval
with day_series as
  (select generate_series(
                            (select min(valid_from)
                             from bookmetrics.book_in_shop), now(), '1 day'::interval) as report_time),
     actual_prices as
  (select ds.report_time,
          bs.book_id,
          bs.price,
          bs.shop_id
   from day_series ds
   left join bookmetrics.book_in_shop bs on ds.report_time between bs.valid_from and bs.valid_to
   where bs.book_number != 0),
     min_prices as
  (select report_time,
          book_id,
          min(price) as min_price
   from actual_prices
   where price is not null
   group by report_time,
            book_id)
select ap.report_time,
       ap.book_id,
       ap.shop_id,
       ap.price
from actual_prices ap
join min_prices mp on ap.report_time = mp.report_time
and ap.book_id = mp.book_id
and ap.price = mp.min_price
order by ap.report_time,
         ap.book_id;

-- 5 -- магазины с количеством выгодных (в других магазинах цена >=) книг

with actual_books as (
    select 
        bis.shop_id,
        bis.book_id,
        bis.price
    from 
        bookmetrics.book_in_shop as bis
    where 
        now() between bis.valid_from and bis.valid_to 
        and bis.book_number != 0
),
min_price_books as (
    select 
        book_id,
        min(price) as min_price
    from 
        actual_books
    group by 
        book_id
)
select 
    ab.shop_id, 
    count(*) as number_cheapest_books
from 
    actual_books as ab
join 
    min_price_books as mpb on ab.book_id = mpb.book_id and ab.price = mpb.min_price
group by 
    ab.shop_id
order by 
    number_cheapest_books desc;

-- 6 -- рейтинг авторов с количеством проданных копий и количеством книг, которые они написали и их самая популярная книга 
     -- (считаем что самая популярная у одного автора ровно одна)
with author_book_sales as (
    select
        a.author_id,
        a.name as author_name,
        b.book_id,
        b.title as book_title,
        coalesce(sum(bib.book_number), 0) as total_copies_sold
    from
        bookmetrics.author as a
        join bookmetrics.author_x_book as ab on a.author_id = ab.author_id
        join bookmetrics.book as b on ab.book_id = b.book_id
        left join bookmetrics.book_in_shop as bis on b.book_id = bis.book_id
        left join bookmetrics.book_in_booking as bib on bis.record_id = bib.book_in_shop_id
    group by
        a.author_id, a.name, b.book_id, b.title
),
author_stats as (
    select
        author_id,
        author_name,
        count(distinct book_id) as total_books_written,
        sum(total_copies_sold) as total_copies_sold
    from
        author_book_sales
    group by
        author_id, author_name
),
most_sold_books as (
    select
        author_id,
        book_title,
        total_copies_sold,
        row_number() over (partition by author_id order by total_copies_sold desc) as rn
    from
        author_book_sales
)
select
    a.author_id,
    a.author_name,
    a.total_books_written,
    a.total_copies_sold,
    msb.book_title as most_sold_book,
    msb.total_copies_sold as copies_sold_for_most_sold_book
from
    author_stats as a
    left join most_sold_books as msb on a.author_id = msb.author_id and msb.rn = 1
order by
    a.total_copies_sold desc;

-- NUMBER 7

drop schema if exists bookmetrics_view cascade;
create schema bookmetrics_view;

drop view if exists bookmetrics_view.author;
create view bookmetrics_view.author as
select
   "name" as author_name
from bookmetrics.author;


drop view if exists bookmetrics_view.shop;
create view bookmetrics_view.shop as
select
    name as shop_name,
    address,
    repeat('*', length(password) - 2) || right(password, 2) as masked_password,
    contacts
from bookmetrics.shop;


drop view if exists bookmetrics_view.customer;
create view bookmetrics_view.customer as
select
    left("name", 1) || repeat('*', greatest(length("name") - 1, 0)) as masked_name,
    left(mails, 3) || repeat('*', position('@' in mails) - 3) || right(mails, length(mails) - position('@' in mails) + 1) as masked_email,
    contacts
from bookmetrics.customer;

drop view if exists bookmetrics_view.book;
create view bookmetrics_view.book as
select
    title,
    isbn,
    edition
from bookmetrics.book;


drop view if exists bookmetrics_view.author_x_book;
create view bookmetrics_view.author_x_book as
select
    a.name as author_name,
    b.title as book_title
from bookmetrics.author_x_book ab
inner join bookmetrics.author a on ab.author_id = a.author_id
inner join bookmetrics.book b on ab.book_id = b.book_id;


drop view if exists bookmetrics_view.book_in_shop;
create view bookmetrics_view.book_in_shop as
select
    b.title as book_title,
    s.name as shop_name,
    bis.book_number as "number",
    bis.price,
    bis.valid_from
from bookmetrics.book_in_shop bis
inner join bookmetrics.shop s on bis.shop_id = s.shop_id
inner join bookmetrics.book b on bis.book_id = b.book_id
where bis.valid_to = '5999-01-01 00:00:00';


drop view if exists bookmetrics_view.booking;
create view bookmetrics_view.booking as
select
    s.name as shop_name,
    bk.customer_id,
    left(c."name", 1) || repeat('*', greatest(length(c."name") - 1, 0)) as masked_customer_name,
    bk.booking_date
from bookmetrics.booking bk
inner join bookmetrics.shop s on bk.shop_id = s.shop_id
inner join bookmetrics.customer c on bk.customer_id = c.customer_id;


drop view if exists bookmetrics_view.book_in_booking;
create view bookmetrics_view.book_in_booking as
select
    bib.book_number,
    left(c.name, 1) || repeat('*', greatest(length(c.name) - 1, 0)) as masked_customer_name, 
    b.title as book_title, 
    s.name as shop_name 
from bookmetrics.book_in_booking bib
inner join bookmetrics.booking bkg on bib.booking_id = bkg.booking_id
inner join bookmetrics.customer c on bkg.customer_id = c.customer_id
inner join bookmetrics.book_in_shop bis on bib.book_in_shop_id = bis.record_id
inner join bookmetrics.book b on bis.book_id = b.book_id
inner join bookmetrics.shop s on bis.shop_id = s.shop_id
order by bib.book_number desc; 


select * from bookmetrics_view.author;
select * from bookmetrics_view.shop;
select * from bookmetrics_view.customer;
select * from bookmetrics_view.book;
select * from bookmetrics_view.author_x_book;
select * from bookmetrics_view.book_in_shop;
select * from bookmetrics_view.booking;
select * from bookmetrics_view.book_in_booking;

-- NUMBER 8

-- Отображает статистику по продажам для каждого магазина.
-- Включает название магазина, количество проданных книг, общий доход
-- и дату последней продажи
drop view if exists bookmetrics_view.shop_sales_summary;

create view
    bookmetrics_view.shop_sales_summary as
select
    s."name" as shop_name,
    sum(bib.book_number) as total_books_sold,
    sum(bib.book_number * bis.price) as total_revenue,
    max(b.booking_date) as last_sale_date
from
    bookmetrics.shop s
    join bookmetrics.booking b on s.shop_id = b.shop_id
    join bookmetrics.book_in_booking bib on b.booking_id = bib.booking_id
    join bookmetrics.book_in_shop bis on bib.book_in_shop_id = bis.record_id
group by
    s.shop_id,
    s."name";

SELECT
    *
from
    bookmetrics_view.shop_sales_summary;

-- Отображает все брони всех пользователей, в случае если броней несколько,
-- показывает их все в разных строках.
-- Включает логин пользователя, дату брони, id и название магазина,
-- а так же количество забронированных книг и их список в формате (<название> #количество)
drop view if exists bookmetrics_view.active_bookings;

create view
    bookmetrics_view.active_bookings as
select
    c.login as customer_login,
    b.booking_date,
    s.shop_id,
    s.name as shop_name,
    sum(bib.book_number) as total_books_reserved,
    array_agg (distinct bk.title || ' #' || bib.book_number) as reserved_books
from
    bookmetrics.booking b
    join bookmetrics.customer c on b.customer_id = c.customer_id
    join bookmetrics.shop s on b.shop_id = s.shop_id
    join bookmetrics.book_in_booking bib on b.booking_id = bib.booking_id
    join bookmetrics.book_in_shop bis on bib.book_in_shop_id = bis.record_id
    join bookmetrics.book bk on bis.book_id = bk.book_id
group by
    c.customer_id,
    c.name,
    b.booking_id,
    b.booking_date,
    s.shop_id,
    s.name;

SELECT
    *
from
    bookmetrics_view.active_bookings;

-- Отображает популярность авторов. Включает автора,
-- количество проданных книг и суммарный доход от его книг.
drop view if exists bookmetrics_view.author_popularity;

create view
    bookmetrics_view.author_popularity as
select
    a."name" as author_name,
    sum(bib.book_number) as total_books_sold,
    sum(bib.book_number * bis.price) as total_revenue
from
    bookmetrics.author a
    join bookmetrics.author_x_book axb on a.author_id = axb.author_id
    join bookmetrics.book b on axb.book_id = b.book_id
    join bookmetrics.book_in_shop bis on b.book_id = bis.book_id
    join bookmetrics.book_in_booking bib on bis.record_id = bib.book_in_shop_id
group by
    a.author_id,
    a."name"
order by
    total_books_sold desc,
    total_revenue desc;

SELECT
    *
FROM
    bookmetrics_view.author_popularity;
