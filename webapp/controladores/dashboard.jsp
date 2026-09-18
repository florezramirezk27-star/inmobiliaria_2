<%-- C:/webapp/controladores/dashboard.jsp
     Conversión de ClienteDashboardServlet (JSP): panel del cliente. --%>
<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ include file="/WEB-INF/seguridad/rol-cliente.jspf" %>
<%
    request.getRequestDispatcher("/WEB-INF/views/cliente/dashboard.jsp").forward(request, response);
%>