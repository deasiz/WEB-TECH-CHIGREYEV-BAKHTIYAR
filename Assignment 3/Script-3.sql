BEGIN;


WITH new_movies AS (
    SELECT 
        'Interstellar' AS title,
        'A team of explorers travel through a wormhole in space in an attempt to ensure humanity survival.' AS description,
        2014 AS release_year,
        (SELECT language_id FROM language WHERE lower(name) = 'english') AS language_id,
        7 AS rental_duration,
        4.99 AS rental_rate,
        169 AS length,
        'PG-13'::mpaa_rating AS rating
    UNION ALL
    SELECT 
        'Inception' AS title,
        'A thief who steals corporate secrets through the use of dream-sharing technology.' AS description,
        2010 AS release_year,
        (SELECT language_id FROM language WHERE lower(name) = 'english') AS language_id,
        14 AS rental_duration,
        9.99 AS rental_rate,
        148 AS length,
        'PG-13'::mpaa_rating AS rating
    UNION ALL
    SELECT 
        'The Dark Knight' AS title,
        'When the menace known as the Joker wreaks havoc and chaos on the people of Gotham.' AS description,
        2008 AS release_year,
        (SELECT language_id FROM language WHERE lower(name) = 'english') AS language_id,
        21 AS rental_duration,
        19.99 AS rental_rate,
        152 AS length,
        'PG-13'::mpaa_rating AS rating
),
inserted_movies AS (
    INSERT INTO film 
        (title, description, release_year, language_id, 
         rental_duration, rental_rate, length, rating, last_update)
    SELECT 
        nm.title, nm.description, nm.release_year, nm.language_id, 
        nm.rental_duration, nm.rental_rate, nm.length, nm.rating, 
        CURRENT_DATE
    FROM new_movies nm
    WHERE NOT EXISTS (
        SELECT 1 FROM film f 
        WHERE f.title = nm.title AND f.release_year = nm.release_year
    )
    RETURNING film_id, title, release_year
)
SELECT * FROM inserted_movies;


INSERT INTO actor (first_name, last_name, last_update)
SELECT 'Matthew', 'McConaughey', CURRENT_DATE
WHERE NOT EXISTS (SELECT 1 FROM actor WHERE first_name = 'Matthew' AND last_name = 'McConaughey');

INSERT INTO actor (first_name, last_name, last_update)
SELECT 'Leonardo', 'DiCaprio', CURRENT_DATE
WHERE NOT EXISTS (SELECT 1 FROM actor WHERE first_name = 'Leonardo' AND last_name = 'DiCaprio');

INSERT INTO actor (first_name, last_name, last_update)
SELECT 'Christian', 'Bale', CURRENT_DATE
WHERE NOT EXISTS (SELECT 1 FROM actor WHERE first_name = 'Christian' AND last_name = 'Bale');


INSERT INTO film_actor (actor_id, film_id, last_update)
SELECT 
    (SELECT actor_id FROM actor WHERE first_name = 'Matthew' AND last_name = 'McConaughey'),
    (SELECT film_id FROM film WHERE title = 'Interstellar' AND release_year = 2014),
    CURRENT_DATE
ON CONFLICT DO NOTHING;

INSERT INTO film_actor (actor_id, film_id, last_update)
SELECT 
    (SELECT actor_id FROM actor WHERE first_name = 'Leonardo' AND last_name = 'DiCaprio'),
    (SELECT film_id FROM film WHERE title = 'Inception' AND release_year = 2010),
    CURRENT_DATE
ON CONFLICT DO NOTHING;

INSERT INTO film_actor (actor_id, film_id, last_update)
SELECT 
    (SELECT actor_id FROM actor WHERE first_name = 'Christian' AND last_name = 'Bale'),
    (SELECT film_id FROM film WHERE title = 'The Dark Knight' AND release_year = 2008),
    CURRENT_DATE
ON CONFLICT DO NOTHING;


INSERT INTO inventory (film_id, store_id, last_update)
SELECT film_id, (SELECT MIN(store_id) FROM store), CURRENT_DATE
FROM film WHERE title IN ('Interstellar', 'Inception', 'The Dark Knight')
AND NOT EXISTS (
    SELECT 1 FROM inventory i WHERE i.film_id = film.film_id
);


UPDATE customer
SET 
    first_name = 'Bakhtiyar',
    last_name  = 'Chigreyev',
    email      = 'bchigreev23@apec.edu.kz',
    address_id = (SELECT MIN(address_id) FROM address),
    last_update = CURRENT_DATE
WHERE customer_id = (
    SELECT c.customer_id 
    FROM customer c
    JOIN rental r ON c.customer_id = r.customer_id
    GROUP BY c.customer_id
    ORDER BY COUNT(r.rental_id) DESC
    LIMIT 1
);


DELETE FROM payment WHERE customer_id = (SELECT customer_id FROM customer WHERE first_name = 'Bakhtiyar' AND last_name = 'Chigreyev');
DELETE FROM rental WHERE customer_id = (SELECT customer_id FROM customer WHERE first_name = 'Bakhtiyar' AND last_name = 'Chigreyev');


WITH rental_1 AS (
    INSERT INTO rental (rental_date, inventory_id, customer_id, return_date, staff_id, last_update)
    SELECT '2024-01-15 10:00:00', 
    (SELECT inventory_id FROM inventory i JOIN film f ON i.film_id = f.film_id WHERE f.title = 'Interstellar' LIMIT 1),
    (SELECT customer_id FROM customer WHERE first_name = 'Bakhtiyar' AND last_name = 'Chigreyev'),
    '2024-01-22 10:00:00', (SELECT MIN(staff_id) FROM staff), CURRENT_DATE
    RETURNING rental_id, customer_id
)
INSERT INTO payment (customer_id, staff_id, rental_id, amount, payment_date)
SELECT customer_id, (SELECT MIN(staff_id) FROM staff), rental_id, 4.99, '2024-01-15 10:05:00' FROM rental_1;

WITH rental_2 AS (
    INSERT INTO rental (rental_date, inventory_id, customer_id, return_date, staff_id, last_update)
    SELECT '2024-02-10 12:00:00', 
    (SELECT inventory_id FROM inventory i JOIN film f ON i.film_id = f.film_id WHERE f.title = 'Inception' LIMIT 1),
    (SELECT customer_id FROM customer WHERE first_name = 'Bakhtiyar' AND last_name = 'Chigreyev'),
    '2024-02-24 12:00:00', (SELECT MIN(staff_id) FROM staff), CURRENT_DATE
    RETURNING rental_id, customer_id
)
INSERT INTO payment (customer_id, staff_id, rental_id, amount, payment_date)
SELECT customer_id, (SELECT MIN(staff_id) FROM staff), rental_id, 9.99, '2024-02-10 12:05:00' FROM rental_2;

WITH rental_3 AS (
    INSERT INTO rental (rental_date, inventory_id, customer_id, return_date, staff_id, last_update)
    SELECT '2024-03-20 15:00:00', 
    (SELECT inventory_id FROM inventory i JOIN film f ON i.film_id = f.film_id WHERE f.title = 'The Dark Knight' LIMIT 1),
    (SELECT customer_id FROM customer WHERE first_name = 'Bakhtiyar' AND last_name = 'Chigreyev'),
    '2024-04-10 15:00:00', (SELECT MIN(staff_id) FROM staff), CURRENT_DATE
    RETURNING rental_id, customer_id
)
INSERT INTO payment (customer_id, staff_id, rental_id, amount, payment_date)
SELECT customer_id, (SELECT MIN(staff_id) FROM staff), rental_id, 19.99, '2024-03-20 15:05:00' FROM rental_3;


SELECT r.rental_id, f.title, r.rental_date, p.amount
FROM rental r
JOIN inventory i ON r.inventory_id = i.inventory_id
JOIN film f ON i.film_id = f.film_id
JOIN payment p ON p.rental_id = r.rental_id
WHERE r.customer_id = (SELECT customer_id FROM customer WHERE first_name = 'Bakhtiyar' AND last_name = 'Chigreyev')
ORDER BY r.rental_date;

COMMIT;