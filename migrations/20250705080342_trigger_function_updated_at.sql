-- +goose Up
-- +goose StatementBegin
create or replace function update_updated_at_column()
returns trigger as $$
begin
  new.updated_at = now();
  return new;
end;
$$ language plpgsql;
-- +goose StatementEnd

-- +goose Down
-- +goose StatementBegin
drop function if exists update_updated_at_column;
-- +goose StatementEnd
