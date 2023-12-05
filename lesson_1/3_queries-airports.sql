/*
Запросы.
*/

-- 1. Список моделей самолетов по убыванию частоты их использования (кол-ву рейсов, совершенных на них).

SELECT A.model, COUNT(E.event_id) AS frequency
FROM Aircrafts A
JOIN Flights F ON A.aircraft_id = F.aircraft_id
JOIN Events E ON F.flight_id = E.flight_id
WHERE E.status = 'Состоялся'
GROUP BY A.model
ORDER BY frequency DESC;


-- 2. Топ 5 самых занятых членов экипажа (по количеству рейсов).

SELECT CM.name, COUNT(E.event_id) AS number_of_flights
FROM Crew_members CM
JOIN Crews_Crew_members CCM ON CM.crew_member_id = CCM.crew_member_id
JOIN Crews C ON CCM.crew_id = C.crew_id
JOIN Flights F ON C.flight_id = F.flight_id
JOIN Events E ON F.flight_id = E.flight_id
WHERE E.status = 'Состоялся'
GROUP BY CM.name
ORDER BY number_of_flights DESC
LIMIT 5;


-- 3. Список транзитных рейсов с информацией о времени посадки самолёта и отдыха.

SELECT 
    F.flight_number,
    E.date + E.del_adv_time AS landing_time,
    CURRENT_DATE + CURRENT_TIME - (E.date + E.del_adv_time) AS parking_time
FROM 
    Flights F
JOIN 
    Events E ON F.flight_id = E.flight_id
WHERE 
    F.type = 'Транзитный' AND 
    E.type = 'Посадка' AND 
    E.status = 'Состоялся'
ORDER BY 
    landing_time DESC;


-- 4. Экипажи, работающие на рейсах с самыми короткими временами в пути.

SELECT CM.name, F.travel_time
FROM Crew_members CM
JOIN Crews_Crew_members CCM ON CM.crew_member_id = CCM.crew_member_id
JOIN Crews C ON CCM.crew_id = C.crew_id
JOIN Flights F ON C.flight_id = F.flight_id
WHERE F.travel_time = (
    SELECT MIN(travel_time)
    FROM Flights);


-- 5. Самые длинные рейсы по каждой авиакомпании.

SELECT 
    A.name AS airline,
    F.flight_number,
    F.travel_time AS longest_flight_time
FROM 
    Flights F
JOIN 
    Airlines A ON F.airline_id = A.airline_id
INNER JOIN (
    SELECT 
        airline_id, 
        MAX(travel_time) AS max_travel_time
    FROM 
        Flights
    GROUP BY 
        airline_id
) AS MaxFlights ON F.airline_id = MaxFlights.airline_id AND F.travel_time = MaxFlights.max_travel_time
ORDER BY 
    longest_flight_time DESC;

/*
Функции/процедуры.
*/

-- 1. Напишите процедуру по изменению самолёта на рейс. В процедуре необходимо выполнять проверку того, 
--    что такой самолёт существует, вместимость совпадает или равна вместимости текущего самолёта,
--    новый самолёт не задействован во время рейса на другом рейсе.

CREATE OR REPLACE PROCEDURE change_aircraft_on_flight(
    p_flight_id INT, 
    p_new_aircraft_id INT
)
LANGUAGE plpgsql
AS $$
DECLARE
    v_current_aircraft_id INT;
    v_current_capacity INT;
    v_new_capacity INT;
    v_count_conflicting_flights INT;
BEGIN
    -- Получаем ID и вместимость текущего самолёта на рейс
    SELECT 
        Flights.aircraft_id, 
        Aircrafts.capacity 
    INTO 
        v_current_aircraft_id, 
        v_current_capacity
    FROM 
        Flights
    JOIN 
        Aircrafts ON Flights.aircraft_id = Aircrafts.aircraft_id
    WHERE 
        Flights.flight_id = p_flight_id;

    -- Проверяем, существует ли новый самолёт и его вместимость
    SELECT capacity INTO v_new_capacity
    FROM Aircrafts
    WHERE aircraft_id = p_new_aircraft_id;

    IF v_new_capacity IS NULL THEN
        RAISE EXCEPTION 'Новый самолет не найден';
    END IF;

    IF v_new_capacity < v_current_capacity THEN
        RAISE EXCEPTION 'Вместимость нового самолета меньше текущего';
    END IF;

    -- Проверяем, не задействован ли новый самолёт в других рейсах в это время
    SELECT COUNT(*) INTO v_count_conflicting_flights
    FROM Flights
    WHERE aircraft_id = p_new_aircraft_id 
    AND flight_id != p_flight_id 
    AND (
        (departure_time BETWEEN Flights.departure_time AND Flights.arrival_time) OR
        (arrival_time BETWEEN Flights.departure_time AND Flights.arrival_time)
    );

    IF v_count_conflicting_flights > 0 THEN
        RAISE EXCEPTION 'Новый самолет уже задействован на другом рейсе в это время';
    END IF;

    -- Обновляем самолёт на рейс
    UPDATE Flights
    SET aircraft_id = p_new_aircraft_id
    WHERE flight_id = p_flight_id;

    RAISE NOTICE 'Самолет на рейс изменен успешно';
END;
$$;


-- Заменить в ID рейса ID самолёта

CALL change_aircraft_on_flight(1, 11); -- Новый самолет не найден
CALL change_aircraft_on_flight(1, 2);  -- Новый самолет уже задействован на другом рейсе в это время
CALL change_aircraft_on_flight(1, 10); -- Вместимость нового самолета меньше текущего
CALL change_aircraft_on_flight(1, 5);  -- Самолет на рейсе изменен успешно


-- 2. Напишите функцию, выводящую по дням недели среднее время в пути для рейсов в указанный аэропорт.  
--    Входные данные: id аэропорта.  Выходные данные: день недели, среднее время. 

CREATE OR REPLACE FUNCTION get_average_travel_time_by_weekday(p_airport_id INT)
RETURNS TABLE(weekday TEXT, average_travel_time INTERVAL)
LANGUAGE plpgsql
AS $$
DECLARE
    v_day TEXT;
BEGIN
    RETURN QUERY
    WITH FrequencyMapping AS (
        SELECT 
            flight_id, 
            UNNEST(CASE 
                WHEN frequency = 'Ежедневно' THEN ARRAY['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday']
                WHEN frequency = 'По будням' THEN ARRAY['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday']
                WHEN frequency = 'По четным дням' THEN ARRAY['Tuesday', 'Thursday', 'Saturday']
                WHEN frequency = 'По нечетным дням' THEN ARRAY['Monday', 'Wednesday', 'Friday', 'Sunday']
                WHEN frequency = 'По выходным' THEN ARRAY['Saturday', 'Sunday']
				WHEN frequency = 'Каждый понедельник' THEN ARRAY['Monday']
				WHEN frequency = 'Каждый вторник' THEN ARRAY['Tuesday']
                WHEN frequency = 'Каждую среду' THEN ARRAY['Wednesday']
				WHEN frequency = 'Каждый четверг' THEN ARRAY['Thursday']   
				WHEN frequency = 'Каждую пятницу' THEN ARRAY['Friday']   
				WHEN frequency = 'Каждую субботу' THEN ARRAY['Saturday']   
				WHEN frequency = 'Каждое воскресенье' THEN ARRAY['Sunday']
            END) AS day
        FROM Flights
    )
    SELECT 
        day AS weekday, 
        AVG(travel_time) AS average_travel_time
    FROM 
        FrequencyMapping FM
    JOIN 
        Flights F ON FM.flight_id = F.flight_id
    JOIN 
        Airports_Flights AF ON F.flight_id = AF.flight_id
    WHERE 
        AF.airport_id = p_airport_id
    GROUP BY 
        day
    ORDER BY 
        CASE 
            WHEN day = 'Monday' THEN 1
            WHEN day = 'Tuesday' THEN 2
            WHEN day = 'Wednesday' THEN 3
            WHEN day = 'Thursday' THEN 4
            WHEN day = 'Friday' THEN 5
            WHEN day = 'Saturday' THEN 6
            WHEN day = 'Sunday' THEN 7
        END;
END;
$$;


-- Вывести по дням недели среднее время в пути для рейсов в указанный аэропорт.

SELECT * FROM get_average_travel_time_by_weekday(1);
