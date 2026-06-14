import os

# Включаем поддержку переводов
SUPERSET_BABEL_KEEP_TRANSLATIONS = True

# Устанавливаем русский язык по умолчанию
BABEL_DEFAULT_LOCALE = "ru"

# Список доступных языков в выпадающем меню
LANGUAGES = {
    "en": {"flag": "us", "name": "English"},
    "ru": {"flag": "ru", "name": "Russian"},
}