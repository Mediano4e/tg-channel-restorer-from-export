# Базовый образ с Python 3.10
FROM python:3.10-slim-bullseye as python-base

# Настройки окружения для Python и Poetry
ENV PYTHONUNBUFFERED=1 \
    PYTHONDONTWRITEBYTECODE=1 \
    \
    PIP_NO_CACHE_DIR=off \
    PIP_DISABLE_PIP_VERSION_CHECK=on \
    PIP_DEFAULT_TIMEOUT=100 \
    \
    POETRY_VERSION=1.8.2 \
    POETRY_HOME="/opt/poetry" \
    POETRY_VIRTUALENVS_IN_PROJECT=true \
    POETRY_NO_INTERACTION=1 \
    \
    PYSETUP_PATH="/opt/pysetup" \
    VENV_PATH="/opt/pysetup/.venv"

ENV PATH="$POETRY_HOME/bin:$VENV_PATH/bin:$PATH"

# Этап сборки: устанавливаем необходимые пакеты и Poetry
FROM python-base as builder-base

RUN apt-get update \
    && apt-get install --no-install-recommends -y \
        curl \
        build-essential \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Установка Poetry
RUN curl -sSL https://install.python-poetry.org | python3 -

# Установка зависимостей через Poetry
WORKDIR $PYSETUP_PATH
COPY poetry.lock pyproject.toml ./
RUN poetry install --only main --no-root

# Production слой
FROM python-base as production

# Копируем установленные зависимости из builder-слоя
COPY --from=builder-base $PYSETUP_PATH $PYSETUP_PATH

# Копируем исходный код проекта
COPY . /tg_bot/
WORKDIR /tg_bot

# Запуск бота
CMD ["python", "main.py"]
