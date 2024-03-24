from flask import Flask
import psycopg2
from psycopg2.extras import RealDictCursor
from flask import request
from psycopg2.sql import SQL, Literal
from dotenv import load_dotenv
import os

load_dotenv()


app = Flask(__name__)
app.json.ensure_ascii = False

connection = psycopg2.connect(
    host=os.getenv('POSTGRES_HOST') if os.getenv('DEBUG_MODE') == 'false' else 'localhost',
    port=os.getenv('POSTGRES_PORT'),
    database=os.getenv('POSTGRES_DB'),
    user=os.getenv('POSTGRES_USER'),
    password=os.getenv('POSTGRES_PASSWORD'),
    cursor_factory=RealDictCursor
)
connection.autocommit = True


@app.get("/films")
def get_films():
    query = """
SELECT f.id, f.name, f.description,f.rating, 
COALESCE(json_agg(json_build_object(
	'cinema_id', c.id,
	'name', c.name,
	'address', c.address
)) FILTER(WHERE c.id IS NOT NULL), '[]') AS cinema,
COALESCE(json_agg(json_build_object(
	'ticket_id', t.id,
	'time', t.time,
	'place', t.place,
	'price', t.price
)) FILTER(WHERE t.id IS NOT NULL), '[]') AS ticket
FROM api_data.film f
LEFT JOIN api_data.film_to_cinema fc ON f.id = fc.film_id
LEFT JOIN api_data.cinema c ON c.id = fc.cinema_id
LEFT JOIN api_data.ticket t ON t.cinema_id = fc.cinema_id AND t.film_id = fc.film_id
GROUP BY f.id
"""

    with connection.cursor() as cursor:
        cursor.execute(query)
        result = cursor.fetchall()

    return result


@app.post('/films/create')
def create_actor():
    body = request.json

    name = body['name']
    description = body['description']
    rating = body['rating']

    query = SQL("""
INSERT INTO api_data.film(name, description, rating) VALUES
({name}, {description}, {rating})
returning id;
""").format(name=Literal(name), description=Literal(description), rating=Literal(rating))

    with connection.cursor() as cursor:
        cursor.execute(query)
        result = cursor.fetchone()

    return result


@app.put('/films/update')
def update_actor():
    body = request.json

    id = body['id']
    name = body['name']
    description = body['description']
    rating = body['rating']

    query = SQL("""
update api_data.film
set 
  name = {name}, 
  description = {description},
  rating = {rating}
where id = {id}
returning id
""").format(name=Literal(name), description=Literal(description),
            rating=Literal(rating), id=Literal(id))

    with connection.cursor() as cursor:
        cursor.execute(query)
        result = cursor.fetchall()

    if len(result) == 0:
        return '', 404

    return '', 204


@app.delete('/films/delete')
def delete_actor():
    body = request.json

    id = body['id']

    deleteFilmLinks = SQL(
        "delete from api_data.film_to_cinema where film_id = {id}").format(
            id=Literal(id))
    deleteFilm = SQL("delete from api_data.film where id = {id} returning id").format(
        id=Literal(id))

    with connection.cursor() as cursor:
        cursor.execute(deleteFilmLinks)
        cursor.execute(deleteFilm)
        result = cursor.fetchall()

    if len(result) == 0:
        return '', 404

    return '', 204

if __name__ == '__main__':
    app.run(port=os.getenv('FLASK_PORT'))