<%-- C:/webapp/controladores/acceso-denegado.jsp
     Conversión de AccesoDenegadoServlet (JSP): 403 amigable. --%>
<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%
    request.setCharacterEncoding("UTF-8");
    response.setCharacterEncoding("UTF-8");
    response.setStatus(HttpServletResponse.SC_FORBIDDEN);
    request.getRequestDispatcher("/WEB-INF/views/error/acceso-denegado.jsp").forward(request, response);
%>