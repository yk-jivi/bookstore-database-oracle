-- Пользователь Guest
-- Процедура регистрации
grant execute on programmer.registration to guest;
create public synonym registration_proc
for programmer.registration;

-- Старший менеджер
-- Процедуры
-- Функции анализа
-- Заказ у поставщиков
grant execute on programmer.order_books_from_supplier to senior_manager;
create public synonym order_books_from_supplier_proc
for programmer.order_books_from_supplier;

-- Назначение менеджера
grant execute on programmer.assign_sales_manager to senior_manager;
create public synonym assign_sales_manager_proc
for programmer.assign_sales_manager;

--Снятие с должности менеджера
grant execute on programmer.remove_sales_manager to senior_manager;
create public synonym remove_sales_manager_proc
for programmer.remove_sales_manager;

-- Изменение статуса заказа книг
grant execute on programmer.update_bookorder_status to senior_manager;
create public synonym update_bookorder_status_proc
for programmer.update_bookorder_status;

-- Анализ продаж
grant execute on programmer.print_sales_analysis to senior_manager;
create public synonym print_sales_analysis_proc
for programmer.print_sales_analysis;

-- Представления
-- Заказы у поставщиков
grant select on programmer.book_orders to senior_manager;
create public synonym book_orders_view
for programmer.book_orders;

-- Просмотр менеджеров по продажам 
grant select on programmer.sales_managers to senior_manager;
create public synonym sales_managers_view
for programmer.sales_managers;

-- Просмотр продаж
grant select on programmer.sales_summary to senior_manager;
create public synonym sales_summary_view
for programmer.sales_summary;

-- Менеджер по продажам
-- Процедуры
-- Добавление книги
grant execute on programmer.add_book to sales_manager;
create public synonym add_book_proc
for programmer.add_book;

-- Обновление книги
grant execute on programmer.update_book to sales_manager;
create public synonym update_book_proc
for programmer.update_book;

-- Обновление статуса книги
grant execute on programmer.update_book_status to sales_manager;
create public synonym update_book_status_proc
for programmer.update_book_status;

-- Обновление статуса заказа
grant execute on programmer.update_order_status to sales_manager;
create public synonym update_order_status_proc
for programmer.update_order_status;

-- Подтверждение заказа покупателя или сообщение о невозможности выполнения
grant execute on programmer.confirm_order to sales_manager;
create public synonym confirm_order_proc
for programmer.confirm_order;

-- Представления
-- Просмотр списка заказов
grant select on programmer.orders_view to sales_manager;
create public synonym orders_view_view for programmer.orders_view;

-- Просмотр списка отзывов
grant select on programmer.reviews_view to sales_manager;
create public synonym reviews_view_view for programmer.reviews_view;

-- Покупатель
-- Процедуры
-- Добавление в Избранное
grant execute on programmer.add_to_wishlist to customer;
create public synonym add_to_wishlist_proc
for programmer.add_to_wishlist;

-- Удаление из Избранного
grant execute on programmer.remove_from_wishlist to customer;
create public synonym remove_from_wishlist_proc
for programmer.remove_from_wishlist;

-- Добавление книги в заказ
grant execute on programmer.add_to_cart to customer;
create public synonym add_to_cart_proc
for programmer.add_to_cart;

-- Удаление книги из заказа
grant execute on programmer.remove_from_cart to customer;
create public synonym remove_from_cart_proc
for programmer.remove_from_cart;

-- Оформление заказа
grant execute on programmer.checkout_order to customer;
create public synonym checkout_order_proc for programmer.checkout_order;

-- Добавление отзыва
grant execute on programmer.add_review to customer;
create public synonym add_review_proc for programmer.add_review;

-- Поиск по фильтрам
grant execute on programmer.find_books to customer;
create public synonym find_books_proc for programmer.find_books;

-- Просмотр заказов
grant execute on programmer.customer_orders to customer;
create public synonym customer_orders_proc for programmer.customer_orders;

-- Просмотр каталога книг
grant select on programmer.books_with_status to customer;
create public synonym books_with_status_view for programmer.books_with_status;

-- Просмотр отзывов
grant execute on programmer.my_reviews to customer;
create public synonym my_reviews_proc for programmer.my_reviews;

