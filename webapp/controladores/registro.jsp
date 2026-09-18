<%-- C:/webapp/controladores/registro.jsp
     Conversión de RegistroServlet (JSP): valida y registra un cliente nuevo. --%>
<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ include file="/WEB-INF/negocio/todo.jspf" %>
<%
    request.setCharacterEncoding("UTF-8");
    response.setCharacterEncoding("UTF-8");

    String metodo = request.getMethod();

    if ("GET".equalsIgnoreCase(metodo) || "HEAD".equalsIgnoreCase(metodo)) {
        request.getRequestDispatcher("/WEB-INF/views/auth/registro.jsp").forward(request, response);
        return;
    }

    /* POST: registro */
    String nombres = request.getParameter("nombres");
    String apellidos = request.getParameter("apellidos");
    String correo = request.getParameter("correo");
    String password = request.getParameter("password");
    String confirmPassword = request.getParameter("confirmPassword");
    String documento = request.getParameter("documento");
    String telefono = request.getParameter("telefono");
    String direccion = request.getParameter("direccion");

    if (nombres == null || nombres.isBlank()
            || apellidos == null || apellidos.isBlank()
            || correo == null || correo.isBlank()
            || password == null || password.isBlank()
            || confirmPassword == null || confirmPassword.isBlank()
            || documento == null || documento.isBlank()) {
        request.setAttribute("error", "Todos los campos obligatorios deben completarse.");
        request.getRequestDispatcher("/WEB-INF/views/auth/registro.jsp").forward(request, response);
        return;
    }

    if (!password.equals(confirmPassword)) {
        request.setAttribute("error", "Las contraseñas no coinciden.");
        request.getRequestDispatcher("/WEB-INF/views/auth/registro.jsp").forward(request, response);
        return;
    }

    if (password.length() < 8) {
        request.setAttribute("error", "La contraseña debe tener mínimo 8 caracteres.");
        request.getRequestDispatcher("/WEB-INF/views/auth/registro.jsp").forward(request, response);
        return;
    }

    if (!correo.matches("^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,}$")) {
        request.setAttribute("error", "El correo ingresado no tiene un formato válido.");
        request.getRequestDispatcher("/WEB-INF/views/auth/registro.jsp").forward(request, response);
        return;
    }

    if (!documento.trim().matches("^[0-9]{4,15}$")) {
        request.setAttribute("error", "El número de documento solo puede contener dígitos (mínimo 4).");
        request.getRequestDispatcher("/WEB-INF/views/auth/registro.jsp").forward(request, response);
        return;
    }

    if (telefono != null && !telefono.isBlank()
            && !telefono.trim().matches("^[0-9+()\\- ]{7,15}$")) {
        request.setAttribute("error",
                "El teléfono tiene un formato inválido: usa solo dígitos, espacios, guiones, paréntesis o el prefijo +.");
        request.getRequestDispatcher("/WEB-INF/views/auth/registro.jsp").forward(request, response);
        return;
    }

    try {
        AuthService authService = new AuthService();
        authService.registrar(nombres, apellidos, correo, password, documento, telefono, direccion);
        response.sendRedirect(request.getContextPath() + "/controladores/login.jsp?registro=exitoso");
    } catch (IllegalArgumentException e) {
        request.setAttribute("error", e.getMessage());
        request.getRequestDispatcher("/WEB-INF/views/auth/registro.jsp").forward(request, response);
    } catch (Exception e) {
        request.setAttribute("error", "No fue posible completar el registro.");
        e.printStackTrace();
        request.getRequestDispatcher("/WEB-INF/views/auth/registro.jsp").forward(request, response);
    }
%>