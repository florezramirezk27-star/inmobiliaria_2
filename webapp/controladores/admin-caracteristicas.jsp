<%-- C:/webapp/controladores/admin-caracteristicas.jsp
     Conversión de AdminCaracteristicasServlet (JSP):
     GET  /admin/caracteristicas      -> listado; ?id=N para edición
     POST /admin/caracteristicas      -> accion=crear|editar|eliminar (+ auditoría) --%>
<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ include file="/WEB-INF/negocio/todo.jspf" %>
<%@ page import="java.sql.SQLException" %>
<%@ page import="java.util.List" %>
<%@ include file="/WEB-INF/seguridad/rol-admin.jspf" %>
<%
    CaracteristicaDAO caracteristicaDAO = new CaracteristicaDAO();
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
                    String categoria = request.getParameter("categoria");

                    if (nombre == null || nombre.isBlank()
                            || categoria == null || categoria.isBlank()) {
                        request.getSession().setAttribute("error",
                                "El nombre y la categoría de la característica son obligatorios.");
                        response.sendRedirect(contexto + "/controladores/admin-caracteristicas.jsp");
                        break;
                    }

                    Caracteristica caracteristica = new Caracteristica();
                    caracteristica.setNombre(nombre.trim());
                    caracteristica.setCategoria(categoria);

                    caracteristicaDAO.insertar(caracteristica);

                    auditoriaDAO.registrar(adminId, "CREAR_CARACTERISTICA",
                            "caracteristica", null,
                            "Característica creada: " + nombre.trim() + " (" + categoria + ")");

                    request.getSession().setAttribute("exito",
                            "Característica creada correctamente.");
                    response.sendRedirect(contexto + "/controladores/admin-caracteristicas.jsp");
                    break;
                }
                case "editar": {
                    int id = Integer.parseInt(request.getParameter("id"));
                    String nombre = request.getParameter("nombre");
                    String categoria = request.getParameter("categoria");

                    if (nombre == null || nombre.isBlank()
                            || categoria == null || categoria.isBlank()) {
                        request.getSession().setAttribute("error",
                                "El nombre y la categoría de la característica son obligatorios.");
                        response.sendRedirect(contexto + "/controladores/admin-caracteristicas.jsp?id=" + id);
                        break;
                    }

                    Caracteristica caracteristica = new Caracteristica();
                    caracteristica.setId(id);
                    caracteristica.setNombre(nombre.trim());
                    caracteristica.setCategoria(categoria);

                    caracteristicaDAO.actualizar(caracteristica);

                    auditoriaDAO.registrar(adminId, "EDITAR_CARACTERISTICA",
                            "caracteristica", id,
                            "Característica actualizada: " + nombre.trim() + " (" + categoria + ")");

                    request.getSession().setAttribute("exito",
                            "Característica actualizada correctamente.");
                    response.sendRedirect(contexto + "/controladores/admin-caracteristicas.jsp");
                    break;
                }
                case "eliminar": {
                    int id = Integer.parseInt(request.getParameter("id"));
                    Caracteristica caracteristica = caracteristicaDAO.buscarPorId(id);

                    caracteristicaDAO.eliminar(id);

                    auditoriaDAO.registrar(adminId, "ELIMINAR_CARACTERISTICA",
                            "caracteristica", id,
                            "Característica eliminada: "
                                    + (caracteristica != null ? caracteristica.getNombre() : "ID " + id));

                    request.getSession().setAttribute("exito",
                            "Característica eliminada correctamente.");
                    response.sendRedirect(contexto + "/controladores/admin-caracteristicas.jsp");
                    break;
                }
                default:
                    response.sendError(HttpServletResponse.SC_BAD_REQUEST, "Acción no válida.");
            }
        } catch (NumberFormatException e) {
            request.getSession().setAttribute("error", "El identificador no es válido.");
            response.sendRedirect(contexto + "/controladores/admin-caracteristicas.jsp");
        } catch (SQLException e) {
            String mensaje = "No se pudo realizar la operación.";
            String detalle = e.getMessage() != null ? e.getMessage().toLowerCase() : "";

            if (detalle.contains("duplicate") || detalle.contains("unique")) {
                mensaje = "La característica ya existe.";
            }
            if (detalle.contains("foreign key") || detalle.contains("constraint")) {
                mensaje = "No se puede eliminar la característica porque está asociada a una o más propiedades.";
            }

            request.getSession().setAttribute("error", mensaje);
            response.sendRedirect(contexto + "/controladores/admin-caracteristicas.jsp");
        }
        return;
    }

    /* GET */
    try {
        List<Caracteristica> caracteristicas = caracteristicaDAO.listarTodas();
        request.setAttribute("caracteristicas", caracteristicas);

        String idParam = request.getParameter("id");
        if (idParam != null && !idParam.isBlank()) {
            try {
                int id = Integer.parseInt(idParam);
                request.setAttribute("caracteristicaEditar",
                        caracteristicaDAO.buscarPorId(id));
            } catch (NumberFormatException e) {
                request.setAttribute("error",
                        "El ID de la característica no es válido.");
            }
        }

        request.getRequestDispatcher("/WEB-INF/views/admin/caracteristicas.jsp")
                .forward(request, response);
    } catch (SQLException e) {
        throw new RuntimeException("Error al consultar las características.", e);
    }
%>