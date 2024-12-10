drop schema if exists bookmetrics_view cascade;

create schema bookmetrics_view;


drop view if exists bookmetrics_view.author;

create view bookmetrics_view.author as
select author_id as id, "name" as author_name
from bookmetrics.author;



drop view if exists bookmetrics_view.shop;

CREATE VIEW bookmetrics_view.shop AS
select shop_id as id, "name", address, login,
repeat ('*', length("password") - 2) || right("password", 2) as masked_password, contacts -- не маскирую, так как публичная информация
from bookmetrics.shop;



drop view if exists bookmetrics_view.customer;

CREATE VIEW bookmetrics_view.customer AS
select customer_id as id, "name", left(mails, 3) ||
repeat (
    '*', position('@' in mails) - 3
) || right(
    mails, length(mails) - position('@' in mails) + 1
) as masked_email, login,
repeat ('*', length("password") - 2) || right("password", 2) as masked_password, contacts -- не маскирую, так как публичная информация
from bookmetrics.customer;



drop view if exists bookmetrics_view.book;

create or replace view bookmetrics_view.book as
select book_id as id, title, isbn, edition
from bookmetrics.book;



drop view if exists bookmetrics_view.author_x_booktomer;

CREATE VIEW bookmetrics_view.author_x_book AS
select author_id, book_id
from bookmetrics.author_x_book;



drop view if exists bookmetrics_view.book_in_shop;

CREATE VIEW bookmetrics_view.book_in_shop AS
select
    shop_id,
    book_id,
    book_number as "number",
    price,
    valid_from
from bookmetrics.book_in_shop
where
    valid_to = '5999-01-01 00:00:00'; -- показываем только актуальную версию


drop view if exists bookmetrics_view.booking;

CREATE VIEW bookmetrics_view.booking AS
select
    booking_id as id,
    shop_id,
    customer_id,
    booking_date
from bookmetrics.booking;


drop view if exists bookmetrics_view.book_in_booking;

CREATE VIEW bookmetrics_view.book_in_booking AS
select
    booking_id,
    book_in_shop_id,
    book_number
from bookmetrics.book_in_booking;


select * from bookmetrics_view.author;
select * from bookmetrics_view.shop;
select * from bookmetrics_view.customer;
SELECT * from bookmetrics_view.book;
SELECT * from bookmetrics_view.author_x_book;
SELECT * from bookmetrics_view.book_in_shop;
SELECT * from bookmetrics_view.booking;
SELECT * from bookmetrics_view.book_in_booking;