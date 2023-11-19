/* 
 Тема: Написание функций и процедур
*/

-- -- -- -- --
--  Блок 1  -- 
-- -- -- -- --

/*
Информационная справка: строение функции

CREATE [или REPLACE] FUNCTION имя_функции(список_параметров)
   RETURNS тип_данных
  as
$$
DECLARE 
-- объявление переменных
BEGIN
 -- логика функции (запросы)
 RETURN переменная; -- возвращаем, что требуется
END;
$$ LANGUAGE plpgsql;

Подробную информацию про функций можно найти в разделе 38.5
https://postgrespro.ru/docs/postgresql/16/xfunc-sql
*/

-- Изучите пример функции, вычисляющей число фильмов, в которых снялся актёр с задаваемым id

CREATE FUNCTION find_number_of_film(actorId int)
    RETURNS numeric(4,0) -- говорим, что будем возращать целочисленную переменную
    LANGUAGE plpgsql
AS
$$
DECLARE
    numFilm numeric(4,0); -- заводим переменную, которую будем использовать
begin
	SELECT COUNT(film_id) INTO numFilm -- инициализуруем переменную numFilm
	FROM film_actor
	WHERE actor_id=actorId;
    RETURN numFilm; -- возвращаем найденное число
end;
$$;

-- Пример работы
SELECT find_number_of_film(21);


-- 1. Реализуйте функцию, определяющую сумму покупок клиента по его id

CREATE OR REPLACE FUNCTION total_customer_purchases(customerId INT)
    RETURNS NUMERIC(10,2)
    LANGUAGE plpgsql
AS
$$
DECLARE
    totalAmount NUMERIC(10,2);
BEGIN
    SELECT SUM(amount) INTO totalAmount
    FROM payment
    WHERE customer_id = customerId;
    RETURN totalAmount;
END;
$$;

SELECT total_customer_purchases(5);

-- Для выполнения задания 2, Вам может пригодиться информация из раздела 38.5.10
-- https://postgrespro.ru/docs/postgresql/16/xfunc-sql


-- Изучите пример функции, возвращающей названия фильма заданного жанра
CREATE OR REPLACE FUNCTION get_movies_by_genre(p_genre_name VARCHAR)
    RETURNS TABLE (
        title VARCHAR,
        genre_name VARCHAR)
AS $$
BEGIN
    RETURN QUERY
    SELECT
        f.title,
		cat.name
    FROM film f
    JOIN film_category fc ON f.film_id = fc.film_id
    JOIN category cat ON fc.category_id = cat.category_id
    WHERE cat.name = p_genre_name;
END;
$$ LANGUAGE plpgsql;

-- Сравните вывод
SELECT get_movies_by_genre('Animation');
SELECT * FROM get_movies_by_genre('Animation');

-- 2. Напишите функцию, возвращающую названия фильма по фамилии актёра

CREATE OR REPLACE FUNCTION get_movies_by_actor_lastname(p_lastname VARCHAR)
    RETURNS TABLE (
        title VARCHAR)
AS $$
BEGIN
    RETURN QUERY
    SELECT
        f.title
    FROM film f
    JOIN film_actor fa ON f.film_id = fa.film_id
    JOIN actor a ON fa.actor_id = a.actor_id
    WHERE a.last_name = p_lastname;
END;
$$ LANGUAGE plpgsql;

SELECT * FROM get_movies_by_actor_lastname('GUINESS');

/*
3. Напишите функцию get_customer_status, возвращающую Best, если клиент арендовал 30 или более фильмов, иначе - "Ordinary". 
Входные данные id клиента.
*/

CREATE OR REPLACE FUNCTION get_customer_status(customerId INT)
    RETURNS VARCHAR
    LANGUAGE plpgsql
AS
$$
DECLARE
    rentalCount INT;
BEGIN
    SELECT COUNT(*)
    INTO rentalCount
    FROM rental
    WHERE customer_id = customerId;

    IF rentalCount >= 30 THEN
        RETURN 'Best';
    ELSE
        RETURN 'Ordinary';
    END IF;
END;
$$;

SELECT get_customer_status(3);
SELECT get_customer_status(5);

/*
Для выполнения 3, Вам потребуются знания про управляющие структуры:
https://postgrespro.ru/docs/postgresql/16/plpgsql-control-structures
*/

-- Проверьте работу своей функции следующим запросом:
SELECT get_customer_status(480);
-- Ordinary

SELECT get_customer_status(64);
-- Best


/*
Посмотрите разделы 43.6.8-43.6.9
https://postgrespro.ru/docs/postgresql/16/plpgsql-control-structures#PLPGSQL-ERROR-TRAPPING
*/

-- Изучите пример процедуры, обрабатывающей ошибки при изменении email покупателя
CREATE OR REPLACE PROCEDURE update_customer_details(
    p_customer_id INT,
    p_new_email VARCHAR
)
AS $$
BEGIN
    -- Проверяем, существует ли указанный покупатель
    IF NOT EXISTS (SELECT 1 FROM customer WHERE customer_id = p_customer_id) THEN
        RAISE EXCEPTION 'Нет покупателя с ID %', p_customer_id;
    END IF;
	
	IF EXISTS (SELECT 1 FROM customer WHERE email = p_new_email) THEN
        RAISE EXCEPTION 'Пользователь с таким email (%) уже существует', p_new_email;
    END IF;

    -- Для обработки ошибок используется блок TRY...EXCEPTION
    BEGIN
        -- Обновляем данные о покупателе
        UPDATE customer
        SET email = p_new_email
        WHERE customer_id = p_customer_id;

        -- Если произошла в блоке TRY произошла какая-то другая ошибка, то выведем информацию об этом
    EXCEPTION
        WHEN others THEN
            RAISE EXCEPTION 'Произошла ошибка: %', SQLERRM;
    END;
END;
$$ LANGUAGE plpgsql;

-- Можно проверить, что всё работает
CALL update_customer_details(601, 'MARI2.SMITH@sakilacustomer.org');
CALL update_customer_details(1, 'MARI.SMITH@sakilacustomer.org');
CALL update_customer_details(1, 'BARBARA.JONES@sakilacustomer.org');


/* 
4. Напишите процедуру, изменяющую rental_duraction и rental_rate по названию фильма.
Необходимо выдавать ошибки в случаях:
- если фильма с указанным названием не существует;
- если rental_duraction и rental_rate равны нулю;
- если rental_duraction больше 14;
- если rental_rate больше 7.
*/

CREATE OR REPLACE PROCEDURE update_film_rental_details(
    p_title VARCHAR,
    p_rental_duration INT,
    p_rental_rate NUMERIC
)
AS $$
BEGIN
    -- Проверка на существование фильма с указанным названием
    IF NOT EXISTS (SELECT 1 FROM film WHERE title = p_title) THEN
        RAISE EXCEPTION 'Фильм с названием "%" не найден', p_title;
    END IF;

    -- Проверка на нулевые значения rental_duration и rental_rate
    IF p_rental_duration = 0 OR p_rental_rate = 0 THEN
        RAISE EXCEPTION 'rental_duration и rental_rate не могут быть равны нулю';
    END IF;

    IF p_rental_duration > 14 THEN
        RAISE EXCEPTION 'rental_duration не может быть больше 14 (текущее значение: %)', p_rental_duration;
    END IF;

    IF p_rental_rate > 7 THEN
        RAISE EXCEPTION 'rental_rate не может быть больше 7 (текущее значение: %)', p_rental_rate;
    END IF;

    -- Обновляем данные о фильме
    UPDATE film
    SET rental_duration = p_rental_duration, rental_rate = p_rental_rate
    WHERE title = p_title;
END;
$$ LANGUAGE plpgsql;

-- select title, rental_duration, rental_rate from film where title='CRAZY HOME';
CALL update_film_rental_details('CRAZY HOME', 0, 0.0);
CALL update_film_rental_details('CRAZY', 7, 2.99);
CALL update_film_rental_details('CRAZY HOME', 15, 2.99);
CALL update_film_rental_details('CRAZY HOME', 7, 8);
CALL update_film_rental_details('CRAZY HOME', 7, 2.99);
