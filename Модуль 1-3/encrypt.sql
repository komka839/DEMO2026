\c BD

create extension if not exists pgcrypto;

do $$
declare
	e_key text := 'DEMO2025';
begin
	UPDATE users
	set user_password = pgp_sym_encrypt(convert_from(user_password, 'UTF8'), e_key);
end $$;

select * from users;