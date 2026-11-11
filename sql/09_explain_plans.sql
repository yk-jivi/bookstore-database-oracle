-- Проверка работоспособности индексов: составление планов запросов
-- index idx_users_login_upper
explain plan for
select * from users where UPPER(login) = 'NATALIA_CUSTOMER';
select * from table(dbms_xplan.display);

-- idx_books_title_upper
explain plan for
select * from books where upper(title) = 'Белый олеандр';
select * from table(dbms_xplan.display);


-- idx_orders_user_status
explain plan for 
select order_id from orders where user_id = 122 and status = 'Черновик';
select * from table(dbms_xplan.display);

-- idx_orderitems_order_id
explain plan for 
select book_id, quantity from orderitems where order_id = 81;
select * from table(dbms_xplan.display);
