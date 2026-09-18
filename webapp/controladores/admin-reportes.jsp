<%-- C:/webapp/controladores/admin-reportes.jsp
     Conversión de ReporteServlet (JSP): reportes globales del administrador. --%>
<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ include file="/WEB-INF/negocio/todo.jspf" %>
<%@ include file="/WEB-INF/seguridad/rol-admin.jspf" %>
<%
    ReporteDAO reporteDAO = new ReporteDAO();

    request.setAttribute("propiedadesPublicadas", reporteDAO.propiedadesPublicadas());
    request.setAttribute("citasActivas", reporteDAO.citasActivas());
    request.setAttribute("propiedadesSinCitas", reporteDAO.propiedadesSinCitas());
    request.setAttribute("resumenPorCiudad", reporteDAO.resumenPorCiudad());
    request.setAttribute("citasPorEstado", reporteDAO.citasPorEstado());
    request.setAttribute("solicitudesPorInmobiliaria", reporteDAO.solicitudesPorInmobiliaria());

    String idPropiedadParam = request.getParameter("idPropiedad");
    int idPropiedad = 1;
    if (idPropiedadParam != null && !idPropiedadParam.isBlank()) {
        try {
            idPropiedad = Integer.parseInt(idPropiedadParam);
        } catch (NumberFormatException e) {
            idPropiedad = 1;
        }
    }

    request.setAttribute("idPropiedadSeleccionada", idPropiedad);
    request.setAttribute("caracteristicasPropiedad",
            reporteDAO.caracteristicasPropiedad(idPropiedad));

    request.getRequestDispatcher("/WEB-INF/views/admin/reportes.jsp")
            .forward(request, response);
%>