<%-- C:/webapp/controladores/propiedad-detalle.jsp
     Conversión de PropiedadDetalleServlet (JSP): ficha pública de una
     propiedad con galería, datos y características, protegiendo de la
     consulta por URL las propiedades BORRADOR/CERRADA. --%>
<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ include file="/WEB-INF/negocio/todo.jspf" %>
<%@ page import="java.sql.SQLException" %>
<%@ page import="java.util.List" %>
<%!
    private Integer idDeSesionONulo(HttpServletRequest request) {
        HttpSession sesion = request.getSession(false);
        if (sesion == null) {
            return null;
        }
        return (Integer) sesion.getAttribute("usuarioId");
    }

    private boolean tieneRol(HttpServletRequest request, String rolBuscado) {
        HttpSession sesion = request.getSession(false);
        if (sesion == null) {
            return false;
        }
        return tieneRol(sesion.getAttribute("roles"), rolBuscado);
    }
%>
<%
    request.setCharacterEncoding("UTF-8");
    response.setCharacterEncoding("UTF-8");

    PropiedadDAO propiedadDAO = new PropiedadDAO();
    ImagenPropiedadDAO imagenDAO = new ImagenPropiedadDAO();
    CaracteristicaDAO caracteristicaDAO = new CaracteristicaDAO();
    FavoritoDAO favoritoDAO = new FavoritoDAO();
    InmobiliariaDAO inmobiliariaDAO = new InmobiliariaDAO();

    class AyudaDetalle {
        boolean esPropiedadNoPublica(Propiedad p) {
            return p.getEstado() != null
                    && p.getEstado() != EstadoPropiedad.PUBLICADA;
        }

        boolean puedeGestionarPropiedad(Propiedad propiedad, InmobiliariaDAO inmobiliariaDAO)
                throws SQLException {
            if (!tieneRol(request, "AGENTE")) {
                return false;
            }
            Integer usuarioId = idDeSesionONulo(request);
            if (usuarioId == null) {
                return false;
            }
            Inmobiliaria inmobiliaria = inmobiliariaDAO.buscarPorUsuario(usuarioId);
            return inmobiliaria != null
                    && propiedad.getInmobiliariaId() == inmobiliaria.getId();
        }

        boolean puedeVerPropiedadNoPublica(Propiedad propiedad, InmobiliariaDAO inmobiliariaDAO)
                throws SQLException {
            return tieneRol(request, "ADMIN")
                    || puedeGestionarPropiedad(propiedad, inmobiliariaDAO);
        }
    }
    AyudaDetalle ayudaDetalle = new AyudaDetalle();

    String idParam = request.getParameter("id");

    if (idParam == null || idParam.isBlank()) {
        request.setAttribute("error", "No se indicó qué propiedad mostrar.");
        request.getRequestDispatcher("/detalle-propiedad.jsp").forward(request, response);
        return;
    }

    int id;
    try {
        id = Integer.parseInt(idParam.trim());
    } catch (NumberFormatException e) {
        request.setAttribute("error", "El identificador de la propiedad no es válido.");
        request.getRequestDispatcher("/detalle-propiedad.jsp").forward(request, response);
        return;
    }

    try {
        Propiedad propiedad = propiedadDAO.buscarPorId(id);

        if (propiedad == null) {
            request.setAttribute("error", "No se encontró la propiedad solicitada.");
        } else if (ayudaDetalle.esPropiedadNoPublica(propiedad)
                && !ayudaDetalle.puedeVerPropiedadNoPublica(propiedad, inmobiliariaDAO)) {
            request.setAttribute("error", "Esta propiedad no está disponible públicamente.");
        } else {
            List<ImagenPropiedad> imagenes = imagenDAO.listarPorPropiedad(id);
            List<Caracteristica> caracteristicas = caracteristicaDAO.listarPorPropiedad(id);

            request.setAttribute("propiedad", propiedad);
            request.setAttribute("imagenes", imagenes);
            request.setAttribute("caracteristicas", caracteristicas);
            request.setAttribute("puedeGestionarPropiedad",
                    ayudaDetalle.puedeGestionarPropiedad(propiedad, inmobiliariaDAO));
            request.setAttribute("categoriasCaracteristica",
                    Arrays.asList("INTERIOR", "EXTERIOR", "CONJUNTO", "SEGURIDAD"));

            Integer usuarioId = idDeSesionONulo(request);
            boolean esFavorito = usuarioId != null && favoritoDAO.esFavorito(usuarioId, id);
            request.setAttribute("esFavorito", esFavorito);
        }
    } catch (SQLException e) {
        application.log("Error al consultar el detalle de la propiedad " + id, e);
        request.setAttribute("error",
                "No fue posible cargar esta propiedad en este momento. Intenta de nuevo en unos minutos.");
    }

    request.getRequestDispatcher("/detalle-propiedad.jsp").forward(request, response);
%>