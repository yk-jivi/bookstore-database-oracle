--Процедуры, функции, представления, триггеры Старшего менеджера
--Процедуры
--Заказ книг у поставщика
create or replace procedure order_books_from_supplier(
    p_book_id   in number,
    p_quantity  in number
) as
begin
    -- 1. Вставка данных
    insert into bookorders (book_id, quantity, status, order_date)
    values (p_book_id, p_quantity, 'Заказан', sysdate);
    
    commit;
    dbms_output.put_line('Успех: Заказ на книгу ID ' || p_book_id || ' в количестве ' || p_quantity || ' шт. оформлен.');

exception
    when others then
        rollback;
        -- Проверка на нарушение целостности (если передан несуществующий ID книги)
        if sqlcode = -2291 then
            dbms_output.put_line('Ошибка: Книги с ID ' || p_book_id || ' не существует в каталоге.');
        else
            dbms_output.put_line('Системная ошибка: ' || sqlerrm);
        end if;
end;

-- Назначение менеджера по продажам
create or replace procedure assign_sales_manager(
    p_target_id in number,  -- ID того, кого назначаем
    p_admin_id  in number   -- ID админа, который назначает
) as
    v_target_role number;
    v_admin_role  number;
begin
    -- 1. Проверка роли обоих пользователей одним запросом
    -- Проверяем админа
    select user_role into v_admin_role from users where user_id = p_admin_id;
    
    if v_admin_role != 1 then
        dbms_output.put_line('Ошибка: Пользователь ID ' || p_admin_id || ' не обладает правами администратора.');
        return;
    end if;

    -- Проверка кандидата
    select user_role into v_target_role from users where user_id = p_target_id;

    if v_target_role = 2 then
        dbms_output.put_line('Инфо: Пользователь ID ' || p_target_id || ' уже является менеджером.');
        return;
    end if;

    -- 2. Назначение
    -- Обновление роли в основной таблице
    update users set user_role = 2 where user_id = p_target_id;

    -- Добавление в таблицу иерархии
    insert into managers (manager_id, supervisor_id) 
    values (p_target_id, p_admin_id);

    commit;
    dbms_output.put_line('Успех: Пользователь ID ' || p_target_id || ' назначен менеджером (куратор ID ' || p_admin_id || ').');

exception
    when no_data_found then
        dbms_output.put_line('Ошибка: Указанный ID пользователя не найден.');
    when others then
        rollback;
        dbms_output.put_line('Системная ошибка: ' || sqlerrm);
end;

-- Снятие с должности
create or replace procedure remove_sales_manager(
    p_target_id in number, -- ID того, кого снимаем
    p_admin_id  in number  -- ID админа
) as
    v_admin_role  number;
    v_target_role number;
begin
    -- 1. Базовая проверка на логику (самоисключение)
    if p_target_id = p_admin_id then
        dbms_output.put_line('Ошибка: Вы не можете снять полномочия с самого себя.');
        return;
    end if;
    
    -- 2. Проверка роли админа
    select user_role into v_admin_role 
    from users 
    where user_id = p_admin_id;

    if v_admin_role != 1 then
        dbms_output.put_line('Ошибка: Снимать с должности может только Старший менеджер (ID 1).');
        return;
    end if;

    -- 3. Проверка текущей роли цели
    select user_role into v_target_role
    from users 
    where user_id = p_target_id;

    if v_target_role != 2 then
        dbms_output.put_line('Инфо: Пользователь ID ' || p_target_id || ' не является менеджером.');
        return;
    end if;

    -- 4. Изменения
    -- Возврат роли обычного клиента (3)
    update users 
    set user_role = 3 
    where user_id = p_target_id;

    -- Удаление из таблицы иерархии
    delete from managers 
    where manager_id = p_target_id;

    commit;
    dbms_output.put_line('Успех: Пользователь ID ' || p_target_id || ' снят с должности администратором ID ' || p_admin_id);

exception
    when no_data_found then
        dbms_output.put_line('Ошибка: Один из указанных ID не найден в системе.');
    when others then
        rollback;
        dbms_output.put_line('Системный сбой: ' || sqlerrm);
end;

-- Изменение статуса заказа книг
create or replace procedure update_bookorder_status(
    p_book_order_id in number,
    p_status        in varchar2
)
as
begin
    -- 1. Валидация входного статуса
    if p_status not in ('Заказан', 'Едет', 'Доставлен') then
        dbms_output.put_line('Ошибка: Некорректный статус. Используйте: Заказан, Едет или Доставлен.');
        return;
    end if;

    -- 2. Попытка обновления
    update bookorders
    set status = p_status
    where book_order_id = p_book_order_id;

    -- 3. Проверка: обновилось ли что-то?
    if sql%rowcount = 0 then
        dbms_output.put_line('Ошибка: Заказ с ID ' || p_book_order_id || ' не найден.');
    else
        commit;
        dbms_output.put_line('Успех: Статус заказа №' || p_book_order_id || ' изменен на "' || p_status || '".');
    end if;

exception
    when others then
        rollback;
        dbms_output.put_line('Системная ошибка при обновлении статуса: ' || sqlerrm);
end;

--Анализ продаж
create or replace procedure print_sales_analysis
as
begin
    dbms_output.put_line('Топ 3 продаж: ');
    for rec in (
        select b.title, sum(oi.quantity) as total_sold
        from orderitems oi
        join books b on oi.book_id = b.book_id
        group by b.title
        order by 2 desc fetch first 3 rows only
    ) loop
        dbms_output.put_line(rec.title || ': ' || rec.total_sold);
    end loop;

    dbms_output.put_line(chr(10) || 'Топ 3 худших продаж: ');
    for rec in (
        select b.title, coalesce(sum(oi.quantity), 0) as total_sold
        from books b
        left join orderitems oi on b.book_id = oi.book_id
        group by b.title
        order by 2 asc fetch first 3 rows only
    ) loop
        dbms_output.put_line(rec.title || ': ' || rec.total_sold);
    end loop;
end;

--Представления
--Заказы у поставщиков
create or replace view book_orders as
select 
    bo.book_order_id,
    b.title,
    bo.quantity,
    bo.order_date,
    bo.status
from bookorders bo
join books b on bo.book_id = b.book_id;

--Список менеджеров
create or replace view sales_managers as
select 
    u.user_id,
    u.login,
    u.email
from users u
where u.user_role = 2;

--Продажи
create or replace view sales_summary as
select 
    b.book_id,
    b.title,
    sum(oi.quantity) as total_sold,
    sum(oi.quantity * b.price) as total_income
from orderitems oi
join orders o on oi.order_id = o.order_id
join books b on oi.book_id = b.book_id
group by b.book_id, b.title;

-- Триггеры
-- Проверка количества при заказе книг
create or replace trigger trg_check_bookorder_quantity
before insert on bookorders
for each row
begin
    if :new.quantity <= 0 then
        raise_application_error(-20010, 'Количество должно быть больше 0');
    end if;
end;

-- В таблицу Managers только менеджеры
create or replace trigger trg_check_manager_role
before insert on managers
for each row
declare
    v_role number;
begin
    select user_role into v_role
    from users
    where user_id = :new.manager_id;

    if v_role != 2 then
        raise_application_error(-20201, 'Ошибка: Данный пользователь не имеет роли "Менеджер" в таблице Users.');
    end if;
end;

--Запрет дубликатов
create or replace trigger trg_no_duplicate_manager
before insert on managers
for each row
declare
    v_count number;
begin
    -- Проверка, нет ли уже такого ID в таблице менеджеров
    select count(*)
    into v_count
    from managers
    where manager_id = :new.manager_id;

    if v_count > 0 then
        raise_application_error(-20202, 'Ошибка: Этот пользователь уже назначен менеджером.');
    end if;
end;

