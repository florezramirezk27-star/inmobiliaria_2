<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" trimDirectiveWhitespaces="true" %><%@ page import="java.nio.file.Files" %><%@ page import="java.nio.file.Path" %><%@ page import="java.nio.file.Paths" %><%@ page import="java.util.Locale" %><%@ page import="java.util.regex.Pattern" %><%!
private static final Pattern NOMBRE_PERMITIDO = Pattern.compile("prop-[1-9][0-9]*-[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}\\.(jpg|png|webp)", Pattern.CASE_INSENSITIVE);
%><%
// Antes el nombre del archivo llegaba en el pathInfo, porque esta pagina
// estaba mapeada en /media/propiedades/*. Ese mapeo se elimino del
// web.xml, asi que ahora viaja como parametro:
//     controladores/media-propiedad.jsp?archivo=prop-5-....jpg
String nombreArchivo = request.getParameter("archivo");
if (nombreArchivo == null || nombreArchivo.isBlank()
        || nombreArchivo.indexOf('/') >= 0 || nombreArchivo.contains("\\")
        || nombreArchivo.contains("..")) {
    response.sendError(HttpServletResponse.SC_NOT_FOUND);
    return;
}
if (!NOMBRE_PERMITIDO.matcher(nombreArchivo).matches()) {
    response.sendError(HttpServletResponse.SC_NOT_FOUND);
    return;
}
Path carpeta;
try {
    // La ruta sale del parametro de contexto "carpetaDatos" del web.xml.
    // No se usa System.getProperty("catalina.base") porque el compilador
    // de JSP de Tomcat 8.5 sobre JDK 21 no resuelve java.lang.System.
    String carpetaDatos = application.getInitParameter("carpetaDatos");

    if (carpetaDatos == null || carpetaDatos.isBlank()) {
        java.io.File temporal =
                (java.io.File) application.getAttribute("javax.servlet.context.tempdir");
        if (temporal == null) {
            response.sendError(HttpServletResponse.SC_INTERNAL_SERVER_ERROR);
            return;
        }
        java.io.File base = temporal;
        for (int i = 0; i < 4 && base.getParentFile() != null; i++) {
            base = base.getParentFile();
        }
        carpetaDatos = new java.io.File(base, "inmobiliaria-data").getAbsolutePath();
    }

    carpeta = Paths.get(carpetaDatos, "imagenes", "propiedades").toAbsolutePath().normalize();
} catch (Exception e) {
    response.sendError(HttpServletResponse.SC_INTERNAL_SERVER_ERROR);
    return;
}
Path archivo = carpeta.resolve(nombreArchivo).normalize();
if (!archivo.getParent().equals(carpeta) || !Files.isRegularFile(archivo)) {
    response.sendError(HttpServletResponse.SC_NOT_FOUND);
    return;
}
try {
    String nombre = nombreArchivo.toLowerCase(Locale.ROOT);
    String tipo = nombre.endsWith(".png") ? "image/png" : nombre.endsWith(".webp") ? "image/webp" : "image/jpeg";
    response.setContentType(tipo);
    response.setHeader("X-Content-Type-Options", "nosniff");
    response.setHeader("Cache-Control", "public, max-age=86400");
    response.setContentLengthLong(Files.size(archivo));
    Files.copy(archivo, response.getOutputStream());
} catch (Exception e) {
    if (!response.isCommitted()) {
        response.sendError(HttpServletResponse.SC_INTERNAL_SERVER_ERROR);
    }
}
%>