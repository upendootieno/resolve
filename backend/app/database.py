import sqlitecloud
from sqlalchemy import create_engine
from sqlalchemy.orm import DeclarativeBase, Session, sessionmaker

from app.config import get_settings

settings = get_settings()


def _creator():
    """Return a patched sqlitecloud DBAPI connection compatible with SQLAlchemy's sqlite dialect."""
    conn = sqlitecloud.connect(settings.database_url)

    # SQLAlchemy's pysqlite dialect tries to register a REGEXP helper function
    # using create_function(), which sqlitecloud does not support at all.
    # Make it a silent no-op — we don't use REGEXP in any queries.
    conn.create_function = lambda *args, **kwargs: None
    return conn


# Use SQLite dialect (syntax-compatible) with a sqlitecloud DBAPI creator.
engine = create_engine("sqlite://", creator=_creator, echo=settings.debug)
SessionLocal = sessionmaker(bind=engine, autocommit=False, autoflush=False)


class Base(DeclarativeBase):
    pass


def get_db() -> Session:  # type: ignore[override]
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()


class Base(DeclarativeBase):
    pass


def get_db() -> Session:  # type: ignore[override]
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()
