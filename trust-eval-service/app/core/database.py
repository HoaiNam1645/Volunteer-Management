import mysql.connector
from mysql.connector import pooling
from contextlib import contextmanager
from app.config import get_settings

settings = get_settings()

_db_pool = None


def get_db_pool():
    global _db_pool
    if _db_pool is None:
        _db_pool = pooling.MySQLConnectionPool(
            pool_name="trust_eval_pool",
            pool_size=5,
            pool_reset_session=True,
            host=settings.db_host,
            port=settings.db_port,
            database=settings.db_database,
            user=settings.db_username,
            password=settings.db_password,
            charset=settings.db_charset,
            collation="utf8mb4_unicode_ci",
            autocommit=False,
        )
    return _db_pool


@contextmanager
def get_db_connection():
    pool = get_db_pool()
    conn = pool.get_connection()
    try:
        yield conn
        conn.commit()
    except Exception:
        conn.rollback()
        raise
    finally:
        conn.close()


@contextmanager
def get_db_cursor(dictionary: bool = True, commit: bool = True):
    with get_db_connection() as conn:
        cursor = conn.cursor(dictionary=dictionary)
        try:
            yield cursor
            if commit:
                conn.commit()
        finally:
            cursor.close()


def test_connection() -> dict:
    try:
        with get_db_cursor(commit=False) as cursor:
            cursor.execute("SELECT 1 as test")
            result = cursor.fetchone()
            return {"success": True, "data": result}
    except Exception as e:
        return {"success": False, "error": str(e)}
