import os

import pytest
from dotenv import load_dotenv
from sqlalchemy import make_url, select

from app import Ticket, create_app, db


@pytest.fixture()
def application():
    load_dotenv()
    test_url = os.getenv("TEST_DATABASE_URL")

    if not test_url:
        raise RuntimeError("TEST_DATABASE_URL is missing.")

    # Only allow table deletion in the dedicated local test database.
    parsed_url = make_url(test_url)

    if (
        parsed_url.database != "tickets_test"
        or parsed_url.host not in {"localhost", "127.0.0.1"}
        or parsed_url.get_backend_name() != "postgresql"
    ):
        raise RuntimeError("Tests must use the local tickets_test database.")

    app = create_app({
        "TESTING": True,
        "SQLALCHEMY_DATABASE_URI": test_url,
    })

    with app.app_context():
        db.drop_all()
        db.create_all()

    yield app

    with app.app_context():
        db.session.remove()
        db.drop_all()
        db.engine.dispose()


@pytest.fixture()
def client(application):
    return application.test_client()


def test_create_valid_ticket(client, application):
    response = client.post("/tickets", data={
        "title": "Cannot access email",
        "description": "Login fails.",
    })

    assert response.status_code == 303

    with application.app_context():
        tickets = db.session.execute(select(Ticket)).scalars().all()

        assert len(tickets) == 1
        assert tickets[0].title == "Cannot access email"
        assert tickets[0].description == "Login fails."
        assert tickets[0].status == "Open"
        assert tickets[0].created_at is not None

    page = client.get("/")
    assert b"Cannot access email" in page.data


def test_reject_empty_title(client, application):
    response = client.post("/tickets", data={
        "title": "   ",
        "description": "This should not be saved.",
    })

    assert response.status_code == 400
    assert b"Title is required" in response.data

    with application.app_context():
        tickets = db.session.execute(select(Ticket)).scalars().all()
        assert tickets == []


def test_resolve_existing_ticket(client, application):
    client.post("/tickets", data={
        "title": "Printer problem",
        "description": "Printer is offline.",
    })

    with application.app_context():
        ticket = db.session.execute(select(Ticket)).scalar_one()
        ticket_id = ticket.id

    response = client.post(f"/tickets/{ticket_id}/resolve")

    assert response.status_code == 303

    with application.app_context():
        ticket = db.session.get(Ticket, ticket_id)
        assert ticket.status == "Resolved"

    page = client.get("/")
    assert b"Resolved" in page.data