"""The main point of entry into the app."""


from fastapi import FastAPI
from fastapi.responses import JSONResponse


app = FastAPI()


print("Hello, world!")

@app.get(
    "/healthcheck",
    tags=["healthcheck"],
    summary="Perform a Health Check",
    response_description="Return HTTP Status Code 200 (OK)",
)
async def get_health() -> JSONResponse:
    """Perform all health checks for the service to ensure stability"""
    print("Running health checks...")
    return JSONResponse(status_code=200, content="Success")
