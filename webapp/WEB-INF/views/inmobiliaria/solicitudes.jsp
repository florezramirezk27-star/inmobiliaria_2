<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<%@ taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core" %>

<!DOCTYPE html>
<html lang="es">

<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Solicitudes — Inmobiliaria</title>

    <link rel="preconnect" href="https://fonts.googleapis.com">
    <link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
    <link href="https://fonts.googleapis.com/css2?family=Inter:wght@400;500;600;700;800&display=swap"
          rel="stylesheet">

    <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.3/dist/css/bootstrap.min.css"
          rel="stylesheet">

    <link href="https://cdn.jsdelivr.net/npm/bootstrap-icons@1.11.3/font/bootstrap-icons.min.css"
          rel="stylesheet">

    <link rel="stylesheet" href="${pageContext.request.contextPath}/css/estilos.css">
</head>

<body>

<%@ include file="/WEB-INF/includes/navbar.jspf" %>

<main class="container py-5">

    <div class="cabecera-seccion">
        <div>
            <h1 class="fuente-display mb-1">Solicitudes recibidas</h1>
            <p class="descripcion mb-0">Aprueba o rechaza las solicitudes sobre tus propiedades.</p>
        </div>
        <a href="${pageContext.request.contextPath}/controladores/inmobiliaria-dashboard.jsp" class="btn btn-volver">
            Volver al panel
        </a>
    </div>

    <c:if test="${not empty error}">
        <div class="alert alert-danger" role="alert">
            <c:out value="${error}"/>
        </div>
    </c:if>

    <c:choose>
        <c:when test="${empty solicitudes}">

            <div class="sin-resultados">
                <span class="sin-resultados-icono"><i class="bi bi-inbox"></i></span>
                <h3>No hay solicitudes por ahora</h3>
                <p>Cuando un cliente solicite una de tus propiedades, aparecerá aquí.</p>
                <a class="btn btn-volver" href="${pageContext.request.contextPath}/controladores/inmobiliaria-dashboard.jsp">
                    Volver al panel
                </a>
            </div>

        </c:when>
        <c:otherwise>

            <div class="tabla-scroll">

                <table class="table tabla-tema mb-0">

                    <thead>
                    <tr>
                        <th>ID</th>
                        <th>Cliente</th>
                        <th>Propiedad</th>
                        <th>Tipo</th>
                        <th>Estado</th>
                        <th class="text-end">Acciones</th>
                    </tr>
                    </thead>

                    <tbody>

                    <c:forEach var="solicitud" items="${solicitudes}">
                        <c:set var="estadoSolicitud" value="${solicitud.estado.nombre}"/>
                        <c:choose>
                            <c:when test="${estadoSolicitud == 'APROBADA'}"><c:set var="claseChip" value="chip-verde"/></c:when>
                            <c:when test="${estadoSolicitud == 'RECHAZADA'}"><c:set var="claseChip" value="chip-rojo"/></c:when>
                            <c:when test="${estadoSolicitud == 'PENDIENTE'}"><c:set var="claseChip" value="chip-ocre"/></c:when>
                            <c:when test="${estadoSolicitud == 'EN_REVISION'}"><c:set var="claseChip" value="chip-azul"/></c:when>
                            <c:otherwise><c:set var="claseChip" value="chip-gris"/></c:otherwise>
                        </c:choose>

                        <tr>
                            <td class="fw-semibold">#<c:out value="${solicitud.id}"/></td>
                            <td><c:out value="${solicitud.clienteId}"/></td>
                            <td><c:out value="${solicitud.propiedadId}"/></td>
                            <td><c:out value="${solicitud.tipo.etiqueta}"/></td>

                            <td>
                                <span class="chip ${claseChip}">
                                    <c:out value="${solicitud.estado.etiqueta}"/>
                                </span>
                            </td>

                            <td class="text-end">

                                <div class="d-inline-flex gap-2">

                                    <a href="${pageContext.request.contextPath}/controladores/documentos.jsp?solicitudId=${solicitud.id}"
                                       class="btn btn-contorno"
                                       style="min-height:38px; padding:0 .9rem; font-size:.8125rem;"
                                       title="Ver documentos de esta solicitud">
                                        <i class="bi bi-folder2-open" aria-hidden="true"></i>
                                        Documentos
                                    </a>

                                    <form method="post"
                                          action="${pageContext.request.contextPath}/controladores/inmobiliaria-solicitudes.jsp"
                                          class="d-inline">
                                        <input type="hidden" name="id" value="${solicitud.id}">
                                        <input type="hidden" name="estado" value="APROBADA">
                                        <button type="submit" class="btn btn-marca"
                                                style="min-height:38px; padding:0 .9rem; font-size:.8125rem;">
                                            Aprobar
                                        </button>
                                    </form>

                                    <form method="post"
                                          action="${pageContext.request.contextPath}/controladores/inmobiliaria-solicitudes.jsp"
                                          class="d-inline">
                                        <input type="hidden" name="id" value="${solicitud.id}">
                                        <input type="hidden" name="estado" value="RECHAZADA">
                                        <button type="submit" class="btn btn-peligro"
                                                style="min-height:38px; padding:0 .9rem; font-size:.8125rem;">
                                            Rechazar
                                        </button>
                                    </form>

                                </div>

                            </td>
                        </tr>
                    </c:forEach>

                    </tbody>

                </table>

            </div>

        </c:otherwise>
    </c:choose>

</main>

<%@ include file="/WEB-INF/includes/footer.jspf" %>

</body>
</html>
