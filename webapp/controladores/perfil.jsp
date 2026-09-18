<%-- C:/webapp/controladores/perfil.jsp
     Conversión de PerfilServlet (JSP): consulta y actualización del perfil del cliente. --%>
<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ include file="/WEB-INF/negocio/todo.jspf" %>
<%@ include file="/WEB-INF/seguridad/rol-cliente.jspf" %>
<%
    HttpSession sesion = request.getSession(false);
    Integer usuarioId = (Integer) sesion.getAttribute("usuarioId");
    if (usuarioId == null) {
        response.sendRedirect(request.getContextPath() + "/controladores/login.jsp");
        return;
    }

    PerfilDAO perfilDAO = new PerfilDAO();

    String metodo = request.getMethod();

    if ("POST".equalsIgnoreCase(metodo)) {
        Perfil perfil = new Perfil();
        perfil.setIdUsuario(usuarioId);
        perfil.setNombres(request.getParameter("nombres"));
        perfil.setApellidos(request.getParameter("apellidos"));
        perfil.setDocumento(request.getParameter("documento"));
        perfil.setTelefono(request.getParameter("telefono"));
        perfil.setDireccion(request.getParameter("direccion"));
        perfil.setFoto(request.getParameter("foto"));

        try {
            perfilDAO.actualizarPerfil(perfil);
            response.sendRedirect(request.getContextPath() + "/controladores/perfil.jsp?actualizado=true");
        } catch (Exception e) {
            e.printStackTrace();
            request.setAttribute("error", "No fue posible actualizar el perfil.");
            request.setAttribute("perfil", perfil);
            request.getRequestDispatcher("/WEB-INF/views/cliente/perfil.jsp").forward(request, response);
        }
        return;
    }

    /* GET */
    Perfil perfil = perfilDAO.buscarPorUsuario(usuarioId);
    request.setAttribute("perfil", perfil);
    request.getRequestDispatcher("/WEB-INF/views/cliente/perfil.jsp").forward(request, response);
%>