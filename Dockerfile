# Stage 1: Build stage
FROM python:3.12-slim AS build-stage

# Set the working directory
WORKDIR /app

# Install Poetry and dependencies for private PyPI
RUN pip install poetry

# Add Poetry configuration for private PyPI (using build arguments for secrets)
ARG POETRY_HTTP_BASIC_NUCLEUS_USERNAME
ARG POETRY_HTTP_BASIC_NUCLEUS_PASSWORD
# ENV POETRY_HTTP_BASIC_DUMMYPYPI_USERNAME=${POETRY_HTTP_BASIC_DUMMYPYPI_USERNAME}
# ENV POETRY_HTTP_BASIC_DUMMYPYPI_PASSWORD=${POETRY_HTTP_BASIC_DUMMYPYPI_PASSWORD}

# RUN echo $POETRY_HTTP_BASIC_NUCLEUS_USERNAME

# Copy the pyproject.toml and poetry.lock to configure dependencies
COPY pyproject.toml poetry.lock /app/

# Install dependencies (without dev dependencies)
RUN poetry install --no-root --no-interaction --no-ansi

# Stage 2: Final stage
FROM python:3.12-slim AS final-stage

# Set the working directory for the final stage
WORKDIR /app

# Copy the necessary files from the build stage (without sensitive build data)
COPY --from=build-stage /app /app

# Expose the port your app runs on
EXPOSE 8888

# Set environment variables for the application
ENV LOGLEVEL="DEBUG"
ENV PORT=8888
ENV HOST=0.0.0.0

# Run the application using Poetry and Uvicorn
CMD ["poetry", "run", "uvicorn", "app.main:app", "--host", "0.0.0.0", "--port", "8888", "--header", "servicename:my_service", "--lifespan", "on"]
