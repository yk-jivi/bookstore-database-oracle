begin
    for r in (select table_name from user_tables where table_name in 
        ('REVIEWS','WISHLIST','ORDERITEMS','ORDERS','BOOKORDERS','MANAGERS','USERS','BOOKS','ROLES'))
    loop
        execute immediate 'drop table '||r.table_name||' cascade constraints purge';
    end loop;
end;

--Создание таблиц
create table roles (
    role_id number generated always as identity primary key,
    role_name varchar2(50) not null
);

create table books (
    book_id number generated always as identity primary key,
    title varchar2(200) not null,
    author varchar2(150),
    genre varchar2(100),
    publisher varchar2(150),
    year number(4),
    price number(10,2),
    description clob,
    status varchar2(30) default 'Нет в наличии' not null
);

create table users (
    user_id number generated always as identity primary key,
    user_role number not null references roles(role_id),
    login varchar2(50) unique not null,
    email varchar2(100) unique not null,
    phone varchar2(20),
    user_password varchar2(100) not null,
    registration_date date default sysdate
);

create table managers (
    manager_id number primary key,
    supervisor_id number,
    constraint fk_manager_user
        foreign key (manager_id)
        references users(user_id),
    constraint fk_supervisor_user
        foreign key (supervisor_id)
        references users(user_id)
);

create table orders (
    order_id number generated always as identity primary key,
    user_id number not null references users(user_id),
    order_date date default sysdate,
    status varchar2(50) default 'Принят'
);

create table orderitems (
    order_item_id number generated always as identity primary key,
    order_id number not null references orders(order_id),
    book_id number not null references books(book_id),
    quantity number(5) default 1
);

create table bookorders (
    book_order_id number generated always as identity primary key,
    book_id number not null references books(book_id),
    quantity number(5) not null,
    order_date date default sysdate,
    status varchar2(50) default 'Заказан'
);

create table wishlist (
    wishlist_id number generated always as identity primary key,
    user_id number not null references users(user_id),
    book_id number not null references books(book_id)
);

create table reviews (
    review_id number generated always as identity primary key,
    user_id number not null references users(user_id),
    book_id number not null references books(book_id),
    rating number(1) check (rating between 1 and 5),
    comment_text clob,
    review_date date default sysdate
);