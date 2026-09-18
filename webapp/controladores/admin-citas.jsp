<%-- C:/webapp/controladores/admin-citas.jsp
     Conversión de AdminCitasServlet (JSP): todas las citas del sistema. --%>
<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ include file="/WEB-INF/negocio/todo.jspf" %>
<%@ page import="java.sql.SQLException" %>
<%@ page import="java.util.List" %>
<%@ include file="/WEB-INF/seguridad/rol-admin.jspf" %>
<%
    CitaDAO citaDAO = new CitaDAO();

    try {
        request.setAttribute("citas", citaDAO.listarTodas());
    } catch (SQLException e) {
        application.log("Error al cargar las citas para el administrador", e);
        request.setAttribute("citas", Collections.emptyList());
        request.setAttribute("errorConsulta",
                "No fue posible cargar las citas en este momento.");
    }

    request.getRequestDispatcher("/WEB-INF/views/admin/citas.jsp")
            .forward(request, response);
%>