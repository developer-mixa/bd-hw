-- migrate:up
create index film_rating_idx on api_data.film using btree(rating);

create extension pg_trgm;
create index film_name_trgm_idx on api_data.film using gist(name gist_trgm_ops);

-- migrate:down