# sisarm-backend/controllers/auditoria_controller.py (LIMPIO Y CORREGIDO)

from flask import Blueprint, request, jsonify, Response
# 🔑 SOLUCIÓN: Eliminamos la importación de aquí
# from ..services.auditoria_service import AuditoriaService
from functools import wraps

# 🚨 NOTA: Este Blueprint ahora SOLO maneja las rutas de Auditoría general para el rol ADMIN.
# La ruta /historial/<user_id> se maneja en historial_controller.py
auditoria_bp = Blueprint('auditoria', __name__) 

# Simulación de un decorador de seguridad para el rol de Auditor/Administrador
def auditor_required(f):
    @wraps(f)
    def decorated_function(*args, **kwargs):
        # ... (código de seguridad) ...
        pass 
    return decorated_function

# ENDPOINT 1: Búsqueda y Filtrado del Historial (Ruta original para auditores, ej: /api/v1/auditoria/)
@auditoria_bp.route('/', methods=['GET'])
@auditor_required
def get_auditoria_logs():
    """
    Ruta para que un auditor filtre y visualice el historial de logs (a nivel global, sin ID de usuario en la URL).
    """
    # 🔑 SOLUCIÓN: Importamos el servicio DENTRO de la función
    from ..services.auditoria_service import AuditoriaService
    
    user_id = request.args.get('user_id')
    start_date = request.args.get('start_date')
    end_date = request.args.get('end_date')
    tipo_evento = request.args.get('tipo_evento')
    
    logs = AuditoriaService.get_logs(user_id=user_id, start_date=start_date, end_date=end_date, tipo_evento=tipo_evento)
    
    return jsonify(logs)

# ENDPOINT 2: Exportación de Datos de Auditoría
@auditoria_bp.route('/export', methods=['GET'])
@auditor_required
def export_auditoria_logs():
    """
    Ruta para que un auditor exporte los logs filtrados.
    """
    # 🔑 SOLUCIÓN: Importamos el servicio DENTRO de la función
    from ..services.auditoria_service import AuditoriaService
    
    user_id = request.args.get('user_id')
    start_date = request.args.get('start_date')
    end_date = request.args.get('end_date')
    tipo_evento = request.args.get('tipo_evento')
    
    logs = AuditoriaService.get_logs(user_id=user_id, start_date=start_date, end_date=end_date, tipo_evento=tipo_evento)
    
    # Generar el contenido CSV
    csv_content = AuditoriaService.export_logs(logs)
    
    # Devolver como archivo CSV
    return Response(
        csv_content,
        mimetype="text/csv",
        headers={"Content-disposition":
                    "attachment; filename=auditoria_log.csv"}
    )