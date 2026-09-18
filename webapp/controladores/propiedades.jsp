<%-- C:/webapp/controladores/propiedades.jsp
     Conversión de PropiedadServlet (JSP): catálogo público con buscador
     y filtros (operación, ciudad, tipo, precio máximo, texto y características). --%>
<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ include file="/WEB-INF/negocio/todo.jspf" %>
<%@ page import="java.math.BigDecimal" %>
<%@ page import="java.sql.SQLException" %>
<%@ page import="java.util.ArrayList" %>
<%@ page import="java.util.List" %>
<%@ page import="java.util.Set" %>
<%
    request.setCharacterEncoding("UTF-8");
    response.setCharacterEncoding("UTF-8");

    String urlActual = request.getRequestURI()
            + (request.getQueryString() != null ? "?" + request.getQueryString() : "");
    request.setAttribute("urlActual", urlActual);

    final PropiedadDAO propiedadDAO = new PropiedadDAO();
    final FavoritoDAO favoritoDAO = new FavoritoDAO();
    final CaracteristicaDAO caracteristicaDAO = new CaracteristicaDAO();

    class AyudaCatalogo {
        Set<Integer> favoritosDelUsuario() {
            HttpSession sesion = request.getSession(false);
            if (sesion == null) {
                return Collections.emptySet();
            }
            Integer usuarioId = (Integer) sesion.getAttribute("usuarioId");
            if (usuarioId == null) {
                return Collections.emptySet();
            }
            try {
                return favoritoDAO.listarIdsPropiedadPorUsuario(usuarioId);
            } catch (SQLException e) {
                return Collections.emptySet();
            }
        }

        FiltroPropiedad construirFiltroDesde() {
            FiltroPropiedad filtro = new FiltroPropiedad();
            filtro.setOperacion(Operacion.desde(request.getParameter("operacion")));

            String ciudad = request.getParameter("ciudad");
            if (ciudad != null && !ciudad.isBlank()) {
                try {
                    filtro.setCiudadId(Integer.valueOf(ciudad.trim()));
                } catch (NumberFormatException ignorado) {
                    // <select> envía el id numérico; si llega otra cosa se ignora.
                }
            }

            String tipo = request.getParameter("tipo");
            if (tipo != null && !tipo.isBlank()) {
                filtro.setTipoSlug(tipo.trim());
            }

            String precioMax = request.getParameter("precioMax");
            if (precioMax != null && !precioMax.isBlank()) {
                try {
                    filtro.setPrecioMaximo(new BigDecimal(precioMax.trim()));
                } catch (NumberFormatException ignorado) {
                    // idem: un precio no numérico no rompe la búsqueda.
                }
            }

            String texto = request.getParameter("q");
            if (texto != null && !texto.isBlank()) {
                filtro.setTexto(texto.trim());
            }

            String[] caracteristicas = request.getParameterValues("caracteristicas");
            if (caracteristicas != null && caracteristicas.length > 0) {
                List<Integer> ids = new ArrayList<>();
                for (String valor : caracteristicas) {
                    if (valor != null && !valor.isBlank()) {
                        try {
                            ids.add(Integer.valueOf(valor.trim()));
                        } catch (NumberFormatException ignorado) {
                            // id mal formado se descarta.
                        }
                    }
                }
                if (!ids.isEmpty()) {
                    filtro.setCaracteristicasIds(ids);
                }
            }

            return filtro;
        }

        void cargarCaracteristicas() {
            try {
                request.setAttribute("caracteristicas", caracteristicaDAO.listarTodas());
            } catch (SQLException e) {
                // sin atributo -> la JSP oculta el bloque y el resto sigue funcionando
            }
        }
    }
    AyudaCatalogo ayuda = new AyudaCatalogo();

    FiltroPropiedad filtro = ayuda.construirFiltroDesde();

    try {
        List<Propiedad> propiedades = propiedadDAO.buscar(filtro);
        request.setAttribute("propiedades", propiedades);
        request.setAttribute("filtro", filtro);
        request.setAttribute("favoritosIds", ayuda.favoritosDelUsuario());
        ayuda.cargarCaracteristicas();
    } catch (SQLException e) {
        application.log("Error al consultar el catálogo de propiedades", e);
        request.setAttribute("propiedades", Collections.emptyList());
        request.setAttribute("favoritosIds", Collections.emptySet());
        request.setAttribute("errorConsulta",
                "No fue posible cargar el catálogo en este momento. Intenta de nuevo en unos minutos.");
    }

    request.getRequestDispatcher("/catalogo.jsp").forward(request, response);
%>