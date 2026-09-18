<%-- C:/webapp/controladores/solicitudes.jsp
     Conversión de SolicitudServlet (JSP):
     GET  /cliente/solicitudes                 -> listado de mis solicitudes
     GET  /cliente/solicitudes?accion=nueva    -> formulario para una propiedad
     POST /cliente/solicitudes                 -> registra la solicitud --%>
<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ include file="/WEB-INF/negocio/todo.jspf" %>
<%@ page import="java.sql.SQLException" %>
<%@ page import="java.util.ArrayList" %>
<%@ page import="java.util.List" %>
<%!
    private String vacioComoNulo(String valor) {
        return (valor == null || valor.isBlank()) ? null : valor.trim();
    }
%>
<%@ include file="/WEB-INF/seguridad/rol-cliente.jspf" %>
<%
    HttpSession sesion = request.getSession(false);
    Integer usuarioId = (Integer) sesion.getAttribute("usuarioId");
    if (usuarioId == null) {
        response.sendRedirect(request.getContextPath() + "/controladores/login.jsp");
        return;
    }
    int idCliente = usuarioId;

    SolicitudDAO solicitudDAO = new SolicitudDAO();
    PropiedadDAO propiedadDAO = new PropiedadDAO();

    class AyudaSolicitud {
        void cargarPropiedad(HttpServletRequest request, PropiedadDAO propiedadDAO) {
            String idParam = request.getParameter("id");
            if (idParam == null || idParam.isBlank()) {
                return;
            }
            try {
                int idPropiedad = Integer.parseInt(idParam.trim());
                Propiedad propiedad = propiedadDAO.buscarPublicadaPorId(idPropiedad);
                if (propiedad != null) {
                    request.setAttribute("propiedad", propiedad);
                    request.setAttribute("idPropiedad", idPropiedad);
                }
            } catch (SQLException | NumberFormatException e) {
                // no se pudo cargar la propiedad del formulario
            }
        }

        List<String> validar(HttpServletRequest request, PropiedadDAO propiedadDAO) {
            List<String> errores = new ArrayList<>();

            String idPropiedad = request.getParameter("idPropiedad");
            if (idPropiedad == null || idPropiedad.isBlank()) {
                errores.add("Selecciona la propiedad sobre la que quieres solicitar.");
            } else {
                try {
                    int propiedadId = Integer.parseInt(idPropiedad.trim());
                    if (propiedadId <= 0) {
                        errores.add("La propiedad seleccionada no es válida.");
                    } else if (propiedadDAO.buscarPublicadaPorId(propiedadId) == null) {
                        errores.add("La propiedad seleccionada no existe o no está disponible.");
                    }
                } catch (NumberFormatException e) {
                    errores.add("La propiedad seleccionada no es válida.");
                } catch (SQLException e) {
                    errores.add("No fue posible validar la propiedad en este momento.");
                }
            }

            if (TipoSolicitud.desde(request.getParameter("tipo")) == null) {
                errores.add("Selecciona si la solicitud es de compra o de arriendo.");
            }

            return errores;
        }

        Solicitud construirDesde(HttpServletRequest request, int idCliente) {
            Solicitud solicitud = new Solicitud();
            solicitud.setPropiedadId(Integer.parseInt(request.getParameter("idPropiedad").trim()));
            solicitud.setClienteId(idCliente);
            solicitud.setTipo(TipoSolicitud.desde(request.getParameter("tipo")));
            solicitud.setComentario(vacioComoNulo(request.getParameter("comentario")));
            return solicitud;
        }
    }
    AyudaSolicitud ayudaSolicitud = new AyudaSolicitud();

    String metodo = request.getMethod();

    if ("POST".equalsIgnoreCase(metodo)) {
        List<String> errores = ayudaSolicitud.validar(request, propiedadDAO);

        if (!errores.isEmpty()) {
            request.setAttribute("errores", errores);
            ayudaSolicitud.cargarPropiedad(request, propiedadDAO);
            request.getRequestDispatcher("/WEB-INF/views/cliente/formulario-solicitud.jsp")
                    .forward(request, response);
            return;
        }

        Solicitud solicitud = ayudaSolicitud.construirDesde(request, idCliente);

        try {
            solicitudDAO.insertar(solicitud);
            response.sendRedirect(request.getContextPath() + "/controladores/solicitudes.jsp?creada=1");
        } catch (SQLException e) {
            application.log("Error al registrar la solicitud", e);
            request.setAttribute("errores",
                    Collections.singletonList("No fue posible registrar la solicitud en este momento. Intenta de nuevo en unos minutos."));
            request.setAttribute("solicitud", solicitud);
            ayudaSolicitud.cargarPropiedad(request, propiedadDAO);
            request.getRequestDispatcher("/WEB-INF/views/cliente/formulario-solicitud.jsp")
                    .forward(request, response);
        }
        return;
    }

    /* GET */
    String accion = request.getParameter("accion");

    try {
        if ("nueva".equals(accion)) {
            ayudaSolicitud.cargarPropiedad(request, propiedadDAO);
            request.getRequestDispatcher("/WEB-INF/views/cliente/formulario-solicitud.jsp")
                    .forward(request, response);
            return;
        }

        request.setAttribute("solicitudes", solicitudDAO.listarPorCliente(idCliente));
        request.getRequestDispatcher("/WEB-INF/views/cliente/mis-solicitudes.jsp")
                .forward(request, response);
    } catch (SQLException e) {
        application.log("Error al listar las solicitudes del cliente", e);
        request.setAttribute("error",
                "No fue posible cargar tus solicitudes en este momento. Intenta de nuevo en unos minutos.");
        request.getRequestDispatcher("/WEB-INF/views/cliente/mis-solicitudes.jsp")
                .forward(request, response);
    } catch (NumberFormatException e) {
        request.setAttribute("error", "El identificador de la propiedad no es válido.");
        request.getRequestDispatcher("/WEB-INF/views/cliente/mis-solicitudes.jsp")
                .forward(request, response);
    }
%>