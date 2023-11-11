-- -- -- -- --
--  Блок 2  -- 
-- -- -- -- --
-- Написание SQL-запросов на примере базы данных sakila

-- 1. Выведите дни недели в порядке убывания средней стоимости суммы продаж (amount) в них (таблица payment)
-- если не делали блок 1
SELECT TO_CHAR(payment_date, 'Day') AS day_of_week, AVG(amount) AS avg_sales
FROM payment
GROUP BY day_of_week
ORDER BY avg_sales DESC;

-- 2. Сколько копий фильма Caper Motions имеется в системе? (используйте таблицы film и inventory)
SELECT COUNT(inventory.inventory_id) AS count_copy, 
 film.title AS film_title
FROM inventory
JOIN film 
 ON inventory.film_id = film.film_id 
WHERE film.title ILIKE 'Caper Motions'
GROUP BY film_title;

/*
3. Выведите имена, фамилии и email всех клиентов компании, проживающих в Russian Federation.
Список должен быть упорядочен по фамилиям. Имена и фамилии необходимо выводит в едином столбце "Name".
*/
SELECT CONCAT(customer.first_name, ' ', customer.last_name) AS Name, 
 customer.email 
FROM customer 
JOIN address ON customer.address_id = address.address_id 
JOIN city ON address.city_id = city.city_id 
JOIN country ON city.country_id = country.country_id 
WHERE country.country = 'Russian Federation' 
ORDER BY last_name;

-- 4. Без использования join выведите в одном столбце фамилии и имена актёров, которые снялись в фильме MASK PEACH.
SELECT CONCAT(actor.first_name, ' ', actor.last_name) AS full_name
FROM actor 
WHERE actor_id IN (
	SELECT film_actor.actor_id FROM film_actor WHERE film_id = (
		SELECT film_id FROM film WHERE title = 'MASK PEACH'));

/*
5. Выведите объём продаж по каждому пункту проката.
Выдаваемая таблица должна содержать id пункта проката, общий объём выручки в этом пункте, страну и город, где расположен пункт.
*/
SELECT store.store_id, SUM(payment.amount) AS total_revenue, country.country, city.city 
FROM payment 
JOIN staff ON payment.staff_id = staff.staff_id 
JOIN store ON staff.store_id = store.store_id 
JOIN address ON store.address_id = address.address_id 
JOIN city ON address.city_id = city.city_id 
JOIN country ON city.country_id = country.country_id 
GROUP BY store.store_id, country.country, city.city;

-- 6. Перечислите пять самых прибыльных категорий фильмов в порядке убывания.
SELECT category.name, SUM(payment.amount) AS total_revenue 
FROM payment 
JOIN rental ON payment.rental_id = rental.rental_id 
JOIN inventory ON rental.inventory_id = inventory.inventory_id 
JOIN film ON inventory.film_id = film.film_id 
JOIN film_category ON film.film_id = film_category.film_id 
JOIN category ON film_category.category_id = category.category_id 
GROUP BY category.name 
ORDER BY total_revenue DESC 
LIMIT 5;

/*
7. Выведите title, description, special_features, length и rental_duration фильмов с закадровым текстом,
которые имеют продолжительность не менее 2 часов и продолжительность проката от 5 до 7 дней.
Выведите первые 10 фильмов, расположенные в порядке убывания продолжительности.
*/
SELECT title, description, special_features, length, rental_duration 
FROM film 
WHERE 'Behind the Scenes' = ANY(special_features) AND length >= 120 AND rental_duration BETWEEN 5 AND 7 
ORDER BY length DESC 
LIMIT 10;

-- 8. Выведите топ-7 продавцов (фамилии, имена и сумма продаж)
SELECT CONCAT(staff.first_name, ' ', staff.last_name) AS full_name, 
 SUM(payment.amount) AS sum_sales 
FROM payment 
JOIN staff ON payment.staff_id = staff.staff_id 
GROUP BY staff.staff_id 
ORDER BY sum_sales DESC 
LIMIT 7;

-- 9. Выведите топ-17 актёров, снявшихся в наибольшем количестве фильмов
SELECT CONCAT(actor.first_name, ' ', actor.last_name) AS full_name, 
 COUNT(film_actor.film_id) AS count_films 
FROM actor 
JOIN film_actor ON actor.actor_id = film_actor.actor_id 
GROUP BY actor.actor_id 
ORDER BY count_films DESC 
LIMIT 17;
