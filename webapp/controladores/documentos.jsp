<%-- C:/webapp/controladores/documentos.jsp
     Conversión de DocumentoServlet (JSP). Atiende dos rutas:
     /cliente/solicitudes/documentos       (cliente: lista, sube, descarga)
     /inmobiliaria/solicitudes/documentos  (agente: lista, revisa, descarga)
     Los archivos se guardan fuera del webroot y toda descarga valida permisos. --%>
<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ include file="/WEB-INF/negocio/todo.jspf" %>
<%@ page import="java.io.InputStream" %>
<%@ page import="java.nio.file.Files" %>
<%@ page import="java.nio.file.Path" %>
<%@ page import="java.nio.file.Paths" %>
<%@ page import="java.nio.file.StandardCopyOption" %>
<%@ page import="java.sql.SQLException" %>
<%@ page import="java.util.Set" %>
<%@ page import="java.util.UUID" %>
<%!
    private static final Set<String> TIPOS_MIME_PERMITIDOS =
            new LinkedHashSet<>(Arrays.asList(
                    "application/pdf",
                    "image/jpeg",
                    "image/png",
                    "application/msword",
                    "application/vnd.openxmlformats-officedocument.wordprocessingml.document"
            ));

    /**
     * Carpeta donde se guardan los documentos, fuera del webapp.
     *
     * No se usa System.getProperty("catalina.base"): el compilador de JSP
     * de Tomcat 8.5 corriendo sobre JDK 21 no logra resolver
     * java.lang.System y la pagina no compila. En su lugar la ruta sale
     * del parametro de contexto "carpetaDatos" del web.xml y, si no esta
     * definido, se deduce de la carpeta temporal que el contenedor le
     * asigna a la aplicacion.
     */
    private String carpetaDeDatos() throws IOException {

        String configurada = getServletContext().getInitParameter("carpetaDatos");

        if (configurada != null && !configurada.isBlank()) {
            return configurada;
        }

        // tempdir = <base>/work/Catalina/localhost/<aplicacion>
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

    private Path carpetaDeDocumentos(int solicitudId) throws IOException {
        return Paths.get(carpetaDeDatos(), "documentos", "solicitudes",
                String.valueOf(solicitudId)).toAbsolutePath().normalize();
    }

    private String extensionSegura(String nombreOriginal) {
        int punto = nombreOriginal.lastIndexOf('.');
        if (punto == -1) {
            return ".dat";
        }
        String ext = nombreOriginal.substring(punto).toLowerCase();
        if (".pdf".equals(ext) || ".jpg".equals(ext) || ".jpeg".equals(ext)
                || ".png".equals(ext) || ".doc".equals(ext) || ".docx".equals(ext)) {
            return ext;
        }
        return ".dat";
    }
%>
<%
    request.setCharacterEncoding("UTF-8");
    response.setCharacterEncoding("UTF-8");

    HttpSession sesion = request.getSession(false);
    if (sesion == null || sesion.getAttribute("usuario") == null) {
        response.sendRedirect(request.getContextPath() + "/controladores/login.jsp");
        return;
    }

    /*
     * Reemplazo del AuthFilter por rol.
     *
     * Antes esta página atendía dos rutas (/cliente/... y
     * /inmobiliaria/...) y decidía la vista mirando getServletPath().
     * Ahora todo entra por controladores/documentos.jsp, así que quien
     * decide es el rol de la sesión: el agente ve la pantalla de
     * revisión y el cliente la de radicación.
     */
    boolean esRutaAgente = tieneRol(sesion.getAttribute("roles"), "AGENTE");
    String rolExigido = esRutaAgente ? "AGENTE" : "CLIENTE";

    boolean permisoRol = tieneRol(sesion.getAttribute("roles"), rolExigido);
    if (!permisoRol) {
        response.sendRedirect(request.getContextPath() + "/controladores/acceso-denegado.jsp");
        return;
    }

    DocumentoDAO documentoDAO = new DocumentoDAO();
    SolicitudDAO solicitudDAO = new SolicitudDAO();
    InmobiliariaDAO inmobiliariaDAO = new InmobiliariaDAO();

    class AyudaDocumentos {
        Path archivoFisico(Documento documento) throws IOException {
            String rutaGuardada = documento.getRuta();
            if (rutaGuardada == null || rutaGuardada.isBlank()) {
                throw new IOException("El documento no tiene una ruta física válida.");
            }
            Path nombreFisico = Paths.get(rutaGuardada).getFileName();
            if (nombreFisico == null || nombreFisico.toString().isBlank()) {
                throw new IOException("No se pudo determinar el nombre físico del documento.");
            }
            Path carpeta = carpetaDeDocumentos(documento.getSolicitudId());
            Path archivo = carpeta.resolve(nombreFisico.toString()).normalize();
            if (!archivo.startsWith(carpeta)) {
                throw new IOException("La ruta física del documento no es válida.");
            }
            return archivo;
        }

        boolean guardarDocumento(int solicitudId, Part parte, DocumentoDAO documentoDAO)
                throws IOException, SQLException {
            if (parte == null) {
                request.setAttribute("error", "Selecciona un archivo para subir.");
                return false;
            }

            String nombreOriginal = parte.getSubmittedFileName();
            if (nombreOriginal == null || nombreOriginal.isBlank() || parte.getSize() == 0) {
                request.setAttribute("error", "Selecciona un archivo para subir.");
                return false;
            }

            String tipoMime = parte.getContentType();
            if (tipoMime == null || !TIPOS_MIME_PERMITIDOS.contains(tipoMime.toLowerCase())) {
                request.setAttribute("error",
                        "El tipo de archivo no está permitido. Sube un PDF, imagen o documento de Word.");
                return false;
            }

            String extension = extensionSegura(nombreOriginal);
            String nombreArchivo = "doc-" + solicitudId + "-" + UUID.randomUUID() + extension;

            Path carpetaDestino = carpetaDeDocumentos(solicitudId);
            Files.createDirectories(carpetaDestino);
            Path archivoDestino = carpetaDestino.resolve(nombreArchivo);

            try (InputStream in = parte.getInputStream()) {
                Files.copy(in, archivoDestino, StandardCopyOption.REPLACE_EXISTING);
            }

            Documento documento = new Documento();
            documento.setSolicitudId(solicitudId);
            documento.setNombreArchivo(nombreOriginal);
            documento.setRuta("docs/solicitudes/" + solicitudId + "/" + nombreArchivo);

            try {
                documentoDAO.insertar(documento);
            } catch (SQLException e) {
                try {
                    Files.deleteIfExists(archivoDestino);
                } catch (IOException limpieza) {
                    e.addSuppressed(limpieza);
                }
                throw e;
            }

            return true;
        }

        void descargarDocumento(boolean esRutaAgente,
                                DocumentoDAO documentoDAO, SolicitudDAO solicitudDAO,
                                InmobiliariaDAO inmobiliariaDAO)
                throws IOException {
            String idParam = request.getParameter("id");

            try {
                int idDocumento = Integer.parseInt(idParam.trim());
                Documento documento = documentoDAO.buscarPorId(idDocumento);

                if (documento == null) {
                    response.sendError(HttpServletResponse.SC_NOT_FOUND, "El documento no existe.");
                    return;
                }

                HttpSession sessionDescarga = request.getSession(false);
                if (sessionDescarga == null || sessionDescarga.getAttribute("usuarioId") == null) {
                    response.sendRedirect(request.getContextPath() + "/controladores/login.jsp");
                    return;
                }

                int idUsuario = (int) sessionDescarga.getAttribute("usuarioId");

                boolean tienePermiso;
                if (esRutaAgente) {
                    Inmobiliaria inmobiliaria = inmobiliariaDAO.buscarPorUsuario(idUsuario);
                    tienePermiso = inmobiliaria != null
                            && solicitudDAO.perteneceAInmobiliaria(documento.getSolicitudId(),
                                    inmobiliaria.getId());
                } else {
                    tienePermiso = solicitudDAO.perteneceACliente(documento.getSolicitudId(), idUsuario);
                }

                if (!tienePermiso) {
                    response.sendError(HttpServletResponse.SC_FORBIDDEN,
                            "No tienes permiso para descargar este documento.");
                    return;
                }

                Path archivo = archivoFisico(documento);

                if (!Files.exists(archivo) || !Files.isRegularFile(archivo)) {
                    response.sendError(HttpServletResponse.SC_NOT_FOUND, "El archivo físico no está disponible.");
                    return;
                }

                response.setContentType("application/octet-stream");
                response.setHeader("Content-Disposition",
                        "attachment; filename=\"" + documento.getNombreArchivo() + "\"");

                Files.copy(archivo, response.getOutputStream());

            } catch (SQLException e) {
                application.log("Error al descargar el documento", e);
                response.sendError(HttpServletResponse.SC_INTERNAL_SERVER_ERROR);
            } catch (NumberFormatException e) {
                response.sendError(HttpServletResponse.SC_BAD_REQUEST,
                        "El identificador del documento no es válido.");
            }
        }
    }
    AyudaDocumentos ayudaDocs = new AyudaDocumentos();

    String metodo = request.getMethod();

    if ("POST".equalsIgnoreCase(metodo)) {
        if (esRutaAgente) {
            /* Cambiar estado de documento (solo agente de la inmobiliaria) */
            String idParam = request.getParameter("documentoId");
            String estadoParam = request.getParameter("estado");

            if (idParam == null || idParam.isBlank()
                    || estadoParam == null || estadoParam.isBlank()) {
                response.sendError(HttpServletResponse.SC_BAD_REQUEST,
                        "Debes indicar el documento y el estado.");
                return;
            }

            try {
                int idDocumento = Integer.parseInt(idParam.trim());
                EstadoDocumento estado = EstadoDocumento.desde(estadoParam);

                if (estado != EstadoDocumento.APROBADO
                        && estado != EstadoDocumento.RECHAZADO) {
                    response.sendError(HttpServletResponse.SC_BAD_REQUEST,
                            "El estado indicado no es valido.");
                    return;
                }

                Documento documento = documentoDAO.buscarPorId(idDocumento);
                if (documento == null) {
                    response.sendError(HttpServletResponse.SC_NOT_FOUND, "El documento no existe.");
                    return;
                }

                int idUsuario = (int) sesion.getAttribute("usuarioId");
                Inmobiliaria inmobiliaria = inmobiliariaDAO.buscarPorUsuario(idUsuario);
                boolean autorizado = inmobiliaria != null
                        && solicitudDAO.perteneceAInmobiliaria(documento.getSolicitudId(),
                                inmobiliaria.getId());

                if (!autorizado) {
                    response.sendError(HttpServletResponse.SC_FORBIDDEN,
                            "No tienes permiso para gestionar este documento.");
                    return;
                }

                if (!documentoDAO.cambiarEstado(idDocumento, estado)) {
                    response.sendError(HttpServletResponse.SC_NOT_FOUND,
                            "No fue posible actualizar el documento.");
                    return;
                }

                response.sendRedirect(request.getContextPath()
                        + "/controladores/documentos.jsp?solicitudId="
                        + documento.getSolicitudId() + "&estadoActualizado=1");
            } catch (NumberFormatException e) {
                response.sendError(HttpServletResponse.SC_BAD_REQUEST,
                        "El identificador del documento no es valido.");
            } catch (SQLException e) {
                application.log("Error al cambiar el estado del documento", e);
                response.sendError(HttpServletResponse.SC_INTERNAL_SERVER_ERROR);
            }
            return;
        }

        /* Cliente: subir documento */
        String solicitudId = request.getParameter("solicitudId");
        if (solicitudId == null || solicitudId.isBlank()) {
            request.setAttribute("error",
                    "Indica la solicitud a la que quieres adjuntar el documento.");
            request.getRequestDispatcher("/WEB-INF/views/cliente/documentos.jsp").forward(request, response);
            return;
        }

        int idSolicitud;
        try {
            idSolicitud = Integer.parseInt(solicitudId.trim());
        } catch (NumberFormatException e) {
            request.setAttribute("error", "El identificador de la solicitud no es válido.");
            request.getRequestDispatcher("/WEB-INF/views/cliente/documentos.jsp").forward(request, response);
            return;
        }

        int idCliente = (int) sesion.getAttribute("usuarioId");

        try {
            if (!solicitudDAO.perteneceACliente(idSolicitud, idCliente)) {
                response.sendError(HttpServletResponse.SC_FORBIDDEN,
                        "No tienes permiso para modificar esta solicitud.");
                return;
            }
        } catch (SQLException e) {
            application.log("Error al validar la solicitud del documento", e);
            response.sendError(HttpServletResponse.SC_INTERNAL_SERVER_ERROR);
            return;
        }

        Part parte;
        try {
            parte = request.getPart("archivo");
        } catch (Exception e) {
            application.log("No se pudo leer el archivo subido", e);
            request.setAttribute("error", "No se pudo leer el archivo enviado.");
            request.getRequestDispatcher("/WEB-INF/views/cliente/documentos.jsp").forward(request, response);
            return;
        }

        try {
            boolean guardado = ayudaDocs.guardarDocumento(idSolicitud, parte, documentoDAO);

            if (!guardado) {
                request.setAttribute("solicitudId", idSolicitud);
                request.setAttribute("documentos", documentoDAO.listarPorSolicitud(idSolicitud));
                request.getRequestDispatcher("/WEB-INF/views/cliente/documentos.jsp").forward(request, response);
                return;
            }

            response.sendRedirect(request.getContextPath()
                    + "/controladores/documentos.jsp?solicitudId=" + idSolicitud + "&subido=1");
        } catch (SQLException | IOException e) {
            application.log("Error al guardar el documento", e);
            request.setAttribute("error",
                    "No fue posible guardar el documento en este momento. Intenta de nuevo en unos minutos.");
            request.setAttribute("solicitudId", idSolicitud);
            request.getRequestDispatcher("/WEB-INF/views/cliente/documentos.jsp").forward(request, response);
        }
        return;
    }

    /* GET */
    String idDocumento = request.getParameter("id");
    if (idDocumento != null && !idDocumento.isBlank()) {
        ayudaDocs.descargarDocumento(esRutaAgente, documentoDAO, solicitudDAO, inmobiliariaDAO);
        return;
    }

    String solicitudId = request.getParameter("solicitudId");
    if (solicitudId == null || solicitudId.isBlank()) {
        request.setAttribute("error", "Indica la solicitud de la que quieres ver los documentos.");
        request.getRequestDispatcher(esRutaAgente
                        ? "/WEB-INF/views/inmobiliaria/documentos.jsp"
                        : "/WEB-INF/views/cliente/documentos.jsp")
                .forward(request, response);
        return;
    }

    try {
        int idSolicitud = Integer.parseInt(solicitudId.trim());
        int idUsuario = (int) sesion.getAttribute("usuarioId");

        boolean tienePermiso;
        if (esRutaAgente) {
            Inmobiliaria inmobiliaria = inmobiliariaDAO.buscarPorUsuario(idUsuario);
            tienePermiso = inmobiliaria != null
                    && solicitudDAO.perteneceAInmobiliaria(idSolicitud, inmobiliaria.getId());
        } else {
            tienePermiso = solicitudDAO.perteneceACliente(idSolicitud, idUsuario);
        }

        if (!tienePermiso) {
            response.sendError(HttpServletResponse.SC_FORBIDDEN,
                    "No tienes permiso para acceder a esta solicitud.");
            return;
        }

        request.setAttribute("solicitudId", idSolicitud);
        request.setAttribute("documentos", documentoDAO.listarPorSolicitud(idSolicitud));
    } catch (SQLException e) {
        application.log("Error al listar los documentos de la solicitud", e);
        request.setAttribute("error",
                "No fue posible cargar los documentos en este momento. Intenta de nuevo en unos minutos.");
    } catch (NumberFormatException e) {
        request.setAttribute("error", "El identificador de la solicitud no es válido.");
    }

    request.getRequestDispatcher(esRutaAgente
                    ? "/WEB-INF/views/inmobiliaria/documentos.jsp"
                    : "/WEB-INF/views/cliente/documentos.jsp")
            .forward(request, response);
%>