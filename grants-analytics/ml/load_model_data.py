import ast
import json
import os
from datetime import datetime, timezone
from pathlib import Path

import pandas as pd
from sqlalchemy import create_engine, text
from sqlalchemy.types import DateTime, Integer, Text


# ======================================================
# 1. Настройки
# ======================================================

CSV_PATH = Path(os.getenv("CSV_PATH", "classification_labeled.csv"))

DB_USER = os.getenv("DB_USER", "username")
DB_PASSWORD = os.getenv("DB_PASSWORD", "password")
DB_HOST = os.getenv("DB_HOST", "localhost")
DB_PORT = os.getenv("DB_PORT", "5432")
DB_NAME = os.getenv("DB_NAME", "dwh")
DB_SCHEMA = os.getenv("DB_SCHEMA", "ml_model")

DATABASE_URL = (
    f"postgresql+psycopg2://{DB_USER}:{DB_PASSWORD}"
    f"@{DB_HOST}:{DB_PORT}/{DB_NAME}"
)

TEXT_COLUMN = "target_groups"
LABELS_COLUMN = "labels"
TARGET_GROUP_ID_COLUMN = "target_group_id"
SOURCE_VALUE = "llm"


# ======================================================
# 2. Справочник категорий 1–38
# ======================================================

categories = [
    (1, "Дети", "Дети дошкольного и младшего возраста, если не указан более конкретный статус."),
    (2, "Подростки", "Подростки и несовершеннолетние примерно 12–17 лет, если не указан более конкретный статус."),
    (3, "Школьники", "Учащиеся школ, лицеев, гимназий, кадетских корпусов и школьных классов."),
    (4, "Студенты", "Обучающиеся колледжей, техникумов, училищ, вузов и университетов."),
    (5, "Молодежь", "Молодые люди примерно 14–35 лет без более конкретного социального статуса."),
    (6, "Молодые специалисты", "Молодые специалисты, выпускники и начинающие профессионалы после получения образования."),
    (7, "Родители и семьи с детьми", "Родители, законные представители и семьи, воспитывающие детей."),
    (8, "Многодетные семьи", "Семьи, воспитывающие трех и более детей."),
    (9, "Семьи участников СВО", "Семьи военнослужащих, мобилизованных и участников специальной военной операции."),
    (10, "Дети-сироты и дети без попечения родителей", "Дети-сироты, дети без попечения родителей, воспитанники и выпускники детских домов."),
    (11, "Люди с инвалидностью и ОВЗ", "Люди с инвалидностью, ограниченными возможностями здоровья, ментальными, сенсорными, двигательными и иными нарушениями."),
    (12, "Пожилые люди", "Пенсионеры, граждане старшего возраста и представители старшего поколения."),
    (13, "Ветераны", "Ветераны труда, ветераны боевых действий и другие категории ветеранов."),
    (14, "Военнослужащие и участники СВО", "Военнослужащие, мобилизованные, участники СВО и участники боевых действий."),
    (15, "Люди в трудной жизненной ситуации", "Люди, находящиеся в трудной жизненной ситуации, малоимущие и социально уязвимые группы населения."),
    (16, "Люди с зависимостями", "Люди с алкогольной, наркотической и другими формами зависимости."),
    (17, "Люди без определенного места жительства", "Бездомные люди и лица без постоянного места проживания."),
    (18, "Медицинские пациенты и люди с хроническими заболеваниями", "Пациенты медицинских учреждений, люди с хроническими заболеваниями, ВИЧ-положительным статусом и нуждающиеся в реабилитации."),
    (19, "Мигранты и переселенцы", "Мигранты, иностранные граждане, беженцы и вынужденные переселенцы."),
    (20, "Лица в местах лишения свободы", "Осужденные, заключенные, лица в исправительных учреждениях и люди после освобождения."),
    (21, "Жители территорий и местных сообществ", "Жители городов, районов, муниципалитетов, регионов и локальных сообществ."),
    (22, "Жители сельских территорий", "Жители сел, деревень, поселков и сельских территорий."),
    (23, "Женщины", "Женщины и женские сообщества как самостоятельная целевая аудитория."),
    (24, "Педагоги и наставники", "Учителя, воспитатели, преподаватели, наставники и другие педагогические работники."),
    (25, "Специалисты социальной сферы", "Социальные работники, специалисты служб помощи, психологи, кураторы и специалисты сопровождения."),
    (26, "Специалисты и руководители", "Профессионалы различных отраслей, руководители организаций, управленцы и профильные специалисты."),
    (27, "Ученые и эксперты", "Ученые, исследователи, эксперты, аналитики и представители экспертного сообщества."),
    (28, "Волонтеры и общественные активисты", "Волонтеры, добровольцы, активисты и участники общественно полезной деятельности."),
    (29, "Представители НКО", "Сотрудники, руководители, активисты и участники некоммерческих организаций."),
    (30, "Предприниматели и самозанятые", "Предприниматели, представители бизнеса, самозанятые и начинающие предприниматели."),
    (31, "Культурные и творческие сообщества", "Деятели культуры, искусства, творческие коллективы, ремесленники, дизайнеры и представители креативных индустрий."),
    (32, "Спортсмены и участники ЗОЖ", "Спортсмены, физкультурники, участники спортивных секций и проектов здорового образа жизни."),
    (33, "Туристы", "Туристы, путешественники и участники туристических маршрутов и инициатив."),
    (34, "Читатели и библиотечная аудитория", "Читатели, посетители библиотек, любители чтения и участники литературных проектов."),
    (35, "Экологические сообщества", "Экологи, природоохранные активисты, участники экологических движений и инициатив."),
    (36, "СМИ и медиа", "Журналисты, редакторы, блогеры, сотрудники СМИ и представители медиа-сообщества."),
    (37, "Представители национальных, этнокультурных и казачьих сообществ", "Национальные общины, этнокультурные объединения, коренные народы и казачьи общества."),
    (38, "Широкая аудитория", "Население, граждане, жители региона или широкая общественность без выделения конкретной социальной группы."),
]

categories_df = pd.DataFrame(
    categories,
    columns=["category_id", "category_name", "category_description"]
)

categories_df["keywords"] = ""

valid_category_ids = set(categories_df["category_id"])


# ======================================================
# 3. Загрузка CSV
# ======================================================

if not CSV_PATH.exists():
    raise FileNotFoundError(
        f"CSV-файл не найден: {CSV_PATH.resolve()}. "
        "Положите classification_labeled.csv рядом со скриптом "
        "или передайте путь через переменную окружения CSV_PATH."
    )

df = pd.read_csv(CSV_PATH)

required_columns = {TEXT_COLUMN, LABELS_COLUMN}
missing_columns = required_columns - set(df.columns)

if missing_columns:
    raise ValueError(
        "В CSV нет обязательных столбцов: "
        + ", ".join(sorted(missing_columns))
        + f". Найдены столбцы: {list(df.columns)}"
    )


# ======================================================
# 4. Подготовка labels
# ======================================================

def parse_labels(value):
    if pd.isna(value):
        return []

    if isinstance(value, list):
        raw_labels = value
    else:
        value = str(value).strip()

        if value == "" or value == "[]":
            return []

        try:
            raw_labels = json.loads(value)
        except json.JSONDecodeError:
            try:
                raw_labels = ast.literal_eval(value)
            except (SyntaxError, ValueError):
                return []

    if not isinstance(raw_labels, list):
        return []

    parsed_labels = []

    for item in raw_labels:
        try:
            parsed_labels.append(int(item))
        except (TypeError, ValueError):
            continue

    return sorted(set(parsed_labels))


df[LABELS_COLUMN] = df[LABELS_COLUMN].apply(parse_labels)

invalid_labels = sorted(
    {
        category_id
        for labels in df[LABELS_COLUMN]
        for category_id in labels
        if category_id not in valid_category_ids
    }
)

if invalid_labels:
    raise ValueError(
        "В CSV найдены labels, которых нет в справочнике категорий: "
        + ", ".join(map(str, invalid_labels))
    )


# ======================================================
# 5. Таблица target_groups
# ======================================================

if TARGET_GROUP_ID_COLUMN not in df.columns:
    df[TARGET_GROUP_ID_COLUMN] = range(1, len(df) + 1)

if df[TARGET_GROUP_ID_COLUMN].duplicated().any():
    raise ValueError(f"В столбце {TARGET_GROUP_ID_COLUMN} есть дубли ID.")

now = datetime.now(timezone.utc).replace(tzinfo=None)

target_groups_df = df[[TARGET_GROUP_ID_COLUMN, TEXT_COLUMN]].copy()

target_groups_df = target_groups_df.rename(
    columns={
        TARGET_GROUP_ID_COLUMN: "target_group_id",
        TEXT_COLUMN: "target_group_text",
    }
)

target_groups_df["target_group_text"] = (
    target_groups_df["target_group_text"]
    .fillna("")
    .astype(str)
)

target_groups_df["created_at"] = now


# ======================================================
# 6. Связующая таблица target_group_category_links
# ======================================================

link_rows = []

for _, row in df.iterrows():
    target_group_id = int(row[TARGET_GROUP_ID_COLUMN])

    for category_id in row[LABELS_COLUMN]:
        link_rows.append(
            {
                "target_group_id": target_group_id,
                "category_id": int(category_id),
                "source": "llm",
                "created_at": now,
            }
        )

links_df = pd.DataFrame(
    link_rows,
    columns=["target_group_id", "category_id", "source", "created_at"],
)


# ======================================================
# 7. Подключение к PostgreSQL
# ======================================================

engine = create_engine(DATABASE_URL)


# ======================================================
# 8. Создание схемы и таблиц
# ======================================================

create_tables_sql = f"""
CREATE SCHEMA IF NOT EXISTS {DB_SCHEMA};

CREATE TABLE IF NOT EXISTS {DB_SCHEMA}.target_groups (
    target_group_id INTEGER PRIMARY KEY,
    target_group_text TEXT NOT NULL,
    created_at TIMESTAMP
);

CREATE TABLE IF NOT EXISTS {DB_SCHEMA}.audience_categories (
    category_id INTEGER PRIMARY KEY,
    category_name TEXT NOT NULL,
    category_description TEXT,
    keywords TEXT
);

CREATE TABLE IF NOT EXISTS {DB_SCHEMA}.target_group_category_links (
    target_group_id INTEGER NOT NULL,
    category_id INTEGER NOT NULL,
    source TEXT,
    created_at TIMESTAMP,
    PRIMARY KEY (target_group_id, category_id),
    FOREIGN KEY (target_group_id)
        REFERENCES {DB_SCHEMA}.target_groups(target_group_id)
        ON DELETE CASCADE,
    FOREIGN KEY (category_id)
        REFERENCES {DB_SCHEMA}.audience_categories(category_id)
        ON DELETE CASCADE
);
"""

with engine.begin() as conn:
    conn.execute(text(create_tables_sql))


# ======================================================
# 9. Очистка и загрузка данных
# ======================================================

with engine.begin() as conn:
    conn.execute(
        text(
            f"""
            TRUNCATE TABLE
                {DB_SCHEMA}.target_group_category_links,
                {DB_SCHEMA}.target_groups,
                {DB_SCHEMA}.audience_categories
            RESTART IDENTITY CASCADE;
            """
        )
    )

categories_df.to_sql(
    "audience_categories",
    engine,
    schema=DB_SCHEMA,
    if_exists="append",
    index=False,
    dtype={
        "category_id": Integer(),
        "category_name": Text(),
        "category_description": Text(),
        "keywords": Text(),
    },
)

target_groups_df.to_sql(
    "target_groups",
    engine,
    schema=DB_SCHEMA,
    if_exists="append",
    index=False,
    dtype={
        "target_group_id": Integer(),
        "target_group_text": Text(),
        "created_at": DateTime(),
    },
)

if not links_df.empty:
    links_df.to_sql(
        "target_group_category_links",
        engine,
        schema=DB_SCHEMA,
        if_exists="append",
        index=False,
        dtype={
            "target_group_id": Integer(),
            "category_id": Integer(),
            "source": Text(),
            "created_at": DateTime(),
        },
    )


# ======================================================
# 10. Проверка
# ======================================================

with engine.begin() as conn:
    target_count = conn.execute(
        text(f"SELECT COUNT(*) FROM {DB_SCHEMA}.target_groups")
    ).scalar()

    category_count = conn.execute(
        text(f"SELECT COUNT(*) FROM {DB_SCHEMA}.audience_categories")
    ).scalar()

    link_count = conn.execute(
        text(f"SELECT COUNT(*) FROM {DB_SCHEMA}.target_group_category_links")
    ).scalar()

print("Готово!")
print(f"CSV-файл: {CSV_PATH.resolve()}")
print(f"Строк в исходном CSV: {len(df):,}")
print(f"target_groups: {target_count:,}")
print(f"audience_categories: {category_count:,}")
print(f"target_group_category_links: {link_count:,}")