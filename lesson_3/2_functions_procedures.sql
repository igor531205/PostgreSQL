/* 
 Тема: Написание функций и процедур
*/

-- -- -- -- --
--  Блок 2  -- 
-- -- -- -- --

/* 
1. Напишите функцию, которая по id актёра выдаёт имена и фамилии всех его коллег по фильмам
(т.е. актёров, снявшихся в тех же фильмах, что и он)
*/

CREATE OR REPLACE FUNCTION get_actor_colleagues(actorId INT)
    RETURNS TABLE (
        first_name VARCHAR,
        last_name VARCHAR)
    LANGUAGE plpgsql
AS
$$
BEGIN
    RETURN QUERY
    SELECT DISTINCT a.first_name, a.last_name
    FROM actor a
    JOIN film_actor fa ON a.actor_id = fa.actor_id
    WHERE fa.film_id IN (
        SELECT film_id
        FROM film_actor
        WHERE actor_id = actorId)
    AND a.actor_id != actorId;
END;
$$;

SELECT * FROM get_actor_colleagues(5);

/* 
2. Напишите процедуру, обновляющую адрес покупателя по его email.
Процедура должна обрабатывать ошибки, свзязанные с несуществующим email, незаданным адресом, city_id и postal_code.
*/

CREATE OR REPLACE PROCEDURE update_customer_address(
    p_email VARCHAR,
    p_new_address VARCHAR,
    p_new_city_id INT,
    p_new_postal_code VARCHAR
)
AS $$
DECLARE
    v_address_id INT;
BEGIN
    -- Проверка на существование покупателя с указанным email и получение его address_id
    SELECT address_id INTO v_address_id FROM customer WHERE email = p_email;
    IF v_address_id IS NULL THEN
        RAISE EXCEPTION 'Покупатель с email "%" не найден', p_email;
    END IF;

    -- Проверка на незаданный адрес
    IF p_new_address IS NULL OR p_new_address = '' THEN
        RAISE EXCEPTION 'Адрес не может быть пустым';
    END IF;

    -- Проверка на незаданный city_id
    IF p_new_city_id IS NULL OR p_new_city_id <= 0 THEN
        RAISE EXCEPTION 'city_id не может быть пустым';
    END IF;

    -- Проверка на незаданный postal_code
    IF p_new_postal_code IS NULL OR p_new_postal_code = '' THEN
        RAISE EXCEPTION 'postal_code не может быть пустым';
    END IF;

    -- Обновляем адрес в таблице address, используя полученный address_id
    UPDATE address
    SET address = p_new_address, city_id = p_new_city_id, postal_code = p_new_postal_code
    WHERE address_id = v_address_id;

END;
$$ LANGUAGE plpgsql;

-- select * from customer JOIN address ON customer.address_id=address.address_id;
CALL update_customer_address('ELIZABETH.BROWN@sakilacustomer.org', '', 361, '42399');
CALL update_customer_address('ELIZABETH.BROWN@sakilacustomer.org', '53 Idfu Parkway', 0, '42399');
CALL update_customer_address('ELIZABETH.BROWN@sakilacustomer.org', '53 Idfu Parkway', 361, '');
CALL update_customer_address('ELIZABETH.BROWN@sakilacustomer.org', '53 Idfu Parkway', 361, '42399');
