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