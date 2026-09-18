<%-- C:/webapp/controladores/logout.jsp
     Conversión de LogoutServlet (JSP):
     GET  /logout -> página de confirmación (aún NO cierra sesión).
     POST /logout -> invalida la sesión y vuelve al login. --%>
<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ include file="/WEB-INF/seguridad/requiere-sesion.jspf" %>
<%
    String metodo = request.getMethod();

    if ("GET".equalsIgnoreCase(metodo) || "HEAD".equalsIgnoreCase(metodo)) {
        request.getRequestDispatcher("/WEB-INF/views/auth/confirmar-logout.jsp").forward(request, response);
        return;
    }

    /* POST: cierre definitivo */
    HttpSession sesion = request.getSession(false);
    if (sesion != null) {
        sesion.invalidate();
    }

    response.sendRedirect(request.getContextPath() + "/controladores/login.jsp");
%>