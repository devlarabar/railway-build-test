# Base image
FROM python:3.12-slim

WORKDIR /app

# Install Poetry and dependencies
RUN pip install poetry
COPY pyproject.toml poetry.lock /app/
# Add a package source and configure its authentication credentials
# RUN poetry source add --priority=explicit nucleus https://ion8-nucleus.up.railway.app/
# These will be injected by Railway at build time:
# https://docs.railway.com/guides/dockerfiles#using-variables-at-build-time
# ARG POETRY_HTTP_BASIC_DUMMY_USERNAME
# ARG POETRY_HTTP_BASIC_DUMMY_PASSWORD
# RUN poetry config http-basic.dummypypi $POETRY_HTTP_BASIC_DUMMY_USERNAME $POETRY_HTTP_BASIC_DUMMY_PASSWORD
# Install dependencies
ENV POETRY_HTTP_BASIC_NUCLEUS_USERNAME=${POETRY_HTTP_BASIC_NUCLEUS_USERNAME}
ENV POETRY_HTTP_BASIC_NUCLEUS_PASSWORD=${POETRY_HTTP_BASIC_NUCLEUS_PASSWORD}

RUN poetry config --list
RUN poetry lock
RUN poetry install --no-root --no-interaction --no-ansi -vvv

# Copy the whole project into the container
COPY . /app

# The container will run in this port
EXPOSE 8888

# Set environment variables for app
ENV LOGLEVEL="DEBUG"
ENV PORT=8888
ENV HOST=0.0.0.0

# Run the container
CMD ["poetry", "run", "app.main:app", "--host", "0.0.0.0", "--port", "8888"]
