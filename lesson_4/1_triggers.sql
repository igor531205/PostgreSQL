-- Тема 3: Триггеры

/*
Триггер выполнятся при наступлении некоторого события в базе данных.
Такое событие должно быть связано с одной из следующих команд: INSERT, UPDATE или DELETE.

Создание триггера:

CREATE TRIGGER trigger_name
{BEFORE | AFTER} { событие } -- Когда будет срабатывать триггер: BEFORE — перед событием. AFTER — после события.
ON table_name  -- Для какой таблицы
[FOR [EACH] { ROW | STATEMENT }] -- Уровня строки или оператора
EXECUTE FUNCTION trigger_function -- Что будет выполняться при активации триггера


Немного про триггеры, если ничего не понятно:
https://sql-ex.ru/blogs/?/Rukovodstvo_po_triggeram_v_SQL_nastrojka_otsleZhivaniJa_bazy_dannyh_v_PostgreSQL.html&ysclid=lp8e8k976c71217248
https://w3resource.com/PostgreSQL/postgresql-triggers.php
*/

/*
Рассмотрим пример триггера для базы данных Sakila.
Триггер будет вызываться перед вставкой новой записи в таблицу film_actor.
Если film_id или actor_id не существует в соответствующих таблицах,
то будет вызвано исключение, и вставка будет отклонена.
Если оба идентификатора существуют, вставка будет успешно завершена.
*/

-- шаг 1. Создание триггерной функции. 
CREATE OR REPLACE FUNCTION check_film_actor_insert() -- Триггерная функция не имеет аргументов
RETURNS TRIGGER AS $$ -- Возвращаемое значение имеет тип trigger
BEGIN
    -- Проверка наличия film_id в таблице film
    IF NOT EXISTS (SELECT 1 FROM film WHERE film_id = NEW.film_id) THEN
        RAISE EXCEPTION 'film_id % не существует в таблице film', NEW.film_id;
    END IF;

    -- Проверка наличия actor_id в таблице actor
    IF NOT EXISTS (SELECT 1 FROM actor WHERE actor_id = NEW.actor_id) THEN
        RAISE EXCEPTION 'actor_id % не существует в таблице actor', NEW.actor_id;
    END IF;

    -- Если проверки прошли успешно, то возвращаем без изменений
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

/*
Что такое NEW?

NEW - это специальная переменная, предоставляемая в теле триггера,
которая содержит новые значения, которые будут вставлены, обновлены или удалены.
Эта переменная используется, чтобы обращаться к данным,
которые собираются быть внесены в таблицу в результате операции триггера.

Ещё есть специальная переменная OLD, которая содержит старые значения.

Т.е. OLD и NEW представляют состояния строки в таблице до или после триггерного события.
*/

-- шаг 2. Создание триггера на таблице film_actor
CREATE TRIGGER check_film_actor_insert_trigger
BEFORE INSERT ON film_actor
FOR EACH ROW
EXECUTE FUNCTION check_film_actor_insert();

-- Можно проверить работу триггера.
INSERT INTO film_actor(film_id,actor_id) VALUES(35,21);
INSERT INTO film_actor(film_id,actor_id) VALUES(1355,21);
INSERT INTO film_actor(film_id,actor_id) VALUES(35,2211);

-- Задание 1. Доработайте пример, добавив проверку того, существует ли уже такая запись в таблице

-- шаг 1. Доработка триггерной функции 
CREATE OR REPLACE FUNCTION check_film_actor_insert()
RETURNS TRIGGER AS $$
BEGIN
    -- Проверка наличия film_id в таблице film
    IF NOT EXISTS (SELECT 1 FROM film WHERE film_id = NEW.film_id) THEN
        RAISE EXCEPTION 'film_id % не существует в таблице film', NEW.film_id;
    END IF;

    -- Проверка наличия actor_id в таблице actor
    IF NOT EXISTS (SELECT 1 FROM actor WHERE actor_id = NEW.actor_id) THEN
        RAISE EXCEPTION 'actor_id % не существует в таблице actor', NEW.actor_id;
    END IF;

    -- Проверка наличия уже существующей комбинации film_id и actor_id в таблице film_actor
    IF EXISTS (SELECT 1 FROM film_actor WHERE film_id = NEW.film_id AND actor_id = NEW.actor_id) THEN
        RAISE EXCEPTION 'Запись с film_id % и actor_id % уже существует в таблице film_actor', NEW.film_id, NEW.actor_id;
    END IF;

    -- Если все проверки прошли успешно, то возвращаем без изменений
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- шаг 2. Создание триггера остается неизменным
CREATE OR REPLACE TRIGGER check_film_actor_insert_trigger
BEFORE INSERT ON film_actor
FOR EACH ROW
EXECUTE FUNCTION check_film_actor_insert();

-- Можно проверить работу триггера.
INSERT INTO film_actor(film_id,actor_id) VALUES(35,21);
INSERT INTO film_actor(film_id,actor_id) VALUES(1355,21);
INSERT INTO film_actor(film_id,actor_id) VALUES(35,2211);


/*
Задание 2. В таблице film есть поле last_update, отвечающее за то, когда запись о фильме последний раз была обновлена.
Напишите триггер автоматически обновляющий время (на текущее) при внесении изменений в запись этой таблицы.
*/

-- Шаг 1. Создание триггерной функции для обновления last_update
CREATE OR REPLACE FUNCTION update_last_update_column()
RETURNS TRIGGER AS $$
BEGIN
    -- Обновление поля last_update до текущего времени
    NEW.last_update = now();

    -- Возвращаем обновленную строку
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Шаг 2. Создание триггера для автоматического обновления last_update
CREATE OR REPLACE TRIGGER update_film_last_update
AFTER UPDATE ON film
FOR EACH ROW
EXECUTE FUNCTION update_last_update_column();

-- Можно проверить работу триггера.
SELECT film_id, title, last_update
FROM film
WHERE film_id = 1;

UPDATE film
SET title = 'New ACADEMY DINOSAUR'
WHERE film_id = 1;

SELECT film_id, title, last_update
FROM film
WHERE film_id = 1;


/*
Задание 3. В таблице film есть поле rental_duration, которое отвечает за то, на какой срок можно взять фильм в аренду.
Напишите триггер, срабатывающий, когда клиент возвращает взятый в аренду фильм, и проверяющий не просрочил ли он срок аренды. 
Используйте для этого таблицу rental.
*/

-- Создание триггерной функции для проверки срока аренды
CREATE OR REPLACE FUNCTION check_rental_duration()
RETURNS TRIGGER AS $$
DECLARE
    film_rental_duration INT;
    rental_period INT;
BEGIN
    -- Получение rental_duration фильма
    SELECT f.rental_duration INTO film_rental_duration
    FROM film f
    JOIN inventory i ON f.film_id = i.film_id
    WHERE i.inventory_id = NEW.inventory_id;

    -- Вычисление количества дней аренды
    rental_period := DATE_PART('day', NEW.return_date - NEW.rental_date);

    -- Проверка, превышен ли срок аренды
    IF rental_period > film_rental_duration THEN
        RAISE EXCEPTION 'Срок аренды превышен. Фильм арендован на % дней, а возвращен через % дней.', 
        film_rental_duration, rental_period;
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Создание триггера, который вызывает функцию check_rental_duration при каждом возврате фильма
CREATE OR REPLACE TRIGGER rental_check_duration
BEFORE UPDATE ON rental
FOR EACH ROW
EXECUTE FUNCTION check_rental_duration();

-- Можно проверить работу триггера.
SELECT * FROM rental WHERE rental_id = 1;

UPDATE rental
SET return_date = '2005-05-25 22:53:30'
WHERE rental_id = 1;

SELECT * FROM rental WHERE rental_id = 1;

UPDATE rental
SET return_date = '2009-06-29 22:53:30'
WHERE rental_id = 1;