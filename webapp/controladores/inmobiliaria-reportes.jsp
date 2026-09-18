<%-- C:/webapp/controladores/inmobiliaria-reportes.jsp
     Conversión de AgenteReporteServlet (JSP): reportes de ventas, arriendos
     y solicitudes de la inmobiliaria autenticada. --%>
<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ include file="/WEB-INF/negocio/todo.jspf" %>
<%@ page import="java.sql.SQLException" %>
<%@ page import="java.util.List" %>
<%@ include file="/WEB-INF/seguridad/rol-agente.jspf" %>
<%
    HttpSession sesion = request.getSession(false);
    Object usuarioIdSesion = sesion == null ? null : sesion.getAttribute("usuarioId");

    if (!(usuarioIdSesion instanceof Integer)) {
        response.sendRedirect(request.getContextPath() + "/controladores/login.jsp");
        return;
    }
    int usuarioId = ((Integer) usuarioIdSesion).intValue();

    InmobiliariaDAO inmobiliariaDAO = new InmobiliariaDAO();
    ReporteDAO reporteDAO = new ReporteDAO();

    try {
        Inmobiliaria inmobiliaria = inmobiliariaDAO.buscarPorUsuario(usuarioId);

        if (inmobiliaria == null) {
            response.sendError(HttpServletResponse.SC_FORBIDDEN,
                    "El agente no tiene una inmobiliaria asignada.");
            return;
        }

        int idInmobiliaria = inmobiliaria.getId();
        request.setAttribute("inmobiliaria", inmobiliaria);
        request.setAttribute("resumenOperaciones",
                reporteDAO.resumenOperacionesInmobiliaria(idInmobiliaria));
        request.setAttribute("solicitudesPorTipoEstado",
                reporteDAO.solicitudesPorTipoEstadoInmobiliaria(idInmobiliaria));
        request.setAttribute("operacionesAprobadas",
                reporteDAO.operacionesAprobadasInmobiliaria(idInmobiliaria));
    } catch (SQLException | RuntimeException e) {
        application.log("Error al cargar los reportes del agente", e);
        request.setAttribute("error", "No fue posible cargar los reportes en este momento.");
        request.setAttribute("resumenOperaciones", Collections.emptyList());
        request.setAttribute("solicitudesPorTipoEstado", Collections.emptyList());
        request.setAttribute("operacionesAprobadas", Collections.emptyList());
    }

    request.getRequestDispatcher("/WEB-INF/views/inmobiliaria/reportes.jsp")
            .forward(request, response);
%>