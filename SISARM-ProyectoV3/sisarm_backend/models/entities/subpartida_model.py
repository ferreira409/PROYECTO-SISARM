from sqlalchemy import Column, String, Text
from sqlalchemy.orm import relationship
from ..database import Base
from .despacho_aduanero_model import DespachoAduanero 
from sqlalchemy.types import String as TextString # Importación para asegurar tipo de texto

class Subpartida(Base):
    
    # 🔑 Asegura la coherencia con tu DDL: 'subpartidas' (plural y minúsculas)
    __tablename__ = 'subpartidas'
    
    # 🔑 Uso de TextString para forzar el tratamiento como texto en la DB, 
    # crucial para que el LIKE funcione sin ambigüedades.
    codigo_subpartida = Column(TextString(15), primary_key=True)
    descripcion_subpartida = Column(Text, nullable=False)
    
    # 🔑 SOLUCIÓN: Eliminado 'lazy="dynamic"'
    # Ahora 'self.despachos' será una LISTA de objetos DespachoAduanero,
    # que será cargada por el servicio.
    despachos = relationship("DespachoAduanero", 
                            back_populates="subpartida_relacion", 
                            uselist=True) 

    def get_notas_legales_simuladas(self):
        """Devuelve notas simuladas para el capítulo al que pertenece la subpartida."""
        capitulo = self.codigo_subpartida[:2]        
        
        # 🔑 INICIO DE NOTAS EXTENDIDAS
        if capitulo == '01':
            return (
                "Notas del Capítulo 01 (Animales Vivos): "
                "<br>1. Este capítulo comprende todos los animales vivos, excepto: "
                # 🔑 SOLUCIÓN: Añadidos <br> (salto de línea) y &nbsp; (espacios)
                "<br>&nbsp;&nbsp;&nbsp;&nbsp;a) los peces, los crustáceos, moluscos y demás invertebrados acuáticos, de las partidas 03.01, 03.06, 03.07 u 03.08; "
                "<br>&nbsp;&nbsp;&nbsp;&nbsp;b) los cultivos de microorganismos y demás productos de la partida 30.02; y "
                "<br>&nbsp;&nbsp;&nbsp;&nbsp;c) los animales de la partida 95.08 (animales de circos, zoológicos ambulantes o ferias). "
                
                "<br><br>2. Este capítulo incluye especies domésticas y salvajes. Se clasifican aquí, entre otros, los caballos, asnos, mulos y burdéganos (partida 01.01), "
                "los animales vivos de la especie bovina (01.02), porcina (01.03), ovina y caprina (01.04). La partida 01.05 cubre específicamente las aves de corral "
                "(gallos, gallinas, patos, gansos, pavos/pípilos y pintadas). La partida 01.06 es una partida residual para 'Los demás animales vivos', "
                "que incluye mamíferos (como primates, ballenas, camellos), reptiles (serpientes, tortugas), aves de rapiña, e incluso insectos (como abejas). "
                
                "<br><br>Los animales pueden estar destinados a diversos fines, tales como la reproducción, cría, engorde, o sacrificio. Los animales de pura raza para "
                "reproducción deben estar debidamente certificados. Es crucial verificar las regulaciones sanitarias (zoosanitarias) vigentes emitidas por la "
                "autoridad competente (ej. SENASAG en Bolivia) que pueden restringir o prohibir la importación de ciertos animales vivos por razones de sanidad animal, "
                "especialmente en relación con enfermedades como la fiebre aftosa, la gripe aviar o la peste porcina. "
                "(Nota Simulada y Extendida)"
            )
        elif capitulo == '02':
            return (
                "Notas del Capítulo 02 (Carne y despojos comestibles): "
                "<br>1. Este capítulo comprende la carne y los despojos comestibles de los animales del Capítulo 01, siempre que se presenten en los siguientes estados: "
                "frescos, refrigerados o congelados. "
                "La Nota Legal 1 de este capítulo define 'carne' como el producto en canal o en cortes. 'Refrigerado' se refiere a productos enfriados generalmente "
                "hasta una temperatura cercana a 0°C sin alcanzar la congelación. 'Congelado' implica que el producto ha sido enfriado por debajo de su punto de "
                "congelación hasta su total solidificación en el centro térmico. "
                
                "<br><br>2. Este capítulo NO comprende: "
                # 🔑 SOLUCIÓN: Añadidos <br> (salto de línea) y &nbsp; (espacios)
                "<br>&nbsp;&nbsp;&nbsp;&nbsp;a) la carne y despojos impropios para la alimentación humana (Capítulo 05); "
                "<br>&nbsp;&nbsp;&nbsp;&nbsp;b) las grasas de cerdo, de ave, bovino, ovino o caprino (Capítulo 15); "
                "<br>&nbsp;&nbsp;&nbsp;&nbsp;c) la carne y despojos comestibles que hayan sido sometidos a un proceso ulterior a la simple refrigeración o congelación, tales como los salados, "
                "en salmuera, secos, ahumados, o cocidos de cualquier forma. Estos productos se clasifican en el Capítulo 16. "
                
                "<br><br>Las partidas principales incluyen la carne de bovino (02.01, 02.02), porcino (02.03), ovino o caprino (02.04), y aves (02.07). "
                "Los 'despojos' (partida 02.06) son una clasificación importante y se refieren a partes como hígados, riñones, lenguas, corazones, y diafragmas, "
                "siempre que sean comestibles y se presenten frescos, refrigerados o congelados. "
                "(Nota Simulada y Extendida)"
            )
        elif capitulo == '03':
            return (
                "Notas del Capítulo 03 (Pescados y crustáceos, moluscos y demás invertebrados acuáticos): "
                "<br>1. Este capítulo comprende todos los pescados, crustáceos, moluscos y demás invertebrados acuáticos, presentados en los siguientes estados: "
                # 🔑 SOLUCIÓN: Añadidos <br> (salto de línea) y &nbsp; (espacios)
                "<br>&nbsp;&nbsp;&nbsp;&nbsp;a) Vivos (principalmente destinados al consumo humano directo o a la acuicultura, partida 03.01); "
                "<br>&nbsp;&nbsp;&nbsp;&nbsp;b) Frescos o refrigerados; "
                "<br>&nbsp;&nbsp;&nbsp;&nbsp;c) Congelados. "
                
                "<br><br>2. Este capítulo NO comprende: "
                # 🔑 SOLUCIÓN: Añadidos <br> (salto de línea) y &nbsp; (espacios)
                "<br>&nbsp;&nbsp;&nbsp;&nbsp;a) los mamíferos marinos (por ejemplo, ballenas o delfines), que si están vivos se clasifican en la partida 01.06, o su carne en el Capítulo 02; "
                "<br>&nbsp;&nbsp;&nbsp;&nbsp;b) los pescados, crustáceos o moluscos muertos e impropios para el consumo humano (Capítulo 05); "
                "<br>&nbsp;&nbsp;&nbsp;&nbsp;c) los productos que han sido procesados más allá de la congelación, tales como el pescado seco, salado, en salmuera o ahumado (partida 16.04); "
                "<br>&nbsp;&nbsp;&nbsp;&nbsp;d) el caviar y sus sucedáneos (partida 16.04). "
                
                "<br><br>Las partidas distinguen entre pescados vivos (03.01), pescados frescos o refrigerados (03.02), pescados congelados (03.03), y filetes u otra carne "
                "de pescado (03.04). Los crustáceos (partida 03.06) incluyen camarones, langostinos, langostas y cangrejos, presentados con o sin caparazón. "
                "Los moluscos (03.07) incluyen ostras, mejillones, vieiras, calamares y pulpos. "
                "Es fundamental verificar los permisos sanitarios de importación emitidos por la autoridad competente. "
                "(Nota Simulada y Extendida)"
            )
        # 🔑 FIN DE NOTAS EXTENDIDAS
        else:
            return f"Notas del Capítulo {capitulo}: No hay notas específicas y detalladas cargadas en el sistema para este capítulo. (Simulado)"


    def to_dict(self):
        """Serializa la subpartida y sus datos de despacho."""
        despacho_data = {}
        
        # 🔑 SOLUCIÓN: 'self.despachos' ahora es una LISTA.
        # El 'arancel_advanced_service' será responsable de cargar
        # esta lista solo con los despachos correctos.
        
        if self.despachos and len(self.despachos) > 0:
            # Simplemente tomamos el primer despacho de la lista
            # (que ya fue filtrada por el servicio si fue necesario).
            despacho_data = self.despachos[0].to_dict()
        
        return {
            "codigo_subpartida": self.codigo_subpartida,
            "descripcion_subpartida": self.descripcion_subpartida,
            
            # Datos de Notas Legales
            "notas_legales_capitulo": self.get_notas_legales_simuladas(),
            
            # Datos del Despacho Aduanero (tomados del primer despacho o por defecto)
            "GA_porcentaje": despacho_data.get("ga_porcentaje", "0.00"),
            "IEHD_porcentaje": despacho_data.get("porcentaje_iehd", "0.00"),
            "unidad_medida": despacho_data.get("unidad_medida", "N/A"),
            "medida_en_frontera": despacho_data.get("medida_en_frontera", "N/A"),
            "tipo_documento": despacho_data.get("tipo_documento", "N/A"),
            "tipo_entidad_emite": despacho_data.get("tipo_entidad_emite", "N/A"),
            "disp_legal": despacho_data.get("disp_legal", "N/A"),
            "documento_requerido": despacho_data.get("documento", "No Requerido"),
            "observaciones": despacho_data.get("observaciones", "")
        }