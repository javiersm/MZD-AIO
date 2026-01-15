/**
 * Fix for "Failed to execute 'measure' on 'Performance'" error.
 * This script patches performance.measure to safely handle invalid arguments
 * or suppress errors that might crash the application.
 */
(function() {
    if (window.performance && window.performance.measure) {
        var originalMeasure = window.performance.measure;
        window.performance.measure = function(name, startMark, endMark) {
            try {
                // Ensure arguments are strings if possible, or fallback safely
                if (typeof name !== 'string') {
                    name = String(name);
                }
                if (startMark && typeof startMark !== 'string') {
                    startMark = String(startMark);
                }
                if (endMark && typeof endMark !== 'string') {
                    endMark = String(endMark);
                }
                
                return originalMeasure.call(this, name, startMark, endMark);
            } catch (e) {
                console.warn('Suppressed Performance.measure error:', e);
                // Return safely without crashing
                return;
            }
        };
        console.log('Performance.measure patched to suppress errors.');
    }
})();
