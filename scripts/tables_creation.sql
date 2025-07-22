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