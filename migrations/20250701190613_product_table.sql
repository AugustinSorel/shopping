-- +goose Up
-- +goose StatementBegin
create table products(
    id integer primary key generated always as identity,
    title text not null,
    quantity int not null,
    location text,
    urgent boolean default false not null,
    bought_at timestamp,
    created_at timestamp not null default now(),
    updated_at timestamp not null default now()
);
-- +goose StatementEnd

-- +goose Down
-- +goose StatementBegin
drop table products;
-- +goose StatementEnd
