# sisarm-backend/config.py
import os

class Config:
    """Configuración de la conexión a MySQL con PyMySQL."""
    
    # 🚨 REEMPLAZA ESTAS CREDENCIALES CON LAS TUYAS 🚨
    SQLALCHEMY_DATABASE_URI = (
        "mysql+pymysql://root:edimar12345@127.0.0.1:3306/SISARM"
    )
    # Ejemplo Local: "mysql+pymysql://root:@localhost:3306/SISARM"
    
    SQLALCHEMY_TRACK_MODIFICATIONS = False
    SECRET_KEY = os.environ.get('SECRET_KEY') or 'clave_para_seguridad_flask'