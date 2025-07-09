-- +goose Up
-- +goose StatementBegin
create table products(
    id integer primary key generated always as identity,
    user_id int not null references users(id) on delete cascade,
    title text not null,
    quantity int not null,
    location text,
    urgent boolean default false not null,
    bought_at timestamp,
    created_at timestamp not null default now(),
    updated_at timestamp not null default now()
);

create trigger set_updated_at
before update on products
for each row
execute procedure update_updated_at_column();
-- +goose StatementEnd

-- +goose Down
-- +goose StatementBegin
drop table products;
drop trigger if exists set_updated_at on products;
-- +goose StatementEnd
