# sisarm-backend/models/entities/log_auditoria_model.py

from sqlalchemy import Column, Integer, String, DateTime, Text, Enum
from datetime import datetime
from ..database import Base 

class LogAuditoria(Base):
    __tablename__ = 'log_auditoria'
    id_log = Column(Integer, primary_key=True, autoincrement=True)
    
    # Columna corregida en DB: de 'fecha_hora_accion' a 'fecha_hora' (por ALTER TABLE)
    fecha_hora = Column(DateTime, nullable=False, default=datetime.now) 
    
    # 🚨 COLUMNA REAL EN DB: Se llama 'id_usuario' (por tu CREATE TABLE)
    id_usuario = Column(String(50), nullable=False) 
    
    tipo_evento = Column(Enum('CONSULTA_DB', 'EXPORTACION_DATOS', 'MODIFICACION_DATOS', 'ERROR_SISTEMA'), nullable=False)
    
    # 🚨 COLUMNA REAL EN DB: Se llama 'detalle_accion' (por tu CREATE TABLE)
    detalle_accion = Column(Text, nullable=False) 
    
    nombre_usuario = Column(String(100))
    ip_origen = Column(String(45))

    def to_dict(self):
        """
        Mapea el objeto a un diccionario usando los nombres de claves que el frontend/service esperan.
        """
        return {
            "id_log": self.id_log,
            "fecha_hora": self.fecha_hora.isoformat() if self.fecha_hora else None,
            
            # Mapeo de DB (id_usuario) a App (user_id)
            "user_id": self.id_usuario, 
            
            "nombre_usuario": self.nombre_usuario,
            "tipo_evento": self.tipo_evento,
            
            # Mapeo de DB (detalle_accion) a App (detalle)
            "detalle": self.detalle_accion, 
            
            "ip_origen": self.ip_origen
        }