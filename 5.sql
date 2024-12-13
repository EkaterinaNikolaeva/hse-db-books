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

insert into bookmetrics.author_x_book (author_id, book_id) 
select (select author_id from bookmetrics.author where "name" = 'Фёдор Михайлович Достоевский'),
		book_id
from bookmetrics.book 
where title = 'Идиот';

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
