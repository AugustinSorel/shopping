-- +goose Up
-- +goose StatementBegin
create table users(
    id integer primary key generated always as identity,
    email text unique not null,
    password text not null,
    created_at timestamp not null default now(),
    updated_at timestamp not null default now()
);

create trigger set_updated_at
before update on users
for each row
execute procedure update_updated_at_column();
-- +goose StatementEnd

-- +goose Down
-- +goose StatementBegin
drop table users;
drop trigger if exists set_updated_at on users;
-- +goose StatementEnd
