// sisarm-frontend/assets/js/contextual_search.js (COMPLETAMENTE MODIFICADO)

/**
 * Almacén global de estados de búsqueda contextual, indexado por el ID del contenido.
 */
window.contextualSearchState = {};

/**
 * Función que maneja el evento de búsqueda contextual (keyup).
 */
function handleContextualSearch(sectionId, content, countSpan, input, prevBtn, nextBtn, originalText, e) {
    const term = input.value.trim().toLowerCase();
    
    // 1. Limpiar resaltado anterior y restaurar el texto
    content.innerHTML = originalText; 
    
    // Resetear el estado de navegación
    window.contextualSearchState[sectionId] = {
        matches: [],
        currentIndex: -1
    };
    prevBtn.disabled = true;
    nextBtn.disabled = true;
    countSpan.textContent = '';
    
    if (term.length > 0) {
        let count = 0;
        const regex = new RegExp(`(${term})`, 'gi');
        let newHTML = originalText;
        
        // Usar replace para contar y preparar el HTML
        newHTML = originalText.replace(regex, (match) => {
            const spanId = `match-${sectionId}-${count}`;
            count++;
            // Envolvemos con una clase 'highlight' y un ID para la navegación
            return `<span class="highlight" id="${spanId}">${match}</span>`; 
        });

        content.innerHTML = newHTML;
        
        // 2. Almacenar los elementos resaltados para la navegación
        const matches = Array.from(content.querySelectorAll('.highlight'));
        window.contextualSearchState[sectionId].matches = matches;
        
        countSpan.textContent = `Se encontraron ${matches.length} coincidencias para '${term}'.`;
        
        if (matches.length > 0) {
            // Habilitar la navegación y mover al primer resultado
            prevBtn.disabled = true; // El primero no tiene anterior, pero se puede navegar cíclicamente
            nextBtn.disabled = (matches.length === 1);
            
            window.contextualSearchState[sectionId].currentIndex = 0;
            scrollToMatch(matches[0]);
        }

    }
}

/**
 * Función para desplazarse al elemento resaltado y enfocarlo.
 */
function scrollToMatch(element) {
    if (!element) return;
    
    // 1. Eliminar el enfoque visual de la coincidencia anterior
    const activeMatch = element.closest('.section-content').querySelector('.highlight.active');
    if (activeMatch) {
        activeMatch.classList.remove('active');
    }
    
    // 2. Añadir clase 'active' para resaltado temporal
    element.classList.add('active'); 

    // 3. Mover el scroll del navegador al elemento
    element.scrollIntoView({
        behavior: 'smooth',
        block: 'center'
    });
}

/**
 * Función para manejar el clic en los botones de navegación (cíclica).
 */
function handleNavigation(sectionId, direction) {
    const state = window.contextualSearchState[sectionId];
    if (!state || state.matches.length === 0) return;
    
    let newIndex = state.currentIndex + direction;
    
    // Navegación Cíclica: si pasa el final, va al inicio; si pasa el inicio, va al final.
    if (newIndex >= state.matches.length) {
        newIndex = 0; 
    } else if (newIndex < 0) {
        newIndex = state.matches.length - 1; 
    }
    
    state.currentIndex = newIndex;
    const currentMatch = state.matches[newIndex];
    
    scrollToMatch(currentMatch);
}


/**
 * Función global para inicializar y reiniciar la búsqueda contextual en todas las secciones.
 * Llamada por DOMContentLoaded y por main.js (cuando se carga un nuevo capítulo).
 */
window.initializeContextualSearch = function() {
    
    document.querySelectorAll('.contextual-section').forEach(section => {
        const content = section.querySelector('.section-content');
        const sectionId = content.id || section.dataset.sectionName.replace(/\s/g, '_');
        
        const input = section.querySelector('.contextual-input');
        const countSpan = section.querySelector('.count-span');
        const prevBtn = section.querySelector('.prev-btn');
        const nextBtn = section.querySelector('.next-btn');

        // CRUCIAL: El texto original se toma en el momento de la inicialización
        const originalText = content.textContent; 

        // 1. Limpiar listeners anteriores clonando y reemplazando el input (para keyup)
        const new_input = input.cloneNode(true);
        input.parentNode.replaceChild(new_input, input);
        
        // 2. Añadir el nuevo listener para la búsqueda (key up)
        // Se utiliza bind para pasar todos los parámetros necesarios
        new_input.addEventListener('keyup', handleContextualSearch.bind(null, sectionId, content, countSpan, new_input, prevBtn, nextBtn, originalText));

        // 3. Añadir Listeners para los botones de navegación
        prevBtn.onclick = () => handleNavigation(sectionId, -1);
        nextBtn.onclick = () => handleNavigation(sectionId, 1);
        
        // 4. Inicializar estado
        window.contextualSearchState[sectionId] = { matches: [], currentIndex: -1 };
    });
};


// Inicializar la búsqueda contextual al cargar la página por primera vez
window.addEventListener('DOMContentLoaded', window.initializeContextualSearch);