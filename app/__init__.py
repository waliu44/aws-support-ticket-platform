import os
from datetime import datetime, timezone

import click
from dotenv import load_dotenv
from flask import Flask, jsonify, redirect, render_template, request, url_for
from flask_sqlalchemy import SQLAlchemy
from sqlalchemy import select

db = SQLAlchemy()


class Ticket(db.Model):
    id = db.Column(db.Integer, primary_key=True)
    title = db.Column(db.String(150), nullable=False)
    description = db.Column(db.Text, nullable=False, default="")
    status = db.Column(db.String(20), nullable=False, default="Open")
    created_at = db.Column(
        db.DateTime(timezone=True),
        nullable=False,
        default=lambda: datetime.now(timezone.utc),
    )


def create_app(test_config=None):
    load_dotenv()

    app = Flask(__name__)

    app.config["SQLALCHEMY_DATABASE_URI"] = os.getenv("DATABASE_URL")
    app.config["SQLALCHEMY_TRACK_MODIFICATIONS"] = False

    if test_config:
        app.config.update(test_config)

    if not app.config["SQLALCHEMY_DATABASE_URI"]:
        raise RuntimeError("DATABASE_URL is missing. Check your .env file.")

    db.init_app(app)

    @app.get("/")
    def index():
        tickets = db.session.execute(
            select(Ticket).order_by(Ticket.created_at.desc(), Ticket.id.desc())
        ).scalars().all()

        return render_template("index.html", tickets=tickets)

    @app.post("/tickets")
    def create_ticket():
        title = request.form.get("title", "").strip()
        description = request.form.get("description", "").strip()

        if not title:
            return "Title is required.", 400

        if len(title) > 150:
            return "Title must be 150 characters or fewer.", 400

        ticket = Ticket(title=title, description=description)
        db.session.add(ticket)
        db.session.commit()

        return redirect(url_for("index"), code=303)

    @app.post("/tickets/<int:ticket_id>/resolve")
    def resolve_ticket(ticket_id):
        ticket = db.get_or_404(Ticket, ticket_id)
        ticket.status = "Resolved"
        db.session.commit()

        return redirect(url_for("index"), code=303)

    @app.get("/health")
    def health():
        return jsonify(status="ok"), 200

    @app.cli.command("init-db")
    def init_db():
        db.create_all()
        click.echo("Database tables created.")

    return app