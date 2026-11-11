insert into books (title, author, genre, publisher, year, price, description, status)
values ('Война и мир', 'Лев Толстой', 'Роман', 'Эксмо', 1869, 1200, 'Классика русской литературы', 'Активна');

insert into books (title, author, genre, publisher, year, price, description, status)
values ('Преступление и наказание', 'Фёдор Достоевский', 'Роман', 'АСТ', 1866, 950, 'Психологический роман', 'Активна');

insert into books (title, author, genre, publisher, year, price, description, status)
values ('Мастер и Маргарита', 'Михаил Булгаков', 'Фантастика', 'Азбука', 1967, 1100, 'Мистический роман', 'Активна');

insert into books (title, author, genre, publisher, year, price, description, status)
values ('1984', 'Джордж Оруэлл', 'Антиутопия', 'Penguin', 1949, 800, 'Антиутопия про тоталитаризм', 'Активна');

insert into books (title, author, genre, publisher, year, price, description, status)
values ('Гарри Поттер и философский камень', 'Джоан Роулинг', 'Фэнтези', 'Bloomsbury', 1997, 1500, 'Первая книга о Гарри Поттере', 'Активна');

insert into books (title, author, genre, publisher, year, price, description, status)
values ('Clean Code', 'Robert Martin', 'Программирование', 'Prentice Hall', 2008, 3000, 'Книга о чистом коде', 'Активна');

commit;

select * from Books;


--Менеджер по продажам Anastasiya

--Старший менеджер Yuliya
--Заказ книг у поставщиков.
--Важно! Книга должна присутсвовать в таблице Books,
--иначе заказать её будет невозможно
begin
    orderbooksfromsupplier_by_title_proc('Война и мир',10);
    commit;
end;

--Тут же сделаем проверку на неправильный заказ
--Заказ книг у поставщиков при неизвестной книге
begin
    orderbooksfromsupplier_by_title_proc('Неизвестно',10);
    commit;
end;

--Заказ книг у поставщиков при неправильном количестве
begin
    orderbooksfromsupplier_by_title_proc('Война и мир',0);
    commit;
end;

begin
    orderbooksfromsupplier_by_title_proc('Война и мир',-1);
    commit;
end;

--Далее рассмотрим управление менеджерами по продажам
--Назначение пользователя на роль менеджера по продажам
begin
    assign_sales_manager_proc('Natalia');
    commit;
end;
--Попробуем себя же назанчить на роль менджера по продажам
begin
    assign_sales_manager_proc('Yuliya');
    commit;
end;

--Уволим менеджера по продажам
begin
    remove_sales_manager_proc('Natalia');
    commit;
end;
--Попробуем уволить себя / или же присвоить роль Customer
begin
    remove_sales_manager_proc('Yuliya');
    commit;
end;

--Далее рассмотрим функции Старшего менеджера
--Функции основаны на анализе продаж
--Есть функция вывода ТОП3 продаваемых книги
--(для того, чтобы увидеть ТОП3 продаваемых книги,
--необходимо, чтобы пользователи сначала заказали что-то.
--Поэтому, возможно пока вывод будет пустым.
--То есть смотриться наибольшее количество заказов книги)
select * from table(get_top3_books_pipe_func);
--Есть функция вывода ТОП3 непродаваемых книги
--(Здесь то же самое, только смотрится наименьшее количество заказов книги)
select * from table(get_least3_books_pipe_func);

--Далее представления
--Можем посмотреть заказы у поставщиков
select * from book_orders_view;
--Просмотр менеджеров по продажам
select * from sales_managers_view;
--Просмотр суммарных продаж
--(ничего не выведет, если никто ничего не заказывал)
select * from sales_summary_view;

--Менеджер по продажам Anastasiya
--Добавление книги
begin
    add_book_proc(
        'Test Book',
        'Test Author',
        'Fantasy',
        'Test Publisher',
        2024,
        100,
        'Test description'
    );
    commit;
end;

select * from books_table;

--Обновление книги
begin
    update_book_proc(
        'Test Book',
        'New Author',
        'Drama',
        'New Publisher',
        2025,
        150,
        'Updated'
    );
    commit;
end;

select * from books_table;

--Обновление статуса книги
begin
    update_book_status_proc(
        'Test Book',
        'Активна'
    );
    commit;
end;

select * from books_table;


--Обновление статуса заказа
begin
    update_order_status_proc(1, 'Отправлен');
    commit;
end;

--Проверка тиггеров
begin
    update_book_status_proc('Test Book', 'INVALID');
    commit;
end;

--Неверный статус заказа
begin
    update_order_status_proc(1, 'WRONG');
    commit;
end;

--Покупатель Natalia
--Просмотр каталога
select * from customer_catalog_view;

--Фильтрация
--По названию
select * from table(search_books_func(p_text => 'Te'));
select * from table(search_books_func(p_text => 'Test'));

--По автору 
select * from table(search_books_func(p_author => 'New author'));

--По жанру
select * from table(search_books_func(p_genre => 'Fanta'));

--По издателю
select * from table(search_books_func(p_publisher => 'Publisher'));

--По году
select * from table(search_books_func(p_year => 2024));

--Минимальная цена
select * from table(search_books_func(p_min_price => 100));

--Максимальная цена
select * from table(search_books_func(p_max_price => 500));

--Диапазон
select * from table(search_books_func(
    p_min_price => 100,
    p_max_price => 500
));

select * from table(search_books_func(
    p_text      => 'Test',
    p_author    => 'New author',
    p_genre     => 'Drama',
    p_year      => 2025,
    p_min_price => 100,
    p_max_price => 200
));

--Добавление книги в Избранное
begin
    add_to_wishlist_proc('Test');
    commit;
end;

--Удаление книги из Избранного
begin
    remove_from_wishlist_proc('Test');
    commit;
end;

--Проверить ещё много чего надо




