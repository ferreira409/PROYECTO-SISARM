# sisarm-backend/services/arancel_advanced_service.py

from sisarm_backend.app import db 
# 🔑 SOLUCIÓN: Importamos 'contains_eager'
from sqlalchemy.orm import joinedload, contains_eager
from sqlalchemy import or_, and_, func 

from sisarm_backend.models.entities.subpartida_model import Subpartida as SubpartidaModel
from sisarm_backend.models.entities.despacho_aduanero_model import DespachoAduanero as DespachoAduaneroModel

class ArancelAdvancedService:
    
    @staticmethod
    def filter_subpartidas(capitulo=None, partida=None, subpartida=None, cliente=None):
        """
        Función que aplica filtros combinados (arancel y cliente) a las Subpartidas.
        """
        db_session = db.session 
        filters = [] 
        
        # Limpieza y normalización de parámetros
        capitulo = (capitulo or "").strip()
        partida = (partida or "").strip()
        subpartida = (subpartida or "").strip()
        cliente = (cliente or "").strip()
        
        try:
            # 1. Base de la consulta
            query = db_session.query(SubpartidaModel)

            # 2. FILTRO ARANCELARIO
            arancel_filter = None
            if subpartida: arancel_filter = subpartida
            elif partida: arancel_filter = partida
            elif capitulo: arancel_filter = capitulo
            
            if arancel_filter:
                filters.append(func.trim(SubpartidaModel.codigo_subpartida).like(f'{arancel_filter}%'))
                
            # 3. FILTRO POR CLIENTE (RUC/NIT) Y JOIN
            if cliente:
                # 🔑 SOLUCIÓN: Si hay cliente, hacemos un INNER JOIN.
                # Solo queremos subpartidas QUE TENGAN data para ese cliente.
                query = query.join(SubpartidaModel.despachos).filter(DespachoAduaneroModel.cliente_asociado == cliente)
                
                # 🔑 SOLUCIÓN: Y usamos contains_eager para cargar SÓLO esos despachos
                # 'despachos' es el nombre de la relación en SubpartidaModel
                query = query.options(contains_eager(SubpartidaModel.despachos))

            else:
                # 🔑 SOLUCIÓN: Si NO hay cliente, hacemos un LEFT OUTER JOIN.
                # Queremos TODAS las subpartidas, y si tienen despacho, también.
                query = query.outerjoin(SubpartidaModel.despachos)
                query = query.options(contains_eager(SubpartidaModel.despachos))

            # 4. Aplicamos los filtros de arancel (si los hay)
            if filters:
                query = query.filter(and_(*filters))

            # 5. Evitar duplicados
            # Si una subpartida tiene múltiples despachos, el JOIN crea filas duplicadas.
            query = query.distinct()

            # 🚨 PASO CRÍTICO DE DEBUGGING: Imprimir la consulta SQL generada
            print("================== DEBUG SQL ==================")
            print(f"Filtro Arancel: {arancel_filter}, Filtro Cliente: {cliente}")
            print(query.statement.compile(db.engine, compile_kwargs={"literal_binds": True}))
            print("===============================================")


            results_orm = query.all()
            
            # 🔑 SOLUCIÓN: Ahora el to_dict() recibirá la lista de despachos correcta
            results_dict = [r.to_dict() for r in results_orm]
            
            return results_dict
            
        except Exception as e:
            # Revertir la transacción en caso de error
            db_session.rollback()
            print(f"🔥 ERROR FATAL EN FILTRO AVANZADO (SQLAlchemy): {e}") 
            raise e 
        finally:
            # No cerramos db_session aquí si usamos Flask-SQLAlchemy
            pass