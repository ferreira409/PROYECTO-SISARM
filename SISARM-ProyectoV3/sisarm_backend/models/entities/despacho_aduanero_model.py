from sqlalchemy import Column, String, ForeignKey, Text, DECIMAL
from sqlalchemy.orm import relationship
from ..database import Base

class DespachoAduanero(Base):
    __tablename__ = 'despacho_aduanero'
    
    # Claves primarias
    # 🔑 Apunta correctamente a la tabla 'subpartidas' (plural)
    codigo_subpartida = Column(String(15), ForeignKey('subpartidas.codigo_subpartida'), primary_key=True)
    # Asumimos que hay otras claves primarias o una clave compuesta/ID único si fuera necesario

    # Campos arancelarios
    ga_porcentaje = Column(DECIMAL(5, 2), default=0.00)
    porcentaje_iehd = Column(DECIMAL(5, 2), default=0.00)
    unidad_medida = Column(String(50))
    medida_en_frontera = Column(String(50))
    tipo_documento = Column(String(100))
    tipo_entidad_emite = Column(String(100))
    disp_legal = Column(String(100))
    documento = Column(String(100))
    observaciones = Column(Text)

    # Columna clave para el filtro
    cliente_asociado = Column(String(100), nullable=True) 

    # RELACIÓN INVERSA (usada en back_populates)
    subpartida_relacion = relationship("Subpartida", back_populates="despachos")
    
    def to_dict(self):
        return {
            "codigo_subpartida": self.codigo_subpartida,
            "ga_porcentaje": str(self.ga_porcentaje),
            "porcentaje_iehd": str(self.porcentaje_iehd),
            "unidad_medida": self.unidad_medida,
            "medida_en_frontera": self.medida_en_frontera,
            "tipo_documento": self.tipo_documento,
            "tipo_entidad_emite": self.tipo_entidad_emite,
            "disp_legal": self.disp_legal,
            "documento": self.documento,
            "observaciones": self.observaciones,
            "cliente_asociado": self.cliente_asociado
        }