\c BD

create extension if not exists pgcrypto;

select
	username, dbname,
	pgp_sym_decrypt(user_password, 'DEMO2025') as decrypted_password
from users;