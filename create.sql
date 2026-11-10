create database "BD";

\c BD

create table if not exists Users
(
	username varchar(50) primary key,
	dbname varchar(50) not null,
	user_password bytea not null
);

create extension if not exists pgcrypto;


do $$
declare
	i int := 1;
	user_name text;
	db_name text;
	random_password text;
begin
	while i <= 10 loop
	user_name = 'user' || i;
	db_name = 'BD' || i;
	random_password := substr(encode(gen_random_bytes(5), 'hex'), 1, 5);
	execute format('CREATE USER %I WITH PASSWORD %L', user_name, random_password);
	insert into Users(username, dbname, user_password)
	values (user_name, db_name, convert_to(random_password, 'UTF8'));
	i := i + 1;
	end loop;
end $$;

create database "BD1" owner user1;
create database "BD2" owner user2;
create database "BD3" owner user3;
create database "BD4" owner user4;
create database "BD5" owner user5;
create database "BD6" owner user6;
create database "BD7" owner user7;
create database "BD8" owner user8;
create database "BD9" owner user9;
create database "BD10" owner user10;

select username, dbname, convert_from(user_password, 'UTF8') as descrypted_password from users