alter session set container=FREEPDB1;

-- Заполнение 100 000 строк случайными данными
insert into books (title, author, genre, publisher, year, price, description, status)
select 
    'Книга №' || level,
    'Автор ' || trunc(dbms_random.value(1, 5000)),
    'Жанр ' || trunc(dbms_random.value(1, 20)),
    'Издательство ' || trunc(dbms_random.value(1, 50)),
    trunc(dbms_random.value(1950, 2024)),
    round(dbms_random.value(500, 5000), 2),
    'Описание для книги номер ' || level,
    'В наличии'
from dual
connect by level <= 100000;
commit;

-- Запрос по автору и стоимости (вызовет Full Table Scan)
-- Перед созданием индекса
select * from books 
where author = 'Автор 500' 
  and price > 1000;

explain plan for
select * from books where author = 'Автор 500' and price > 1000

select * from table(dbms_xplan.display);

-- Создание индекса для оптимизации поиска по автору
create index idx_books_author_perf on books(author);

select * from books 
where author = 'Автор 500' 
  and price > 1000;

explain plan for
select * from books where author = 'Автор 500' and price > 1000

select * from table(dbms_xplan.display);