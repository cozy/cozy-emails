var fdLocale = {
fullMonths:["Enero", "Febrero", "Marzo", "Abril", "Mayo", "Junio", "Julio", "Agosto", "Septiembre", "Octubre", "Noviembre", "Diciembre"],
monthAbbrs:["Ene", "Feb", "Mar", "Abr", "May", "Jun", "Jul", "Ago", "Sep", "Oct", "Nov", "Dic"],
fullDays:["Lunes", "Martes", "Mi\u00E9rcoles", "Jueves", "Viernes", "S\u00E1bado", "Domingo"],
dayAbbrs:["Lun", "Mar", "Mi\u00E9", "Jue", "Vie", "S\u00E1b", "Dom"],
titles:["Mes Anterior", "Mes Siguiente", "A\u00F1o Anterior", "A\u00F1o Siguiente", "Hoy", "Mostrar Calendario", "sem", "Semana[[%0%]] de [[%1%]]", "Semana", "Seleccione una Fecha", "Haga clic y arrastre para mover", "Mostrar \u0022[[%0%]]\u0022 primero", "Ir al d\u00EDa de hoy", "Deshabilitar Fecha"]};
try { 
        if("datePickerController" in window) { 
                datePickerController.loadLanguage(); 
        }; 
} catch(err) {}; 
