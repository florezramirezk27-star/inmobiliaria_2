<%-- C:/webapp/controladores/admin-tipos-propiedad.jsp
     Conversión de AdminTiposPropiedadServlet (JSP):
     GET  /admin/tipos-propiedad      -> listado; ?id=N para edición
     POST /admin/tipos-propiedad      -> accion=crear|editar|eliminar (+ auditoría) --%>
<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ include file="/WEB-INF/negocio/todo.jspf" %>
<%@ page import="java.sql.SQLException" %>
<%@ page import="java.util.List" %>
<%@ include file="/WEB-INF/seguridad/rol-admin.jspf" %>
<%
    TipoPropiedadDAO tipoDAO = new TipoPropiedadDAO();
    AuditoriaDAO auditoriaDAO = new AuditoriaDAO();

    String metodo = request.getMethod();

    if ("POST".equalsIgnoreCase(metodo)) {
        request.setCharacterEncoding("UTF-8");

        HttpSession sesion = request.getSession(false);
        if (sesion == null) {
            response.sendError(HttpServletResponse.SC_UNAUTHORIZED, "Sesión no válida.");
            return;
        }
        Integer adminId = (Integer) sesion.getAttribute("usuarioId");
        if (adminId == null) {
            response.sendError(HttpServletResponse.SC_UNAUTHORIZED, "Sesión no válida.");
            return;
        }

        String accion = request.getParameter("accion");
        String contexto = request.getContextPath();

        try {
            switch (accion == null ? "" : accion) {
                case "crear": {
                    String nombre = request.getParameter("nombre");
                    String descripcion = request.getParameter("descripcion");

                    if (nombre == null || nombre.isBlank()) {
                        request.getSession().setAttribute("error",
                                "El nombre del tipo es obligatorio.");
                        response.sendRedirect(contexto + "/controladores/admin-tipos-propiedad.jsp");
                        break;
                    }

                    tipoDAO.insertar(new TipoPropiedad(0, nombre.trim(),
                            descripcion != null ? descripcion.trim() : null));

                    auditoriaDAO.registrar(adminId, "CREAR_TIPO_PROPIEDAD",
                            "tipo_propiedad", null, "Tipo creado: " + nombre.trim());

                    request.getSession().setAttribute("exito",
                            "Tipo de propiedad creado correctamente.");
                    response.sendRedirect(contexto + "/controladores/admin-tipos-propiedad.jsp");
                    break;
                }
                case "editar": {
                    int id = Integer.parseInt(request.getParameter("id"));
                    String nombre = request.getParameter("nombre");
                    String descripcion = request.getParameter("descripcion");

                    if (nombre == null || nombre.isBlank()) {
                        request.getSession().setAttribute("error",
                                "El nombre del tipo es obligatorio.");
                        response.sendRedirect(contexto + "/controladores/admin-tipos-propiedad.jsp?id=" + id);
                        break;
                    }

                    tipoDAO.actualizar(new TipoPropiedad(id, nombre.trim(),
                            descripcion != null ? descripcion.trim() : null));

                    auditoriaDAO.registrar(adminId, "EDITAR_TIPO_PROPIEDAD",
                            "tipo_propiedad", id, "Tipo actualizado: " + nombre.trim());

                    request.getSession().setAttribute("exito",
                            "Tipo de propiedad actualizado correctamente.");
                    response.sendRedirect(contexto + "/controladores/admin-tipos-propiedad.jsp");
                    break;
                }
                case "eliminar": {
                    int id = Integer.parseInt(request.getParameter("id"));
                    TipoPropiedad tipo = tipoDAO.buscarPorId(id);

                    tipoDAO.eliminar(id);

                    auditoriaDAO.registrar(adminId, "ELIMINAR_TIPO_PROPIEDAD",
                            "tipo_propiedad", id,
                            "Tipo eliminado: "
                                    + (tipo != null ? tipo.getNombre() : "ID " + id));

                    request.getSession().setAttribute("exito",
                            "Tipo de propiedad eliminado correctamente.");
                    response.sendRedirect(contexto + "/controladores/admin-tipos-propiedad.jsp");
                    break;
                }
                default:
                    response.sendError(HttpServletResponse.SC_BAD_REQUEST, "Acción no válida.");
            }
        } catch (NumberFormatException e) {
            request.getSession().setAttribute("error", "El identificador no es válido.");
            response.sendRedirect(contexto + "/controladores/admin-tipos-propiedad.jsp");
        } catch (SQLException e) {
            String mensaje = "No se pudo realizar la operación.";
            String detalle = e.getMessage() != null ? e.getMessage().toLowerCase() : "";

            if (detalle.contains("duplicate") || detalle.contains("unique")) {
                mensaje = "El tipo de propiedad ya existe.";
            }
            if (detalle.contains("foreign key") || detalle.contains("constraint")) {
                mensaje = "No se puede eliminar el tipo porque está siendo utilizado por propiedades.";
            }

            request.getSession().setAttribute("error", mensaje);
            response.sendRedirect(contexto + "/controladores/admin-tipos-propiedad.jsp");
        }
        return;
    }

    /* GET */
    try {
        List<TipoPropiedad> tipos = tipoDAO.listarTodos();
        request.setAttribute("tipos", tipos);

        String idParam = request.getParameter("id");
        if (idParam != null && !idParam.isBlank()) {
            try {
                int id = Integer.parseInt(idParam);
                request.setAttribute("tipoEditar", tipoDAO.buscarPorId(id));
            } catch (NumberFormatException e) {
                request.setAttribute("error", "El ID del tipo no es válido.");
            }
        }

        request.getRequestDispatcher("/WEB-INF/views/admin/tipos-propiedad.jsp")
                .forward(request, response);
    } catch (SQLException e) {
        throw new RuntimeException("Error al consultar los tipos de propiedad.", e);
    }
%>