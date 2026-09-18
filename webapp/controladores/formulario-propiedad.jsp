<%-- C:/webapp/controladores/formulario-propiedad.jsp
     Conversión de PropiedadFormServlet (JSP). Creación y edición de
     propiedades con características e imágenes (multipart). Requiere rol AGENTE.
     GET  -> formulario en blanco o con datos de la propiedad (edición)
     POST -> guarda datos, características e imágenes nuevas --%>
<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ include file="/WEB-INF/negocio/todo.jspf" %>
<%@ page import="java.io.InputStream" %>
<%@ page import="java.math.BigDecimal" %>
<%@ page import="java.nio.file.Files" %>
<%@ page import="java.nio.file.Path" %>
<%@ page import="java.nio.file.Paths" %>
<%@ page import="java.nio.file.StandardCopyOption" %>
<%@ page import="java.sql.SQLException" %>
<%@ page import="java.util.ArrayList" %>
<%@ page import="java.util.Arrays" %>
<%@ page import="java.util.Collections" %>
<%@ page import="java.util.HashSet" %>
<%@ page import="java.util.LinkedHashSet" %>
<%@ page import="java.util.List" %>
<%@ page import="java.util.Set" %>
<%@ page import="java.util.UUID" %>
<%!
    private static final Set<String> TIPOS_MIME_PERMITIDOS =
            new LinkedHashSet<>(Arrays.asList("image/jpeg", "image/png", "image/webp"));

    private boolean tieneRol(HttpServletRequest request, String rolBuscado) {
        HttpSession sesion = request.getSession(false);
        if (sesion == null) {
            return false;
        }
        return tieneRol(sesion.getAttribute("roles"), rolBuscado);
    }
    /**
     * Carpeta donde se guardan las fotos, fuera del webapp.
     *
     * No se usa System.getProperty("catalina.base"): el compilador de JSP
     * de Tomcat 8.5 sobre JDK 21 no resuelve java.lang.System y la pagina
     * no compila. La ruta sale del parametro de contexto "carpetaDatos"
     * del web.xml y, si falta, se deduce de la carpeta temporal que el
     * contenedor le asigna a la aplicacion.
     */
    private String carpetaDeDatos() throws IOException {

        String configurada = getServletContext().getInitParameter("carpetaDatos");

        if (configurada != null && !configurada.isBlank()) {
            return configurada;
        }

        java.io.File temporal =
                (java.io.File) getServletContext().getAttribute("javax.servlet.context.tempdir");

        if (temporal == null) {
            throw new IOException("No se pudo determinar la carpeta de datos. "
                    + "Define el parametro de contexto carpetaDatos en el web.xml.");
        }

        java.io.File base = temporal;
        for (int i = 0; i < 4 && base.getParentFile() != null; i++) {
            base = base.getParentFile();
        }

        return new java.io.File(base, "inmobiliaria-data").getAbsolutePath();
    }

    private Path carpetaDeImagenes() throws IOException {
        return Paths.get(carpetaDeDatos(), "imagenes", "propiedades")
                .toAbsolutePath().normalize();
    }

    private String extensionSegura(String nombreOriginal, String tipoMime) {
        String mime = tipoMime.toLowerCase();
        if ("image/png".equals(mime)) {
            return ".png";
        }
        if ("image/webp".equals(mime)) {
            return ".webp";
        }
        return ".jpg";
    }

    private void borrarArchivoFisico(String rutaRelativa) {
        String nombreArchivo = nombrePersistenteDesdeRuta(rutaRelativa);
        if (nombreArchivo == null) {
            return;
        }
        try {
            Path carpeta = carpetaDeImagenes();
            Path archivo = carpeta.resolve(nombreArchivo).normalize();
            if (!archivo.getParent().equals(carpeta)) {
                return;
            }
            Files.deleteIfExists(archivo);
        } catch (IOException e) {
            // no se pudo borrar el archivo físico
        }
    }

    private String nombrePersistenteDesdeRuta(String rutaRelativa) {
        String prefijo = "media/propiedades/";
        if (rutaRelativa == null || !rutaRelativa.startsWith(prefijo)) {
            return null;
        }
        String nombre = rutaRelativa.substring(prefijo.length());
        if (nombre.isBlank() || nombre.contains("/")
                || nombre.contains("\\") || nombre.contains("..")) {
            return null;
        }
        return nombre;
    }

    private void exigirTexto(HttpServletRequest request, String campo, String mensaje, List<String> errores) {
        String valor = request.getParameter(campo);
        if (valor == null || valor.isBlank()) {
            errores.add(mensaje);
        }
    }

    private void exigirEntero(HttpServletRequest request, String campo, String mensaje, List<String> errores) {
        String valor = request.getParameter(campo);
        if (valor == null || valor.isBlank()) {
            errores.add(mensaje);
            return;
        }
        try {
            Integer.parseInt(valor.trim());
        } catch (NumberFormatException e) {
            errores.add(mensaje);
        }
    }

    private String vacioComoNulo(String valor) {
        return (valor == null || valor.isBlank()) ? null : valor.trim();
    }

    private int parseEnteroOCero(String valor) {
        if (valor == null || valor.isBlank()) {
            return 0;
        }
        try {
            return Integer.parseInt(valor.trim());
        } catch (NumberFormatException e) {
            return 0;
        }
    }

    private Integer parseEnteroONulo(String valor) {
        if (valor == null || valor.isBlank()) {
            return null;
        }
        try {
            return Integer.parseInt(valor.trim());
        } catch (NumberFormatException e) {
            return null;
        }
    }

    private BigDecimal parseDecimalONulo(String valor, BigDecimal porDefecto) {
        if (valor == null || valor.isBlank()) {
            return porDefecto;
        }
        try {
            return new BigDecimal(valor.trim());
        } catch (NumberFormatException e) {
            return porDefecto;
        }
    }

%>
<%@ include file="/WEB-INF/seguridad/rol-agente.jspf" %>
<%
    HttpSession sesion = request.getSession(false);
    Integer usuarioId = (Integer) sesion.getAttribute("usuarioId");
    if (usuarioId == null) {
        response.sendRedirect(request.getContextPath() + "/controladores/login.jsp");
        return;
    }

    PropiedadDAO propiedadDAO = new PropiedadDAO();
    CiudadDAO ciudadDAO = new CiudadDAO();
    TipoPropiedadDAO tipoPropiedadDAO = new TipoPropiedadDAO();
    InmobiliariaDAO inmobiliariaDAO = new InmobiliariaDAO();
    CaracteristicaDAO caracteristicaDAO = new CaracteristicaDAO();
    ImagenPropiedadDAO imagenDAO = new ImagenPropiedadDAO();

    class AyudaPropiedad {
        void cargarCatalogos(HttpServletRequest request,
                             CiudadDAO ciudadDAO, TipoPropiedadDAO tipoPropiedadDAO,
                             CaracteristicaDAO caracteristicaDAO) throws SQLException {
            request.setAttribute("ciudades", ciudadDAO.listarTodas());
            request.setAttribute("tiposPropiedad", tipoPropiedadDAO.listarTodos());
            request.setAttribute("todasLasCaracteristicas", caracteristicaDAO.listarTodas());
            request.setAttribute("categoriasCaracteristica",
                    Arrays.asList("INTERIOR", "EXTERIOR", "CONJUNTO", "SEGURIDAD"));
        }

        void guardarCaracteristicas(HttpServletRequest request, int propiedadId,
                                    CaracteristicaDAO caracteristicaDAO) throws SQLException {
            String[] seleccionadas = request.getParameterValues("idsCaracteristica");
            List<Integer> ids = new ArrayList<>();
            if (seleccionadas != null) {
                for (String valor : seleccionadas) {
                    try {
                        ids.add(Integer.parseInt(valor.trim()));
                    } catch (NumberFormatException ignorado) {
                        // valor manipulado a mano; se ignora
                    }
                }
            }
            caracteristicaDAO.reemplazarAsignaciones(propiedadId, ids);
        }

        void guardarImagenesNuevas(HttpServletRequest request, int propiedadId,
                                   ImagenPropiedadDAO imagenDAO,
                                   javax.servlet.ServletContext context)
                throws Exception {
            for (Part parte : request.getParts()) {
                if (!"imagenesNuevas".equals(parte.getName())) {
                    continue;
                }

                String nombreOriginal = parte.getSubmittedFileName();
                if (nombreOriginal == null || nombreOriginal.isBlank() || parte.getSize() == 0) {
                    continue;
                }

                String tipoMime = parte.getContentType();
                if (tipoMime == null || !TIPOS_MIME_PERMITIDOS.contains(tipoMime.toLowerCase())) {
                    context.log("Imagen rechazada por tipo no permitido: "
                            + nombreOriginal + " (" + tipoMime + ")");
                    continue;
                }

                String extension = extensionSegura(nombreOriginal, tipoMime);
                String nombreArchivo = "prop-" + propiedadId + "-" + UUID.randomUUID() + extension;

                Path carpetaDestino = carpetaDeImagenes();
                Files.createDirectories(carpetaDestino);
                Path archivoDestino = carpetaDestino.resolve(nombreArchivo);

                try (InputStream in = parte.getInputStream()) {
                    Files.copy(in, archivoDestino, StandardCopyOption.REPLACE_EXISTING);
                }

                ImagenPropiedad imagen = new ImagenPropiedad();
                imagen.setPropiedadId(propiedadId);
                imagen.setRuta("media/propiedades/" + nombreArchivo);
                imagen.setTextoAlt(request.getParameter("titulo"));
                imagen.setOrden(0);

                try {
                    imagenDAO.insertar(imagen);
                } catch (SQLException e) {
                    try {
                        Files.deleteIfExists(archivoDestino);
                    } catch (IOException limpieza) {
                        e.addSuppressed(limpieza);
                    }
                    throw e;
                }
            }
        }

        void procesarEliminacionesDeImagen(HttpServletRequest request, int propiedadId,
                                           ImagenPropiedadDAO imagenDAO) throws SQLException {
            String[] aEliminar = request.getParameterValues("eliminarImagen");
            if (aEliminar == null) {
                return;
            }
            for (String valor : aEliminar) {
                try {
                    int idImagen = Integer.parseInt(valor.trim());
                    ImagenPropiedad imagen = imagenDAO.buscarPorId(idImagen);
                    if (imagen != null && imagen.getPropiedadId() == propiedadId) {
                        imagenDAO.eliminar(idImagen);
                        borrarArchivoFisico(imagen.getRuta());
                    }
                } catch (NumberFormatException ignorado) {
                    // valor manipulado a mano; se ignora
                }
            }
        }

        void procesarCambioDePortada(HttpServletRequest request, int propiedadId,
                                     ImagenPropiedadDAO imagenDAO) throws SQLException {
            String idPortada = request.getParameter("imagenPortada");
            if (idPortada == null || idPortada.isBlank()) {
                return;
            }
            try {
                imagenDAO.marcarPortada(Integer.parseInt(idPortada.trim()), propiedadId);
            } catch (NumberFormatException ignorado) {
                // valor manipulado a mano; se ignora
            }
        }

        List<String> validar(HttpServletRequest request) {
            List<String> errores = new ArrayList<>();

            /*
             * Si el envío es multipart y NINGÚN campo llegó, no es que el
             * usuario dejara todo vacío: el servidor descartó la petición
             * completa por superar su tamaño máximo (maxPostSize del
             * conector, 2 MB por defecto en Tomcat) y con ella se fueron
             * todos los parámetros. Sin este aviso el formulario reclama
             * ocho campos obligatorios que sí estaban llenos.
             */
            String tipoEnvio = request.getContentType();
            boolean esMultipart = tipoEnvio != null
                    && tipoEnvio.toLowerCase().startsWith("multipart/form-data");

            if (esMultipart && request.getParameterMap().isEmpty()) {
                errores.add("No se pudo procesar el envío: es probable que alguna "
                        + "foto supere el tamaño máximo que acepta el servidor. "
                        + "Usa imágenes más livianas o aumenta maxPostSize en el "
                        + "conector del server.xml de Tomcat.");
                return errores;
            }

            exigirTexto(request, "codigo", "El código es obligatorio.", errores);
            exigirTexto(request, "matriculaInmobiliaria", "La matrícula inmobiliaria es obligatoria.", errores);
            exigirTexto(request, "titulo", "El título es obligatorio.", errores);
            exigirTexto(request, "direccion", "La dirección es obligatoria.", errores);

            if (Operacion.desde(request.getParameter("operacion")) == null) {
                errores.add("Selecciona si la propiedad es en arriendo o en venta.");
            }

            exigirEntero(request, "idTipoPropiedad", "Selecciona el tipo de inmueble.", errores);
            exigirEntero(request, "idCiudad", "Selecciona la ciudad.", errores);

            String precio = request.getParameter("precio");
            if (precio == null || precio.isBlank()) {
                errores.add("El precio es obligatorio.");
            } else {
                try {
                    if (new BigDecimal(precio.trim()).compareTo(BigDecimal.ZERO) <= 0) {
                        errores.add("El precio debe ser mayor que cero.");
                    }
                } catch (NumberFormatException e) {
                    errores.add("El precio debe ser un número válido.");
                }
            }

            String estrato = request.getParameter("estrato");
            if (estrato != null && !estrato.isBlank()) {
                try {
                    int valor = Integer.parseInt(estrato.trim());
                    if (valor < 1 || valor > 6) {
                        errores.add("El estrato debe estar entre 1 y 6.");
                    }
                } catch (NumberFormatException e) {
                    errores.add("El estrato debe ser un número entre 1 y 6.");
                }
            }

            return errores;
        }

        Propiedad construirDesde(HttpServletRequest request) {
            Propiedad p = new Propiedad();
            p.setCodigo(request.getParameter("codigo").trim());
            p.setMatriculaInmobiliaria(request.getParameter("matriculaInmobiliaria").trim());
            p.setTitulo(request.getParameter("titulo").trim());
            p.setDescripcion(vacioComoNulo(request.getParameter("descripcion")));
            p.setOperacion(Operacion.desde(request.getParameter("operacion")));
            p.setEstado(EstadoPropiedad.desde(request.getParameter("estado")) != null
                    ? EstadoPropiedad.desde(request.getParameter("estado"))
                    : EstadoPropiedad.BORRADOR);

            p.setTipoPropiedadId(Integer.parseInt(request.getParameter("idTipoPropiedad").trim()));
            p.setCiudadId(Integer.parseInt(request.getParameter("idCiudad").trim()));

            p.setPrecio(new BigDecimal(request.getParameter("precio").trim()));
            p.setAdministracion(parseDecimalONulo(request.getParameter("administracion"), BigDecimal.ZERO));
            p.setAreaConstruida(parseDecimalONulo(request.getParameter("areaConstruida"), null));
            p.setAreaLote(parseDecimalONulo(request.getParameter("areaLote"), null));

            p.setHabitaciones(parseEnteroOCero(request.getParameter("habitaciones")));
            p.setBanos(parseEnteroOCero(request.getParameter("banos")));
            p.setParqueaderos(parseEnteroOCero(request.getParameter("parqueaderos")));
            p.setEstrato(parseEnteroONulo(request.getParameter("estrato")));
            p.setAntiguedadAnios(parseEnteroONulo(request.getParameter("antiguedadAnios")));

            p.setDireccion(request.getParameter("direccion").trim());
            p.setBarrio(vacioComoNulo(request.getParameter("barrio")));

            return p;
        }

        Set<Integer> idsDe(List<Caracteristica> caracteristicas) {
            Set<Integer> ids = new HashSet<>();
            for (Caracteristica c : caracteristicas) {
                ids.add(c.getId());
            }
            return ids;
        }

        boolean perteneceAlAgente(int propiedadId, int usuarioId,
                                  InmobiliariaDAO inmobiliariaDAO,
                                  PropiedadDAO propiedadDAO) {
            try {
                Inmobiliaria inmobiliaria = inmobiliariaDAO.buscarPorUsuario(usuarioId);
                if (inmobiliaria == null) {
                    return false;
                }
                for (Propiedad propiedad : propiedadDAO.listarPorInmobiliaria(inmobiliaria.getId())) {
                    if (propiedad.getId() == propiedadId) {
                        return true;
                    }
                }
                return false;
            } catch (SQLException e) {
                throw new RuntimeException("No fue posible validar la propiedad del agente", e);
            }
        }
    }
    AyudaPropiedad ayudaPropiedad = new AyudaPropiedad();

    String metodo = request.getMethod();

    if ("POST".equalsIgnoreCase(metodo)) {
        request.setAttribute("caracteristicasAsignadas", new HashSet<Integer>());

        try {
            ayudaPropiedad.cargarCatalogos(request, ciudadDAO, tipoPropiedadDAO, caracteristicaDAO);
        } catch (SQLException e) {
            application.log("Error al cargar catálogos del formulario", e);
        }

        List<String> errores = ayudaPropiedad.validar(request);

        if (!errores.isEmpty()) {
            request.setAttribute("errores", errores);
            request.getRequestDispatcher("/formulario-propiedad.jsp").forward(request, response);
            return;
        }

        Inmobiliaria inmobiliaria;
        try {
            inmobiliaria = inmobiliariaDAO.buscarPorUsuario(usuarioId);
        } catch (SQLException e) {
            application.log("Error al localizar la inmobiliaria del agente", e);
            request.setAttribute("errores",
                    Collections.singletonList("No fue posible validar tu inmobiliaria en este momento. Intenta de nuevo en unos minutos."));
            request.getRequestDispatcher("/formulario-propiedad.jsp").forward(request, response);
            return;
        }

        if (inmobiliaria == null) {
            response.sendError(HttpServletResponse.SC_FORBIDDEN,
                    "El usuario no tiene una inmobiliaria asignada.");
            return;
        }

        Propiedad p = ayudaPropiedad.construirDesde(request);
        p.setInmobiliariaId(inmobiliaria.getId());
        p.setUsuarioId(usuarioId);

        String idParam = request.getParameter("idPropiedad");
        boolean esEdicion = idParam != null && !idParam.isBlank();

        try {
            if (esEdicion) {
                p.setId(Integer.parseInt(idParam));

                if (!ayudaPropiedad.perteneceAlAgente(p.getId(), usuarioId, inmobiliariaDAO, propiedadDAO)) {
                    response.sendError(HttpServletResponse.SC_FORBIDDEN,
                            "No tienes permiso para modificar esta propiedad.");
                    return;
                }

                propiedadDAO.actualizar(p);
            } else {
                propiedadDAO.insertar(p);
            }

            ayudaPropiedad.guardarCaracteristicas(request, p.getId(), caracteristicaDAO);
            ayudaPropiedad.guardarImagenesNuevas(request, p.getId(), imagenDAO, application);
            ayudaPropiedad.procesarEliminacionesDeImagen(request, p.getId(), imagenDAO);
            ayudaPropiedad.procesarCambioDePortada(request, p.getId(), imagenDAO);

            response.sendRedirect(request.getContextPath()
                    + "/controladores/propiedad-detalle.jsp?id=" + p.getId() + "&guardado=1");
        } catch (DuplicidadException e) {
            request.setAttribute("errores", Arrays.asList(e.getMessage()));
            request.setAttribute("propiedad", p);
            request.getRequestDispatcher("/formulario-propiedad.jsp").forward(request, response);
        } catch (Exception e) {
            application.log("Error al guardar la propiedad", e);
            request.setAttribute("errores",
                    Collections.singletonList("No fue posible guardar la propiedad en este momento. Intenta de nuevo en unos minutos."));
            request.setAttribute("propiedad", p);
            request.getRequestDispatcher("/formulario-propiedad.jsp").forward(request, response);
        }
        return;
    }

    /* GET */
    request.setAttribute("caracteristicasAsignadas", new HashSet<Integer>());

    try {
        ayudaPropiedad.cargarCatalogos(request, ciudadDAO, tipoPropiedadDAO, caracteristicaDAO);

        String idParam = request.getParameter("id");
        if (idParam != null && !idParam.isBlank()) {
            int id = Integer.parseInt(idParam.trim());
            Propiedad existente = propiedadDAO.buscarPorId(id);

            if (existente == null) {
                request.setAttribute("error", "La propiedad solicitada no existe.");
            } else if (!ayudaPropiedad.perteneceAlAgente(id, usuarioId, inmobiliariaDAO, propiedadDAO)) {
                response.sendError(HttpServletResponse.SC_FORBIDDEN,
                        "No tienes permiso para editar esta propiedad.");
                return;
            } else {
                request.setAttribute("propiedad", existente);
                request.setAttribute("caracteristicasAsignadas",
                        ayudaPropiedad.idsDe(caracteristicaDAO.listarPorPropiedad(id)));
                request.setAttribute("imagenesActuales", imagenDAO.listarPorPropiedad(id));
            }
        }
    } catch (SQLException e) {
        application.log("Error al cargar el formulario de propiedad", e);
        request.setAttribute("error",
                "No fue posible cargar el formulario en este momento. Intenta de nuevo en unos minutos.");
    } catch (NumberFormatException e) {
        request.setAttribute("error", "El identificador de la propiedad no es válido.");
    }

    request.getRequestDispatcher("/formulario-propiedad.jsp").forward(request, response);
%>