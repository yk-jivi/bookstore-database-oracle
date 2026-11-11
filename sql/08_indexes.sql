-- Ускорение проверки прав доступа во всех процедурах
create index idx_users_login_upper on users(upper(login));

SELECT * FROM users WHERE UPPER(login) = 'IVAN_IVANOV'

-- Для быстрого поиска и добавления в корзину/избранное
create index idx_books_title_upper on books(upper(title));
create index idx_books_author_upper on books(upper(author));
create index idx_books_publisher_upper on books(upper(publisher));

-- Для фильтрации по цене в поиске
create index idx_books_price on books(price);

-- Ускорение поиска активной корзины пользователя (add_to_cart, checkout_order)
create index idx_orders_user_status on orders(user_id, status);

-- Внешний ключ для связи заказов с позициями (JOIN в представлениях)
create index idx_orderitems_order_id on orderitems(order_id);

-- Ускорение триггера списания остатков (поиск всех книг в заказе)
create index idx_orderitems_book_id on orderitems(book_id);

-- Для работы складского триггера при списании и возврате
create index idx_bookorders_fifo on bookorders(book_id, book_order_id);

-- Ускорение просмотра отзывов конкретного пользователя или книги
create index idx_reviews_book_id on reviews(book_id);
create index idx_reviews_user_id on reviews(user_id);

-- Ускорение проверки дублей в избранном (триггер trg_wishlist_unique)
create index idx_wishlist_user_book on wishlist(user_id, book_id);




-- Если индексы не видны
-- Это заставит базу пересчитать количество строк и распределение данных, 
-- осле чего она «увидит», что индексы теперь есть
begin
  dbms_stats.gather_schema_stats(ownname => user);
end;

-- Проверка валидности индексов
select index_name, status 
from user_indexes 
where status = 'VALID';п