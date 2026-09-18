<%-- C:/webapp/controladores/index.jsp
     Conversión de IndexServlet (JSP): página de inicio (welcome-file),
     carga las 6 publicaciones recientes y los favoritos de la sesión. --%>
<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ include file="/WEB-INF/negocio/todo.jspf" %>
<%@ page import="java.sql.SQLException" %>
<%@ page import="java.util.List" %>
<%@ page import="java.util.Set" %>
<%
    request.setCharacterEncoding("UTF-8");
    response.setCharacterEncoding("UTF-8");

    int LIMITE_RECIENTES = 6;
    PropiedadDAO propiedadDAO = new PropiedadDAO();
    FavoritoDAO favoritoDAO = new FavoritoDAO();

    request.setAttribute("urlActual", request.getRequestURI());

    try {
        List<Propiedad> recientes = propiedadDAO.listarRecientes(LIMITE_RECIENTES);
        request.setAttribute("propiedades", recientes);

        Set<Integer> favoritosIds = Collections.emptySet();
        HttpSession sesionHome = request.getSession(false);
        if (sesionHome != null) {
            Integer idSesion = (Integer) sesionHome.getAttribute("usuarioId");
            if (idSesion != null) {
                try {
                    favoritosIds = favoritoDAO.listarIdsPropiedadPorUsuario(idSesion);
                } catch (SQLException ignorada) {
                    favoritosIds = Collections.emptySet();
                }
            }
        }
        request.setAttribute("favoritosIds", favoritosIds);
    } catch (SQLException e) {
        application.log("Error al cargar las publicaciones recientes", e);
        request.setAttribute("propiedades", Collections.emptyList());
        request.setAttribute("favoritosIds", Collections.emptySet());
        request.setAttribute("errorConsulta",
                "No fue posible cargar las publicaciones en este momento. Intenta de nuevo en unos minutos.");
    }

    request.getRequestDispatcher("/index.jsp").forward(request, response);
%>