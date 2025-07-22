import pandas as pd


def save_to_csv(data, filename):
    """
    Преобразует словарь в таблицу csv
    :param data: список словарей вида:
    [{Параметр1: Значение1, Параметр2: Значение2}]
    :param filename: Название файла
    :return: просто сохраняет файл
    """
    try:
        df = pd.DataFrame(data)
        df.to_csv(path_or_buf=filename, index=False, encoding="utf-8")
        print(f"Dataframe сохранен в {filename}")
    except Exception as e:
        print(e)
