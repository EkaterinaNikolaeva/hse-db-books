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

-- 3 -- список актуальных книг с рейтингом по цене

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

-- 5 -- Магазины с количеством выгодных книг

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
	


