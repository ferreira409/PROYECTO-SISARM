# sisarm-backend/services/arancel_service.py

# 🔑 SOLUCIÓN: Importamos 'db' desde la app de Flask y ajustamos las rutas
from sisarm_backend.app import db
from sqlalchemy import or_

from sisarm_backend.models.entities.subpartida_model import Subpartida as SubpartidaModel
from sisarm_backend.models.entities.despacho_aduanero_model import DespachoAduanero as DespachoAduaneroModel 

class ArancelService:
    
    # 🚨 NOTA: Se ha eliminado el método filter_subpartidas de este módulo. 
    # La lógica de filtro avanzado ahora debe estar en ArancelAdvancedService.
    pass

    
    @staticmethod
    def autocomplete_search(query: str):
        """
        Realiza la búsqueda predictiva en Subpartidas y simula otros tipos de datos.
        """
        # 🔑 SOLUCIÓN: Usamos db.session de Flask-SQLAlchemy
        db_session = db.session
        query_lower = query.lower()
        results = []
        
        try:
            # 1. Búsqueda en Subpartidas (limitada a 5 para autocompletar)
            # 🔑 SOLUCIÓN: Usamos db_session
            subpartida_logs = db_session.query(SubpartidaModel).filter(
                # Búsqueda en CÓDIGO (ilike con % para flexibilidad)
                (SubpartidaModel.codigo_subpartida.ilike(f'%{query}%')) | 
                # Búsqueda en DESCRIPCIÓN (ilike con % para flexibilidad)
                (SubpartidaModel.descripcion_subpartida.ilike(f'%{query_lower}%'))
            ).limit(5).all()

            for sp in subpartida_logs:
                results.append({
                    "codigo": sp.codigo_subpartida,
                    "descripcion": sp.descripcion_subpartida,
                    "tipo_dato": "Arancel"
                })
                
            # 2. Simulación de búsqueda en otros tipos (Documentos y Clientes)
            if "certi" in query_lower or "doc" in query_lower:
                results.append({"codigo": "DOC-CSI", "descripcion": "Certificado Sanitario de Importación", "tipo_dato": "Documento"})
            if "fito" in query_lower:
                results.append({"codigo": "DOC-FIT", "descripcion": "Certificado Fitosanitario (SENASAG)", "tipo_dato": "Documento"})
                
            if "client" in query_lower or "abc" in query_lower:
                results.append({"codigo": "CLI-001", "descripcion": "Cliente ABC S.R.L.", "tipo_dato": "Cliente"})
            
            # Limitar la lista final a 10 resultados
            return results[:10]
            
        except Exception as e:
            print(f"Error en ArancelService.autocomplete_search: {e}")
            db_session.rollback()
            return [] # Devuelve lista vacía en caso de error
        finally:
            # 🔑 SOLUCIÓN: Flask-SQLAlchemy maneja el cierre de sesión. No usamos db.close()
            pass