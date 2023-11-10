-- -- -- -- --
--  Блок 1  -- 
-- -- -- -- --
-- Написание SQL-запросов на примере базы данных sakila

-- Двойным "-" обозначается однострочный комментарий

/*
В такой конструкции может быть написан многострочный комментарий.
*/

/* Информационная справка 
Одна из основных функций SQL — это получение выборок данных из СУБД. Для этого в SQL используется оператор SELECT.
Структура запроса выглядит следующим образом:
SELECT названия_столбов FROM название_таблицы;
*/
-- 1. Запустите команду для вывода всех строк из таблицы фильмы. Измените запрос таким образом, чтобы он вывел только название, описание и год выхода фильма
SELECT title, description, release_year 
FROM film;

/* Информационная справка 
Зачастую необходимо извлекать не все данные из БД, а только те, которые соответствуют определенному условию.
Для фильтрации данных в команде SELECT применяется оператор WHERE, после которого указывается условие.
Если условие истинно, то строка попадает в результирующую выборку. 
Структура запроса выглядит следующим образом:

SELECT названия_столбцов
FROM название_таблицы
WHERE условие;
*/
-- 2. Выведите только те фильмы, которые не имеют возрастных ограничений (рейтинг G).
SELECT title, description, release_year 
FROM film 
WHERE rating = 'G';

-- 3. Среди фильмов, не имеющих возрастных ограничений, найдите те, которые длятся более 100 минут.
SELECT title, description, release_year
FROM film 
WHERE rating = 'G'
 AND length > 100;

/* Информационная справка 
Агрегатные функции — это функции, которые выполняют вычисления на наборе значений и возвращают одиночное значение
AVG: вычисляет среднее значение
SUM: вычисляет сумму значений

MIN: вычисляет наименьшее значение
MAX: вычисляет наибольшее значение
COUNT: вычисляет количество строк в выборке
*/
-- 4. Выведите количество фильмов, которые были найдены в 3 пункте.
SELECT COUNT(film_id) AS count_films
FROM film 
WHERE rating = 'G'
 AND length > 100;

/* Информационная справка 
LIKE позволяет выполнить поиск строк, которые соответствуют определенному образцу, а не строгому совпадению.

% — любые символы, в любом количестве (даже без символов)
_  — один любой символ

SELECT названия_столбцов
FROM название_таблицы
WHERE название_столбца
LIKE условие_фильтрации;
*/
-- 5. Выведите имена и фамилии тех актёров/актрис, у которых в имени встречается 'en'  
SELECT first_name, last_name
FROM actor 
WHERE first_name LIKE '%en%'
 OR first_name LIKE '_%EN%';

/* Информационная справка 
ORDER BY позволяет упорядочивать данные в результирующем наборе в определенном порядке

ASC — по возрастанию (по умолчанию)
DESC  — по убыванию

Сортировка по возрастанию:
SELECT названия_столбцов
FROM название_таблицы
ORDER BY название_столбца;

Сортировка по убыванию:
SELECT названия_столбцов
FROM название_таблицы
ORDER BY название_столбца DESC;

Сортировка по нескольким столбцам в разном порядке:
SELECT названия_столбцов
FROM название_таблицы
ORDER BY название_столбца1 ASC, название_столбца2 DESC;
*/

-- 6. Найдите всех актеров, чьи фамилии содержат буквы LI. Выведите их имена и фамилии, отсортированные в порядке убывания
SELECT first_name, last_name
FROM actor 
WHERE last_name LIKE '%LI%'
ORDER BY first_name DESC, last_name DESC;

-- 7. Измените запрос из задания 6 таким образом, чтобы первыми выводились фамилии в порядке убывания, а затем имена в порядке возрастания
SELECT first_name, last_name
FROM actor 
WHERE last_name LIKE '%LI%'
ORDER BY last_name DESC, first_name ASC;

/* Информационная справка 
GROUP BY используется для группировки строк по значениям в одном или нескольких столбцах

!!! Важное замечание:
При использовании группировки в SELECT-части запроса должны использоваться либо агрегатные функции (например, COUNT, AVG),
либо все указанные после SELECT столбцы должны быть также перечислены в GROUP BY. 

Простая группировка по одному столбцу:
SELECT название_столбца
FROM название_таблицы
GROUP BY название_столбца;

Простая группировка с использованием агрегатных функций:
SELECT название_столбца, COUNT(*)
FROM название_таблицы
GROUP BY название_столбца;
*/

-- 8. Найдите среднюю продолжительность, среднюю арендную ставку и число фильмов, имеющих одинаковый рейтинг
SELECT 
 AVG(length) AS avg_length, 
 AVG(rental_rate) AS avg_rental_rate, 
 COUNT(film_id) AS count_films, 
 rating
FROM film
GROUP BY rating;

-- 9. Для таблицы payment выведите сумму всех заказов, сгруппированную по id покупателя
SELECT SUM(amount) AS sum_payments, customer_id
FROM payment
GROUP BY customer_id;

/* Информационная справка 
Группировка по нескольким столбцам:

SELECT названия_столбцов
FROM название_таблицы
GROUP BY название_столбца1, название_столбца2;
*/

-- 10. Измените предыдущий запрос так, чтобы можно было посмотреть разбивку итоговой суммы по id персонала
SELECT SUM(amount) AS sum_payments, customer_id, staff_id
FROM payment
GROUP BY customer_id, staff_id;

/* Информационная справка 
Фильтрация результатов группировки с использованием HAVING:

SELECT названия_столбцов
FROM название_таблицы
GROUP BY названия_столбцов
HAVING условие;
*/

-- 11. Измените предыдущий запрос так, чтобы выводились только те данные, где сумма заказов была больше 70
SELECT SUM(amount) AS sum_payments, customer_id, staff_id
FROM payment
GROUP BY customer_id, staff_id
HAVING SUM(amount) > 70;

-- 12. Добавьте сортировку по убыванию сумм в предыдущем запросе
SELECT SUM(amount) AS sum_payments, customer_id, staff_id
FROM payment
GROUP BY customer_id, staff_id
HAVING SUM(amount) > 70
ORDER BY sum_payments DESC;

/* Информационная справка: Конструктор запроса

SELECT имена_столбцов
FROM имя_таблицы 
[WHERE условие_фильтрации_строк]
[GROUP BY поля_группировки]
[HAVING условие_фильтрации_групп]
[ORDER BY столбцы_для_сортировки];
*/

/* Информационная справка: Многотабличные запросы

Нередко возникает необходимость в одном запросе получить данные сразу из нескольких таблиц. 
Операция, позволяющая это сделать, называется "соединением" (JOIN). 
В MySQL и других реляционных базах данных существует несколько типов соединений, таких как INNER JOIN, LEFT JOIN, RIGHT JOIN и FULL JOIN.
*/

-- 13.  Попробуйте сравнить следующие 3 запроса 
SELECT city, country FROM city, country;

SELECT city, country FROM city, country
WHERE city.country_id=country.country_id;

SELECT city, country FROM city
JOIN country
ON city.country_id=country.country_id;

/*
[INNER] JOIN (Внутреннее соединение): Возвращает строки, у которых есть соответствующие значения в обеих таблицах.
Если нет совпадающих значений, строки не возвращаются.

SELECT столбцы
FROM таблица1
    [INNER] JOIN таблица2
    ON условие1
    [[INNER] JOIN таблица3
    ON условие2]
*/

-- 14. Найдите всех актеров, которые снялись в фильме WONKA SEA или DATE SPEED. Выведите их имя, фамилию и названия фильмов
SELECT a.first_name, a.last_name, f.title
FROM actor AS a
JOIN film_actor AS fa ON a.actor_id = fa.actor_id
JOIN film AS f ON f.film_id = fa.film_id
WHERE f.title = 'WONKA SEA' OR f.title = 'DATE SPEED';

/*
Используя псевдонимы для таблиц, можно сократить код: 
используемое_название AS новое_название
*/

-- 15. Посчитайте, сколько фильмов каждого жанра содержится в таблице
SELECT c.name AS genre, COUNT(f.film_id) AS count_films
FROM category AS c
JOIN film_category AS fc ON c.category_id = fc.category_id
JOIN film AS f ON fc.film_id = f.film_id
GROUP BY genre;

/*
Информационная справка: Строковые функции SQL
Выдачу информацию в запросах можно преобразовывать при помощи различных функций

Например:
Функция UPPER может преобразовывать переданные ей строки в буквы верхнего регистра
INITCAP возвращает значение в строке, в которой каждое слово начинается с заглавной буквы
CONCAT используется для объединения значений двух столбцов в один
LOWER возвращает в значение все слова с маленькой буквы
Функция LPAD/RPAD пригодится, если необходимо дополнить слева/справа некими символами, до определенного количества знаков
LTRIM удаляет крайние левые символы, которые Вы укажите
REPLACE возвращает строку, в которой все совпадения символов, заменяются на символы, которые Вы укажите
*/
-- 16. Выведите фамилии и имена актёров в одном столбце (full_name). Все символы должны быть в верхнем регистре
SELECT UPPER(CONCAT(first_name, ' ', last_name)) AS full_name
FROM actor;

/*
Изучите информацию про форматирование данных:

https://postgrespro.ru/docs/postgresql/14/functions-formatting?ysclid=lor6cmtzq8416447459
*/

-- 17. Выведите дни недели в порядке убывания средней стоимости суммы продаж (amount) в них (таблица payment)
SELECT TO_CHAR(payment_date, 'Day') AS day_of_week, AVG(amount) AS avg_sales
FROM payment
GROUP BY day_of_week
ORDER BY avg_sales DESC;
