<%-- C:/webapp/controladores/admin-usuarios.jsp
     Conversión de AdminUsuariosServlet (JSP):
     GET  /admin/usuarios  -> listado de usuarios con roles
     POST /admin/usuarios  -> activar/desactivar/cambiarRol (con auditoría) --%>
<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ include file="/WEB-INF/negocio/todo.jspf" %>
<%@ page import="java.util.List" %>
<%@ include file="/WEB-INF/seguridad/rol-admin.jspf" %>
<%
    UsuarioDAO usuarioDAO = new UsuarioDAO();
    RolDAO rolDAO = new RolDAO();
    UsuarioRolDAO usuarioRolDAO = new UsuarioRolDAO();
    AuditoriaDAO auditoriaDAO = new AuditoriaDAO();

    class AyudaUsuarios {
        List<Rol> obtenerTodosLosRoles() {
            return Arrays.asList(
                    crearRol(1, "ADMIN", "Administrador"),
                    crearRol(2, "AGENTE", "Agente inmobiliario"),
                    crearRol(3, "CLIENTE", "Cliente")
            );
        }

        Rol crearRol(int id, String nombre, String descripcion) {
            Rol rol = new Rol();
            rol.setIdRol(id);
            rol.setNombre(nombre);
            rol.setDescripcion(descripcion);
            return rol;
        }
    }
    AyudaUsuarios ayudaUsuarios = new AyudaUsuarios();

    String metodo = request.getMethod();

    if ("POST".equalsIgnoreCase(metodo)) {
        String accion = request.getParameter("accion");
        String idParam = request.getParameter("id");

        HttpSession sesion = request.getSession(false);
        Integer adminId = (Integer) sesion.getAttribute("usuarioId");

        if (adminId == null) {
            response.sendError(HttpServletResponse.SC_UNAUTHORIZED, "Sesión no válida");
            return;
        }

        try {
            int idUsuario = Integer.parseInt(idParam);

            if ("activar".equals(accion)) {
                usuarioDAO.cambiarEstado(idUsuario, "ACTIVO");
                auditoriaDAO.registrar(adminId, "ACTIVAR_USUARIO", "usuario", idUsuario,
                        "Usuario activado por administrador");
            } else if ("desactivar".equals(accion)) {
                usuarioDAO.cambiarEstado(idUsuario, "INACTIVO");
                auditoriaDAO.registrar(adminId, "DESACTIVAR_USUARIO", "usuario", idUsuario,
                        "Usuario desactivado por administrador");
            } else if ("cambiarRol".equals(accion)) {
                int idRol = Integer.parseInt(request.getParameter("idRol"));
                usuarioRolDAO.reemplazarRol(idUsuario, idRol);
                auditoriaDAO.registrar(adminId, "CAMBIAR_ROL", "usuario_rol", idUsuario,
                        "Rol cambiado. Nuevo rol ID: " + idRol);
            }

            response.sendRedirect(request.getContextPath() + "/controladores/admin-usuarios.jsp");
        } catch (NumberFormatException e) {
            response.sendError(HttpServletResponse.SC_BAD_REQUEST, "Datos inválidos");
        }
        return;
    }

    /* GET */
    List<Usuario> usuarios = usuarioDAO.listarTodos();
    request.setAttribute("usuarios", usuarios);
    request.setAttribute("roles", ayudaUsuarios.obtenerTodosLosRoles());

    for (Usuario usuario : usuarios) {
        List<Rol> rolesUsuario = rolDAO.obtenerRolesPorUsuario(usuario.getIdUsuario());
        request.setAttribute("roles_" + usuario.getIdUsuario(), rolesUsuario);
    }

    request.getRequestDispatcher("/WEB-INF/views/admin/usuarios.jsp").forward(request, response);
%>