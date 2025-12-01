import psycopg2

def get_connection():
    conn = psycopg2.connect(
        host="localhost",
        port=5432,
        dbname="FCKPS",
        user="postgres",      
        password="password"
    )
    return conn
