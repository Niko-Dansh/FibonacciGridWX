CREATE TABLE grid_points
(
    point_id SERIAL PRIMARY KEY,        -- 1…600 unique points
    lat      DOUBLE PRECISION NOT NULL, -- rounding is not exact, but fast
    lon      DOUBLE PRECISION NOT NULL,
    UNIQUE (lat, lon)                   -- guard against duplicates
);

CREATE TABLE weather_raw
(
    raw_id     SERIAL PRIMARY KEY,
    point_id   INTEGER     NOT NULL
        REFERENCES grid_points (point_id),
    fetched_at TIMESTAMPTZ NOT NULL, -- when We called the API
    payload    JSONB       NOT NULL, -- stores the entire JSON response
    CONSTRAINT uq_point_time UNIQUE (point_id, fetched_at) -- No same combination of point_id and fetched_at
);


SELECT MAX(weather_raw.raw_id) -- Смотрим сколько измерений у нас есть
FROM weather_raw;

CREATE TABLE weather_analytics_daily
(
    point_id     INT         NOT NULL REFERENCES grid_points (point_id),
    weather_date DATE        NOT NULL,
    weather_desc VARCHAR(50) NOT NULL,
    temp         SMALLINT    NOT NULL,
    feels_like   SMALLINT    NOT NULL,
    temp_min     SMALLINT    NOT NULL,
    temp_max     SMALLINT    NOT NULL,
    pressure     SMALLINT    NOT NULL,
    humidity     SMALLINT    NOT NULL,
    sea_level    SMALLINT    NOT NULL,
    grnd_level   SMALLINT    NOT NULL,
    visibility   SMALLINT    NOT NULL,
    wind_speed   SMALLINT    NOT NULL,
    wind_deg     SMALLINT    NOT NULL,
    wind_gust    SMALLINT    NOT NULL,
    PRIMARY KEY (point_id, weather_date)
);

-- Тест трансформации

SELECT weather_raw.payload -> 'main' -> 'pressure' as pressure FROM weather_raw LIMIT 10; -- Как получить поля из джейсонби

SELECT *
FROM weather_raw
WHERE fetched_at > '2025-07-26 23:59:58.628231+00:00'::timestamptz -- как получить поля по таймстампзу
LIMIT 10;

-- Тестируем MVP запрос для перегона данных из raw в аналитику
SELECT *
FROM weather_raw
WHERE point_id = 1
  AND fetched_at >= '2025-07-26 00:00:00.00 +00:00'
  AND fetched_at < '2025-07-27 00:00:00.00 +00:00'
ORDER BY fetched_at DESC;



-- Выбираем все строки с датой 2025-07-26
SELECT DISTINCT on (weather_raw.payload) *,
       TO_TIMESTAMP((weather_raw.payload ->> 'dt')::BIGINT)::DATE AS DT
FROM weather_raw
WHERE TO_TIMESTAMP((weather_raw.payload ->> 'dt')::BIGINT)::DATE = '2025-07-26'
ORDER BY weather_raw.payload, fetched_at;

SELECT *
FROM weather_raw
ORDER BY raw_id
LIMIT 10;

-- point_id
    SELECT weather_raw.point_id FROM weather_raw limit 1;
-- weather_date
SELECT TO_TIMESTAMP((weather_raw.payload -> 'dt')::BIGINT)::DATE AS DT
FROM weather_raw
LIMIT 1;

SELECT DISTINCT raw_id
FROM weather_raw
ORDER BY raw_id
LIMIT 15;


-- Смотрим сколько уникальных джейсонов на день 2025-07-26
SELECT COUNT(*)                            AS total_rows,
       COUNT(DISTINCT weather_raw.payload) AS distinct_jsonb_rows
FROM weather_raw
WHERE TO_TIMESTAMP((weather_raw.payload -> 'dt')::BIGINT)::DATE = '2025-07-26';

-- показываем дупликаты с тамстепсами и номерами точек
WITH duplicated_payloads AS (SELECT payload
                             FROM weather_raw
                             WHERE TO_TIMESTAMP((payload ->> 'dt')::BIGINT)::DATE = '2025-07-26'
                             GROUP BY payload
                             HAVING COUNT(*) > 1)
SELECT weather_raw.payload,
       weather_raw.fetched_at,
       weather_raw.point_id
FROM weather_raw
         JOIN duplicated_payloads ON weather_raw.payload = duplicated_payloads.payload
WHERE TO_TIMESTAMP((weather_raw.payload ->> 'dt')::BIGINT)::DATE = '2025-07-26'
ORDER BY weather_raw.payload, weather_raw.point_id, weather_raw.fetched_at;
-- weather_desc
-- temp
-- feels_like
-- temp_min
-- temp_max
-- pressure
-- humidity
-- sea_level
-- grnd_level
-- visibility
-- wind_speed
-- wind_deg
-- wind_gust


-- Test от GPT

-- Удаляем таблицы, они не получились
DROP TABLE weather_analytics_daily;
DROP TABLE weather_analytics_daily_test;

CREATE TABLE wx_analytics_daily_v1
(
    point_id               INT  NOT NULL REFERENCES grid_points (point_id),
    weather_date           DATE NOT NULL,
    number_of_unique_jsons SMALLINT,
    PRIMARY KEY (point_id, weather_date)
);


-- Надо заполнить табличку новую:
SELECT DISTINCT (TO_TIMESTAMP((weather_raw.payload -> 'dt')::BIGINT)::DATE)
FROM weather_raw
LIMIT 10;

-- Нет нужно только для point_id = 1 AND DATE = 2025-07-26
SELECT *
FROM weather_raw
WHERE point_id = 1
  AND TO_TIMESTAMP((weather_raw.payload -> 'dt')::BIGINT)::DATE = '2025-07-26'
ORDER BY raw_id;

-- Выбрать point_id = 1 AND DATE = 2025-07-26 и количество уникальных json
SELECT COUNT(DISTINCT weather_raw.payload) AS number_of_uq
FROM weather_raw
WHERE point_id = 1
  AND TO_TIMESTAMP((weather_raw.payload -> 'dt')::BIGINT)::DATE = '2025-07-26';

-- Выбрать для всех 600 point_id AND DATE = 2025-07-26 и количество уникальных json
SELECT weather_raw.point_id, COUNT(DISTINCT weather_raw.payload) AS number_of_uq
FROM weather_raw
WHERE TO_TIMESTAMP((weather_raw.payload -> 'dt')::BIGINT)::DATE = '2025-07-26';

-- Парсим все строки из weather_raw в временную табличку от GPT
INSERT INTO wx_analytics_daily_v2(point_id, weather_date, number_of_unique_jsons)
SELECT point_id,
       TO_TIMESTAMP((weather_raw.payload -> 'dt')::BIGINT)::DATE AS weather_date,
       COUNT(DISTINCT weather_raw.payload)                       AS number_of_unique_jsons
FROM weather_raw
GROUP BY point_id, weather_date
ORDER BY weather_date, point_id;

-- Еще одна попытка
CREATE TABLE wx_analytics_daily_v2
(
    point_id               INT      NOT NULL REFERENCES grid_points (point_id),
    weather_date           DATE     NOT NULL,
    number_of_unique_jsons SMALLINT NOT NULL,
    PRIMARY KEY (point_id, weather_date)
);

DROP TABLE wx_analytics_daily_v1;




-- Узнать что в строке raw_id = 605
EXPLAIN
SELECT *
FROM weather_raw
WHERE raw_id = 605
   OR raw_id = 606;


ALTER TABLE wx_analytics_daily_v2
    RENAME COLUMN number_of_unique_jsons TO unique_payload_count;



CREATE TABLE wx_analytics_daily_v3
(
    point_id             INT         NOT NULL REFERENCES grid_points (point_id),
    weather_date         DATE        NOT NULL,
    unique_payload_count SMALLINT    NOT NULL,
    weather_desc         VARCHAR(50) NOT NULL
);

INSERT INTO wx_analytics_daily_v3 (point_id, weather_date, unique_payload_count, weather_desc)
SELECT weather_raw.point_id,
       TO_TIMESTAMP((weather_raw.payload -> 'dt')::BIGINT)::DATE AS weather_date,
       COUNT(DISTINCT weather_raw.payload)                       AS unique_payload_count,
       MODE() WITHIN GROUP (ORDER BY weather_raw.payload -> 'weather' -> 0 ->> 'description')
                                                                 AS weather_desc
FROM weather_raw
GROUP BY point_id, weather_date
ORDER BY weather_date, point_id;


CREATE TABLE wx_analytics_daily_v5
(
    point_id             INT         NOT NULL REFERENCES grid_points (point_id),
    weather_date         DATE        NOT NULL,
    unique_payload_count SMALLINT    NOT NULL,
    weather_desc         VARCHAR(50) NOT NULL,
    temp                 SMALLINT    NOT NULL,
    feels_like           SMALLINT    NOT NULL,
    temp_min             SMALLINT    NOT NULL,
    temp_max             SMALLINT    NOT NULL,
    pressure             SMALLINT    NOT NULL,
    humidity             SMALLINT    NOT NULL,
    sea_level            SMALLINT    NOT NULL,
    grnd_level           SMALLINT    NOT NULL,
    visibility           SMALLINT    NOT NULL,
    wind_speed           SMALLINT    NOT NULL,
    wind_deg             SMALLINT    NOT NULL,
    wind_gust            SMALLINT    NOT NULL,
    clouds SMALLINT NOT NULL,
    PRIMARY KEY (point_id, weather_date)
);

DROP TABLE wx_analytics_daily_v2, wx_analytics_daily_v3;
DROP TABLE wx_analytics_daily_v4;

INSERT INTO wx_analytics_daily_v5 (point_id, weather_date, unique_payload_count, weather_desc, temp, feels_like,
                                   temp_min, temp_max, pressure, humidity, sea_level, grnd_level, visibility,
                                   wind_speed, wind_deg, wind_gust, clouds)
SELECT weather_raw.point_id,
       TO_TIMESTAMP((weather_raw.payload -> 'dt')::BIGINT)::DATE                                AS weather_date,
       COUNT(DISTINCT weather_raw.payload)                                                      AS unique_payload_count,
       MODE() WITHIN GROUP ( ORDER BY weather_raw.payload -> 'weather' -> 0 ->> 'description' ) AS weather_desc,
       AVG((weather_raw.payload -> 'main' ->> 'temp')::NUMERIC)                                 AS temp,
       AVG((weather_raw.payload -> 'main' ->> 'feels_like')::NUMERIC)                           AS feels_like,
       AVG((weather_raw.payload -> 'main' ->> 'temp_min')::NUMERIC)                             AS temp_min,
       AVG((weather_raw.payload -> 'main' ->> 'temp_max')::NUMERIC)                             AS temp_max,
       AVG((weather_raw.payload -> 'main' ->> 'pressure')::NUMERIC)                             AS pressure,
       AVG((weather_raw.payload -> 'main' ->> 'humidity')::NUMERIC)                             AS humidity,
       AVG((weather_raw.payload -> 'main' ->> 'sea_level')::NUMERIC)                            AS sea_level,
       AVG((weather_raw.payload -> 'main' ->> 'grnd_level')::NUMERIC)                           AS grnd_level,
       AVG((weather_raw.payload ->> 'visibility')::NUMERIC)                                     AS visibility,
       AVG((weather_raw.payload -> 'wind' ->> 'speed')::NUMERIC)                                AS wind_speed,
       -- Average wind direction calculation:
       CASE
           WHEN DEGREES(ATAN2(
                   AVG(SIN(RADIANS((weather_raw.payload -> 'wind' ->> 'deg')::NUMERIC))),
                   AVG(COS(RADIANS((weather_raw.payload -> 'wind' ->> 'deg')::NUMERIC)))
                        )) < 0 THEN
               DEGREES(ATAN2(
                       AVG(SIN(RADIANS((weather_raw.payload -> 'wind' ->> 'deg')::NUMERIC))),
                       AVG(COS(RADIANS((weather_raw.payload -> 'wind' ->> 'deg')::NUMERIC)))
                       )) + 360
           ELSE
               DEGREES(ATAN2(
                       AVG(SIN(RADIANS((weather_raw.payload -> 'wind' ->> 'deg')::NUMERIC))),
                       AVG(COS(RADIANS((weather_raw.payload -> 'wind' ->> 'deg')::NUMERIC)))
                       ))
           END                                                                                  AS wind_deg,
       COALESCE(AVG((weather_raw.payload -> 'wind' ->> 'wind_gust')::NUMERIC), 0) AS wind_gust,
       avg(  (weather_raw.payload -> 'clouds' ->> 'all')::NUMERIC) as clouds


FROM weather_raw
GROUP BY point_id, weather_date
ORDER BY weather_date, point_id;


ALTER TABLE wx_analytics_daily_v5
    RENAME TO weather_analytics_daily;