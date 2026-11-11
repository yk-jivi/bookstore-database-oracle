-- Выполняется от SYS
alter session set container=FREEPDB1;

-- Создание директории
create or replace directory DATA_DIR as '/home/oracle/data';

grant read, write on directory DATA_DIR to Programmer;

select directory_name, directory_path
from all_directories;

select * from dba_tab_privs where table_name = 'DATA_DIR';

-- Далее от программиста 
-- Процедура экспорта данных таблицы Books в JSON
create or replace procedure export_books_json(
    p_dir  in varchar2, -- Входной параметр: имя объекта DIRECTORY в Oracle (путь к папке).
    p_file in varchar2 -- Входной параметр: имя создаваемого файла (например, 'books.json').
)
as
    file_handle utl_file.file_type; -- "Указатель" на файл. Через эту переменную программа понимает, в какой именно файл писать данные.
    v_json      clob; -- Переменная для хранения всего JSON-текста (может вмещать Гб данных).
    v_offset    number := 1; -- Счетчик-смещение. Указывает, с какого символа мы сейчас читаем CLOB (начинаем с 1-го).
    v_chunk     varchar2(32767); -- Временный "буфер". Сюда мы отрезаем кусок из CLOB, чтобы передать его в файл.
    v_chunk_size number := 32767; -- Размер этого "куска" в символах (максимум для VARCHAR2 в PL/SQL).
begin
    -- Формирование JSON массива из всех книг
    select json_arrayagg(
               json_object(
                   'title'     value title,
                   'author'    value author,
                   'genre'     value genre,
                   'publisher' value publisher,
                   'year'      value year,
                   'price'     value price,
                   'status'    value status
               )
           )
    into v_json
    from books;

    -- Открытие файла для записи
    file_handle := utl_file.fopen(p_dir, p_file, 'w', 32767);

    -- Потоковая запись CLOB в файл
    while v_offset <= dbms_lob.getlength(v_json) loop
        v_chunk := dbms_lob.substr(v_json, v_chunk_size, v_offset);
        utl_file.put(file_handle, v_chunk);
        v_offset := v_offset + v_chunk_size;
    end loop; 

    utl_file.fclose(file_handle);
exception
    when others then
        if utl_file.is_open(file_handle) then
            utl_file.fclose(file_handle);
        end if;
        raise;
end;

-- Процедура импорта таблицы Books в JSON
create or replace procedure import_books_json(
    p_dir  in varchar2,
    p_file in varchar2
)
as
    v_bfile        bfile; -- Ссылка на внешний файл, который лежит на диске сервера (вне базы данных).
    v_clob         clob; -- Временное хранилище в памяти базы, куда мы загрузим текст из файла.
    v_dest_offset  number := 1; -- Указатель позиции в целевом CLOB (куда записывать данные).
    v_src_offset   number := 1; -- Указатель позиции в исходном файле (откуда начинать чтение).
    v_lang_context number := dbms_lob.default_lang_ctx; -- Техническая переменная для контроля кодировки (языка).
    v_warning      number; -- Сюда Oracle запишет код предупреждения, если при чтении возникнут мелкие ошибки.
begin
    -- Подготовка временного CLOB
    v_bfile := bfilename(p_dir, p_file);
    dbms_lob.createtemporary(v_clob, true);
    
    -- Загрузка файла в CLOB с явным указанием UTF-8
    dbms_lob.fileopen(v_bfile, dbms_lob.file_readonly);
    dbms_lob.loadclobfromfile(
        dest_lob      => v_clob,
        src_bfile     => v_bfile,
        amount        => dbms_lob.getlength(v_bfile),
        dest_offset   => v_dest_offset,
        src_offset    => v_src_offset,
        bfile_csid    => nls_charset_id('AL32UTF8'),
        lang_context  => v_lang_context,
        warning       => v_warning
    );
    dbms_lob.fileclose(v_bfile);

    -- Слияние данных (MERGE)
    merge into books b
    using (
        select *
        from json_table(
            v_clob,
            '$[*]'
            columns (
                title     varchar2(255) path '$.title',
                author    varchar2(255) path '$.author',
                genre     varchar2(100) path '$.genre',
                publisher varchar2(100) path '$.publisher',
                year      number        path '$.year',
                price     number        path '$.price',
                status    varchar2(50)  path '$.status'
            )
        )
    ) src
    on (
        upper(b.title) = upper(src.title)
        and upper(b.author) = upper(src.author)
        and upper(b.publisher) = upper(src.publisher)
    )
    when matched then
        update set
            b.genre  = src.genre,
            b.year   = src.year,
            b.price  = src.price,
            b.status = src.status
    when not matched then
        insert (title, author, genre, publisher, year, price, status)
        values (src.title, src.author, src.genre, src.publisher, src.year, src.price, src.status);

    dbms_lob.freetemporary(v_clob);
    commit;
end;

-- Процедура экспорта данных таблицы Users в JSON
create or replace procedure export_users_json(
    p_dir  in varchar2,
    p_file in varchar2
)
as
    file_handle utl_file.file_type;
    v_json      clob;
    v_offset    number := 1;
    v_chunk     varchar2(32767);
    v_chunk_size number := 32767;
begin
    -- Формирование JSON
    select json_arrayagg(
               json_object(
                   'login'         value login,
                   'email'         value email,
                   'user_password' value user_password,
                   'user_role'     value user_role,
                   'phone'         value phone,
                   'reg_date'      value to_char(registration_date, 'YYYY-MM-DD')
               )
               
           )
    into v_json
    from users;

    file_handle := utl_file.fopen(p_dir, p_file, 'w', 32767);

    while v_offset <= dbms_lob.getlength(v_json) loop
        v_chunk := dbms_lob.substr(v_json, v_chunk_size, v_offset);
        utl_file.put(file_handle, v_chunk);
        v_offset := v_offset + v_chunk_size;
    end loop;

    utl_file.fclose(file_handle);
exception
    when others then
        if utl_file.is_open(file_handle) then
            utl_file.fclose(file_handle);
        end if;
        raise;
end;

-- Процедура импорта данных таблицы Users в JSON
create or replace procedure import_users_json(
    p_dir  in varchar2,
    p_file in varchar2
)
as
    v_bfile        bfile;
    v_clob         clob;
    v_dest_offset  number := 1;
    v_src_offset   number := 1;
    v_lang_context number := dbms_lob.default_lang_ctx;
    v_warning      number;
begin
    v_bfile := bfilename(p_dir, p_file);
    dbms_lob.createtemporary(v_clob, true);
    
    dbms_lob.fileopen(v_bfile, dbms_lob.file_readonly);
    dbms_lob.loadclobfromfile(
        dest_lob    => v_clob,
        src_bfile   => v_bfile,
        amount      => dbms_lob.getlength(v_bfile),
        dest_offset => v_dest_offset,
        src_offset  => v_src_offset,
        bfile_csid  => nls_charset_id('AL32UTF8'),
        lang_context => v_lang_context,
        warning     => v_warning
    );
    dbms_lob.fileclose(v_bfile);

    merge into users u
    using (
        select *
        from json_table(
            v_clob,
            '$[*]'
            columns (
                login         varchar2(50)  path '$.login',
                email         varchar2(100) path '$.email',
                user_password varchar2(100) path '$.user_password',
                user_role     number        path '$.user_role',
                phone         varchar2(20)  path '$.phone'
            )
        )
    ) src
    on (upper(u.login) = upper(src.login))
    when matched then
        update set
            u.email         = src.email,
            u.user_password  = src.user_password,
            u.user_role     = src.user_role,
            u.phone         = src.phone
    when not matched then
        insert (login, email, user_password, user_role, phone)
        values (src.login, src.email, src.user_password, src.user_role, src.phone);

    dbms_lob.freetemporary(v_clob);
    commit;
end;


-- Вызов экпорта Books
begin
    export_books_json('DATA_DIR', 'books.json');
    commit;
end;

delete from books where title = 'Test Book';

select count(*) from books;

-- Вызов импорта Books
begin
    import_books_json('DATA_DIR', 'books.json');
    commit;
end;

select count(*) from books;

-- Вызов экспорта Users
exec export_users_json('DATA_DIR', 'users_export2.json');

-- Вызов импорта Users
exec import_users_json('DATA_DIR', 'users_export2.json');

























create or replace procedure export_books_json(
    p_dir  in varchar2,
    p_file in varchar2
)
as
    file_handle  utl_file.file_type;
    v_first      boolean := true; -- Флаг для расстановки запятых
begin
    -- 1. Открываем файл
    file_handle := utl_file.fopen(p_dir, p_file, 'w', 32767);

    -- 2. Записываем начало массива
    utl_file.put(file_handle, '[');

    -- 3. Читаем таблицу курсором построчно
    for rec in (select title, author, genre, publisher, year, price, status from books) loop
        
        -- Если это не первая строка, добавляем запятую перед следующим объектом
        if not v_first then
            utl_file.put(file_handle, ',');
        end if;

        -- Формируем JSON только для ОДНОЙ строки и сразу пишем в файл
        utl_file.put(file_handle, 
            json_object(
                'title'     value rec.title,
                'author'    value rec.author,
                'genre'     value rec.genre,
                'publisher' value rec.publisher,
                'year'      value rec.year,
                'price'     value rec.price,
                'status'    value rec.status
            )
        );

        v_first := false;
        
        -- Сбрасываем буфер каждые 1000 строк (опционально, для стабильности)
        -- utl_file.fflush(file_handle); 
    end loop;

    -- 4. Записываем конец массива
    utl_file.put_line(file_handle, ']');

    -- 5. Закрываем файл
    utl_file.fclose(file_handle);

exception
    when others then
        if utl_file.is_open(file_handle) then
            utl_file.fclose(file_handle);
        end if;
        raise;
end;
/

