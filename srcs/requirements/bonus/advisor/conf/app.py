from flask import Flask, jsonify

app = Flask(__name__)

SERVICES = [
    "Nginx",
    "WordPress",
    "MariaDB",
    "Redis",
    "FTP",
    "Adminer",
    "Static Website",
    "Advisor"
]


@app.route("/", methods=["GET"])
def home():
    return """
    <!DOCTYPE html>
    <html lang="fr">
    <head>
        <meta charset="UTF-8">
        <meta name="viewport" content="width=device-width, initial-scale=1.0">
        <title>Inception Advisor</title>
        <style>
            body {
                font-family: Arial, sans-serif;
                background: #f2f4f8;
                margin: 0;
                padding: 40px 20px;
                color: #222;
            }
            main {
                max-width: 650px;
                margin: auto;
                background: white;
                padding: 30px;
                border-radius: 12px;
                box-shadow: 0 4px 15px rgba(0,0,0,0.08);
            }
            h1 {
                color: #2457a7;
            }
            li {
                padding: 8px 0;
            }
            .status {
                color: #187443;
                font-weight: bold;
            }
        </style>
    </head>
    <body>
        <main>
            <h1>Inception Advisor</h1>
            <p>Bienvenue sur le service Advisor.</p>
            <p>Cette application présente les services de l'infrastructure.</p>
            <h2>Services configurés</h2>
            <ul>
                """ + "".join(
                    f"<li>{service}</li>" for service in SERVICES
                ) + """
            </ul>
            <p class="status">Le service Advisor fonctionne.</p>
            <p>Consultez <a href="health">/health</a> pour vérifier son état.</p>
            <p>Consultez <a href="api/services">/api/services</a> pour obtenir la liste des services en JSON.</p>
        </main>
    </body>
    </html>
    """


@app.route("/health", methods=["GET"])
def health():
    return jsonify({
        "service": "advisor",
        "status": "healthy"
    }), 200


@app.route("/api/services", methods=["GET"])
def services():
    return jsonify({
        "services": SERVICES
    }), 200


if __name__ == "__main__":
    app.run(host="0.0.0.0", port=5000)