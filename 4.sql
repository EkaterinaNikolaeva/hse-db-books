-- 1

INSERT INTO bookmetrics.author (name) VALUES 
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

INSERT INTO bookmetrics.shop (name, address, login, password, contacts) VALUES 
	('Буквоед', 'г. Санкт-Петербург, пр-т Невский, д. 46, Лит. А', 'shop1', 'password1', 'Customer@bookvoed.ru'),
	('Буквоед', 'г. Санкт-Петербург, пр-т Московский, д. 109, Лит. А', 'shop2', 'password2', 'Customer@bookvoed.ru'),
	('Буквоед', 'г. Санкт-Петербург, ул. Комсомола, д. 41', 'shop3', 'password3', 'Customer@bookvoed.ru'),
	('Читай-город', 'г. Москва, пл. Манежная, д. 1, стр. 2', 'shop4', 'password4', 'Customer@bookvoed.ru'),
	('Читай-город', 'г. Москва, ул. Таганская, д. 1, стр. 1', 'shop5', 'password5', 'Customer@bookvoed.ru'),
	('Читай-город', 'г. Москва, ул. Земляной Вал, д. 33', 'shop6', 'password6', 'Customer@bookvoed.ru'),
	('Читай-город', 'г. Новосибирск, ул. Военная, д. 5', 'shop7', 'password7', 'Customer@bookvoed.ru'),
	('Читай-город', 'г. Новосибирск, пр-т Красный, д. 31', 'shop8', 'password8', 'Customer@bookvoed.ru'),
	('Читай-город', 'г. Новосибирск, пл. Карла Маркса, д. 7', 'shop9', 'password9', 'Customer@bookvoed.ru'),
	('Дом Книги «Зингер»', 'г. Санкт-Петербург, пр-т Невский, д. 28', 'shop10', 'password10', '+7 (812) 667 84 25'),
	('Книжная лавка Ходасевич', 'г. Москва, ул. Покровка, д. 6', 'shop11', 'password11', 'xodacevich@ya.ru'),
	('Фаланстер', 'г. Москва, ул. Тверская, д. 17', 'shop12', 'password12', 'shop@falanster.ru');

-- 3

INSERT INTO bookmetrics.customer (name, mails, login, password, contacts) VALUES 
	('Иван Иванов', 'ivan@example.com', 'ivan', 'ivanpassword', ''),
	('Селезнева Мария', 'maria@example.com', 'maria', 'mariapassword', ''),
	('Титов Артём', 'artem@example.com', 'artem', 'artempassword', ''),
	('Пахомов Захар', 'zahar@example.com', 'zahar', 'zaharpassword', ''),
	('Маслова Дарья', 'darya@example.com', 'darya', 'daryapassword', '');

-- 4

INSERT INTO bookmetrics.book (title, isbn, edition) VALUES 
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

INSERT INTO bookmetrics.author_x_book (author_id, book_id) VALUES 
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

INSERT INTO bookmetrics.book_in_shop (shop_id, book_id, book_number, price) VALUES 

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

-- 7

INSERT INTO bookmetrics.booking (shop_id, customer_id, deadline) VALUES 
	(1, 1, '2024-12-01'),
	(1, 2, '2024-12-02'),
	(1, 3, '2024-12-03'),
	(2, 1, '2024-12-04'),
	(2, 4, '2024-12-05'),
	(3, 5, '2024-12-06');

--8

INSERT INTO bookmetrics.book_in_booking (booking_id, book_in_shop_id, book_number) values

	(1, 1, 2), 
	(1, 2, 1), 
	(1, 3, 1),
	
	(2, 1, 1), 
	(2, 2, 2),
	
	(3, 3, 1), 
	(3, 4, 1),
	
	(4, 8, 1), 
	(4, 9, 1),
	
	(5, 2, 1), 
	
	(6, 6, 1), 
	(6, 7, 1);
	

-- select

select * from bookmetrics.shop;
select * from bookmetrics.author;
select * from bookmetrics.customer;
select * from bookmetrics.book;
select * from bookmetrics.author_x_book;
select * from bookmetrics.book_in_shop;
select * from bookmetrics.booking;
