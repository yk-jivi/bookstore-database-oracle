--Процедуры, функции, представления, триггеры Менеджера по продажам
--Процедуры
--Добавление книги в таблицу Books
create or replace procedure add_book(
    p_title       in varchar2,
    p_author      in varchar2,
    p_genre       in varchar2,
    p_publisher   in varchar2,
    p_year        in number,
    p_price       in number,
    p_description in clob
)
as
    v_cnt number;
begin
    -- 1. Проверка на дубликат
    select count(*)
    into v_cnt
    from books
    where upper(title) = upper(p_title)
      and upper(author) = upper(p_author)
      and upper(publisher) = upper(p_publisher)
      and year = p_year;

    if v_cnt > 0 then
        dbms_output.put_line('Инфо: Книга "' || p_title || '" уже существует в каталоге.');
        return;
    end if;

    -- 2. Вставка
    insert into books(
        title,
        author,
        genre,
        publisher,
        year,
        price,
        description
    )
    values (
        p_title,
        p_author,
        p_genre,
        p_publisher,
        p_year,
        p_price,
        p_description
    );

    commit;
    dbms_output.put_line('Успех: Книга "' || p_title || '" добавлена в каталог.');

exception
    when others then
        rollback;
        dbms_output.put_line('Системная ошибка при добавлении книги: ' || sqlerrm);
end;

--Редактирование книги по названию в таблице Books (тут имеется в виду полноценное редактироание книги)
create or replace procedure update_book(
    p_book_id      in number,
    p_title        in varchar2 default null,
    p_author       in varchar2 default null,
    p_genre        in varchar2 default null,
    p_publisher    in varchar2 default null,
    p_year         in number   default null,
    p_price        in number   default null,
    p_description  in clob     default null
)
as
begin
    -- Обновление только тех полей, где передано значение.
    -- Если передан NULL (значение по умолчанию), nvl оставит старое значение из колонки.
    update books
    set title       = nvl(p_title, title),
        author      = nvl(p_author, author),
        genre       = nvl(p_genre, genre),
        publisher   = nvl(p_publisher, publisher),
        year        = nvl(p_year, year),
        price       = nvl(p_price, price),
        description = nvl(p_description, description)
    where book_id   = p_book_id;

    -- Проверка: нашлась ли книга с таким ID
    if sql%rowcount = 0 then
        dbms_output.put_line('Ошибка: Книга с ID ' || p_book_id || ' не найдена.');
    else
        commit;
        dbms_output.put_line('Успех: Данные книги ID ' || p_book_id || ' обновлены.');
    end if;

exception
    when others then
        rollback;
        dbms_output.put_line('Системная ошибка при обновлении книги: ' || sqlerrm);
end;

--Редактирование книги по названию в таблице Books (тут имеется в виду только редактирование статуса)
create or replace procedure update_book_status(
    p_book_id   in number,
    p_status    in varchar2
)
as
begin
    -- 1. Проверка допустимых значений статуса
    if p_status not in ('Нет в наличии', 'Скоро в продаже', 'В продаже') then
        dbms_output.put_line('Ошибка: Некорректный статус. Допустимые значения: "Нет в наличии", "Скоро в продаже", "В продаже".');
        return;
    end if;

    -- 2. Обновление строго по ID
    update books
    set status = p_status
    where book_id = p_book_id;

    -- 3. Анализ результата
    if sql%rowcount = 0 then
        dbms_output.put_line('Ошибка: Книга с ID ' || p_book_id || ' не найдена.');
    else
        commit;
        dbms_output.put_line('Успех: Статус книги ID ' || p_book_id || ' изменен на "' || p_status || '".');
    end if;

exception
    when others then
        rollback;
        dbms_output.put_line('Системная ошибка при обновлении статуса: ' || sqlerrm);
end;

--Изменение статуса заказа по названию в таблице Books (тут только изменение статуса)
create or replace procedure update_order_status(
    p_order_id in number,
    p_status   in varchar2
)
as
    v_current_status varchar2(30);
begin
    -- 1. Поиск заказа и получение текущего статуса
    begin
        select status
        into v_current_status
        from orders
        where order_id = p_order_id;
    exception
        when no_data_found then
            dbms_output.put_line('Ошибка: Заказ №' || p_order_id || ' не найден.');
            return;
    end;

    -- 2. Проверка на "Черновик" (защита бизнес-логики)
    if v_current_status = 'Черновик' then
        dbms_output.put_line('Ошибка: Статус "Черновик" нельзя изменить вручную через эту процедуру.');
        return;
    end if;

    -- 3. Валидация входного статуса
    if p_status not in ('Принят','Оплачен','Отправлен','Доставлен','Отменён','Подтверждён') then
        dbms_output.put_line('Ошибка: Некорректный целевой статус: ' || p_status);
        return;
    end if;

    -- 4. Логика допустимых переходов (State Machine)
    if v_current_status = 'Принят' and p_status not in ('Оплачен','Отменён','Подтверждён') then
        dbms_output.put_line('Ошибка: Из статуса "Принят" можно перейти только в "Оплачен", "Подтверждён" или "Отменён".');
        return;
    end if;

    if v_current_status = 'Оплачен' and p_status not in ('Отправлен','Отменён') then
        dbms_output.put_line('Ошибка: Оплаченный заказ можно только "Отправить" или "Отменить".');
        return;
    end if;

    if v_current_status = 'Отправлен' and p_status not in ('Доставлен','Отменён') then
        dbms_output.put_line('Ошибка: Отправленный заказ можно только "Доставить" или "Отменить".');
        return;
    end if;

    if v_current_status = 'Доставлен' then
        dbms_output.put_line('Инфо: Заказ уже доставлен (завершен). Изменение статуса невозможно.');
        return;
    end if;

    -- 5. Обновление
    update orders
    set status = p_status
    where order_id = p_order_id;

    commit;
    dbms_output.put_line('Успех: Статус заказа №' || p_order_id || ' изменен с "' || v_current_status || '" на "' || p_status || '".');

exception
    when others then
        rollback;
        dbms_output.put_line('Системная ошибка при обновлении статуса заказа: ' || sqlerrm);
end;

-- Подтверждение заказа
create or replace procedure confirm_order(
    p_order_id in number
) as
    v_bad_items      number;
    v_current_status varchar2(30);
begin
    -- 1. Получение текущего статуса и проверка существования заказа
    begin
        select status into v_current_status
        from orders
        where order_id = p_order_id;
    exception
        when no_data_found then
            dbms_output.put_line('Ошибка: Заказ №' || p_order_id || ' не найден.');
            return;
    end;

    -- 2. Проверка статуса
    if v_current_status in ('Отменён', 'Доставлен') then
        dbms_output.put_line('Ошибка: Заказ в статусе "' || v_current_status || '" нельзя подтвердить.');
        return;
    end if;

    -- 3. Проверка наличия товаров
    select count(*)
    into v_bad_items
    from orderitems oi
    join books b on b.book_id = oi.book_id
    where oi.order_id = p_order_id
      and b.status != 'В продаже';

    if v_bad_items > 0 then
        dbms_output.put_line('Ошибка: В заказе есть товары, которых нет в продаже.');
        return;
    end if;

    -- 4. Обновление статуса
    update orders
    set status = 'Подтверждён'
    where order_id = p_order_id;

    commit;
    dbms_output.put_line('Успех: Заказ №' || p_order_id || ' успешно подтверждён.');

exception
    when others then
        rollback;
        dbms_output.put_line('Системная ошибка при подтверждении: ' || sqlerrm);
end;

--Представления
--Просмотр списка заказов
create or replace view orders_view as
select 
    o.order_id,
    u.login,
    o.order_date,
    o.status
from orders o
join users u on o.user_id = u.user_id;

--Просмотр отзывов покупателей о книгах
create or replace view reviews_view as
select 
    r.review_id,
    u.login,
    b.title,
    r.rating,
    r.comment_text,
    r.review_date
from reviews r
join users u on r.user_id = u.user_id
join books b on r.book_id = b.book_id;

--Триггеры
--Проверка статуса заказа
create or replace trigger trg_check_order_status
before update of status on orders
for each row
begin
    if :new.status not in ('Принят','Оплачен','Отправлен','Доставлен','Отменён','Подтверждён','Черновик') then
        raise_application_error(-20121, 'Некорректный статус заказа');
    end if;
end;