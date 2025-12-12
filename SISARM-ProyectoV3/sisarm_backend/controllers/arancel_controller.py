from flask import Blueprint, jsonify, request
from sqlalchemy import func 

# Rutas ABSOLUTAS: Importaciones de services (Ajustar las rutas si usa una estructura diferente)
# (Importaciones de servicios DENTRO de las funciones)

# Inicialización del Blueprint
arancel_bp = Blueprint('arancel_bp', __name__)

# =========================================================================
# 1. RUTA DE BÚSQUEDA AVANZADA (Filtro) - Acepta GET para formularios
# =========================================================================
@arancel_bp.route('/filter', methods=['GET']) 
def filter_aranceles():
    
    # Importamos los servicios DENTRO de la función
    from sisarm_backend.services.arancel_advanced_service import ArancelAdvancedService
    from sisarm_backend.services.auditoria_service import AuditoriaService
    
    try:
        # Los datos se obtienen de los argumentos de la URL (GET)
        capitulo = request.args.get('capitulo')
        partida = request.args.get('partida')
        subpartida = request.args.get('subpartida')
        cliente = request.args.get('cliente')
        
        # 🔑 SOLUCIÓN: Modificada la validación.
        # Ahora permite buscar si CUALQUIERA (incluyendo cliente) está presente.
        if not (capitulo or partida or subpartida or cliente):
            return jsonify({'error': 'Debe proporcionar al menos un criterio de búsqueda.'}), 400

        # 2. REGISTRA LA BÚSQUEDA EN LA AUDITORÍA
        try:
            # El formato del log ya es correcto
            detalle_busqueda = f"Capitulo={capitulo or '-'}, Partida={partida or '-'}, SUBPARTIDA={subpartida or '-'}, CLIENTE={cliente or '-'}"
            user_id = request.headers.get('X-User-ID', 'despachante_001') # Obtenemos el ID del header
            
            AuditoriaService.registrar_log(
                user_id=user_id,
                tipo_evento='CONSULTA_DB', 
                detalle=detalle_busqueda,
                ip_origen=request.remote_addr 
            )
        except Exception as log_error:
            print(f"🔥 ADVERTENCIA: No se pudo guardar el log de auditoría. Error: {log_error}")
        
        # -----------------------------------------------------------------

        # Llama al servicio avanzado con los parámetros
        results = ArancelAdvancedService.filter_subpartidas(capitulo, partida, subpartida, cliente)

        return jsonify(results), 200

    except Exception as e:
        print(f"Error al aplicar el filtro en el controlador: {e}")
        return jsonify({'error': f'Error interno del servidor: {str(e)}'}), 500