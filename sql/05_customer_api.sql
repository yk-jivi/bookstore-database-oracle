--Процедуры, функции, представления, триггеры Покупателя

--Процедуры
--Добавление в избранное
create or replace procedure add_to_wishlist(
    p_book_id in number,
    p_user_id in number  -- Используем ID вместо логина
)
as
    v_cnt     number;
begin
    -- 1. Проверка: нет ли уже этой книги в списке желаемого
    select count(*)
    into v_cnt
    from wishlist
    where user_id = p_user_id and book_id = p_book_id;

    if v_cnt > 0 then
        dbms_output.put_line('Инфо: Книга (ID ' || p_book_id || ') уже есть в вашем списке желаемого.');
        return;
    end if;

    -- 2. Вставка
    insert into wishlist(user_id, book_id)
    values (p_user_id, p_book_id);
    
    commit;
    dbms_output.put_line('Успех: Книга добавлена в список желаемого.');

exception
    when others then
        rollback;
        dbms_output.put_line('Системная ошибка: ' || sqlerrm);
end;

--Удаление из избранного
create or replace procedure remove_from_wishlist(
    p_book_id in number,
    p_user_id in number
)
as
begin
    -- 1. Попытка удалить запись напрямую по ключам
    delete from wishlist
    where user_id = p_user_id
      and book_id = p_book_id;

    -- 2. Проверка, было ли что-то удалено
    if sql%rowcount = 0 then
        dbms_output.put_line('Инфо: Данная книга (ID ' || p_book_id || ') не найдена в вашем списке желаемого.');
    else
        commit;
        dbms_output.put_line('Успех: Книга удалена из списка желаемого.');
    end if;

exception
    when others then
        rollback;
        dbms_output.put_line('Системная ошибка при удалении: ' || sqlerrm);
end;

--Добавление книги в корзину
create or replace procedure add_to_cart(
    p_book_id in number,
    p_user_id in number,
    p_qty     in number
)
as
    v_order_id  number;
    v_available number;
    v_in_cart   number;
begin
    -- 1. Подсчёт остатка на складе (только доставленные партии)
    select nvl(sum(quantity), 0) into v_available 
    from bookorders 
    where book_id = p_book_id 
      and status = 'Доставлен'; 

    -- 2. Подсчёт, сколько этого товара уже лежит в текущей корзине пользователя
    select nvl(sum(oi.quantity), 0) into v_in_cart
    from orderitems oi 
    join orders o on o.order_id = oi.order_id
    where o.user_id = p_user_id 
      and o.status = 'Черновик' 
      and oi.book_id = p_book_id;

    -- 3. Проверка доступности
    if v_available < (p_qty + v_in_cart) then
        dbms_output.put_line('Ошибка: На складе недостаточно книг. Доступно: ' || v_available || 
                             ' (в корзине уже: ' || v_in_cart || ')');
        return;
    end if;

    -- 4. Поиск активной корзины или создание новой
    begin
        select order_id into v_order_id 
        from (
            select order_id from orders 
            where user_id = p_user_id and status = 'Черновик' 
            order by order_date desc
        ) where rownum = 1;
    exception 
        when no_data_found then
            insert into orders(user_id, status, order_date) 
            values (p_user_id, 'Черновик', sysdate) 
            returning order_id into v_order_id;
    end;

    -- 5. MERGE: Обновление количества или добавление новой строки в корзину
    merge into orderitems target
    using (select v_order_id as oid, p_book_id as bid, p_qty as qty from dual) source
    on (target.order_id = source.oid and target.book_id = source.bid)
    when matched then
        update set target.quantity = target.quantity + source.qty
    when not matched then
        insert (order_id, book_id, quantity) 
        values (source.oid, source.bid, source.qty);
    
    commit;
    dbms_output.put_line('Успех: Товар (ID ' || p_book_id || ') в количестве ' || p_qty || ' шт. добавлен в корзину.');

exception
    when others then
        rollback;
        dbms_output.put_line('Системная ошибка: ' || sqlerrm);
end;

-- Удаление книги из корзины
create or replace procedure remove_from_cart(
    p_book_id in number,
    p_user_id in number,
    p_qty     in number
)
as
    v_order_id  number;
    v_qty_db    number;
    v_remaining number;
begin
    -- 1. Валидация
    if p_qty <= 0 then
        dbms_output.put_line('Ошибка: Количество для удаления должно быть больше 0.');
        return;
    end if;

    -- 2. Поиск активной корзины (Черновик) напрямую по user_id
    begin
        select order_id into v_order_id 
        from (
            select order_id from orders 
            where user_id = p_user_id and status = 'Черновик' 
            order by order_id desc
        ) where rownum = 1;
    exception 
        when no_data_found then
            dbms_output.put_line('Инфо: У пользователя ID ' || p_user_id || ' нет активной корзины.');
            return;
    end;

    -- 3. Проверка наличия книги в корзине по book_id
    begin
        select quantity into v_qty_db 
        from orderitems 
        where order_id = v_order_id and book_id = p_book_id;
    exception 
        when no_data_found then
            dbms_output.put_line('Ошибка: Товар ID ' || p_book_id || ' не найден в вашей корзине.');
            return;
    end;

    -- 4. Проверка количества
    if p_qty > v_qty_db then
        dbms_output.put_line('Ошибка: Вы пытаетесь удалить ' || p_qty || ' шт., но в корзине всего ' || v_qty_db || '.');
        return;
    end if;

    -- 5. Удаление или уменьшение
    if p_qty = v_qty_db then
        delete from orderitems 
        where order_id = v_order_id and book_id = p_book_id;
        dbms_output.put_line('Успех: Товар полностью удален из корзины.');
    else
        update orderitems 
        set quantity = quantity - p_qty 
        where order_id = v_order_id and book_id = p_book_id;
        dbms_output.put_line('Успех: Количество товара в корзине уменьшено.');
    end if;

    -- 6. Если корзина стала пустой, то будет удаление «черновика» заказа
    select count(*) into v_remaining 
    from orderitems 
    where order_id = v_order_id;

    if v_remaining = 0 then
        delete from orders where order_id = v_order_id;
        dbms_output.put_line('Инфо: Корзина опустела и удалена.');
    end if;
    
    commit;

exception
    when others then
        rollback;
        dbms_output.put_line('Системная ошибка: ' || sqlerrm);
end;

--Оформление заказа
create or replace procedure checkout_order(
    p_user_id in number
)
as
    v_order_id number;
begin
    -- 1. Поиск самого "свежего" активного "Черновика" для этого пользователя
    begin
        select order_id
        into v_order_id
        from (
            select order_id
            from orders
            where user_id = p_user_id
              and status = 'Черновик'
            order by order_id desc
        )
        where rownum = 1;
    exception
        when no_data_found then
            dbms_output.put_line('Ошибка: Не удалось оформить заказ. Корзина пуста или не существует.');
            return;
    end;

    -- 2. Перевод заказа в статус "Принят" и фиксация времени покупки
    update orders
    set status = 'Принят',
        order_date = sysdate
    where order_id = v_order_id;
    
    commit;
    dbms_output.put_line('Успех: Заказ №' || v_order_id || ' оформлен и передан в обработку.');

exception
    when others then
        rollback;
        dbms_output.put_line('Системная ошибка при оформлении заказа: ' || sqlerrm);
end;

--Добавление отзыва
create or replace procedure add_review(
    p_book_id in number,
    p_user_id in number,
    p_rating  in number,
    p_comment in varchar2
)
as
begin
    -- 1. Валидация рейтинга (от 1 до 5)
    if p_rating not between 1 and 5 then
        dbms_output.put_line('Ошибка: Рейтинг должен быть от 1 до 5.');
        return;
    end if;

    -- 2. Вставка отзыва напрямую по ID
    insert into reviews (
        user_id, 
        book_id, 
        rating, 
        comment_text, 
        review_date
    )
    values (
        p_user_id, 
        p_book_id, 
        p_rating, 
        p_comment, 
        sysdate
    );
    
    commit;
    dbms_output.put_line('Успех: Ваш отзыв (книга ID ' || p_book_id || ') успешно опубликован.');

exception
    when others then
        rollback;
        dbms_output.put_line('Системная ошибка при добавлении отзыва: ' || sqlerrm);
end;

-- Поиск книги
create or replace procedure find_books(
    p_book_id    number   default null,
    p_title      varchar2 default null,
    p_author     varchar2 default null,
    p_genre      varchar2 default null,
    p_publisher  varchar2 default null,
    p_year       number   default null,
    p_min_price  number   default null,
    p_max_price  number   default null
) as
    v_found boolean := false;
begin
    dbms_output.put_line(rpad('-', 100, '-'));
    dbms_output.put_line(
        rpad('ID', 5) || 
        rpad('НАЗВАНИЕ', 35) || 
        rpad('АВТОР', 20) || 
        rpad('ГОД', 6) || 
        'ЦЕНА'
    );
    dbms_output.put_line(rpad('-', 100, '-'));

    for r in (
        select book_id, title, author, year, price
        from books
        where status = 'В продаже'
          and (p_book_id is null or book_id = p_book_id)
          and (p_title is null or upper(title) like '%' || upper(p_title) || '%')
          and (p_author is null or upper(author) like '%' || upper(p_author) || '%')
          and (p_genre is null or upper(genre) like '%' || upper(p_genre) || '%')
          and (p_publisher is null or upper(publisher) like '%' || upper(p_publisher) || '%')
          and (p_year is null or year = p_year)
          and (p_min_price is null or price >= p_min_price)
          and (p_max_price is null or price <= p_max_price)
    ) loop
        v_found := true;
        dbms_output.put_line(
            rpad(r.book_id, 5) || 
            rpad(substr(r.title, 1, 33), 35) || 
            rpad(substr(r.author, 1, 18), 20) || 
            rpad(r.year, 6) || 
            r.price
        );
    end loop;

    if not v_found then
        dbms_output.put_line('Книги по заданным фильтрам не найдены.');
    end if;
    
    dbms_output.put_line(rpad('-', 100, '-'));
end;

-- Мои заказы
create or replace procedure customer_orders(
    p_user_id in number
)
as
    v_cursor sys_refcursor;
begin
    -- Открытие курсора с обычным селектом
    open v_cursor for
        select 
            order_id, 
            order_date, 
            status
        from orders
        where user_id = p_user_id
        order by order_date desc;

    -- "Выброс" результата в среду разработки
    dbms_sql.return_result(v_cursor);
end;

-- Мои отзывы
create or replace procedure my_reviews(
    p_user_id in number
)
as
    v_cursor sys_refcursor;
begin
    -- Открытие курсора для выдачи таблицы отзывов
    open v_cursor for
        select 
            r.review_id,
            b.title as book_title,
            r.rating,
            r.comment_text,
            r.review_date
        from reviews r
        join books b on r.book_id = b.book_id
        where r.user_id = p_user_id
        order by r.review_date desc;

    -- Выброс результата
    dbms_sql.return_result(v_cursor);
end;

-- Представления
-- Просмотр каталога книг
create or replace view books_with_status as
select book_id, title, author, price, status
from books;

--Триггеры
--Защита от добавления дублей в Избранное
create or replace trigger trg_wishlist_unique
before insert on wishlist
for each row
declare
    v_count number;
begin
    select count(*) into v_count
    from wishlist
    where user_id = :new.user_id
      and book_id = :new.book_id;

    if v_count > 0 then
        raise_application_error(-20042, 'Уже в избранном');
    end if;
end;

--Защита рейтинга
create or replace trigger trg_review_rating
before insert or update on reviews
for each row
begin
    if :new.rating not between 1 and 5 then
        raise_application_error(-20040, 'Рейтинг 1-5');
    end if;
end;

--Нельзя добавить отзыв без покупки
create or replace trigger trg_review_only_bought
before insert on reviews
for each row
declare
    v_count number;
begin
    select count(*)
    into v_count
    from orders o
    join orderitems oi on o.order_id = oi.order_id
    where o.user_id = :new.user_id
      and oi.book_id = :new.book_id
      and o.status = 'Доставлен';

    if v_count = 0 then
        raise_application_error(-20050, 'Отзыв можно оставить только после покупки');
    end if;
end;

-- Защита от дублей заказов
create or replace trigger trg_one_draft_per_user
before insert on orders
for each row
declare
    v_count number;
begin
    if :new.status = 'Черновик' then
        select count(*)
        into v_count
        from orders
        where user_id = :new.user_id
          and status = 'Черновик';

        if v_count > 0 then
            raise_application_error(-20095, 'У пользователя уже есть активная корзина');
        end if;
    end if;
end;

-- Триггер списания и возврата
create or replace trigger trg_orders_stock_control
after update of status on orders
for each row
declare
    v_need number;
    v_last_order_id number;
begin
    -- Списание при отправке
    if :new.status = 'Отправлен' and :old.status != 'Отправлен' then
        for r in (select book_id, quantity from orderitems where order_id = :new.order_id) loop
            v_need := r.quantity;
            for s in (
                select book_order_id, quantity 
                from bookorders 
                where book_id = r.book_id and quantity > 0 
                order by book_order_id -- FIFO: списание с самых старых поставок
            ) loop
                exit when v_need = 0;
                if s.quantity >= v_need then
                    update bookorders set quantity = quantity - v_need where book_order_id = s.book_order_id;
                    v_need := 0;
                else
                    v_need := v_need - s.quantity;
                    update bookorders set quantity = 0 where book_order_id = s.book_order_id;
                end if;
            end loop;

            if v_need > 0 then
                raise_application_error(-20099, 'Критическая ошибка: товара book_id='||r.book_id||' не хватило при списании!');
            end if;
        end loop;
    end if;

    -- Возврат только в одну запись (последнюю активную)
    if :new.status = 'Отменён' and :old.status != 'Отменён' and :old.status = 'Отправлен' then
        for r in (select book_id, quantity from orderitems where order_id = :new.order_id) loop
            begin
                select book_order_id into v_last_order_id
                from (select book_order_id from bookorders where book_id = r.book_id order by order_date desc)
                where rownum = 1;

                update bookorders set quantity = quantity + r.quantity where book_order_id = v_last_order_id;
            exception when no_data_found then
                -- Если поставок вообще не было
                insert into bookorders(book_id, quantity, status) values (r.book_id, r.quantity, 'Возврат');
            end;
        end loop;
    end if;
end;