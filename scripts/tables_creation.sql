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
    fetched_at TIMESTAMPTZ NOT NULL,                       -- when We called the API
    payload    JSONB       NOT NULL,                       -- stores the entire JSON response
    CONSTRAINT uq_point_time UNIQUE (point_id, fetched_at) -- No same combination of point_id and fetched_at
);

CREATE TABLE weather_analytics_daily
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


-- Скрипт для заполнения таблицы
INSERT INTO weather_analytics_daily (point_id, weather_date, unique_payload_count, weather_desc, temp, feels_like,
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
       COALESCE(AVG((weather_raw.payload -> 'wind' ->> 'wind_gust')::NUMERIC), 0)               AS wind_gust,
       AVG((weather_raw.payload -> 'clouds' ->> 'all')::NUMERIC)                                AS clouds


FROM weather_raw
GROUP BY point_id, weather_date
ORDER BY weather_date, point_id;


