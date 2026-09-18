<%-- C:/webapp/controladores/favoritos.jsp
     Conversión de FavoritoServlet (JSP):
     GET  /favoritos, /cliente/favoritos  -> lista de favoritos del cliente
     POST /propiedades/favorito           -> alterna el favorito y vuelve a la página
     El usuario siempre sale de la sesión (usuarioId). --%>
<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ include file="/WEB-INF/negocio/todo.jspf" %>
<%@ page import="java.sql.SQLException" %>
<%@ page import="java.util.ArrayList" %>
<%@ page import="java.util.List" %>
<%!
    private Integer usuarioDeSesion(HttpServletRequest request) {
        HttpSession sesion = request.getSession(false);
        if (sesion == null) {
            return null;
        }
        return (Integer) sesion.getAttribute("usuarioId");
    }

    private String destinoSeguro(HttpServletRequest request) {
        String volver = request.getParameter("volver");
        String contexto = request.getContextPath();
        boolean esRutaInterna = (volver != null && volver.startsWith(contexto + "/"))
                || (contexto.isEmpty() && volver != null && volver.startsWith("/"));
        if (esRutaInterna) {
            return volver;
        }
        return contexto + "/controladores/propiedades.jsp";
    }
%>
<%@ include file="/WEB-INF/seguridad/rol-cliente.jspf" %>
<%
    HttpSession sesion = request.getSession(false);
    Integer usuarioId = (Integer) sesion.getAttribute("usuarioId");
    if (usuarioId == null) {
        response.sendRedirect(request.getContextPath() + "/controladores/login.jsp");
        return;
    }

    String metodo = request.getMethod();

    if ("POST".equalsIgnoreCase(metodo)) {
        FavoritoDAO favoritoDAO = new FavoritoDAO();
        PropiedadDAO propiedadDAO = new PropiedadDAO();

        String idParam = request.getParameter("propiedadId");

        if (idParam != null && !idParam.isBlank()) {
            try {
                int propiedadId = Integer.parseInt(idParam.trim());
                if (favoritoDAO.esFavorito(usuarioId, propiedadId)) {
                    favoritoDAO.quitar(usuarioId, propiedadId);
                } else if (propiedadDAO.buscarPublicadaPorId(propiedadId) != null) {
                    favoritoDAO.agregar(usuarioId, propiedadId);
                }
            } catch (NumberFormatException | SQLException e) {
                application.log("Error al alternar favorito", e);
            }
        }

        response.sendRedirect(destinoSeguro(request));
        return;
    }

    /* GET: listado de favoritos */
    FavoritoDAO favoritoDAO = new FavoritoDAO();
    PropiedadDAO propiedadDAO = new PropiedadDAO();

    try {
        List<Integer> ids = favoritoDAO.listarIdsPropiedadPorUsuarioOrdenados(usuarioId);
        List<Propiedad> propiedades = new ArrayList<>();
        for (Integer id : ids) {
            Propiedad p = propiedadDAO.buscarPublicadaPorId(id);
            if (p != null) {
                propiedades.add(p);
            }
        }
        request.setAttribute("propiedades", propiedades);
        request.setAttribute("favoritosIds", new java.util.HashSet<>(ids));
    } catch (SQLException e) {
        application.log("Error al cargar los favoritos", e);
        request.setAttribute("propiedades", java.util.Collections.emptyList());
        request.setAttribute("favoritosIds", java.util.Collections.emptySet());
        request.setAttribute("errorConsulta",
                "No fue posible cargar tus favoritos en este momento. Intenta de nuevo en unos minutos.");
    }

    request.getRequestDispatcher("/favoritos.jsp").forward(request, response);
%>