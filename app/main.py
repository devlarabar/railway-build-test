"""The main point of entry into the app."""


from fastapi import FastAPI
from fastapi.responses import JSONResponse
from zoho_clients.zoho_crm import ZohoCRMClient


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
    zoho_crm = ZohoCRMClient(
        refresh_token="123",
        client_id="123",
        client_secret="123",
        base_url="https://example.com",
        zoho_accounts_url="https://example.com",
    )
    print(zoho_crm.log_id)
    return JSONResponse(status_code=200, content={"message": "Success"})
