-- 0

drop schema if exists bookmetrics cascade;
create schema bookmetrics;

-- 1

drop table if exists bookmetrics.author cascade;

create table bookmetrics.author (
	author_id serial primary key,
	"name" varchar(255) not null
);

-- 2

drop table if exists bookmetrics.shop cascade;

create table bookmetrics.shop (
	shop_id serial primary key,
	"name" varchar(128) not null,
	address varchar(128),
	login varchar(100) not null unique,
	"password" varchar(128) not null,
	contacts varchar(128) not null
);


--3 

drop table if exists bookmetrics.customer cascade;

create table bookmetrics.customer (
	customer_id serial primary key,
	"name" varchar(255),
	mails varchar(128),
	login varchar(100) not null unique,
	"password" varchar(128) not null,
	contacts varchar(128)
);

-- 4

drop table if exists bookmetrics.book cascade;

create table bookmetrics.book (
	book_id serial primary key,
	title varchar(255) not null,
	isbn varchar(13) not null check (regexp_match(isbn, '^\d{10}$') is not null or regexp_match(isbn, '^\d{13}$') is not null),
	edition varchar(255)
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
 	valid_to timestamp
);


-- 7

drop table if exists bookmetrics.booking cascade;

create table bookmetrics.booking (
	booking_id serial primary key,
	shop_id integer references bookmetrics.shop(shop_id) not null,
	customer_id integer references bookmetrics.book(book_id) not null,
	deadline date not null
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