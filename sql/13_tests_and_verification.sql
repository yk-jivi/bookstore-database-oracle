-- Сдача курсовой работы по дисциплине:
-- Базы данных

-- Сначала от гостя регистрируемся
exec registration_proc('Natalia_customer', 'Natalia@mail.ru', 'pass123', 'Customer');


-- Старший менеджер
-- Назначение менеджера по продажам
-- id кандидата, id старшего менеджера
exec assign_sales_manager_proc(123,121);


-- Снятие с должности менеджера по продажам
-- id менеджера по продажам, id старшего менеджера
exec remove_sales_manager_proc(123,121);


-- Просмотр списка менеджеров
select * from sales_managers_view;


-- Заказ книг у поставщиков (книга должна быть в таблице Books)
-- id книги, количество 
exec order_books_from_supplier_proc(68, 5);


-- Изменение статуса заказа
-- id заказа, статус (возможные: 'Заказан', 'Едет', 'Доставлен')
exec update_bookorder_status_proc(144, 'Доставлен');


-- Просмотр заказов у поставщиков
select * from book_orders_view;


-- Анализ продаж
exec print_sales_analysis_proc;


-- Выручка с продаж
select * from sales_summary_view;


-- Проверка защитных механизмов
-- Отрицательное кол-во книг при заказе у поставщиков
exec order_books_from_supplier_proc(10, -5);

-- Назанчение одного человека менеджером по продажам дважды
exec assign_sales_manager_proc(123,121);

-- Если попытаются вставить обычного клиента вручную 
-- в таблицу иерархии менеджеров (выполнять от программиста)
-- id простого покупателя, id старшего менеджера
insert into managers (manager_id, supervisor_id) values (123,121);





-- Менеджер по продажам
-- Добавление новой книги
exec add_book_proc('Бfsfsd', 'Дfdsfdsfd', 'Совfdsssss проза', 'Азбука', 2022, 700, 'иссею по приемным семьям после того, как её мать попадает в тюрьму.');

select * from books where title = 'Бfsfsd'

-- Редактирование книги
-- id книги
exec update_book_proc(p_book_id => 68, p_price => 800, p_description => 'Новое описание');


-- Изменение статуса книги
-- id книги, статус
exec update_book_status_proc(181569,'В продаже');

-- 181569


-- Подтверждение заказа
-- id заказа
exec confirm_order_proc(84);


-- Смена статуса заказа
-- id заказа, статус
-- Принят --> (Подтверждён) --> Оплачен --> Отправлен --> Доставлен 
exec update_order_status_proc(85, 'Доставлен');


-- Просмотр всех заказов
select * from orders_view_view;


-- Просмотр отзывов покупателей
select * from reviews_view_view;


-- Проверка защитных механизмов
-- Попытка установить некорректный статус
update orders set status = 'Потерян' where order_id = 5;


-- Попытка "перепрыгнуть" через этапы логики переходов статуса заказа
exec update_order_status(5, 'Доставлен'); 





-- Покупатель
-- Поиск книги
exec find_books_proc(p_author => 'Джанет');


-- Добавление книги в Избранное
-- id книги, id пользователя
exec add_to_wishlist_proc(68, 123);

-- Удаление книги из Избранного
-- id книги, id пользователя
exec remove_from_wishlist_proc(68, 123);


-- Добавление книги в корзину
-- id книги, id пользователя, количество
exec add_to_cart_proc(68, 123, 2);


-- Удаление книги из корзины
-- id книги, id пользователя, количество
exec remove_from_cart_proc(68, 123, 1);


-- Оформление заказа
-- id пользователя
exec checkout_order_proc(123);


-- Просмотр заказов
-- id пользователя
exec customer_orders_proc(123);


-- Написание отзыва
exec add_review_proc(p_book_id => 68, p_user_id => 123, p_rating => 5, p_comment => 'Потрясающее качество печати!');


-- Просмотр отзывов
-- id пользователя
exec my_reviews_proc(123);


-- Просмотр всех книг абсолютно
select * from books_with_status_view;


-- Проверка защитных механизмов
-- Отзыв на книгу, которую не купили
exec add_review_proc(p_book_id => 66, p_user_id => 123, p_rating => 5, p_comment => 'Я её не купила');

-- Некорректный рейтинг
exec add_review_proc(p_book_id => 68, p_user_id => 123, p_rating => -5, p_comment => 'Потрясающее качество печати!');

-- Дубликат в Избранное
exec add_to_wishlist_proc(68, 123);

-- Вторая активная корзина (выполнять от программиста)
insert into orders (user_id, status, order_date) values (123, 'Черновик', sysdate);



drop table reviews;

drop procedure registration