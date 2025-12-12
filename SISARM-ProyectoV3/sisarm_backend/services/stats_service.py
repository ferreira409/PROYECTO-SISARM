from sisarm_backend.app import db
from sqlalchemy import func
from sisarm_backend.models.entities.despacho_aduanero_model import DespachoAduanero

class StatsService:
    @staticmethod
    def get_promedio_ga_por_capitulo():
        """
        Calcula el promedio de GA% agrupado por Capítulo (primeros 2 dígitos).
        """
        db_session = db.session
        try:
            # Consulta SQL equivalente:
            # SELECT SUBSTRING(codigo_subpartida, 1, 2) as capitulo, AVG(ga_porcentaje) as promedio
            # FROM despacho_aduanero
            # GROUP BY capitulo ORDER BY capitulo;
            
            results = db_session.query(
                func.substring(DespachoAduanero.codigo_subpartida, 1, 2).label('capitulo'),
                func.avg(DespachoAduanero.ga_porcentaje).label('promedio_ga')
            ).group_by('capitulo').order_by('capitulo').all()
            
            # Formateamos los resultados para el frontend
            stats_data = []
            for row in results:
                stats_data.append({
                    "capitulo": row.capitulo,
                    # Convertimos a float y redondeamos a 2 decimales para que se vea bonito
                    "promedio_ga": round(float(row.promedio_ga or 0), 2)
                })
                
            return stats_data
            
        except Exception as e:
            print(f"Error en StatsService: {e}")
            return []