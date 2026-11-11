-- Вставка ролей в таблицу
insert into roles(role_name) values ('Senior_manager');
insert into roles(role_name) values ('Sales_manager');
insert into roles(role_name) values ('Customer');

select * from roles;

-- Создание ролей
alter session set container=FREEPDB1

create role senior_manager;
create role sales_manager;
create role customer;
create role guest;

grant create session to senior_manager;
grant create session to sales_manager;
grant create session to customer;
grant create session to guest;

-- Процедура регистрации
create or replace procedure registration(
    p_login      in varchar2,
    p_email      in varchar2,
    p_password   in varchar2,
    p_role_name  in varchar2,
    p_phone      in varchar2 default null
)
as
    v_role_id number;
    v_count   number;
begin
    -- 1. Поиск ID роли
    select role_id into v_role_id 
    from roles
    where upper(role_name) = upper(p_role_name);

    -- 2. Проверка дубликатов логина
    select count(*) into v_count 
    from users 
    where upper(login) = upper(p_login);
    
    if v_count > 0 then
        raise_application_error(-20001, 'Ошибка: Логин "' || p_login || '" уже занят.');
    end if;

    -- 3. Добавление в таблицу (регистрация)
    insert into users(user_role, login, email, phone, user_password, registration_date)
    values(v_role_id, upper(p_login), p_email, p_phone, p_password, sysdate);
    
    commit;
    dbms_output.put_line('Пользователь ' || p_login || ' успешно зарегистрирован!');

exception
    when no_data_found then
        raise_application_error(-20002, 'Ошибка: Роль "' || p_role_name || '" не существует в справочнике Roles.');
    when others then
        rollback;
        raise_application_error(-20999, 'При регистрации произошла ошибка: ' || SQLERRM);
end;

-- Создание пользователей
-- Старший менеджер
create user senior_manager_user identified by password123
grant senior_manager to senior_manager_user

-- Менеджер по продажам
create user sales_manager_user identified by password123
grant sales_manager to sales_manager_user

-- Покупатель
create user customer_user identified by password123
grant customer to customer_user

-- Гость
create user guest_user identified by password123
grant guest to guest_user

