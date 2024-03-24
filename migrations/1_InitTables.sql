-- migrate:up

CREATE SCHEMA api_data;

CREATE EXTENSION IF NOT EXISTS "uuid-ossp" SCHEMA api_data;

CREATE TABLE IF NOT EXISTS api_data.cinema(
	id uuid PRIMARY KEY DEFAULT api_data.uuid_generate_v4(),
	name VARCHAR(80) NOT NULL CHECK(LENGTH(name) > 0), --Вдруг есть фильм "я"
	address VARCHAR(256) NOT NULL CHECK(LENGTH(address) > 10)
);

CREATE TABLE IF NOT EXISTS api_data.film(
	id uuid PRIMARY KEY DEFAULT api_data.uuid_generate_v4(),
	name VARCHAR(80) NOT NULL CHECK(LENGTH(name) > 0),
	description VARCHAR(1024) NOT NULL CHECK(LENGTH(description) > 0),
	rating decimal NOT NULL CHECK(rating >= 0)
);

CREATE TABLE IF NOT EXISTS api_data.film_to_cinema (
	film_id uuid REFERENCES api_data.film(id),
	cinema_id uuid REFERENCES api_data.cinema(id),
	PRIMARY KEY(film_id, cinema_id)
);

CREATE TABLE IF NOT EXISTS api_data.ticket(
	id uuid PRIMARY KEY DEFAULT api_data.uuid_generate_v4(),
	time TIMESTAMP NOT NULL,
	place VARCHAR(256) NOT NULL CHECK(LENGTH(place) > 0), 
	price decimal NOT NULL CHECK(price >= 0),
	film_id uuid,
	cinema_id uuid,
	CONSTRAINT FK_ticket_cinema_film_id FOREIGN KEY(film_id, cinema_id) REFERENCES api_data.film_to_cinema(film_id, cinema_id)
);

CREATE OR REPLACE FUNCTION api_data.get_cinema_id(cinema_name VARCHAR) RETURNS uuid AS $$

	SELECT id FROM api_data.cinema WHERE name = cinema_name;

$$ LANGUAGE SQL;

CREATE OR REPLACE FUNCTION api_data.get_film_id(film_name VARCHAR) RETURNS uuid AS $$
	
	SELECT id FROM api_data.film WHERE name = film_name;

$$ LANGUAGE SQL;

INSERT INTO api_data.cinema(name, address) VALUES
('Komsomoleth', 'Near school #25 =)'),
('Plaza', 'Near school #25 =)'),
('Sirius-street', 'in front of Fiht');

INSERT INTO api_data.film(name, description, rating) VALUES
('Kungfu-panda 1', 'A very super puper film!', 10.0),
('Kungfu-panda 2', 'A very super puper film!', 10.0),
('Kungfu-panda 3', 'A very super puper film!', 10.0),
('Kungfu-panda 4', 'A very super puper film!', 10.0),
('Cat and dog', 'I havent watched this, but it is not kungfu-panda', 3.0);

INSERT INTO api_data.film_to_cinema(film_id, cinema_id)
SELECT 
    api_data.get_film_id('Kungfu-panda 1'), 
    api_data.get_cinema_id('Komsomoleth')
UNION ALL
SELECT 
    api_data.get_film_id('Kungfu-panda 2'), 
    api_data.get_cinema_id('Komsomoleth')
UNION ALL
SELECT 
    api_data.get_film_id('Kungfu-panda 3'), 
    api_data.get_cinema_id('Komsomoleth')
UNION ALL
SELECT 
    api_data.get_film_id('Kungfu-panda 4'), 
    api_data.get_cinema_id('Komsomoleth')
UNION ALL
SELECT 
    api_data.get_film_id('Kungfu-panda 1'), 
    api_data.get_cinema_id('Plaza')
UNION ALL
SELECT 
    api_data.get_film_id('Kungfu-panda 2'), 
    api_data.get_cinema_id('Plaza')
UNION ALL
SELECT 
    api_data.get_film_id('Kungfu-panda 3'), 
    api_data.get_cinema_id('Plaza');


INSERT INTO api_data.ticket(time, place, price, cinema_id, film_id)
SELECT 
    now(), 'first place', 99.99,
    api_data.get_cinema_id('Komsomoleth'),
    api_data.get_film_id('Kungfu-panda 1')
UNION ALL
SELECT 
    now(), 'second place', 199.99,
    api_data.get_cinema_id('Plaza'),
    api_data.get_film_id('Kungfu-panda 2')
UNION ALL
SELECT 
    now(), 'third place', 299.99,
    api_data.get_cinema_id('Komsomoleth'),
    api_data.get_film_id('Kungfu-panda 3');

-- migrate:down