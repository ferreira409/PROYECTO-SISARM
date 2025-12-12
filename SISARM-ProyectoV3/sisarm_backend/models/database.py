# sisarm-backend/models/database.py
from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker
from sqlalchemy.ext.declarative import declarative_base
from flask import Flask 
# 🔑 CORRECCIÓN: Subir un nivel (..) para importar config desde sisarm-backend/
from config import Config 

# 1. Crear el motor
Engine = create_engine(
    Config.SQLALCHEMY_DATABASE_URI, 
    pool_recycle=3600,
    # 🔑 Logging activado para que veamos la consulta SQL
    echo=True 
)

# 2. Base declarativa
Base = declarative_base()

# 3. Sesión local
SessionLocal = sessionmaker(
    autocommit=False,
    autoflush=False,
    bind=Engine
)

# 🚨 FUNCIÓN AGREGADA PARA CUMPLIR CON LA IMPORTACIÓN EN app.py 🚨
def init_db(app: Flask):
    """
    Inicializa la base de datos: crea todas las tablas definidas en los modelos.
    """
    with app.app_context():
        # **IMPORTANTE**: Asegúrate de que todos tus archivos de modelo (.py) 
        # (ej. subpartida_model, log_auditoria_model) sean importados en algún 
        # lugar de tu aplicación antes de llamar a create_all() 
        # para que SQLAlchemy los conozca.
        
        # Base.metadata contiene la información de todos los modelos conocidos
        Base.metadata.create_all(bind=Engine) 
        print("Base de datos inicializada: Tablas verificadas o creadas.")


# Generador para la sesión (útil en Flask)
def get_db():
    """Generador para manejar la sesión de DB."""
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()