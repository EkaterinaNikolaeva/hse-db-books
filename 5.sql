--create table bookmetrics.book (
-- 	book_id serial primary key,
-- 	title varchar(255) not null,
-- 	isbn varchar(13) not null check (regexp_match(isbn, '^\d{10}$') is not null or regexp_match(isbn, '^\d{13}$') is not null),
-- 	edition varchar(255)
-- );

-- 1
bookmetrics.book (title, isbn, edition)
VALUES (
        'Портрет Дориана Грея',
        '9785040986842',
        'Эксклюзив: Русская классика'
    );

INSERT INTO
    bookmetrics.book (title, isbn, edition)
VALUES (
        'Портрет Дориана Грея',
        '9700000986842',
        'Эксклюзив: Русская классика'
    );

SELECT title FROM bookmetrics.book WHERE isbn = '9785040986842';

UPDATE bookmetrics.book
SET
    edition = 'Эксмо, Редакция 1'
WHERE
    isbn = '9785040986842';

DELETE FROM bookmetrics.book WHERE isbn = '9700000986842';

-- 2
-- create table bookmetrics.shop (
-- 	shop_id serial primary key,
-- 	"name" varchar(128) not null,
-- 	address varchar(128),
-- 	login varchar(100) not null unique,
-- 	"password" varchar(128) not null,
-- 	contacts varchar(128) not null
-- );
INSERT INTO
    bookmetrics.shop (
        "name",
        address,
        login,
        "password",
        contacts
    )
VALUES (
        'Мир Книг',
        'Проспект Литературы, дом 15',
        'bookstore_user',
        'password123',
        'not_mail'
    );

SELECT
    "name" AS shop_name,
    address,
    login,
    contacts
FROM bookmetrics.shop
ORDER BY "name";

UPDATE bookmetrics.shop
SET
    address = 'г. Москва, ул. Новый адрес, д. 394'
WHERE
    "name" = 'Мир Книг';

DELETE FROM bookmetrics.shop
WHERE
    contacts NOT LIKE '%@%'
    OR contacts ~ '[0-9]';