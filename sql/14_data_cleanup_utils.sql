
-- Пример удаления всех зависимостей
delete from orderitems where order_id in (select order_id from orders where user_id = 2);
delete from orders where user_id = 2;

delete from reviews where user_id = 2;
delete from wishlist where user_id = 2;

-- Потом уже удаляем пользователя
delete from users where user_id = 2;

