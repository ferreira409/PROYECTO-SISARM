import sys
import os
import logging
from datetime import datetime

# 1. Añade la ruta del paquete 'sisarm-backend' al sistema de rutas de Python.
# Esto permite que todas las importaciones 'from sisarm_backend...' funcionen.
# La ruta base es el directorio donde está 'run.py'.
sys.path.insert(0, os.path.abspath(os.path.join(os.path.dirname(__file__), 'sisarm_backend')))

# 2. Importamos la aplicación principal.
from sisarm_backend.app import app

# Configuración de Logging
logging.basicConfig(level=logging.INFO, format='%(asctime)s %(levelname)s: %(message)s')

if __name__ == '__main__':
    print(f"[{datetime.now().strftime('%Y-%m-%d %H:%M:%S')}] Iniciando SISARM Flask App...")
    app.run(debug=True, port=5000)