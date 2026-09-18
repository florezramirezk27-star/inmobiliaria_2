<%-- C:/webapp/controladores/login.jsp
     Conversión de LoginServlet (JSP): valida credenciales e inicia sesión. --%>
<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ include file="/WEB-INF/negocio/todo.jspf" %>
<%
    request.setCharacterEncoding("UTF-8");
    response.setCharacterEncoding("UTF-8");

    String metodo = request.getMethod();

    if ("GET".equalsIgnoreCase(metodo) || "HEAD".equalsIgnoreCase(metodo)) {
        request.getRequestDispatcher("/WEB-INF/views/auth/login.jsp").forward(request, response);
        return;
    }

    /* POST: autenticación */
    String correo = request.getParameter("correo");
    String password = request.getParameter("password");

    if (correo == null || correo.isBlank()
            || password == null || password.isBlank()) {

        request.setAttribute("error", "Correo y contraseña son obligatorios.");
        request.getRequestDispatcher("/WEB-INF/views/auth/login.jsp").forward(request, response);
        return;
    }

    AuthService authService = new AuthService();
    LoginResult resultado = authService.autenticar(correo, password);

    if (!resultado.isExitoso()) {
        request.setAttribute("error", resultado.getMensaje());
        request.getRequestDispatcher("/WEB-INF/views/auth/login.jsp").forward(request, response);
        return;
    }

    HttpSession sesion = request.getSession(true);
    sesion.setAttribute("usuario", resultado.getUsuario());
    sesion.setAttribute("usuarioId", resultado.getUsuario().getIdUsuario());
    sesion.setAttribute("correo", resultado.getUsuario().getCorreo());
    sesion.setAttribute("roles", resultado.getRoles());

    List<Rol> roles = resultado.getRoles();
    String rolPrincipal = roles.get(0).getNombre().toUpperCase();

    switch (rolPrincipal) {
        case "ADMIN":
            response.sendRedirect(request.getContextPath() + "/controladores/admin-dashboard.jsp");
            break;
        case "AGENTE":
            response.sendRedirect(request.getContextPath() + "/controladores/inmobiliaria-dashboard.jsp");
            break;
        case "CLIENTE":
            response.sendRedirect(request.getContextPath() + "/controladores/dashboard.jsp");
            break;
        default:
            sesion.invalidate();
            request.setAttribute("error", "Rol de usuario no reconocido.");
            request.getRequestDispatcher("/WEB-INF/views/auth/login.jsp").forward(request, response);
    }
%>