import os

import psycopg
from psycopg import sql

from app import create_app, db


def main():
    username = os.environ["APP_DB_USERNAME"]
    password = os.environ["APP_DB_PASSWORD"]

    if username != "ticket_app":
        raise RuntimeError("The application username must be ticket_app.")

    connection_settings = {
        "host": os.environ["DB_HOST"],
        "port": int(os.environ["DB_PORT"]),
        "dbname": os.environ["DB_NAME"],
        "sslmode": os.environ["DB_SSLMODE"],
        "sslrootcert": os.environ["DB_SSLROOTCERT"],
    }

    # Use the administrator credentials only for setup.
    with psycopg.connect(
        **connection_settings,
        user=os.environ["DB_USERNAME"],
        password=os.environ["DB_PASSWORD"],
    ) as connection:
        with connection.cursor() as cursor:
            cursor.execute(
                "SELECT 1 FROM pg_roles WHERE rolname = %s",
                (username,),
            )

            if cursor.fetchone() is None:
                cursor.execute(
                    sql.SQL("CREATE ROLE {} LOGIN PASSWORD {}").format(
                        sql.Identifier(username),
                        sql.Literal(password),
                    )
                )
            else:
                cursor.execute(
                    sql.SQL("ALTER ROLE {} LOGIN PASSWORD {}").format(
                        sql.Identifier(username),
                        sql.Literal(password),
                    )
                )

           

            cursor.execute(
                "REVOKE CREATE ON SCHEMA public FROM PUBLIC"
            )

    # Create the table using the administrator connection.
    application = create_app()

    with application.app_context():
        db.create_all()
        db.session.remove()
        db.engine.dispose()

    # Give the application only the access needed for tickets.
    with psycopg.connect(
        **connection_settings,
        user=os.environ["DB_USERNAME"],
        password=os.environ["DB_PASSWORD"],
    ) as connection:
        with connection.cursor() as cursor:
            cursor.execute(
                sql.SQL("GRANT CONNECT ON DATABASE {} TO {}").format(
                    sql.Identifier(os.environ["DB_NAME"]),
                    sql.Identifier(username),
                )
            )
            cursor.execute(
                sql.SQL("GRANT USAGE ON SCHEMA public TO {}").format(
                    sql.Identifier(username)
                )
            )
            cursor.execute(
                sql.SQL(
                    "GRANT SELECT, INSERT, UPDATE "
                    "ON TABLE public.ticket TO {}"
                ).format(sql.Identifier(username))
            )
            cursor.execute(
                sql.SQL(
                    "GRANT USAGE, SELECT "
                    "ON SEQUENCE public.ticket_id_seq TO {}"
                ).format(sql.Identifier(username))
            )

    # Verify the application credentials. Roll back the sample ticket.
    with psycopg.connect(
        **connection_settings,
        user=username,
        password=password,
    ) as connection:
        try:
            with connection.cursor() as cursor:
                cursor.execute(
                    """
                    INSERT INTO public.ticket
                        (title, description, status, created_at)
                    VALUES (%s, %s, %s, CURRENT_TIMESTAMP)
                    RETURNING id
                    """,
                    ("Setup verification", "Temporary ticket", "Open"),
                )
                ticket_id = cursor.fetchone()[0]

                cursor.execute(
                    "UPDATE public.ticket SET status = %s WHERE id = %s",
                    ("Resolved", ticket_id),
                )
                cursor.execute(
                    "SELECT status FROM public.ticket WHERE id = %s",
                    (ticket_id,),
                )

                if cursor.fetchone()[0] != "Resolved":
                    raise RuntimeError("Database verification failed.")
        finally:
            connection.rollback()

    print("Database setup succeeded. Application access verified.")


if __name__ == "__main__":
    main()