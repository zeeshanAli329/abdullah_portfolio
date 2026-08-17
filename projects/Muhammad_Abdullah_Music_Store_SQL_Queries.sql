-- ============================================================
-- MUSIC STORE SQL ANALYSIS
-- PostgreSQL / Chinook Database
-- Questions organized from Question Set 1 to Question Set 3
-- ============================================================

-- QUESTION SET 1 - EASY

-- Q1: Who is the senior most employee based on job title?
SELECT *
FROM employee
ORDER BY levels DESC
LIMIT 1;


-- Q2: Which countries have the most invoices?
SELECT COUNT(*) AS c,
       billing_country
FROM invoice
GROUP BY billing_country
ORDER BY c DESC;


-- Q3: What are the top 3 values of total invoice?
SELECT total
FROM invoice
ORDER BY total DESC
LIMIT 3;


-- Q4: Which city has the best customers?
-- Return the city with the highest sum of invoice totals.
SELECT SUM(total) AS invoice_total,
       billing_city
FROM invoice
GROUP BY billing_city
ORDER BY invoice_total DESC;


-- Q5: Who is the best customer?
-- The customer who has spent the most money.
SELECT customer.customer_id,
       customer.first_name,
       customer.last_name,
       SUM(invoice.total) AS total
FROM customer
JOIN invoice
    ON customer.customer_id = invoice.customer_id
GROUP BY customer.customer_id
ORDER BY total DESC
LIMIT 1;


-- QUESTION SET 2 - MODERATE

-- Q1: Return the email, first name, last name, and Genre
-- of all Rock Music listeners.
SELECT DISTINCT
       email,
       first_name,
       last_name
FROM customer
JOIN invoiceline
    ON customer.customer_id = invoiceline.customer_id
WHERE track_id IN (
    SELECT track_id
    FROM track
    JOIN genre
        ON track.genre_id = genre.genre_id
    WHERE genre.name LIKE 'Rock'
)
ORDER BY email;


-- Q2: Return the Artist name and total track count
-- of the top 10 rock bands.
SELECT artist.artist_id,
       artist.name,
       COUNT(artist.artist_id) AS number_of_songs
FROM track
JOIN album
    ON album.album_id = track.album_id
JOIN artist
    ON artist.artist_id = album.artist_id
JOIN genre
    ON genre.genre_id = track.genre_id
WHERE genre.name LIKE 'Rock'
GROUP BY artist.artist_id
ORDER BY number_of_songs DESC
LIMIT 10;


-- Q3: Return tracks longer than the average song length.
SELECT name,
       milliseconds
FROM track
WHERE milliseconds > (
    SELECT AVG(milliseconds) AS avg_track_length
    FROM track
)
ORDER BY milliseconds DESC;


-- QUESTION SET 3 - ADVANCED

-- Q1: Find how much amount is spent by each customer on artists.
-- Return customer name, artist name, and total spent.
WITH best_selling_artist AS (
    SELECT artist.artist_id AS artist_id,
           artist.name AS artist_name,
           SUM(invoice_line.unit_price * invoice_line.quantity) AS total_sales
    FROM invoice_line
    JOIN track
        ON track.track_id = invoice_line.track_id
    JOIN album
        ON album.album_id = track.album_id
    JOIN artist
        ON artist.artist_id = album.artist_id
    GROUP BY 1
    ORDER BY 3 DESC
    LIMIT 1
)
SELECT c.customer_id,
       c.first_name,
       c.last_name,
       bsa.artist_name,
       SUM(il.unit_price * il.quantity) AS amount_spent
FROM invoice i
JOIN customer c
    ON c.customer_id = i.customer_id
JOIN invoice_line il
    ON il.invoice_id = i.invoice_id
JOIN track t
    ON t.track_id = il.track_id
JOIN album alb
    ON alb.album_id = t.album_id
JOIN best_selling_artist bsa
    ON bsa.artist_id = alb.artist_id
GROUP BY 1, 2, 3, 4
ORDER BY 5 DESC;


-- Q2: Find the most popular music Genre for each country.
-- Where the maximum number of purchases is shared, return all Genres.
WITH popular_genre AS (
    SELECT COUNT(invoice_line.quantity) AS purchases,
           customer.country,
           genre.name,
           genre.genre_id,
           ROW_NUMBER() OVER (
               PARTITION BY customer.country
               ORDER BY COUNT(invoice_line.quantity) DESC
           ) AS RowNo
    FROM invoice_line
    JOIN invoice
        ON invoice.invoice_id = invoice_line.invoice_id
    JOIN customer
        ON customer.customer_id = invoice.customer_id
    JOIN track
        ON track.track_id = invoice_line.track_id
    JOIN genre
        ON genre.genre_id = track.genre_id
    GROUP BY 2, 3, 4
    ORDER BY 2 ASC, 1 DESC
)
SELECT *
FROM popular_genre
WHERE RowNo <= 1;


-- Q3: Determine the customer that has spent the most on music
-- for each country. For shared top amounts, return all customers.
WITH customer_with_country AS (
    SELECT customer.customer_id,
           first_name,
           last_name,
           billing_country,
           SUM(total) AS total_spending
    FROM invoice
    JOIN customer
        ON customer.customer_id = invoice.customer_id
    GROUP BY 1, 2, 3, 4
),
country_max_spending AS (
    SELECT billing_country,
           MAX(total_spending) AS max_spending
    FROM customer_with_country
    GROUP BY billing_country
)
SELECT cc.billing_country,
       cc.total_spending,
       cc.first_name,
       cc.last_name
FROM customer_with_country cc
JOIN country_max_spending ms
    ON cc.billing_country = ms.billing_country
WHERE cc.total_spending = ms.max_spending
ORDER BY 1;


-- ============================================================
-- END OF FILE
-- ============================================================
