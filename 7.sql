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

