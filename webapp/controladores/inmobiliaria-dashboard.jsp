<%-- C:/webapp/controladores/inmobiliaria-dashboard.jsp
     Conversión de InmobiliariaDashboardServlet (JSP): panel de la inmobiliaria. --%>
<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ include file="/WEB-INF/seguridad/rol-agente.jspf" %>
<%
    request.getRequestDispatcher("/WEB-INF/views/inmobiliaria/dashboard.jsp").forward(request, response);
%>