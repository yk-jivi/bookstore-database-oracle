--Создание пользователя программиста для работы в БД--
alter session set container=FREEPDB1
show con_name;

--Создание нового табличного пространства для программиста
create tablespace prog_ts
datafile '/opt/oracle/oradata/FREE/prog_ts01.dbf' 
size 50M 
autoextend on next 10M 
maxsize 500M
extent management local
segment space management auto;

create temporary tablespace prog_temp_ts
tempfile '/opt/oracle/oradata/FREE/prog_temp01.dbf' 
size 20M 
autoextend on next 10M 
maxsize 100M
extent management local;

create user programmer
identified by programmer
default tablespace prog_ts
temporary tablespace prog_temp_ts;

alter user programmer quota unlimited on prog_ts;

--Выдача всех прав для работы в БД
grant create session to programmer;       -- подключение к базе
grant create table to programmer;         -- создание таблиц
grant create sequence to programmer;      -- создание последовательностей
grant create view to programmer;          -- создание представлений
grant create procedure to programmer;     -- создание процедур и функций
grant create trigger to programmer;       -- создание триггеров
grant create type to programmer;          -- создание пользовательских типов данных
grant grant any role to programmer;       -- возможность выдавать гранты
grant create public synonym to programmer;-- для создания публичных синонимов
grant create synonym to programmer;
grant drop public synonym to programmer;
grant create user to programmer;
grant alter user to programmer;
grant drop user to programmer;
