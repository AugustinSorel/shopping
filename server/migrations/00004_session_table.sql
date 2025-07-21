-- +goose Up
-- +goose StatementBegin
create table sessions (
    id text not null primary key,
    user_id int not null references users(id) on delete cascade,
    secret_hash bytea not null, 
    last_verified_at timestamp not null default now(),
    created_at timestamp not null default now(),
    updated_at timestamp not null default now()
);

create trigger set_updated_at
before update on sessions
for each row
execute procedure update_updated_at_column();
-- +goose StatementEnd

-- +goose Down
-- +goose StatementBegin
drop table sessions;
drop trigger if exists set_updated_at on sessions;
-- +goose StatementEnd
