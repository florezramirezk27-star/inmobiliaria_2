<%-- C:/webapp/controladores/admin-ciudades.jsp
     Conversión de AdminCiudadesServlet (JSP):
     GET  /admin/ciudades      -> listado; ?id=N para edición
     POST /admin/ciudades      -> accion=crear|editar|eliminar (+ auditoría) --%>
<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ include file="/WEB-INF/negocio/todo.jspf" %>
<%@ page import="java.sql.SQLException" %>
<%@ page import="java.util.List" %>
<%@ include file="/WEB-INF/seguridad/rol-admin.jspf" %>
<%
    CiudadDAO ciudadDAO = new CiudadDAO();
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
            if ("crear".equals(accion)) {
                String nombre = request.getParameter("nombre");
                String departamento = request.getParameter("departamento");

                if (nombre == null || nombre.isBlank()
                        || departamento == null || departamento.isBlank()) {
                    request.getSession().setAttribute("error",
                            "Nombre y departamento son obligatorios.");
                    response.sendRedirect(contexto + "/controladores/admin-ciudades.jsp");
                    return;
                }

                ciudadDAO.insertar(new Ciudad(0, nombre.trim(), departamento.trim()));

                auditoriaDAO.registrar(adminId, "CREAR_CIUDAD", "ciudad", null,
                        "Ciudad creada: " + nombre.trim() + " - " + departamento.trim());

                request.getSession().setAttribute("exito", "Ciudad creada correctamente.");
                response.sendRedirect(contexto + "/controladores/admin-ciudades.jsp");

            } else if ("editar".equals(accion)) {
                int id = Integer.parseInt(request.getParameter("id"));
                String nombre = request.getParameter("nombre");
                String departamento = request.getParameter("departamento");

                if (nombre == null || nombre.isBlank()
                        || departamento == null || departamento.isBlank()) {
                    request.getSession().setAttribute("error",
                            "Nombre y departamento son obligatorios.");
                    response.sendRedirect(contexto + "/controladores/admin-ciudades.jsp?id=" + id);
                    return;
                }

                ciudadDAO.actualizar(new Ciudad(id, nombre.trim(), departamento.trim()));

                auditoriaDAO.registrar(adminId, "EDITAR_CIUDAD", "ciudad", id,
                        "Ciudad actualizada: " + nombre.trim() + " - " + departamento.trim());

                request.getSession().setAttribute("exito",
                        "Ciudad actualizada correctamente.");
                response.sendRedirect(contexto + "/controladores/admin-ciudades.jsp");

            } else if ("eliminar".equals(accion)) {
                int id = Integer.parseInt(request.getParameter("id"));
                Ciudad ciudad = ciudadDAO.buscarPorId(id);

                ciudadDAO.eliminar(id);

                auditoriaDAO.registrar(adminId, "ELIMINAR_CIUDAD", "ciudad", id,
                        "Ciudad eliminada: "
                                + (ciudad != null ? ciudad.getNombre() : "ID " + id));

                request.getSession().setAttribute("exito",
                        "Ciudad eliminada correctamente.");
                response.sendRedirect(contexto + "/controladores/admin-ciudades.jsp");

            } else {
                response.sendError(HttpServletResponse.SC_BAD_REQUEST, "Acción no válida.");
            }
        } catch (NumberFormatException e) {
            response.sendError(HttpServletResponse.SC_BAD_REQUEST,
                    "Los datos numéricos no son válidos.");
        } catch (SQLException e) {
            String mensaje = "No se pudo realizar la operación.";
            String detalle = e.getMessage() != null ? e.getMessage().toLowerCase() : "";

            if (detalle.contains("duplicate") || detalle.contains("unique")) {
                mensaje = "La ciudad ya existe.";
            }
            if (detalle.contains("foreign key") || detalle.contains("constraint")) {
                mensaje = "No se puede eliminar la ciudad porque está siendo utilizada por propiedades.";
            }

            request.getSession().setAttribute("error", mensaje);
            response.sendRedirect(contexto + "/controladores/admin-ciudades.jsp");
        }
        return;
    }

    /* GET */
    try {
        List<Ciudad> ciudades = ciudadDAO.listarTodas();
        request.setAttribute("ciudades", ciudades);

        String idParam = request.getParameter("id");
        if (idParam != null && !idParam.isBlank()) {
            try {
                int id = Integer.parseInt(idParam);
                request.setAttribute("ciudadEditar", ciudadDAO.buscarPorId(id));
            } catch (NumberFormatException e) {
                request.setAttribute("error", "El ID de la ciudad no es válido.");
            }
        }

        request.getRequestDispatcher("/WEB-INF/views/admin/ciudades.jsp")
                .forward(request, response);
    } catch (SQLException e) {
        throw new RuntimeException("Error al consultar las ciudades.", e);
    }
%>