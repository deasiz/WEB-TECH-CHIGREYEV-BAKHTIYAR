-- ============================================================
-- Assignment 3: dvdrental Data Manipulation Script
-- Student: Bakhtiyar Chigreyev
-- Films: Green Book, The Wolf of Wall Street, Bad Boys
-- ============================================================
-- The entire script is wrapped in a single transaction.
-- Running it twice produces no errors and no duplicate rows.
-- All FK IDs are resolved dynamically via subqueries — no hardcoded IDs.
-- ============================================================

BEGIN;

-- ============================================================
-- TASK 1: Add Favorite Films
-- We define all three films in a single CTE (new_movies), then
-- insert them in one shot using WHERE NOT EXISTS to check for
-- duplicates by title + release_year. RETURNING lets us confirm
-- what was inserted and feeds into downstream tasks.
-- language_id is resolved via subquery — never hardcoded.
-- ============================================================

WITH new_movies AS (
    SELECT
        'Green Book'                        AS title,
        'A working-class Italian-American bouncer becomes the driver '
        'for an African-American classical pianist on a tour of venues '
        'through the 1960s American South.'  AS description,
        2018                                AS release_year,
        (SELECT language_id FROM public.language WHERE lower(name) = 'english') AS language_id,
        7                                   AS rental_duration,
        4.99::numeric                       AS rental_rate,
        130                                 AS length,
        'PG-13'::mpaa_rating               AS rating

    UNION ALL

    SELECT
        'The Wolf of Wall Street',
        'A New York stockbroker refuses to cooperate in a large securities '
        'fraud case involving corruption on Wall Street, corporate banking '
        'world and mob infiltration.',
        2013,
        (SELECT language_id FROM public.language WHERE lower(name) = 'english'),
        14,
        9.99::numeric,
        180,
        'R'::mpaa_rating

    UNION ALL

    SELECT
        'Bad Boys',
        'Two hip detectives protect a witness to a murder while trying to '
        'identify the thieves who stole a shipment of heroin from the '
        'evidence storage room of the police precinct.',
        1995,
        (SELECT language_id FROM public.language WHERE lower(name) = 'english'),
        21,
        19.99::numeric,
        119,
        'R'::mpaa_rating
),

-- Insert films that don't already exist; RETURNING passes film data forward
inserted_movies AS (
    INSERT INTO public.film
        (title, description, release_year, language_id,
         rental_duration, rental_rate, length, rating, last_update)
    SELECT
        nm.title, nm.description, nm.release_year, nm.language_id,
        nm.rental_duration, nm.rental_rate, nm.length, nm.rating,
        CURRENT_DATE
    FROM new_movies nm
    WHERE NOT EXISTS (
        SELECT 1 FROM public.film f
        WHERE f.title = nm.title
          AND f.release_year = nm.release_year
    )
    RETURNING film_id, title, release_year, rental_duration, rental_rate, last_update
)

SELECT film_id, title, release_year, rental_duration, rental_rate, last_update
FROM inserted_movies;


-- ============================================================
-- TASK 2: Add Actors and Link to Films
-- Actors are defined in a CTE, inserted with WHERE NOT EXISTS
-- (no unique constraint on name, so ON CONFLICT unavailable here).
-- film_actor links use ON CONFLICT DO NOTHING because it has a
-- composite PK (actor_id, film_id) — perfect for that clause.
-- All IDs resolved via subqueries.
-- ============================================================

-- Insert actors
WITH new_actors AS (
    SELECT 'Viggo'      AS first_name, 'Mortensen' AS last_name  -- Green Book
    UNION ALL
    SELECT 'Mahershala', 'Ali'                                    -- Green Book
    UNION ALL
    SELECT 'Leonardo',  'DiCaprio'                                -- Wolf of Wall Street
    UNION ALL
    SELECT 'Jonah',     'Hill'                                    -- Wolf of Wall Street
    UNION ALL
    SELECT 'Will',      'Smith'                                   -- Bad Boys
    UNION ALL
    SELECT 'Martin',    'Lawrence'                                -- Bad Boys
),

inserted_actors AS (
    INSERT INTO public.actor (first_name, last_name, last_update)
    SELECT na.first_name, na.last_name, CURRENT_DATE
    FROM new_actors na
    WHERE NOT EXISTS (
        SELECT 1 FROM public.actor a
        WHERE a.first_name = na.first_name
          AND a.last_name  = na.last_name
    )
    RETURNING actor_id, first_name, last_name
)

SELECT actor_id, first_name, last_name FROM inserted_actors;


-- Link actors to films via film_actor
-- ON CONFLICT DO NOTHING handles the composite PK safely on re-run.
WITH film_actor_pairs AS (
    SELECT
        (SELECT actor_id FROM public.actor WHERE first_name = 'Viggo'      AND last_name = 'Mortensen') AS actor_id,
        (SELECT film_id  FROM public.film  WHERE title = 'Green Book'      AND release_year = 2018    ) AS film_id
    UNION ALL
    SELECT
        (SELECT actor_id FROM public.actor WHERE first_name = 'Mahershala' AND last_name = 'Ali'),
        (SELECT film_id  FROM public.film  WHERE title = 'Green Book'      AND release_year = 2018)
    UNION ALL
    SELECT
        (SELECT actor_id FROM public.actor WHERE first_name = 'Leonardo'   AND last_name = 'DiCaprio'),
        (SELECT film_id  FROM public.film  WHERE title = 'The Wolf of Wall Street' AND release_year = 2013)
    UNION ALL
    SELECT
        (SELECT actor_id FROM public.actor WHERE first_name = 'Jonah'      AND last_name = 'Hill'),
        (SELECT film_id  FROM public.film  WHERE title = 'The Wolf of Wall Street' AND release_year = 2013)
    UNION ALL
    SELECT
        (SELECT actor_id FROM public.actor WHERE first_name = 'Will'       AND last_name = 'Smith'),
        (SELECT film_id  FROM public.film  WHERE title = 'Bad Boys'        AND release_year = 1995)
    UNION ALL
    SELECT
        (SELECT actor_id FROM public.actor WHERE first_name = 'Martin'     AND last_name = 'Lawrence'),
        (SELECT film_id  FROM public.film  WHERE title = 'Bad Boys'        AND release_year = 1995)
)

INSERT INTO public.film_actor (actor_id, film_id, last_update)
SELECT fap.actor_id, fap.film_id, CURRENT_DATE
FROM film_actor_pairs fap
ON CONFLICT DO NOTHING;


-- ============================================================
-- TASK 3: Add Films to Inventory
-- film_id resolved by title + release_year, store_id resolved
-- via MIN(store_id). WHERE NOT EXISTS prevents duplicate copies.
-- ============================================================

WITH new_inventory AS (
    SELECT
        (SELECT film_id FROM public.film WHERE title = 'Green Book'              AND release_year = 2018) AS film_id,
        (SELECT MIN(store_id) FROM public.store) AS store_id
    UNION ALL
    SELECT
        (SELECT film_id FROM public.film WHERE title = 'The Wolf of Wall Street' AND release_year = 2013),
        (SELECT MIN(store_id) FROM public.store)
    UNION ALL
    SELECT
        (SELECT film_id FROM public.film WHERE title = 'Bad Boys'                AND release_year = 1995),
        (SELECT MIN(store_id) FROM public.store)
),

inserted_inventory AS (
    INSERT INTO public.inventory (film_id, store_id, last_update)
    SELECT ni.film_id, ni.store_id, CURRENT_DATE
    FROM new_inventory ni
    WHERE NOT EXISTS (
        SELECT 1 FROM public.inventory i
        WHERE i.film_id  = ni.film_id
          AND i.store_id = ni.store_id
    )
    RETURNING inventory_id, film_id, store_id
)

SELECT inventory_id, film_id, store_id FROM inserted_inventory;


-- ============================================================
-- TASK 4: Become a Customer
-- Dynamically find the customer with the most rentals who has
-- >= 43 rentals AND >= 43 payments. No hardcoded customer_id.
-- AND first_name != 'Bakhtiyar' makes the UPDATE idempotent —
-- it won't re-run needlessly on the second execution.
-- ============================================================

UPDATE public.customer
SET
    first_name  = 'Bakhtiyar',
    last_name   = 'Chigreyev',
    email       = 'bakhtiyar.chigreyev@sakilacustomer.org',
    address_id  = (SELECT MIN(address_id) FROM public.address),
    last_update = CURRENT_DATE
WHERE customer_id = (
    SELECT c.customer_id
    FROM public.customer c
    JOIN public.rental  r ON c.customer_id = r.customer_id
    JOIN public.payment p ON c.customer_id = p.customer_id
    GROUP BY c.customer_id
    HAVING COUNT(DISTINCT r.rental_id)  >= 43
       AND COUNT(DISTINCT p.payment_id) >= 43
    ORDER BY COUNT(DISTINCT r.rental_id) DESC
    LIMIT 1
)
AND first_name != 'Bakhtiyar';


-- ============================================================
-- TASK 5: Clean Up Prior Records
-- We verify with SELECT before each DELETE.
-- Only payment and rental are cleaned — customer and inventory
-- are intentionally left untouched per the assignment rules.
-- ============================================================

-- Preview payments before deletion
SELECT payment_id, amount, payment_date
FROM public.payment
WHERE customer_id = (
    SELECT customer_id FROM public.customer
    WHERE first_name = 'Bakhtiyar' AND last_name = 'Chigreyev'
);

-- Delete old payments
DELETE FROM public.payment
WHERE customer_id = (
    SELECT customer_id FROM public.customer
    WHERE first_name = 'Bakhtiyar' AND last_name = 'Chigreyev'
);

-- Preview rentals before deletion
SELECT rental_id, rental_date, return_date
FROM public.rental
WHERE customer_id = (
    SELECT customer_id FROM public.customer
    WHERE first_name = 'Bakhtiyar' AND last_name = 'Chigreyev'
);

-- Delete old rentals
DELETE FROM public.rental
WHERE customer_id = (
    SELECT customer_id FROM public.customer
    WHERE first_name = 'Bakhtiyar' AND last_name = 'Chigreyev'
);


-- ============================================================
-- TASK 6: Rent Films and Pay
-- Each rental is inserted via CTE with RETURNING, and its
-- rental_id is immediately reused in the payment INSERT —
-- all within a single statement per film, keeping it atomic.
-- return_date = rental_date + rental_duration * INTERVAL '1 day'
-- payment_date is in 2017 H1 to match the partition range.
-- All IDs resolved dynamically — no hardcoded values.
-- ============================================================

-- ---- Green Book ----
WITH rented_green_book AS (
    INSERT INTO public.rental
        (rental_date, inventory_id, customer_id, return_date, staff_id, last_update)
    VALUES (
        '2017-01-15 10:00:00'::TIMESTAMP,
        (
            SELECT i.inventory_id FROM public.inventory i
            JOIN public.film f ON i.film_id = f.film_id
            WHERE f.title = 'Green Book' AND f.release_year = 2018
              AND i.store_id = (SELECT MIN(store_id) FROM public.store)
            LIMIT 1
        ),
        (SELECT customer_id FROM public.customer WHERE first_name = 'Bakhtiyar' AND last_name = 'Chigreyev'),
        '2017-01-15 10:00:00'::TIMESTAMP + (
            SELECT rental_duration FROM public.film WHERE title = 'Green Book' AND release_year = 2018
        ) * INTERVAL '1 day',
        (SELECT MIN(staff_id) FROM public.staff),
        CURRENT_DATE
    )
    RETURNING rental_id, customer_id, staff_id
)
INSERT INTO public.payment (customer_id, staff_id, rental_id, amount, payment_date)
SELECT
    rgb.customer_id,
    rgb.staff_id,
    rgb.rental_id,
    (SELECT rental_rate FROM public.film WHERE title = 'Green Book' AND release_year = 2018),
    '2017-01-15 10:30:00'::TIMESTAMP
FROM rented_green_book rgb;


-- ---- The Wolf of Wall Street ----
WITH rented_wolf AS (
    INSERT INTO public.rental
        (rental_date, inventory_id, customer_id, return_date, staff_id, last_update)
    VALUES (
        '2017-02-10 14:00:00'::TIMESTAMP,
        (
            SELECT i.inventory_id FROM public.inventory i
            JOIN public.film f ON i.film_id = f.film_id
            WHERE f.title = 'The Wolf of Wall Street' AND f.release_year = 2013
              AND i.store_id = (SELECT MIN(store_id) FROM public.store)
            LIMIT 1
        ),
        (SELECT customer_id FROM public.customer WHERE first_name = 'Bakhtiyar' AND last_name = 'Chigreyev'),
        '2017-02-10 14:00:00'::TIMESTAMP + (
            SELECT rental_duration FROM public.film WHERE title = 'The Wolf of Wall Street' AND release_year = 2013
        ) * INTERVAL '1 day',
        (SELECT MIN(staff_id) FROM public.staff),
        CURRENT_DATE
    )
    RETURNING rental_id, customer_id, staff_id
)
INSERT INTO public.payment (customer_id, staff_id, rental_id, amount, payment_date)
SELECT
    rw.customer_id,
    rw.staff_id,
    rw.rental_id,
    (SELECT rental_rate FROM public.film WHERE title = 'The Wolf of Wall Street' AND release_year = 2013),
    '2017-02-10 14:30:00'::TIMESTAMP
FROM rented_wolf rw;


-- ---- Bad Boys ----
WITH rented_bad_boys AS (
    INSERT INTO public.rental
        (rental_date, inventory_id, customer_id, return_date, staff_id, last_update)
    VALUES (
        '2017-03-05 09:00:00'::TIMESTAMP,
        (
            SELECT i.inventory_id FROM public.inventory i
            JOIN public.film f ON i.film_id = f.film_id
            WHERE f.title = 'Bad Boys' AND f.release_year = 1995
              AND i.store_id = (SELECT MIN(store_id) FROM public.store)
            LIMIT 1
        ),
        (SELECT customer_id FROM public.customer WHERE first_name = 'Bakhtiyar' AND last_name = 'Chigreyev'),
        '2017-03-05 09:00:00'::TIMESTAMP + (
            SELECT rental_duration FROM public.film WHERE title = 'Bad Boys' AND release_year = 1995
        ) * INTERVAL '1 day',
        (SELECT MIN(staff_id) FROM public.staff),
        CURRENT_DATE
    )
    RETURNING rental_id, customer_id, staff_id
)
INSERT INTO public.payment (customer_id, staff_id, rental_id, amount, payment_date)
SELECT
    rbb.customer_id,
    rbb.staff_id,
    rbb.rental_id,
    (SELECT rental_rate FROM public.film WHERE title = 'Bad Boys' AND release_year = 1995),
    '2017-03-05 09:30:00'::TIMESTAMP
FROM rented_bad_boys rbb;


COMMIT;