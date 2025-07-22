import math
import csv

n = 600  # free API allows only 600 unique places


def fibonacci_grid(n, save_csv=False, csv_filename="grid_points.csv"):
    """
    Computes Longitudes and Latitudes for points
    with almost equal spacing on globe sphere.
    :param n: number of points in grid system
    :return: list of dicts with keys 'id', 'lat', 'lon', CSV if save_csv=True
    """
    phi = (1 + math.sqrt(5)) / 2  # the golden ratio

    golden_angle = 2 * math.pi * (1 - 1 / phi)  # ≃2.39996 rad

    points = []
    for k in range(n):
        z_k = 1 - 2 * k / (n - 1)  # Equal stepping from +1 to -1 for n points
        lat_k = math.asin(z_k)  # latitude, rad
        lon_k = (golden_angle * k) % (2 * math.pi)  # longitude, rad
        # convert to degrees
        lat_deg = math.degrees(lat_k)
        lon_deg = math.degrees(lon_k) - 180
        points.append({"lat": lat_deg, "lon": lon_deg})  # dont need id here
    if save_csv:
        with open(csv_filename, "w", newline="") as file:
            writer = csv.DictWriter(file, fieldnames=["lat", "lon"])
            writer.writeheader()
            writer.writerows(points)

    return points


if __name__ == "__main__":
    standard_grid = fibonacci_grid(n, save_csv=True)
    print(standard_grid)
