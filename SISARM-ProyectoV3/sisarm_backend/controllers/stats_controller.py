from flask import Blueprint, jsonify
from sisarm_backend.services.stats_service import StatsService

stats_bp = Blueprint('stats_bp', __name__)

@stats_bp.route('/promedio-ga', methods=['GET'])
def get_promedio_ga():
    try:
        results = StatsService.get_promedio_ga_por_capitulo()
        return jsonify(results), 200
    except Exception as e:
        print(f"Error en stats controller: {e}")
        return jsonify({'error': str(e)}), 500