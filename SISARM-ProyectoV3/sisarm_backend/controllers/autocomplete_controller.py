from flask import Blueprint, jsonify, request
# 🔑 CORRECCIÓN: USAR RUTA ABSOLUTA COMPLETA para services
# 🔑 SOLUCIÓN: Eliminamos la importación de aquí
# from sisarm_backend.services.arancel_service import ArancelService 

# Define el blueprint.
autocomplete_bp = Blueprint('autocomplete_bp', __name__)

# --- ENDPOINT DE AUTOCOMPLETADO (SOLUCIONA 404 para /autocomplete) ---
# La ruta es solo '/autocomplete'. El prefijo '/api/v1/aranceles' se añade en app.py.
@autocomplete_bp.route('/autocomplete', methods=['GET'])
def autocomplete_arancel_route():
    # 🔑 SOLUCIÓN: Importamos el servicio DENTRO de la función
    from sisarm_backend.services.arancel_service import ArancelService
    
    query_param = request.args.get('query', '').strip()
    
    if not query_param:
        return jsonify([])

    try:
        # Asumimos que ArancelService.autocomplete_search() está implementado y funcional.
        results = ArancelService.autocomplete_search(query_param)
        return jsonify(results), 200
        
    except Exception as e:
        print(f"Error en endpoint de autocompletado: {e}")
        return jsonify({"error": f"Error en autocompletado: {e}"}), 500