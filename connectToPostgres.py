import psycopg2

def get_connection():
    try:
        connection = psycopg2.connect(
            host="localhost",
            port=5432,
            database="mydatabase",
            user="myuser",
            password="mypassword"
        )
        return connection
    except Exception as e:
        print("Database connection error:", e)
        return None
