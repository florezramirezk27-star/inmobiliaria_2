<%-- C:/webapp/controladores/inmobiliaria-solicitudes.jsp
     Conversión de AgenteSolicitudServlet (JSP):
     GET  /inmobiliaria/solicitudes  -> solicitudes de las propiedades del agente
     POST /inmobiliaria/solicitudes  -> aprueba/rechaza una solicitud (solo de su inmobiliaria) --%>
<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ include file="/WEB-INF/negocio/todo.jspf" %>
<%@ page import="java.sql.SQLException" %>
<%@ page import="java.util.ArrayList" %>
<%@ page import="java.util.List" %>
<%@ include file="/WEB-INF/seguridad/rol-agente.jspf" %>
<%
    HttpSession sesion = request.getSession(false);
    Integer usuarioId = (Integer) sesion.getAttribute("usuarioId");
    if (usuarioId == null) {
        response.sendRedirect(request.getContextPath() + "/controladores/login.jsp");
        return;
    }

    SolicitudDAO solicitudDAO = new SolicitudDAO();
    PropiedadDAO propiedadDAO = new PropiedadDAO();
    InmobiliariaDAO inmobiliariaDAO = new InmobiliariaDAO();

    String metodo = request.getMethod();

    if ("POST".equalsIgnoreCase(metodo)) {
        String idParam = request.getParameter("id");
        String estadoParam = request.getParameter("estado");

        if (idParam == null || estadoParam == null) {
            response.sendError(HttpServletResponse.SC_BAD_REQUEST);
            return;
        }

        try {
            int idSolicitud = Integer.parseInt(idParam);
            EstadoSolicitud estado = EstadoSolicitud.desde(estadoParam);

            if (estado == null
                    || (estado != EstadoSolicitud.APROBADA
                    && estado != EstadoSolicitud.RECHAZADA)) {
                response.sendError(HttpServletResponse.SC_BAD_REQUEST);
                return;
            }

            Inmobiliaria inmobiliaria = inmobiliariaDAO.buscarPorUsuario(usuarioId);
            if (inmobiliaria == null) {
                response.sendError(HttpServletResponse.SC_FORBIDDEN);
                return;
            }

            Solicitud solicitud = solicitudDAO.buscarPorId(idSolicitud);
            if (solicitud == null) {
                response.sendError(HttpServletResponse.SC_NOT_FOUND);
                return;
            }

            Propiedad propiedad = propiedadDAO.buscarPorId(solicitud.getPropiedadId());
            if (propiedad == null || propiedad.getInmobiliariaId() != inmobiliaria.getId()) {
                response.sendError(HttpServletResponse.SC_FORBIDDEN);
                return;
            }

            solicitudDAO.cambiarEstado(idSolicitud, estado);
            response.sendRedirect(request.getContextPath() + "/controladores/inmobiliaria-solicitudes.jsp");
        } catch (NumberFormatException e) {
            response.sendError(HttpServletResponse.SC_BAD_REQUEST);
        } catch (SQLException e) {
            application.log("Error al actualizar solicitud", e);
            response.sendError(HttpServletResponse.SC_INTERNAL_SERVER_ERROR);
        }
        return;
    }

    /* GET */
    try {
        Inmobiliaria inmobiliaria = inmobiliariaDAO.buscarPorUsuario(usuarioId);

        if (inmobiliaria == null) {
            request.setAttribute("error", "El usuario no tiene una inmobiliaria asociada.");
            request.getRequestDispatcher("/WEB-INF/views/inmobiliaria/solicitudes.jsp")
                    .forward(request, response);
            return;
        }

        List<Propiedad> propiedades = propiedadDAO.listarPorInmobiliaria(inmobiliaria.getId());
        List<Solicitud> solicitudes = new ArrayList<>();

        for (Propiedad propiedad : propiedades) {
            solicitudes.addAll(solicitudDAO.listarPorPropiedad(propiedad.getId()));
        }

        request.setAttribute("solicitudes", solicitudes);
        request.getRequestDispatcher("/WEB-INF/views/inmobiliaria/solicitudes.jsp")
                .forward(request, response);
    } catch (SQLException e) {
        application.log("Error al cargar solicitudes del agente", e);
        request.setAttribute("error", "No fue posible cargar las solicitudes.");
        request.getRequestDispatcher("/WEB-INF/views/inmobiliaria/solicitudes.jsp")
                .forward(request, response);
    }
%>