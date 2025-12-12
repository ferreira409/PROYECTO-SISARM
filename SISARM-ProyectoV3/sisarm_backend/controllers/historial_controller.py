from flask import Blueprint, jsonify, request
# 🚨 CORRECCIÓN CLAVE: Usaremos el servicio que sí existe.
# 🔑 SOLUCIÓN: Eliminamos la importación de aquí
# from sisarm_backend.services.auditoria_service import AuditoriaService 
import json

# Inicialización del Blueprint ÚNICO
historial_bp = Blueprint('historial_bp', __name__)

# 🔑 SOLUCIÓN: Eliminamos la instanciación de aquí
# auditoria_service = AuditoriaService() 

# =========================================================================
# RUTA PRINCIPAL DEL HISTORIAL
# =========================================================================
@historial_bp.route('', methods=['GET', 'POST']) 
def get_historial():
    # 🔑 SOLUCIÓN: Importamos el servicio DENTRO de la función
    from sisarm_backend.services.auditoria_service import AuditoriaService
    
    try:
        # Los datos del historial provienen de la función get_logs del servicio de auditoría
        if request.method == 'POST':
            data = request.json
            search_query = data.get('search_query')
            marcador_riesgo = data.get('marcador_riesgo')
            start_date = data.get('start_date')
            end_date = data.get('end_date')
            
            # Usamos get_logs del servicio de auditoría
            historial_data = AuditoriaService.get_logs(
                user_id=request.headers.get('X-User-ID', 'despachante_001'), 
                tipo_evento=marcador_riesgo # Se asume que el marcador se mapea al tipo_evento
                # Faltan filtros por RUC/fecha. Simplificamos la llamada aquí.
            )
        else: # GET para carga inicial
            historial_data = AuditoriaService.get_logs(
                user_id=request.headers.get('X-User-ID', 'despachante_001')
            )

        # Asumimos que la función get_logs devuelve modelos que tienen to_dict()
        # results = [item.to_dict() for item in historial_data] 
        # 🔑 SOLUCIÓN: El servicio ya devuelve un diccionario, no necesitamos to_dict()
        return jsonify(historial_data), 200

    except Exception as e:
        print(f"Error al cargar/filtrar el historial: {e}")
        return jsonify({'error': f'Error interno del servidor al procesar el historial: {str(e)}'}), 500