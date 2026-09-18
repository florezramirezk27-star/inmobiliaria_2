<%-- C:/webapp/controladores/inmobiliaria-propiedades.jsp
     Conversión de InmobiliariaPropiedadesServlet (JSP):
     GET  /inmobiliaria/propiedades  -> tabla de propiedades del agente
     POST /inmobiliaria/propiedades  -> accion=darDeBaja (baja lógica CERRADA) --%>
<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ include file="/WEB-INF/negocio/todo.jspf" %>
<%@ page import="java.sql.SQLException" %>
<%@ page import="java.util.List" %>
<%@ include file="/WEB-INF/seguridad/rol-agente.jspf" %>
<%
    HttpSession sesion = request.getSession(false);
    Integer usuarioId = (Integer) sesion.getAttribute("usuarioId");
    if (usuarioId == null) {
        response.sendRedirect(request.getContextPath() + "/controladores/login.jsp");
        return;
    }
    int idUsuario = usuarioId;

    PropiedadDAO propiedadDAO = new PropiedadDAO();
    InmobiliariaDAO inmobiliariaDAO = new InmobiliariaDAO();
    AuditoriaDAO auditoriaDAO = new AuditoriaDAO();

    String metodo = request.getMethod();

    if ("POST".equalsIgnoreCase(metodo)) {
        String accion = request.getParameter("accion");

        try {
            if ("darDeBaja".equals(accion)) {
                int idPropiedad = Integer.parseInt(request.getParameter("id").trim());

                Inmobiliaria inmobiliaria = inmobiliariaDAO.buscarPorUsuario(usuarioId);
                Propiedad propiedad = propiedadDAO.buscarPorId(idPropiedad);

                if (inmobiliaria == null
                        || propiedad == null
                        || propiedad.getInmobiliariaId() != inmobiliaria.getId()) {
                    response.sendError(HttpServletResponse.SC_FORBIDDEN,
                            "La propiedad no pertenece a tu inmobiliaria.");
                    return;
                }

                if (propiedad.getEstado() == EstadoPropiedad.CERRADA) {
                    sesion.setAttribute("exito", "La propiedad ya estaba dada de baja.");
                } else {
                    propiedadDAO.cambiarEstado(idPropiedad, EstadoPropiedad.CERRADA);
                    auditoriaDAO.registrar(usuarioId, "DAR_DE_BAJA_PROPIEDAD",
                            "propiedad", idPropiedad,
                            "Propiedad marcada como CERRADA (baja lógica): " + propiedad.getTitulo());
                    sesion.setAttribute("exito",
                            "La propiedad «" + propiedad.getTitulo()
                                    + "» se dio de baja y ya no aparece en el catálogo público.");
                }

                response.sendRedirect(request.getContextPath() + "/controladores/inmobiliaria-propiedades.jsp");
            } else {
                response.sendError(HttpServletResponse.SC_BAD_REQUEST, "Acción no válida.");
            }
        } catch (NumberFormatException e) {
            response.sendError(HttpServletResponse.SC_BAD_REQUEST, "Datos inválidos.");
        } catch (SQLException e) {
            application.log("Error en la baja lógica de la propiedad.", e);
            sesion.setAttribute("error",
                    "No fue posible dar de baja la propiedad. Intenta de nuevo en unos minutos.");
            response.sendRedirect(request.getContextPath() + "/controladores/inmobiliaria-propiedades.jsp");
        }
        return;
    }

    /* GET */
    try {
        Inmobiliaria inmobiliaria = inmobiliariaDAO.buscarPorUsuario(usuarioId);

        if (inmobiliaria == null) {
            request.setAttribute("error", "El usuario no tiene una inmobiliaria asociada.");
            request.getRequestDispatcher("/WEB-INF/views/inmobiliaria/propiedades.jsp")
                    .forward(request, response);
            return;
        }

        List<Propiedad> propiedades = propiedadDAO.listarPorInmobiliaria(inmobiliaria.getId());
        request.setAttribute("propiedades", propiedades);
        request.getRequestDispatcher("/WEB-INF/views/inmobiliaria/propiedades.jsp")
                .forward(request, response);
    } catch (SQLException e) {
        application.log("Error al consultar las propiedades de la inmobiliaria.", e);
        request.setAttribute("error", "No fue posible cargar las propiedades en este momento.");
        request.getRequestDispatcher("/WEB-INF/views/inmobiliaria/propiedades.jsp")
                .forward(request, response);
    }
%>