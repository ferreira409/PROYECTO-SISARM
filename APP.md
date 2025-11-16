# PROYECTO-SISARM
Este proyecto esta echo para DESPACHANTES ADUANEROS que tengas la facilidad de ver los códigos arancelarios en cada Exportación.

[app.py](https://github.com/user-attachments/files/23565173/app.py)import os
import sys
from flask import Flask
from flask_cors import CORS
from flask_sqlalchemy import SQLAlchemy
import logging

# Configurar logging para SQL
logging.basicConfig()
logging.getLogger('sqlalchemy.engine').setLevel(logging.INFO)

app = Flask(__name__)

# --- 1. CONFIGURACIÓN BÁSICA ---
CORS(app) 

app.config['SQLALCHEMY_DATABASE_URI'] = 'mysql+mysqlconnector://root:edimar12345@127.0.0.1:3306/SISARM'
app.config['SQLALCHEMY_TRACK_MODIFICATIONS'] = False
app.config['DEBUG'] = True
app.config['SECRET_KEY'] = 'super-secreto-sisarm'

db = SQLAlchemy(app)

# 💡 Importa los modelos ANTES de registrar los blueprints (Usando rutas absolutas)
try:
    from sisarm_backend.models.entities.subpartida_model import Subpartida
    from sisarm_backend.models.entities.despacho_aduanero_model import DespachoAduanero
    from sisarm_backend.models.entities.log_auditoria_model import LogAuditoria 
except ModuleNotFoundError as e:
    print(f"ERROR: No se pudo importar un modelo. Revisar rutas en app.py: {e}")

# --- 2. IMPORTAR Y REGISTRAR BLUEPRINTS (Controllers) ---
try:
    # 🔑 CORRECCIÓN DE RUTAS: Usar ruta absoluta para controllers
    from sisarm_backend.controllers.arancel_controller import arancel_bp
    from sisarm_backend.controllers.historial_controller import historial_bp
    from sisarm_backend.controllers.riesgo_controller import riesgo_bp
    from sisarm_backend.controllers.autocomplete_controller import autocomplete_bp
    from sisarm_backend.controllers.auditoria_controller import auditoria_bp 
    from sisarm_backend.controllers.stats_controller import stats_bp

    # 🔑 SOLUCIÓN: Eliminada esta línea que creaba conflicto con autocomplete_bp
    # app.register_blueprint(arancel_bp, url_prefix='/api/v1/aranceles') 
    
    app.register_blueprint(autocomplete_bp, url_prefix='/api/v1/aranceles', name='autocomplete_plural_bp')
    app.register_blueprint(arancel_bp, url_prefix='/api/v1/arancel', name='arancel_singular_bp') 
    app.register_blueprint(historial_bp, url_prefix='/api/v1/historial')
    app.register_blueprint(riesgo_bp, url_prefix='/api/v1/riesgo')
    app.register_blueprint(auditoria_bp, url_prefix='/api/v1/auditoria')
    app.register_blueprint(stats_bp, url_prefix='/api/v1/stats')

except ModuleNotFoundError as e:
    print(f"CRITICAL ERROR: No se pudo importar un controller/blueprint. Revisar app.py: {e}")

# --- 3. INICIALIZACIÓN DE BASE DE DATOS ---

def initialize_database():
    """Inicializa las tablas de la DB si no existen."""
    with app.app_context():
        try:
            db.create_all() 
            print("Base de datos inicializada: Tablas verificadas o creadas.")
        except Exception as e:
            # Si la contraseña fue corregida, esta parte debe funcionar sin el error 1045
            print(f"Error durante la inicialización de la base de datos: {e}")

# Llamar a la inicialización al inicio
initialize_database()

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000)
