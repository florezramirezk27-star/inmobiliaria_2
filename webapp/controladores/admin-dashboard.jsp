<%-- C:/webapp/controladores/admin-dashboard.jsp
     Conversión de AdminDashboardServlet (JSP): panel del administrador. --%>
<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ include file="/WEB-INF/seguridad/rol-admin.jspf" %>
<%
    request.getRequestDispatcher("/WEB-INF/views/admin/dashboard.jsp").forward(request, response);
%>