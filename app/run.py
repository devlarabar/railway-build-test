import os
from pathlib import Path
from subprocess import run
from dotenv import load_dotenv
from passlib.apache import HtpasswdFile

load_dotenv(override=True)

username = os.getenv("POETRY_HTTP_BASIC_NUCLEUS_USERNAME")
password = os.getenv("POETRY_HTTP_BASIC_NUCLEUS_PASSWORD")

if username and password:
    ht = HtpasswdFile("/auth/.htpasswd", new=True)  # Set credentials dynamically
    ht.set_password(username, password)  # Password is hashed automatically
    ht.save()

    AUTH_DIR = Path("/auth")
    if not AUTH_DIR.is_dir():
        AUTH_DIR.mkdir()

    run([
        "--mount=type=secret,id=auth_file,required,dst=/root/.config/pypoetry/.htpasswd poetry install -vvv --no-ansi",
        "poetry", "run", "app.main:app", "--host", "0.0.0.0", "--port", "8888"
    ])

else:
    raise RuntimeError("Authentication credentials are missing.")
