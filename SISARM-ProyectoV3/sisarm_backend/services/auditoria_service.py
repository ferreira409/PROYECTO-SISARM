# sisarm-backend/services/auditoria_service.py (VERSIÓN ALINEADA CON MAIN.JS)

# 🔑 SOLUCIÓN: Importamos 'db' desde la app de Flask y ajustamos las rutas
from sisarm_backend.app import db
from sisarm_backend.models.entities.log_auditoria_model import LogAuditoria
from datetime import datetime, timedelta

class AuditoriaService:
    
    # ... (registrar_log se mantiene sin cambios) ...
    @staticmethod
    def registrar_log(user_id: str, tipo_evento: str, detalle: str = None, nombre_usuario: str = None, ip_origen: str = None):
        """
        Crea un nuevo registro en la tabla de log_auditoria (SINCRONO).
        """
        # 🔑 SOLUCIÓN: Usamos db.session de Flask-SQLAlchemy
        db_session = db.session
        try:
            nuevo_log = LogAuditoria(
                id_usuario=user_id, 
                fecha_hora=datetime.now(), 
                tipo_evento=tipo_evento,
                detalle_accion=detalle,
                nombre_usuario=nombre_usuario,
                ip_origen=ip_origen
            )
            db_session.add(nuevo_log)
            db_session.commit()
            return True
        except Exception as e:
            print(f"Error al registrar auditoría: {e}") 
            db_session.rollback()
            return False
        finally:
            # 🔑 SOLUCIÓN: Flask-SQLAlchemy maneja el cierre de sesión.
            pass
            
    # Función: Obtener y Filtrar Registros de Log 
    @staticmethod
    def get_logs(user_id=None, start_date=None, end_date=None, tipo_evento=None):
        """
        Permite obtener y filtrar logs. Usado por la interfaz de Historial.
        """
        # 🔑 SOLUCIÓN: Usamos db.session de Flask-SQLAlchemy
        db_session = db.session
        query = db_session.query(LogAuditoria).order_by(LogAuditoria.fecha_hora.desc())
        
        # ... (Lógica de filtrado se mantiene) ...
        if user_id and user_id != 'ADMIN': 
            query = query.filter(LogAuditoria.id_usuario == user_id)
        if tipo_evento:
            query = query.filter(LogAuditoria.tipo_evento == tipo_evento) 
        if start_date:
            try:
                dt_start = datetime.strptime(start_date, '%Y-%m-%d')
                query = query.filter(LogAuditoria.fecha_hora >= dt_start)
            except ValueError:
                pass 
        if end_date:
            try:
                dt_end = datetime.strptime(end_date, '%Y-%m-%d') + timedelta(days=1)
                query = query.filter(LogAuditoria.fecha_hora < dt_end)
            except ValueError:
                pass 
                
        try:
            results = query.limit(500).all()
        except Exception as e:
            print(f"Error al ejecutar get_logs query: {e}")
            db_session.rollback()
            return [] # Devuelve lista vacía en caso de error
        finally:
            # 🔑 SOLUCIÓN: Flask-SQLAlchemy maneja el cierre de sesión.
            pass
        
        # 🚨 CORRECCIÓN CRÍTICA: Mapeo exacto a las claves del main.js 🚨
        logs_list_mapeada = []
        for log in results:
            partida_val = 'N/A'
            cliente_val = 'N/A'
            
            # 1. Parsing de detalle_accion de forma robusta
            if log.detalle_accion:
                detalle_partes = [p.strip() for p in log.detalle_accion.split(',')]
                
                for parte in detalle_partes:
                    # Usamos .upper() y .replace() para tolerar diferencias de formato
                    parte_limpia = parte.upper().replace(' ', '')
                    
                    if 'SUBPARTIDA=' in parte_limpia:
                        try:
                            partida_val = parte.split('=')[1].strip()
                        except IndexError:
                            pass
                    elif 'CLIENTE=' in parte_limpia:
                        try:
                            cliente_val = parte.split('=')[1].strip()
                        except IndexError:
                            pass

            # 2. Mapeo a las claves que el main.js espera (¡Son estas!)
            logs_list_mapeada.append({
                'fecha_hora': log.fecha_hora.isoformat() if log.fecha_hora else 'N/A', # Clave: item.fecha_hora
                'partida_arancelaria': partida_val if partida_val not in ('N/A', None) else 'N/A', # Clave: item.partida_arancelaria
                
                # Usamos 'cliente_ruc' (esperado por JS) y llenamos con el valor parseado o el ID de usuario
                'cliente_ruc': cliente_val if cliente_val not in ('N/A', None) else log.id_usuario, # Clave: item.cliente_ruc
                
                # Campos no mapeados/fijos (el frontend los espera)
                'declaracion_duida': 'N/A', # Clave: item.declaracion_duida (DUI/DAM)
                'marcador_riesgo': 'BAJO', # Clave: item.marcador_riesgo (Riesgo)
                'motivo_riesgo': 'Consulta de arancel sin restricciones.', # Detalle del tooltip
                'referencias_cruzadas': [] # Clave: item.referencias_cruzadas (debe ser un array, aunque esté vacío)
            })
            
        return logs_list_mapeada
        
    # ... (export_logs se mantiene sin cambios) ...
    @staticmethod
    def export_logs(logs_data):
        """
        Genera una cadena CSV a partir de los datos de log.
        """
        if not logs_data:
            return "Fecha y Hora,ID Usuario,Tipo de Evento,Detalle\n"
            
        csv_output = "Fecha y Hora,ID Usuario,Tipo de Evento,Detalle\n" 
        
        for log in logs_data:
            # Para la exportación, usamos las claves mapeadas en la lista logs_data
            
            fecha_hora = log.get('fecha_hora', 'N/A')
            user_id = log.get('cliente_ruc', log.get('id_usuario', 'N/A'))
            tipo_evento = log.get('tipo_evento', 'N/A')
            detalle = log.get('detalle_accion', 'N/A')
            
            csv_output += f"{fecha_hora},{user_id},{tipo_evento},{detalle.replace(',', ';')}\n"
            
        return csv_output