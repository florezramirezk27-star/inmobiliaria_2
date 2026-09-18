<%-- C:/webapp/controladores/admin-auditoria.jsp
     Conversión de AuditoriaServlet (JSP): registro de auditoría. --%>
<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ include file="/WEB-INF/negocio/todo.jspf" %>
<%@ include file="/WEB-INF/seguridad/rol-admin.jspf" %>
<%
    AuditoriaDAO auditoriaDAO = new AuditoriaDAO();
    request.setAttribute("auditorias", auditoriaDAO.listarTodas());
    request.getRequestDispatcher("/WEB-INF/views/admin/auditoria.jsp")
            .forward(request, response);
%>