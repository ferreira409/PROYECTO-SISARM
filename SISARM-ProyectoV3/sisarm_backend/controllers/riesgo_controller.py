# sisarm-backend/controllers/riesgo_controller.py (FINAL AJUSTADO A BOLIVIA)

from flask import Blueprint, request, jsonify
# ... (otras importaciones)

# 🔑 SOLUCIÓN: Eliminado el 'url_prefix' de aquí. Se maneja 100% en app.py
riesgo_bp = Blueprint('riesgo_bp', __name__)

@riesgo_bp.route('', methods=['GET']) 
@riesgo_bp.route('/', methods=['GET'])
def evaluar_riesgo():
    subpartida = request.args.get('subpartida', '').strip()
    pais_origen = request.args.get('pais_origen', '').strip()
    um_facturada = request.args.get('um_facturada', '').strip() 

    if not subpartida or not pais_origen:
        return jsonify({"error": "Faltan parámetros críticos (subpartida o país_origen)"}), 400

    # SIMULACIÓN BASADA EN EL CAPÍTULO (Primeros 2 dígitos)
    capitulo = subpartida[:2]
    
    # Se pasa la subpartida completa para simulaciones más específicas si es necesario
    alerta_preferencia = buscar_preferencia_por_capitulo(capitulo, subpartida, pais_origen)
    alertas_restriccion = buscar_restricciones_por_capitulo(capitulo, subpartida, um_facturada)

    return jsonify({
        "preferencia": alerta_preferencia,
        "restricciones": alertas_restriccion,
        "performance": 280 
    })


# ------------------------------------------------------------------
# 1. FUNCIÓN OPTIMIZADA PARA PREFERENCIA (TLC - BANNER VERDE)
# ------------------------------------------------------------------
def buscar_preferencia_por_capitulo(capitulo, subpartida, pais_origen):
    
    # 🚨 SIMULACIÓN TLC (VERDE):
    # Condición: Capítulo 02 (Carnes) tiene preferencia si viene de Perú (PE) o Chile (CL)
    if capitulo == '02' and pais_origen in ('PE', 'CL'):
        return {
            "nivel": "Preferencia",
            "mensaje": f"¡TLC Aplicable! Arancel 0% sobre Ad Valorem (ACUERDO ALADI con {pais_origen}).",
            "beneficio": "100%",
            "documento": f"Certificado de Origen TLC-{pais_origen}",
            "regla_origen": "Acuerdo de Alcance Parcial - Art. 7"
        }
    return None

# ------------------------------------------------------------------
# 2. FUNCIÓN OPTIMIZADA PARA RESTRICCIONES (ROJO/AMARILLO)
# ------------------------------------------------------------------
def buscar_restricciones_por_capitulo(capitulo, subpartida, um_facturada):
    restricciones = []
    
    # 🚨 CAPÍTULO 01 (Animales Vivos): Prohibición Total (ROJO)
    if capitulo == '01':
        restricciones.append({
            "nivel": "🔴 Prohibición",
            "mensaje": "Capítulo sujeto a PROHIBICIÓN TOTAL de importación por enfermedades estacionales (Criterio CITES/SENASAG).",
            "norma_legal": "Res. SENASAG 045/2025",
            "organismo": "SENASAG"
        })
    
    # 🚨 CAPÍTULO 03 (Pescados): Restricción Sanitaria (AMARILLO)
    if capitulo == '03':
        restricciones.append({
            "nivel": "🟡 Restricción",
            "mensaje": "Requiere Certificado Sanitario de Importación Obligatorio (Pescados y Crustáceos).",
            "norma_legal": "D.S. 515, Res. 123/98",
            "organismo": "SENASAG"
        })
    
    # 🚨 Validación por UM (Aplica a CUALQUIER Capítulo 01, 02 o 03)
    # Asume que la mayoría de los productos de estos capítulos se miden en KG
    if capitulo in ('01', '02', '03') and um_facturada not in ('KG', 'UNIDAD'):
        restricciones.append({
            "nivel": "🟡 Restricción (UM)",
            "mensaje": f"La UM Facturada ('{um_facturada}') es INCORRECTA. La UM legal para este capítulo es 'KG' o 'UNIDAD'.",
            "norma_legal": "Nomenclatura Aduanera V2022",
            "organismo": "Aduana Nacional"
        })
        
    return restricciones