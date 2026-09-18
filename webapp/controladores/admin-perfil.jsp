<%-- C:/webapp/controladores/admin-perfil.jsp
     Conversión de AdminPerfilServlet (JSP):
     GET  /admin/usuarios/perfil?id=N  -> detalle del perfil de un usuario
     POST /admin/usuarios/perfil       -> actualiza perfil + auditoría --%>
<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ include file="/WEB-INF/negocio/todo.jspf" %>
<%@ page import="java.util.List" %>
<%@ include file="/WEB-INF/seguridad/rol-admin.jspf" %>
<%
    HttpSession sesion = request.getSession(false);
    String metodo = request.getMethod();

    if ("POST".equalsIgnoreCase(metodo)) {
        PerfilDAO perfilDAO2 = new PerfilDAO();
        try {
            int idUsuario = Integer.parseInt(request.getParameter("idUsuario"));

            Perfil perfil = new Perfil();
            perfil.setIdUsuario(idUsuario);
            perfil.setNombres(request.getParameter("nombres"));
            perfil.setApellidos(request.getParameter("apellidos"));
            perfil.setDocumento(request.getParameter("documento"));
            perfil.setTelefono(request.getParameter("telefono"));
            perfil.setDireccion(request.getParameter("direccion"));

            perfilDAO2.actualizarPerfil(perfil);

            String contexto = request.getContextPath();
            Integer adminId = (Integer) sesion.getAttribute("usuarioId");
            if (adminId != null) {
                new AuditoriaDAO().registrar(adminId, "ACTUALIZAR_PERFIL",
                        "perfil", idUsuario, "Perfil actualizado por administrador");
            }

            response.sendRedirect(contexto + "/controladores/admin-perfil.jsp?id=" + idUsuario);
        } catch (NumberFormatException e) {
            response.sendError(HttpServletResponse.SC_BAD_REQUEST, "Datos inválidos");
        }
        return;
    }

    /* GET */
    String idParam = request.getParameter("id");
    try {
        int idUsuario = Integer.parseInt(idParam);

        Usuario usuario = null;
        for (Usuario u : new UsuarioDAO().listarTodos()) {
            if (u.getIdUsuario() == idUsuario) {
                usuario = u;
                break;
            }
        }
        Perfil perfil = new PerfilDAO().buscarPorUsuario(idUsuario);
        List<Rol> roles = new RolDAO().obtenerRolesPorUsuario(idUsuario);

        if (usuario == null) {
            response.sendError(HttpServletResponse.SC_NOT_FOUND, "Usuario no encontrado");
            return;
        }

        request.setAttribute("usuario", usuario);
        request.setAttribute("perfil", perfil);
        request.setAttribute("roles", roles);

        request.getRequestDispatcher("/WEB-INF/views/admin/perfil-usuario.jsp")
                .forward(request, response);
    } catch (NumberFormatException e) {
        response.sendError(HttpServletResponse.SC_BAD_REQUEST, "ID de usuario inválido");
    }
%>