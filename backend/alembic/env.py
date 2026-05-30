from logging.config import fileConfig

from sqlalchemy import pool
from alembic import context

# Import the engine and metadata directly from the app
from app.database import Base, engine
import app.models  # noqa: F401 — ensure all models are registered

config = context.config
if config.config_file_name is not None:
    fileConfig(config.config_file_name)

target_metadata = Base.metadata

# Tables that belong to SQLite Cloud itself — never touch them with Alembic
_SYSTEM_TABLES = {"_sqliteai_vector", "migrations", "access_tokens"}


def _include_object(obj, name, type_, reflected, compare_to):
    if type_ == "table" and name in _SYSTEM_TABLES:
        return False
    return True


def run_migrations_offline() -> None:
    # For offline mode we still use the same engine URL trick
    context.configure(
        url="sqlite://",
        target_metadata=target_metadata,
        literal_binds=True,
        render_as_batch=True,
    )
    with context.begin_transaction():
        context.run_migrations()


def run_migrations_online() -> None:
    with engine.connect() as connection:
        context.configure(
            connection=connection,
            target_metadata=target_metadata,
            render_as_batch=True,
            include_object=_include_object,
        )
        with context.begin_transaction():
            context.run_migrations()


if context.is_offline_mode():
    run_migrations_offline()
else:
    run_migrations_online()

