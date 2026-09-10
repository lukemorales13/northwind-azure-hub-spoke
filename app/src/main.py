from flask import Flask

# Use package-relative imports so `src` can be imported when `app` is on PYTHONPATH
from . import config
from .routes.health import health_bp


def create_app():
    app = Flask(__name__, template_folder="templates")
    app.secret_key = config.FLASK_SECRET_KEY
    app.register_blueprint(health_bp)
    return app


app = create_app()

if __name__ == "__main__":
    app.run(debug=True, host="0.0.0.0", port=5000)
