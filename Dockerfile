# Stage 1: Build stage
FROM python:3.12-slim AS build-stage

# Set the working directory
WORKDIR /app

# Install Poetry
RUN pip install poetry

# Configure Nucleus
ARG POETRY_HTTP_BASIC_NUCLEUS_USERNAME
ARG POETRY_HTTP_BASIC_NUCLEUS_PASSWORD

ARG POETRY_HTTP_BASIC_DUMMYPYPI_USERNAME
RUN echo $POETRY_HTTP_BASIC_DUMMYPYPI_USERNAME

# Copy the pyproject.toml and poetry.lock to configure dependencies
COPY pyproject.toml poetry.lock /app/

# Install dependencies
RUN poetry install --no-root --no-interaction --no-ansi

# Stage 2: Final stage
FROM python:3.12-slim AS final-stage

# Set the working directory for the final stage
WORKDIR /app

# Copy the necessary files from the build stage (without sensitive build data)
COPY --from=build-stage /app /app

# Expose the port and set environment variables
EXPOSE 8888
ENV LOGLEVEL="DEBUG"
ENV PORT=8888
ENV HOST=0.0.0.0

RUN echo $POETRY_HTTP_BASIC_DUMMYPYPI_USERNAME

# Install Poetry (again), because it's not accessible here from the first stage
RUN pip install poetry

# Run the app
CMD poetry run uvicorn app.main:app --host $HOST --port $PORT --header servicename:railway-build-test --lifespan on
