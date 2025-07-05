-- +goose Up
-- +goose StatementBegin
create trigger set_updated_at
before update on products
for each row
execute procedure update_updated_at_column();
-- +goose StatementEnd

-- +goose Down
-- +goose StatementBegin
drop trigger if exists set_updated_at on products;
-- +goose StatementEnd
