import shutil
from pathlib import Path
from datetime import datetime


def move_file_with_datetime(
    source_path: str, 
    destination_dir: str, 
    process_time: datetime
) -> None:
    src = Path(source_path)
    dest_folder = Path(destination_dir)

    # Проверяем существование исходного файла
    if not src.is_file():
        raise FileNotFoundError(f"Исходный файл не найден: {source_path}")

    # Создаем целевую директорию, если её нет
    dest_folder.mkdir(parents=True, exist_ok=True)

    # Форматируем datetime в строку (пример: 2026_06_07_16_58_00)
    time_str = process_time.strftime("%Y_%m_%d_%H_%M_%S")

    # Формируем новое имя файла: "имя_дата_время.расширение"
    new_filename = f"{src.stem}_{time_str}{src.suffix}"

    # Собираем полный целевой путь и перемещаем
    final_destination = dest_folder / new_filename
    shutil.move(str(src), str(final_destination))
    
    print(f"Parquet-файл успешно перемещен в: {final_destination}")


