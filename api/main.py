import mysql.connector
from mysql.connector import pooling
import os
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import JSONResponse
from pydantic import BaseModel

app = FastAPI()

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

db_config = {
    "database": os.getenv("MYSQL_DATABASE"),
    "user": os.getenv("MYSQL_USER"),
    "password": os.getenv("MYSQL_ROOT_PASSWORD"),
    "host": os.getenv("MYSQL_HOST"),
    "port": 3306,
}

pool = pooling.MySQLConnectionPool(pool_name="mypool", pool_size=5, **db_config)


class UserCreate(BaseModel):
    firstName: str
    lastName: str
    email: str
    birthDate: str = ""
    zip: str = ""
    city: str = ""


@app.get("/health")
async def health():
    return {"status": "ok"}


@app.get("/users")
async def get_users():
    conn = pool.get_connection()
    try:
        cursor = conn.cursor(dictionary=True)
        cursor.execute("SELECT * FROM utilisateur")
        records = cursor.fetchall()
        users = [
            {
                "firstName": r["prenom"],
                "lastName": r["nom"],
                "email": r["email"],
                "birthDate": r.get("date_naissance") or "",
                "zip": r.get("code_postal") or "",
                "city": r.get("ville") or "",
            }
            for r in records
        ]
        return {"users": users}
    finally:
        conn.close()


@app.post("/users", status_code=201)
async def create_user(user: UserCreate):
    conn = pool.get_connection()
    try:
        cursor = conn.cursor()
        cursor.execute("SELECT id FROM utilisateur WHERE email = %s", (user.email,))
        if cursor.fetchone():
            return JSONResponse(
                status_code=400, content={"message": "EMAIL_ALREADY_EXISTS"}
            )

        cursor.execute(
            "INSERT INTO utilisateur (nom, prenom, email, date_naissance, code_postal, ville) VALUES (%s, %s, %s, %s, %s, %s)",
            (
                user.lastName,
                user.firstName,
                user.email,
                user.birthDate or None,
                user.zip,
                user.city,
            ),
        )
        conn.commit()
        return {
            "firstName": user.firstName,
            "lastName": user.lastName,
            "email": user.email,
            "birthDate": user.birthDate,
            "zip": user.zip,
            "city": user.city,
        }
    finally:
        conn.close()
