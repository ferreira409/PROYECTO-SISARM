// sisarm-frontend/assets/js/main.js - VERSIÓN MAESTRA FINAL (V15 - Novedades como Sección)

const API_BASE_URL = 'http://localhost:5000/api/v1'; 
const USER_ID = 'despachante_001'; 
const NOVEDADES_API_URL = `${API_BASE_URL}/novedades`;
const LAST_READ_NEWS_KEY = 'sisarm_last_read_news_id'; // (VC6)

// --- ELEMENTOS GLOBALES DEL DOM ---
const loadingMessage = document.getElementById('loading-message'); 
const btnSearch = document.querySelector('.search-box button'); 

// Filtros Globales (Pestaña Principal)
const codigoInputPredictive = document.getElementById('codigo-input-predictive');
const suggestionsList = document.getElementById('suggestions-list');
const filterFormAdvanced = document.getElementById('filter-form-advanced');
const capituloInput = document.getElementById('filter-capitulo'); 
const partidaInput = document.getElementById('filter-partida'); 
const subpartidaAdvancedInput = document.getElementById('filter-subpartida'); 
// Campos RUC/NIT Duales
const clienteRucInputPredictive = document.getElementById('cliente-ruc-input-predictive');
const clienteRucInputAdvanced = document.getElementById('cliente-ruc-input-advanced');
const paisOrigenInput = document.getElementById('pais-origen-input');
const umFacturadaInput = document.getElementById('um-facturada-input');

// Elementos de Riesgo (Principal)
const alertaPreferenciaContainer = document.getElementById('alerta-preferencia-container');
const alertaRestriccionContainer = document.getElementById('alerta-restriccion-container');

// Elementos de Historial
const historialSection = document.getElementById('historial-section');
const historialTableContainer = document.getElementById('historial-table-results');
const historialLoadingMessage = document.getElementById('historial-loading-message');
const historialLoadTime = document.getElementById('historial-load-time');
const historialSearchInput = document.getElementById('historial-search');
const historialRiesgoSelect = document.getElementById('historial-marcador-riesgo');
const historialStartDateInput = document.getElementById('historial-start-date');
const historialEndDateInput = document.getElementById('historial-end-date');
const btnFilterHistorial = document.getElementById('btn-filter-historial');

// Elementos Contextuales (Principal)
const notasLegalesContent = document.getElementById('notas-legales-content');
const contextualSearchInput = document.getElementById('contextual-search-input');
const contextualPrevBtn = document.getElementById('contextual-prev-btn');
const contextualNextBtn = document.getElementById('contextual-next-btn');
const contextualCount = document.getElementById('contextual-count');

let currentFocus = -1; 
let latestAutocompleteResults = [];
let highlightedElements = [];
let currentHighlightIndex = -1; 


// =========================================================
// 1. GESTOR DE PESTAÑAS (HU-008) - CORE
// =========================================================
const TabsManager = {
    tabs: new Map(),
    activeTabId: 'main',

    init() {
        this.tabs.set('main', { id: 'main', title: 'Buscador Principal', code: null });
        const mainBtn = document.querySelector('.tab-item.active');
        if (mainBtn && !mainBtn.id) mainBtn.id = 'btn-main';
    },

    openNewTab(code, dataToRender = null) {
        if (!code) return;
        const tabId = `tab-${code.replace(/\./g, '')}`;
        
        if (this.tabs.has(tabId)) {
            this.switchTo(tabId);
            return;
        }

        if (this.tabs.size >= 10) {
            alert("Máximo de 10 pestañas alcanzado. Cierre algunas para continuar.");
            return;
        }

        // Crear botón de pestaña
        const tabBtn = document.createElement('div');
        tabBtn.className = 'tab-item';
        tabBtn.id = `btn-${tabId}`;
        tabBtn.innerHTML = `
            <span class="tab-icon">📄</span> ${code}
            <button class="tab-close-btn" onclick="event.stopPropagation(); TabsManager.closeTab('${tabId}')" title="Cerrar pestaña">×</button>
        `;
        tabBtn.onclick = () => this.switchTo(tabId);
        document.getElementById('tabs-bar').appendChild(tabBtn);

        // Crear panel de contenido
        const tabPane = document.createElement('div');
        tabPane.id = `pane-${tabId}`;
        tabPane.className = 'tab-content';
        tabPane.innerHTML = `
            <div class="results-container card" style="margin-top: 20px;">
                <h3 class="section-title">Ficha Técnica: ${code}</h3>
                <div id="results-${tabId}" class="table-responsive" style="min-height: 100px;">
                    <p class="loading-message">Cargando información...</p>
                </div>
            </div>
            <div class="info-grid">
                <div class="contextual-section card">
                    <div class="section-header"><h4>📖 Notas Legales Asociadas</h4></div>
                    <div id="notes-${tabId}" class="scrollable-content">
                        <p class="placeholder-text">Cargando notas...</p>
                    </div>
                </div>
                <div class="contextual-section card">
                    <div class="section-header"><h4>📄 Documentación y Requisitos</h4></div>
                    <div id="docs-${tabId}" class="scrollable-content">
                        <p class="placeholder-text">Verificando requisitos...</p>
                    </div>
                </div>
            </div>
        `;
        document.getElementById('dynamic-tabs-container').appendChild(tabPane);

        this.tabs.set(tabId, { id: tabId, title: code, code: code });
        this.switchTo(tabId);

        if (dataToRender) {
            this.renderInTab(tabId, dataToRender);
        } else {
            fetchArancelDetail(code, tabId); 
        }
    },

    switchTo(tabId) {
        if (!this.tabs.has(tabId)) return;

        // Desactivar actual
        const currentBtn = document.getElementById(`btn-${this.activeTabId}`);
        const currentPane = document.getElementById(this.activeTabId === 'main' ? 'tab-content-main' : `pane-${this.activeTabId}`);
        if (currentBtn) currentBtn.classList.remove('active');
        if (currentPane) currentPane.classList.remove('active');

        // Activar nueva
        this.activeTabId = tabId;
        const newBtn = document.getElementById(tabId === 'main' ? 'btn-main' : `btn-${tabId}`);
        const newPane = document.getElementById(tabId === 'main' ? 'tab-content-main' : `pane-${tabId}`);
        if (newBtn) newBtn.classList.add('active');
        if (newPane) newPane.classList.add('active');

        if (newBtn) newBtn.scrollIntoView({ behavior: 'smooth', block: 'nearest', inline: 'center' });
    },

    closeTab(tabId) {
        if (tabId === 'main') return;

        document.getElementById(`btn-${tabId}`)?.remove();
        document.getElementById(`pane-${tabId}`)?.remove();
        this.tabs.delete(tabId);

        if (this.activeTabId === tabId) {
            this.switchTo('main');
        }
    },

    renderInTab(tabId, data) {
        const resultsContainer = document.getElementById(`results-${tabId}`);
        const notesContainer = document.getElementById(`notes-${tabId}`);
        const docsContainer = document.getElementById(`docs-${tabId}`);

        if (!resultsContainer || !data || data.length === 0) {
            if (resultsContainer) resultsContainer.innerHTML = '<p class="error-message p-4">No se encontraron datos para esta partida.</p>';
            return;
        }

        // Render Tabla Pestaña
        let html = `
            <div class="table-responsive" style="margin:0;">
                <table class="arancel-table" style="width:100%; margin:0;">
                    <thead>
                        <tr>
                            <th>Código</th><th>Descripción</th><th class="center-text">GA%</th><th class="center-text">IEHD%</th>
                            <th class="center-text">Unidad</th><th>Doc. Req.</th><th class="center-text">Tipo Doc.</th>
                            <th>Entidad</th><th>Disp. Legal</th><th class="center-text">Frontera</th><th>Obs.</th>
                        </tr>
                    </thead>
                    <tbody>`;
        
        data.forEach(sp => {
            html += `
                <tr>
                    <td><strong>${sp.codigo_subpartida || 'N/A'}</strong></td>
                    <td style="min-width: 200px;">${sp.descripcion_subpartida || 'N/A'}</td>
                    <td class="center-text">${sp.GA_porcentaje || '0.00'}%</td>
                    <td class="center-text">${sp.IEHD_porcentaje || '0.00'}%</td>
                    <td class="center-text">${sp.unidad_medida || 'N/A'}</td>
                    <td>${sp.documento_requerido || 'No Req.'}</td>
                    <td class="center-text">${sp.tipo_documento || '-'}</td>
                    <td>${sp.tipo_entidad_emite || '-'}</td>
                    <td>${sp.disp_legal || '-'}</td>
                    <td class="center-text">${sp.medida_en_frontera || '-'}</td>
                    <td>${sp.observaciones || ''}</td>
                </tr>`;
        });
        html += `</tbody></table></div>`;
        
        // BOTONES DE ACCIÓN (PDF Y PERMALINK) CENTRADOS ABAJO
        html += `
            <div style="display: flex; justify-content: center; align-items: center; margin-top: 20px; gap: 15px;">
                <button class="btn btn-primary" onclick="openPDFModal('${data[0].codigo_subpartida}', ${data[0].GA_porcentaje})">
                    🖨️ Generar PDF
                </button>
                <button class="btn btn-icon-secondary" onclick="copyPermalink('${data[0].codigo_subpartida}')" title="Copiar enlace permanente">
                    🔗
                </button>
            </div>
        `;
        
        resultsContainer.innerHTML = html;

        // Render Notas y Documentos
        const first = data[0];
        notesContainer.innerHTML = `<div style="padding: 15px;">${autolinkText(first.notas_legales_capitulo || "Sin notas específicas.")}</div>`;
        
        if (first.documento_requerido && first.documento_requerido !== 'No Requerido') {
             docsContainer.innerHTML = `
                <ul style="padding: 15px 15px 15px 30px; margin: 0;">
                    <li><strong>Documento:</strong> ${first.documento_requerido}</li>
                    <li><strong>Tipo:</strong> ${first.tipo_documento || 'N/A'}</li>
                    <li><strong>Entidad Emisora:</strong> ${first.tipo_entidad_emite || 'N/A'}</li>
                    <li><strong>Base Legal:</strong> ${first.disp_legal || 'N/A'}</li>
                </ul>`;
        } else {
             docsContainer.innerHTML = '<p class="placeholder-text" style="padding-top: 20px;">No se requiere documentación específica.</p>';
        }
    }
};


// =========================================================
// 2. FUNCIONES DE UTILIDAD
// =========================================================

function displayError(message, tabId = 'main') {
    const containerId = tabId === 'main' ? 'arancel-table-results' : `results-${tabId}`;
    const container = document.getElementById(containerId);
    if (container) container.innerHTML = `<p class="error-message p-4">${message}</p>`;
    
    if (tabId === 'main') {
        document.getElementById('results-container').classList.remove('hidden');
        loadingMessage.classList.add('hidden'); 
        if (codigoInputPredictive) codigoInputPredictive.disabled = false;
    }
}

function autolinkText(text) {
    if (!text) return "";
    let linkedText = text.replace(/(Cap[ií]tulo\s+)(\d{2})\b/gi, (match, prefix, code) => {
        return `${prefix}<span class="tariff-link" data-code="${code}" title="Ir al Capítulo ${code}">${code}</span>`;
    });
    return linkedText.replace(/\b(\d{4}(\.\d{2})?(\.\d{2})?(\.\d{2})?)\b/g, (match) => {
        const cleanCode = match.replace(/\./g, '');
        if (cleanCode.length >= 4 && !isNaN(cleanCode) && !(cleanCode.startsWith('20') && cleanCode.length === 4)) {
             return `<span class="tariff-link" data-code="${cleanCode}" title="Abrir ficha de ${match}">${match}</span>`;
        }
        return match;
    });
}

// Helpers de Navegación
function addActive(x) {
    if (!x || x.length === 0) return false;
    removeActive(x);
    if (currentFocus >= x.length) currentFocus = 0;
    if (currentFocus < 0) currentFocus = (x.length - 1);
    x[currentFocus].classList.add("autocomplete-active");
    x[currentFocus].scrollIntoView({ block: "nearest" }); 
}
function removeActive(x) {
    for (let i = 0; i < x.length; i++) x[i].classList.remove("autocomplete-active");
}

/**
 * Muestra una notificación toast (Criterio 6)
 * @param {string} message - El mensaje a mostrar.
 * @param {string} type - 'success' (defecto) o 'error'.
 */
function showToast(message, type = 'success') {
    const toast = document.getElementById('toast-notification');
    if (!toast) return;
    
    toast.textContent = message;
    toast.className = 'toast'; // Resetea clases
    
    if (type === 'error') {
        toast.classList.add('error');
    }
    
    toast.classList.add('show');
    
    // Oculta el toast después de 3 segundos
    setTimeout(() => {
        toast.classList.remove('show');
    }, 3000);
}

/**
 * Copia texto al portapapeles usando el método fallback (Criterio 2)
 * @param {string} text - El texto a copiar.
 */
function copyToClipboard(text) {
    const textarea = document.createElement('textarea');
    textarea.value = text;
    textarea.style.position = 'fixed'; // Evita que la página salte
    textarea.style.opacity = 0;
    document.body.appendChild(textarea);
    textarea.select();
    
    try {
        document.execCommand('copy');
        showToast('¡Enlace copiado al portapapeles!');
    } catch (err) {
        console.error('Error al copiar el enlace:', err);
        showToast('Error al copiar el enlace', 'error');
    }
    
    document.body.removeChild(textarea);
}


// =========================================================
// 3. RENDERIZADO PESTAÑA PRINCIPAL
// =========================================================

function renderArancelTableMain(subpartidas) {
    const tableContainer = document.getElementById('arancel-table-results');
    if (!tableContainer) return;
    while (tableContainer.firstChild) tableContainer.removeChild(tableContainer.firstChild);
    
    if (!subpartidas || subpartidas.length === 0) {
        tableContainer.innerHTML = '<p class="p-4 text-center">No se encontraron subpartidas con ese criterio.</p>';
        document.getElementById('results-container').classList.remove('hidden');
        updateContextualSectionMain("No hay notas disponibles.");
        updateDocumentationSectionMain(null); 
        return;
    }
    
    const firstResult = subpartidas[0];
    updateContextualSectionMain(firstResult.notas_legales_capitulo);
    updateDocumentationSectionMain(firstResult);

    // Tabla Principal
    let html = `
        <div class="table-responsive overflow-x-auto">
            <table class="arancel-table min-w-full divide-y divide-gray-200">
                <thead>
                    <tr>
                        <th>Código</th><th>Descripción</th><th class="center-text">GA%</th><th class="center-text">IEHD%</th>
                        <th class="center-text">Und.</th><th>Doc. Req.</th><th class="center-text">Acción</th>
                    </tr>
                </thead>
                <tbody>
    `;
    subpartidas.forEach(sp => {
        html += `<tr>
            <td><strong>${sp.codigo_subpartida}</strong></td>
            <td>${sp.descripcion_subpartida}</td>
            <td class="center-text">${sp.GA_porcentaje}%</td>
            <td class="center-text">${sp.IEHD_porcentaje}%</td>
            <td class="center-text">${sp.unidad_medida}</td>
            <td>${sp.documento_requerido || '-'}</td>
            <td class="center-text">
                <button class="btn-icon-secondary" style="padding: 5px 10px; font-size: 0.9rem; width:auto; height:auto;" onclick="TabsManager.openNewTab('${sp.codigo_subpartida}')" title="Abrir en nueva pestaña">↗️</button>
            </td>
        </tr>`;
    });
    html += `</tbody></table></div>`;
    tableContainer.innerHTML = html;
    document.getElementById('results-container').classList.remove('hidden');
}

function updateContextualSectionMain(notas) {
    if (notasLegalesContent) {
        notasLegalesContent.innerHTML = `<p class="p-4">${autolinkText(notas || "Sin notas.")}</p>`; 
        if (contextualSearchInput) contextualSearchInput.value = '';
    }
}

function updateDocumentationSectionMain(data) {
    const docContent = document.getElementById('documentacion-content');
    if (!docContent) return;
    if (!data || !data.documento_requerido || data.documento_requerido === 'No Requerido') {
        docContent.innerHTML = '<p class="placeholder-text">No se requiere documentación específica.</p>'; return;
    }
    docContent.innerHTML = `<ul style="list-style-type: disc; padding: 20px;"><li><strong>Documento:</strong> ${data.documento_requerido}</li><li><strong>Tipo:</strong> ${data.tipo_documento || 'N/A'}</li><li><strong>Entidad:</strong> ${data.tipo_entidad_emite || 'N/A'}</li><li><strong>Legal:</strong> ${data.disp_legal || 'N/A'}</li></ul>`;
}


// =========================================================
// 4. LÓGICAS DE BÚSQUEDA (CORE)
// =========================================================

async function fetchAdvancedFilter() {
    loadingMessage.classList.remove('hidden');
    document.getElementById('results-container').classList.add('hidden'); 

    const params = new URLSearchParams();
    const cap = capituloInput.value.trim(); const par = partidaInput.value.trim();
    const sub = subpartidaAdvancedInput.value.trim(); const cli = clienteRucInputAdvanced.value.trim();

    if (cap) params.append('capitulo', cap); if (par) params.append('partida', par);
    if (sub) params.append('subpartida', sub); if (cli) params.append('cliente', cli);
    
    if (!cap && !par && !sub && !cli) {
        loadingMessage.classList.add('hidden'); displayError("Ingrese al menos un criterio."); return;
    }

    try {
        const response = await fetch(`${API_BASE_URL}/arancel/filter?${params.toString()}`, { headers: { 'X-User-ID': USER_ID } });
        const data = await response.json();
        if (response.ok) renderArancelTableMain(data); else displayError(data.error || "Error en filtro.");
    } catch (error) { displayError("Error de conexión."); } 
    finally { loadingMessage.classList.add('hidden'); }
}

async function fetchArancelDetail(codigo, targetTabId = 'main') {
    if (targetTabId === 'main') {
        loadingMessage.classList.remove('hidden'); 
        if(alertaPreferenciaContainer) alertaPreferenciaContainer.classList.add('hidden');
        if(alertaRestriccionContainer) alertaRestriccionContainer.classList.add('hidden');
        btnSearch.disabled = true;
    }
    
    const params = new URLSearchParams(); params.append('subpartida', codigo);
    if (targetTabId === 'main') {
        const cli = clienteRucInputPredictive.value.trim(); if (cli) params.append('cliente', cli);
    }
    
    try {
        const response = await fetch(`${API_BASE_URL}/arancel/filter?${params.toString()}`, { headers: { 'X-User-ID': USER_ID } });
        const data = await response.json();
        if (response.ok) {
            if (targetTabId === 'main') {
                renderArancelTableMain(data); 
                evaluarRiesgoYPreferencia(codigo, paisOrigenInput.value.trim(), umFacturadaInput.value.trim());
            } else {
                TabsManager.renderInTab(targetTabId, data);
            }
        } else displayError(data.error || "Error al cargar.", targetTabId);
    } catch (error) { displayError("Error de conexión.", targetTabId); } 
    finally {
        if (targetTabId === 'main') {
            loadingMessage.classList.add('hidden');
            codigoInputPredictive.disabled = false; btnSearch.disabled = true;
        }
    }
}

async function fetchAutocomplete(query) {
    if (query.length < 3) { suggestionsList.classList.add('hidden'); return; }
    try {
        const response = await fetch(`${API_BASE_URL}/aranceles/autocomplete?query=${query}`);
        latestAutocompleteResults = await response.json();
        let html = '';
        if (latestAutocompleteResults && latestAutocompleteResults.length > 0) {
            latestAutocompleteResults.forEach(item => { html += `<li onclick="handleSuggestionClick('${item.codigo}')">${item.codigo} - ${item.descripcion}</li>`; });
            suggestionsList.innerHTML = html; suggestionsList.classList.remove('hidden'); currentFocus = -1;
        } else suggestionsList.classList.add('hidden');
    } catch (error) { suggestionsList.classList.add('hidden'); }
}
function handleSuggestionClick(codigo) {
    codigoInputPredictive.value = codigo;
    fetchArancelDetail(codigo); suggestionsList.classList.add('hidden'); currentFocus = -1;
}


// =========================================================
// 5. RIESGO, HISTORIAL Y ESTADÍSTICAS
// =========================================================

async function evaluarRiesgoYPreferencia(subpartida, paisOrigen, umFacturada) {
    if (!alertaPreferenciaContainer || !alertaRestriccionContainer) return;
    alertaPreferenciaContainer.classList.add('hidden'); alertaRestriccionContainer.classList.add('hidden');
    if (subpartida.length < 6 || !paisOrigen || !umFacturada) return;
    try {
        const response = await fetch(`${API_BASE_URL}/riesgo/?subpartida=${subpartida}&pais_origen=${paisOrigen}&um_facturada=${umFacturada}`, { headers: { 'X-User-ID': USER_ID } });
        const data = await response.json();
        if (!response.ok) return;

        if (data.preferencia) {
            const p = data.preferencia;
            alertaPreferenciaContainer.className = 'alert-banner alert-green';
            alertaPreferenciaContainer.innerHTML = `🟢 Beneficio TLC (${p.nivel}): ${p.mensaje}<br>Ahorro: ${p.beneficio}`;
            alertaPreferenciaContainer.classList.remove('hidden');
        }
        if (data.restricciones && data.restricciones.length > 0) {
            let html = `🔥 RIESGO ADUANERO (${data.restricciones.length})<hr style="margin: 5px 0;">`;
            let nivelAlertaPrincipal = 'alert-yellow';
            data.restricciones.forEach(r => {
                if (r.nivel.includes('Prohibición')) nivelAlertaPrincipal = 'alert-red'; 
                html += `**${r.nivel}**: ${r.mensaje}<br>`;
            });
            alertaRestriccionContainer.className = `alert-banner ${nivelAlertaPrincipal}`; 
            alertaRestriccionContainer.innerHTML = html; alertaRestriccionContainer.classList.remove('hidden');
        }
    } catch (error) { console.error(error); }
}

async function fetchHistorial(filters = {}) {
    if(historialLoadingMessage) historialLoadingMessage.classList.remove('hidden');
    if(historialTableContainer) historialTableContainer.innerHTML = ''; 
    const params = new URLSearchParams();
    if (filters.q) params.append('q', filters.q); if (filters.marcador) params.append('marcador', filters.marcador);
    if (filters.start_date) params.append('start_date', filters.start_date); if (filters.end_date) params.append('end_date', filters.end_date);
    try {
        const response = await fetch(`${API_BASE_URL}/historial?${params.toString()}`, { headers: { 'X-User-ID': USER_ID } });
        const data = await response.json();
        if (response.ok) {
            if (data.length === 0) { historialTableContainer.innerHTML = '<p class="placeholder-text">No se encontraron registros.</p>'; }
            else {
                let html = `<table class="arancel-table min-w-full"><thead><tr><th>Fecha</th><th>Partida</th><th>RUC/NIT</th><th>Riesgo</th></tr></thead><tbody>`;
                data.forEach(item => {
                    const riskClass = item.marcador_riesgo ? item.marcador_riesgo.toLowerCase() : 'low';
                    html += `<tr><td>${item.fecha_hora}</td><td>${item.partida_arancelaria}</td><td>${item.cliente_ruc}</td><td data-label="Riesgo"><span class="risk-marker ${riskClass}"><span class="risk-tooltip">${item.motivo_riesgo || 'Sin detalle'}</span></span>${item.marcador_riesgo || 'BAJO'}</td></tr>`;
                });
                html += `</tbody></table>`; historialTableContainer.innerHTML = html;
            }
        }
    } catch (error) { historialTableContainer.innerHTML = `<p class="error-message">Error de conexión.</p>`; } 
    finally { if(historialLoadingMessage) historialLoadingMessage.classList.add('hidden'); }
}

async function fetchStats() {
    const statsLoading = document.getElementById('stats-loading');
    const statsTableBody = document.getElementById('stats-table-body');
    if (statsLoading) statsLoading.classList.remove('hidden'); if (statsTableBody) statsTableBody.innerHTML = ''; 
    try {
        const response = await fetch(`${API_BASE_URL}/stats/promedio-ga`);
        const data = await response.json();
        if (response.ok && statsTableBody) {
            if (data.length === 0) { statsTableBody.innerHTML = '<tr><td colspan="2" style="text-align:center;">Sin datos.</td></tr>'; return; }
            let html = '';
            data.forEach(item => {
                let colorStyle = item.promedio_ga > 15 ? 'color: var(--color-danger);' : (item.promedio_ga < 5 ? 'color: var(--color-success);' : '');
                html += `<tr><td style="text-align: center; font-weight: bold;">Capítulo ${item.capitulo}</td><td style="text-align: center; font-weight: bold; ${colorStyle}">${item.promedio_ga}%</td></tr>`;
            });
            statsTableBody.innerHTML = html;
        }
    } catch (error) { if (statsTableBody) statsTableBody.innerHTML = '<tr><td colspan="2" class="error-message">Error de conexión.</td></tr>'; } 
    finally { if (statsLoading) statsLoading.classList.add('hidden'); }
}


// =========================================================
// 6. FAVORITOS (HU-007)
// =========================================================

function toggleFavoritesPanel() {
    document.getElementById('favorites-panel').classList.toggle('open');
    document.getElementById('panel-overlay').classList.toggle('hidden');
    if (document.getElementById('favorites-panel').classList.contains('open')) renderFavoritesList();
}

function saveCurrentSearch(type) {
    let params = {}, nameDefault = "";
    if (type === 'predictive') {
        const code = codigoInputPredictive.value.trim();
        if (!code && !paisOrigenInput.value && !clienteRucInputPredictive.value) { alert("Ingrese parámetros primero."); return; }
        params = { subpartida: code, pais: paisOrigenInput.value.trim(), um: umFacturadaInput.value.trim(), cliente: clienteRucInputPredictive.value.trim() };
        nameDefault = code ? `Partida ${code}` : `Búsqueda Predictiva`;
    } else if (type === 'advanced') {
        const cap = capituloInput.value.trim(), par = partidaInput.value.trim(), sub = subpartidaAdvancedInput.value.trim(), cli = clienteRucInputAdvanced.value.trim();
        if (!cap && !par && !sub && !cli) { alert("Configure filtros primero."); return; }
        params = { capitulo: cap, partida: par, subpartida: sub, cliente: cli };
        nameDefault = `Filtro ${cap || par || sub || cli}`;
    } else if (type === 'historial') {
        params = { q: historialSearchInput.value.trim(), marcador: historialRiesgoSelect.value, start: historialStartDateInput.value.trim(), end: historialEndDateInput.value.trim() };
        nameDefault = "Mi Historial";
    }
    const name = prompt("Nombre para esta búsqueda:", nameDefault);
    if (name) {
        const favs = JSON.parse(localStorage.getItem('sisarm_favorites') || '[]');
        favs.push({ id: Date.now(), name, type, params, createdAt: new Date().toISOString() });
        localStorage.setItem('sisarm_favorites', JSON.stringify(favs));
        alert("¡Guardado!"); renderFavoritesList();
    }
}

function renderFavoritesList() {
    const listEl = document.getElementById('favorites-list');
    const favs = JSON.parse(localStorage.getItem('sisarm_favorites') || '[]');
    if (favs.length === 0) { listEl.innerHTML = '<p class="placeholder-text" style="padding-top: 20px; font-size: 0.9rem;">Sin favoritos.</p>'; return; }
    listEl.innerHTML = '';
    favs.forEach(fav => {
        const li = document.createElement('li'); li.className = 'favorite-item';
        li.innerHTML = `<div class="fav-info" onclick="loadFavorite(${fav.id})"><span class="fav-name">${fav.name}</span><span class="fav-details">${fav.type.toUpperCase()} - ${new Date(fav.createdAt).toLocaleDateString()}</span></div><div class="fav-actions"><button class="fav-action-btn delete" onclick="deleteFavorite(${fav.id})" title="Eliminar">🗑️</button></div>`;
        listEl.appendChild(li);
    });
}

function deleteFavorite(id) {
    if (confirm("¿Eliminar?")) {
        const favs = JSON.parse(localStorage.getItem('sisarm_favorites') || '[]').filter(f => f.id !== id);
        localStorage.setItem('sisarm_favorites', JSON.stringify(favs)); renderFavoritesList();
    }
}

function loadFavorite(id) {
    const fav = JSON.parse(localStorage.getItem('sisarm_favorites') || '[]').find(f => f.id === id); if (!fav) return;
    toggleFavoritesPanel();
    TabsManager.switchTo('main'); // Siempre volver a main para cargar favoritos
    if (fav.type === 'predictive') {
        showSection('arancel-search-section'); codigoInputPredictive.value = fav.params.subpartida || ''; paisOrigenInput.value = fav.params.pais || ''; umFacturadaInput.value = fav.params.um || ''; clienteRucInputPredictive.value = fav.params.cliente || ''; fetchArancelDetail(fav.params.subpartida || '');
    } else if (fav.type === 'advanced') {
        showSection('arancel-search-section'); capituloInput.value = fav.params.capitulo || ''; partidaInput.value = fav.params.partida || ''; subpartidaAdvancedInput.value = fav.params.subpartida || ''; clienteRucInputAdvanced.value = fav.params.cliente || ''; fetchAdvancedFilter();
    } else if (fav.type === 'historial') {
        showSection('historial-section'); historialSearchInput.value = fav.params.q || ''; historialRiesgoSelect.value = fav.params.marcador || ''; historialStartDateInput.value = fav.params.start || ''; historialEndDateInput.value = fav.params.end || ''; fetchHistorial(fav.params);
    }
}


// =========================================================
// 7. EVENT LISTENERS GLOBALES
// =========================================================

if (codigoInputPredictive) {
    codigoInputPredictive.addEventListener('input', (e) => { fetchAutocomplete(e.target.value.trim()); btnSearch.disabled = e.target.value.length < 6; });
    codigoInputPredictive.addEventListener("keydown", (e) => { if ([13,38,40].includes(e.keyCode)) e.preventDefault(); if (e.keyCode===40) { currentFocus++; addActive(suggestionsList.children); } else if (e.keyCode===38) { currentFocus--; addActive(suggestionsList.children); } else if (e.keyCode===13) { if (currentFocus > -1) suggestionsList.children[currentFocus].click(); else if (!btnSearch.disabled) btnSearch.click(); } });
}
if (btnSearch) btnSearch.addEventListener('click', () => fetchArancelDetail(codigoInputPredictive.value.trim()));
if (filterFormAdvanced) filterFormAdvanced.addEventListener('submit', (e) => { e.preventDefault(); fetchAdvancedFilter(); });

// Listeners Contextuales
function applyHighlight(query) {
    removeHighlights(); if (!query || !notasLegalesContent) return;
    const regex = new RegExp(`(${query})`, 'gi');
    function walkAndReplace(node) {
        if (node.nodeType === 3 && node.textContent.match(regex)) {
            const fragment = document.createDocumentFragment(); const parts = node.textContent.split(regex);
            parts.forEach((part, index) => { if (index % 2 !== 0) { const span = document.createElement('span'); span.className = 'highlight'; span.textContent = part; highlightedElements.push(span); fragment.appendChild(span); } else fragment.appendChild(document.createTextNode(part)); });
            node.parentNode.replaceChild(fragment, node);
        } else if (node.nodeType === 1 && node.nodeName !== 'BUTTON' && node.className !== 'highlight') Array.from(node.childNodes).forEach(walkAndReplace);
    }
    walkAndReplace(notasLegalesContent);
    if (highlightedElements.length > 0) { if (contextualNextBtn) contextualNextBtn.disabled = false; highlightNext(); }
}
function removeHighlights() {
    highlightedElements.forEach(el => { const parent = el.parentNode; parent.replaceChild(document.createTextNode(el.textContent), el); parent.normalize(); });
    highlightedElements = []; currentHighlightIndex = -1;
    if (contextualCount) contextualCount.textContent = ''; if (contextualNextBtn) contextualNextBtn.disabled = true;
}
function navigateHighlight(direction) {
    if (highlightedElements.length === 0) return;
    if (currentHighlightIndex >= 0) highlightedElements[currentHighlightIndex].classList.remove('active');
    if (direction === 'next') currentHighlightIndex = (currentHighlightIndex + 1) % highlightedElements.length; else currentHighlightIndex = (currentHighlightIndex - 1 + highlightedElements.length) % highlightedElements.length;
    const newHighlight = highlightedElements[currentHighlightIndex];
    newHighlight.classList.add('active'); newHighlight.scrollIntoView({ behavior: 'smooth', block: 'center' });
    if (contextualCount) contextualCount.textContent = `${currentHighlightIndex + 1} de ${highlightedElements.length}`;
}
const highlightNext = () => navigateHighlight('next');
const highlightPrev = () => navigateHighlight('prev');
if (contextualSearchInput) contextualSearchInput.addEventListener('input', (e) => applyHighlight(e.target.value.trim()));
if (contextualNextBtn) contextualNextBtn.addEventListener('click', highlightNext);
if (contextualPrevBtn) contextualPrevBtn.addEventListener('click', highlightPrev);

if (btnFilterHistorial) btnFilterHistorial.addEventListener('click', () => fetchHistorial({ q: historialSearchInput.value.trim(), marcador: historialRiesgoSelect.value, start: historialStartDateInput.value.trim(), end: historialEndDateInput.value.trim() }));

document.addEventListener('click', (e) => {
    if (e.target && e.target.classList.contains('tariff-link')) {
        const code = e.target.dataset.code;
        if (code) TabsManager.openNewTab(code);
    }
});


// =========================================================
// 8. ESTADO DEL SISTEMA (HU-UPDATE)
// =========================================================

async function fetchSystemStatus() {
    const statusBar = document.getElementById('system-status-bar');
    const statusDateEl = document.getElementById('status-date');
    const statusSourceEl = document.getElementById('status-source');
    const statusRefEl = document.getElementById('status-ref');

    if (!statusBar) return;

    // MOCK DATA (Actualizado)
    const mockApiResponse = {
        last_sync: new Date().toISOString(),
        source_name: "Aduana Nacional (Oficial)",
        source_url: "https://www.aduana.gob.bo/INSTI_mision",
        ref_doc: "Normativa Vigente 2025",
        ref_url: "https://www.aduana.gob.bo/node/1384478"
    };

    try {
        // const response = await fetch(`${API_BASE_URL}/system/status`); const data = await response.json();
        const data = mockApiResponse; 

        const lastSyncDate = new Date(data.last_sync);
        const now = new Date();
        const diffHours = Math.abs(now - lastSyncDate) / 36e5;

        const formattedDate = lastSyncDate.toLocaleString('es-BO', {
            day: '2-digit', month: '2-digit', year: 'numeric', hour: '2-digit', minute: '2-digit'
        });

        let dateText = `Actualizado: ${formattedDate}`;
        if (diffHours > 12) {
             dateText += ` (⚠️ Datos potencialmente desactualizados)`;
             statusBar.classList.add(diffHours > 48 ? 'danger' : 'warning');
        } else {
             statusBar.classList.remove('warning', 'danger');
        }
        
        statusDateEl.textContent = dateText;
        statusSourceEl.innerHTML = `Fuente: <a href="${data.source_url}" target="_blank" class="status-link" title="Ir a fuente oficial">${data.source_name}</a>`;
        statusRefEl.innerHTML = `Ref: <a href="${data.ref_url}" target="_blank" class="status-link" title="Ver normativa">${data.ref_doc}</a>`;

        statusBar.classList.remove('hidden');

    } catch (error) {
        console.error("Error fetching status:", error);
        statusBar.classList.add('danger');
        statusDateEl.textContent = "Error de conexión con servidor de actualizaciones.";
        statusBar.classList.remove('hidden');
    }
}


// =========================================================
// 9. GENERADOR DE REPORTES PDF (HU-PDF)
// =========================================================

let currentPDFData = null;

function openPDFModal(codigo, ga) {
    currentPDFData = { codigo, ga };
    document.getElementById('pdf-modal-partida').textContent = codigo;
    document.getElementById('pdf-options-modal').classList.remove('hidden');
}

function closePDFModal() {
    document.getElementById('pdf-options-modal').classList.add('hidden');
    currentPDFData = null;
}

document.getElementById('btn-generate-pdf-confirm').addEventListener('click', () => {
    if (!currentPDFData) return;
    generatePDFReport(currentPDFData);
    closePDFModal();
});

async function generatePDFReport(data) {
    const { jsPDF } = window.jspdf;
    const doc = new jsPDF();
    
    const cifValue = parseFloat(document.getElementById('pdf-cif-value').value) || 10000;
    const includeTaxes = document.getElementById('check-taxes').checked;
    const includeLogistics = document.getElementById('check-logistics').checked;
    const includeFees = document.getElementById('check-fees').checked;

    // 1. LOGO Y HEADER AGENCIA
    doc.setFillColor(138, 43, 226);
    doc.rect(14, 15, 15, 15, 'F');
    doc.setTextColor(0, 0, 0);
    doc.setFontSize(16); doc.setFont("helvetica", "bold");
    doc.text("AGENCIA DESPACHANTE DE ADUANA", 35, 22);
    doc.setFontSize(10); doc.setFont("helvetica", "normal");
    doc.text('"SISARM BOLIVIA S.R.L."', 35, 27);
    doc.setTextColor(100);
    doc.text("Av. La Salle Nº 123, Santa Cruz - Bolivia | Telf: 3-3333333", 35, 32);

    // 2. HEADER REPORTE
    doc.setDrawColor(200); doc.line(14, 38, 196, 38);
    doc.setFontSize(18); doc.setTextColor(138, 43, 226);
    doc.text("PROFORMA DE IMPORTACIÓN", 105, 50, null, null, "center");
    
    doc.setFontSize(10); doc.setTextColor(0);
    const today = new Date().toLocaleDateString('es-BO');
    doc.text(`Fecha: ${today}`, 14, 60);
    doc.text(`Partida Arancelaria: ${data.codigo}`, 14, 65);
    doc.text(`Valor CIF Estimado: $us ${cifValue.toLocaleString('es-BO', {minimumFractionDigits: 2})}`, 14, 70);

    // 3. CÁLCULOS Y TABLAS
    let totalGeneral = 0;
    let startY = 80;

    if (includeTaxes) {
        const gaValue = cifValue * (data.ga / 100);
        const baseIVA = cifValue + gaValue;
        const ivaValue = baseIVA * 0.1494; 
        const totalImpuestos = gaValue + ivaValue;
        totalGeneral += totalImpuestos;

        doc.autoTable({
            startY: startY,
            head: [['CONCEPTO ADUANERO', 'BASE ($us)', 'TASA (%)', 'IMPORTE ($us)']],
            body: [
                ['Gravamen Arancelario (GA)', cifValue.toFixed(2), `${data.ga}%`, gaValue.toFixed(2)],
                ['Impuesto al Valor Agregado (IVA)', baseIVA.toFixed(2), '14.94%', ivaValue.toFixed(2)],
                [{content: 'TOTAL TRIBUTOS ADUANEROS', colSpan: 3, styles: {fontStyle: 'bold', halign: 'right'}}, totalImpuestos.toFixed(2)]
            ],
            theme: 'striped', headStyles: { fillColor: [138, 43, 226] }, styles: { fontSize: 9 }
        });
        startY = doc.lastAutoTable.finalY + 10;
    }

    if (includeLogistics || includeFees) {
        let logisticsBody = [];
        let subtotalServicios = 0;
        if (includeLogistics) {
            const almacenaje = cifValue * 0.015;
            const transporte = 150.00;
            logisticsBody.push(['Almacenaje Aduanero (Estimado)', almacenaje.toFixed(2)]);
            logisticsBody.push(['Transporte Local', transporte.toFixed(2)]);
            subtotalServicios += almacenaje + transporte;
        }
        if (includeFees) {
            const honorarios = Math.max(cifValue * 0.02, 100);
            logisticsBody.push(['Honorarios Profesionales Agencia', honorarios.toFixed(2)]);
            subtotalServicios += honorarios;
        }
        logisticsBody.push([{content: 'TOTAL SERVICIOS LOGÍSTICOS', styles: {fontStyle: 'bold', halign: 'right'}}, subtotalServicios.toFixed(2)]);
        totalGeneral += subtotalServicios;

        doc.autoTable({
            startY: startY,
            head: [['SERVICIOS LOGÍSTICOS Y OPERATIVOS', 'IMPORTE ($us)']],
            body: logisticsBody,
            theme: 'striped', headStyles: { fillColor: [60, 60, 60] }, styles: { fontSize: 9 }
        });
        startY = doc.lastAutoTable.finalY + 15;
    }

    // 4. TOTALES Y FOOTER
    doc.setFontSize(14); doc.setTextColor(0); doc.setFont("helvetica", "bold");
    doc.text(`TOTAL GENERAL ESTIMADO: $us ${totalGeneral.toLocaleString('es-BO', {minimumFractionDigits: 2})}`, 196, startY, null, null, "right");

    doc.setFontSize(8); doc.setTextColor(150); doc.setFont("helvetica", "normal");
    doc.text("Nota: Esta proforma es una estimación basada en los datos provistos y la normativa vigente.", 105, 280, null, null, "center");
    doc.text(`Generado por SISARM - ${new Date().toLocaleString()}`, 105, 285, null, null, "center");

    doc.save(`Proforma_${data.codigo}_${today.replace(/\//g, '-')}.pdf`);
}

// =========================================================
// 10. LÓGICA DE PERMALINKS (HU-PERMALINK)
// =========================================================

/**
 * Genera y copia un enlace permanente a la partida
 * @param {string} codigo - El código de la partida (ej. 0203.19.10.00)
 */
function copyPermalink(codigo) {
    const cleanCode = codigo.replace(/\./g, '');
    const url = `${window.location.origin}${window.location.pathname}#partida=${cleanCode}`;
    copyToClipboard(url);
}

/**
 * Lee la URL al cargar la página para abrir una partida
 */
function handlePermalink() {
    if (window.location.hash && window.location.hash.startsWith('#partida=')) {
        const codigo = window.location.hash.substring(9); // Longitud de '#partida='
        if (codigo) {
            // Formatear el código (ej. 8471300000 -> 8471.30.00.00)
            const formattedCode = codigo.replace(/(\d{4})(\d{2})(\d{2})(\d{2})/, '$1.$2.$3.$4');
            
            setTimeout(() => {
                TabsManager.openNewTab(formattedCode);
            }, 100);

            // Limpiar el hash
            history.replaceState(null, document.title, window.location.pathname + window.location.search);
        }
    }
}


// =========================================================
// 11. TUTORIAL INTERACTIVO (HU-TOUR) - (ACTUALIZADO A 6 PASOS)
// =========================================================

let globalTour; // Variable para almacenar la instancia del tour

/**
 * Define e inicia el recorrido interactivo.
 */
function startTour() {
    if (globalTour) {
        globalTour.cancel();
    }

    const tour = new Shepherd.Tour({
        useModalOverlay: true, 
        defaultStepOptions: {
            classes: 'shepherd-element data-theme="sisarm-dark"',
            scrollTo: true,
            cancelIcon: {
                enabled: true,
                label: 'Cerrar tutorial'
            }
        }
    });

    // --- DEFINICIÓN DE PASOS ---

    tour.addStep({
        id: 'step-welcome',
        title: '¡Bienvenido a SISARM!',
        text: 'Le guiaremos por las funciones clave en 1 minuto. Este es su panel principal de búsqueda arancelaria.',
        attachTo: { element: '.hero-content', on: 'bottom' },
        buttons: [
            { text: 'Salir', action: tour.cancel },
            { text: 'Comenzar', action: tour.next }
        ]
    });

    tour.addStep({
        id: 'step-status',
        title: 'Novedades y Estado',
        text: 'Aquí verá la fecha de la última actualización de datos de Aduana. Es vital para saber si trabaja con la normativa vigente.',
        attachTo: { element: '#system-status-bar', on: 'bottom' },
        buttons: [
            { text: 'Atrás', action: tour.back },
            { text: 'Siguiente', action: tour.next }
        ]
    });

    // PASO 3 ACTUALIZADO: Apunta al botón de la barra
    tour.addStep({
        id: 'step-novedades',
        title: 'Acceso a Novedades',
        text: 'Agregamos una nueva sección. Haga clic aquí para ver las últimas modificaciones de Aduana. El contador rojo le avisará si hay algo nuevo.',
        attachTo: { element: '#nav-btn-novedades', on: 'bottom' },
        buttons: [
            { text: 'Atrás', action: tour.back },
            { text: 'Siguiente', action: tour.next }
        ]
    });

    tour.addStep({
        id: 'step-search',
        title: 'Búsqueda Rápida',
        text: 'Este es su campo principal. Escriba un código (Ej: 0101) o una descripción (Ej: Caballos) y el sistema le sugerirá resultados.',
        attachTo: { element: '.autocomplete-container', on: 'bottom' },
        buttons: [
            { text: 'Atrás', action: tour.back },
            { text: 'Siguiente', action: tour.next }
        ]
    });

    tour.addStep({
        id: 'step-favorites',
        title: 'Panel de Favoritos',
        text: 'Use este botón para abrir su panel de búsquedas guardadas. Ahorre tiempo guardando sus filtros más frecuentes.',
        attachTo: { element: '.favorites-toggle-btn', on: 'left' },
        buttons: [
            { text: 'Atrás', action: tour.back },
            { text: 'Siguiente', action: tour.next }
        ]
    });

    // Último paso
    tour.addStep({
        id: 'step-historial',
        title: 'Historial y Estadísticas',
        text: 'Finalmente, aquí puede consultar su historial de búsquedas y ver estadísticas.',
        attachTo: { element: 'button[onclick*="historial-section"]', on: 'bottom' },
        buttons: [
            { text: 'Atrás', action: tour.back },
            { text: 'Finalizar', action: tour.complete }
        ]
    });

    // --- LÓGICA DE INICIO Y FIN ---
    tour.on('complete', () => {
        localStorage.setItem('sisarm_tour_completed', 'true');
    });

    tour.on('cancel', () => {
        const currentStep = tour.getCurrentStep();
        if (currentStep && currentStep.id !== 'step-historial') { 
            if (confirm("Ha cerrado el tutorial. ¿Desea marcarlo como completado para no volver a verlo?")) {
                localStorage.setItem('sisarm_tour_completed', 'true');
            }
        }
    });

    globalTour = tour;
    tour.start();
}


// =========================================================
// 12. GESTOR DE NOVEDADES (HU-NOVEDADES)
// =========================================================

// (VC2) Simulación de la API.
const mockNovedades = [
    { id: 105, categoria: "urgente", titulo: "Prohibición de Importación: Neumáticos Usados", resumen: "Se prohíbe el ingreso de neumáticos (llantas) usados bajo la subpartida 4012.20.00.00.", enlace_oficial: "#", fecha: "2025-11-12T10:00:00Z" },
    { id: 104, categoria: "arancel", titulo: "Modificación GA: Vehículos Híbridos", resumen: "Se reduce el Gravamen Arancelario (GA) para vehículos híbridos (8703.40) al 5%.", enlace_oficial: "#", fecha: "2025-11-11T09:00:00Z" },
    { id: 103, categoria: "noticia", titulo: "Actualización Sistema SINTIA", resumen: "Mantenimiento programado de la plataforma SINTIA este viernes de 22:00 a 24:00.", enlace_oficial: "#", fecha: "2025-11-10T15:30:00Z" },
    { id: 102, categoria: "noticia", titulo: "Nuevos Requisitos: SENASAG", resumen: "Nuevos códigos de registro SENASAG requeridos para productos alimenticios (Cap. 04).", enlace_oficial: "#", fecha: "2025-11-09T11:00:00Z" },
    { id: 101, categoria: "arancel", titulo: "Preferencia ACE-22 (Chile)", resumen: "Actualización de la lista de preferencias arancelarias bajo el acuerdo ACE-22.", enlace_oficial: "#", fecha: "2025-11-08T08:00:00Z" },
    { id: 100, categoria: "noticia", titulo: "Feriado Nacional", resumen: "La Aduana Nacional no atenderá el próximo lunes por feriado.", enlace_oficial: "#", fecha: "2025-11-07T16:00:00Z" }
];

function getLabelHtml(categoria) {
    switch (categoria) {
        case 'urgente': return '<span class="novedad-label label-urgente">🔴 Urgente</span>';
        case 'arancel': return '<span class="novedad-label label-arancel">🟡 Arancel</span>';
        case 'noticia': default: return '<span class="novedad-label label-noticia">🔵 Noticia</span>';
    }
}

/**
 * Renderiza la lista de novedades y actualiza contadores
 * MODIFICADO: Ahora actualiza dos contadores (panel y nav)
 */
function renderNovedades(novedades, lastReadId, filter = 'all') {
    // Contadores
    const navCounterEl = document.getElementById('novedades-nav-counter');
    const panelCounterEl = document.getElementById('novedades-new-counter');
    
    // Elementos del panel (pueden no existir si la pestaña no está activa)
    const listEl = document.getElementById('novedades-list');
    const markReadBtn = document.getElementById('novedades-mark-read-btn');
    
    if (!navCounterEl) return; // Si el contador de la barra no existe, salir

    let newCounter = 0;
    let html = '';

    const filteredNovedades = novedades.filter(item => 
        filter === 'all' || item.categoria === filter
    );

    // Calcular contador de nuevos
    novedades.forEach(item => {
        if (item.id > lastReadId) newCounter++;
    });

    // Actualizar contadores
    if (newCounter > 0) {
        navCounterEl.textContent = newCounter;
        navCounterEl.classList.remove('hidden');
        if (panelCounterEl) {
            panelCounterEl.textContent = `${newCounter} Nuevas`;
            panelCounterEl.classList.remove('hidden');
        }
        if (markReadBtn) markReadBtn.disabled = false;
        
    } else {
        navCounterEl.classList.add('hidden');
        if (panelCounterEl) panelCounterEl.classList.add('hidden');
        if (markReadBtn) markReadBtn.disabled = true;
    }

    // Renderizar la lista SOLO SI el panel está visible
    if (listEl) {
        if (filteredNovedades.length === 0) {
            html = '<p class="placeholder-text" style="padding: 20px 0;">No hay novedades para este filtro.</p>';
        }

        const itemsToShow = (filter === 'all') ? filteredNovedades.slice(0, 5) : filteredNovedades;

        itemsToShow.forEach(item => {
            const isNew = item.id > lastReadId;
            html += `
                <li class="novedad-item">
                    <div class="novedad-header">
                        ${getLabelHtml(item.categoria)}
                        ${isNew ? '<span class="novedad-new-indicator">Nuevo</span>' : ''}
                    </div>
                    <h4 class="novedad-title">${item.titulo}</h4>
                    <p class="novedad-summary">${item.resumen}</p>
                    <a href="${item.enlace_oficial}" target="_blank" class="novedad-link" title="Ver documento oficial">
                        Ver documento ↗
                    </a>
                </li>
            `;
        });
        listEl.innerHTML = html;
    }
}

/**
 * (VC9) Marca todas las novedades como leídas
 */
function markAllAsRead() {
    const latestId = mockNovedades.reduce((max, item) => Math.max(max, item.id), 0);
    
    if (latestId > 0) {
        localStorage.setItem(LAST_READ_NEWS_KEY, latestId.toString());
        // Volver a renderizar (esto ocultará los contadores y las etiquetas "Nuevo")
        renderNovedades(mockNovedades, latestId, 'all');
        
        // Resetear filtros
        document.querySelectorAll('.novedades-btn-filter').forEach(btn => {
            btn.classList.remove('active');
            if(btn.dataset.filter === 'all') btn.classList.add('active');
        });
        showToast('Novedades marcadas como leídas');
    }
}

/**
 * Carga las novedades y actualiza contadores/UI
 */
async function fetchNovedades() {
    try {
        // --- SIMULACIÓN ---
        // const response = await fetch(NOVEDADES_API_URL, { headers: { 'X-User-ID': USER_ID } });
        // const data = await response.json();
        
        const data = mockNovedades; 
        
        const lastReadId = parseInt(localStorage.getItem(LAST_READ_NEWS_KEY) || '0');
        
        renderNovedades(data, lastReadId, 'all');
        
    } catch (error) {
        console.error("Error fetching novedades:", error);
        // Intentar mostrar error solo si el panel está visible
        const listEl = document.getElementById('novedades-list');
        if(listEl) {
            listEl.innerHTML = '<p class="error-message p-4">Error al cargar novedades.</p>';
        }
    }
}


// =========================================================
// INICIALIZACIÓN FINAL (CONSOLIDADO)
// =========================================================

document.addEventListener('DOMContentLoaded', () => {
    // Funciones de arranque
    TabsManager.init();
    fetchSystemStatus();
    handlePermalink(); 
    fetchNovedades(); // Cargar Novedades (para actualizar el contador de la barra)

    // --- (VC9) Event Listener para Marcar como Leídas ---
    const markReadBtn = document.getElementById('novedades-mark-read-btn');
    if (markReadBtn) {
        markReadBtn.addEventListener('click', markAllAsRead);
    }

    // --- (VC8) Event Listeners para Filtros ---
    const filterButtons = document.querySelectorAll('.novedades-btn-filter');
    filterButtons.forEach(button => {
        button.addEventListener('click', () => {
            filterButtons.forEach(btn => btn.classList.remove('active'));
            button.classList.add('active');
            
            const filter = button.dataset.filter;
            const lastReadId = parseInt(localStorage.getItem(LAST_READ_NEWS_KEY) || '0');
            renderNovedades(mockNovedades, lastReadId, filter);
        });
    });

    // --- (VC4) Placeholder para historial completo ---
    const historialLink = document.getElementById('novedades-historial-link');
    if(historialLink) {
        historialLink.addEventListener('click', (e) => {
            e.preventDefault();
            showToast('Función de "Historial Completo" no implementada.', 'error');
        });
    }

    // --- Lógica del Tutorial ---
    const startTourBtn = document.getElementById('start-tour-btn');
    if (startTourBtn) {
        startTourBtn.addEventListener('click', (e) => {
            e.preventDefault();
            startTour();
        });
    }
    // Criterio 1 (Primera vez) y Criterio 4 (Rol)
    if (USER_ID === 'despachante_001') {
        const tourCompleted = localStorage.getItem('sisarm_tour_completed');
        
        if (tourCompleted !== 'true') {
            // Esperar un poco a que la UI cargue
            setTimeout(startTour, 500); 
        }
    }
    // --- Fin Lógica del Tutorial ---
});