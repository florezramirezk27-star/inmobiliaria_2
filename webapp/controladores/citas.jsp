<%-- C:/webapp/controladores/citas.jsp
     Conversión de CitaServlet (JSP):
     GET  /propiedades/citas?id=X  -> ficha de citas de la propiedad + form
     POST /propiedades/citas       -> agenda una visita nueva
     POST /propiedades/citas/estado-> cambia el estado de una cita (agente)
     GET  /citas                   -> "Mis citas" del cliente
     El id_cliente siempre sale de la sesión (usuarioId). --%>
<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ include file="/WEB-INF/negocio/todo.jspf" %>
<%@ page import="java.sql.SQLException" %>
<%@ page import="java.time.LocalDateTime" %>
<%@ page import="java.time.format.DateTimeParseException" %>
<%@ page import="java.util.List" %>
<%!
    private boolean tieneRol(HttpServletRequest request, String rolBuscado) {
        HttpSession sesion = request.getSession(false);
        if (sesion == null) {
            return false;
        }
        return tieneRol(sesion.getAttribute("roles"), rolBuscado);
    }

    private String vacioComoNulo(String valor) {
        return (valor == null || valor.isBlank()) ? null : valor.trim();
    }
%>
<%@ include file="/WEB-INF/seguridad/requiere-sesion.jspf" %>
<%
    HttpSession sesion = request.getSession(false);
    Integer usuarioId = (Integer) sesion.getAttribute("usuarioId");
    if (usuarioId == null) {
        response.sendRedirect(request.getContextPath() + "/controladores/login.jsp");
        return;
    }

    final CitaDAO citaDAO = new CitaDAO();
    final PropiedadDAO propiedadDAO = new PropiedadDAO();
    final InmobiliariaDAO inmobiliariaDAO = new InmobiliariaDAO();

    String metodo = request.getMethod();
    boolean esPost = "POST".equalsIgnoreCase(metodo);

    /*
     * Antes esta página atendía dos rutas distintas y decidía qué hacer
     * mirando request.getServletPath(). Ahora todo entra por
     * controladores/citas.jsp, así que la acción se distingue por los
     * datos del formulario: solo el formulario del agente envía
     * "nuevoEstado".
     */
    boolean esCambioDeEstado = request.getParameter("nuevoEstado") != null;

    class AyudaCitas {
        void volverAFormularioConError(int usuarioId, int propiedadId, List<String> errores)
                throws SQLException {
            Propiedad propiedad = propiedadDAO.buscarPublicadaPorId(propiedadId);
            request.setAttribute("propiedad", propiedad);

            if (propiedad != null) {
                request.setAttribute("citas", citaDAO.listarPorClienteYPropiedad(usuarioId, propiedadId));
            } else {
                request.setAttribute("citas", Collections.emptyList());
            }

            request.setAttribute("puedeCrearCita", true);
            request.setAttribute("puedeGestionarCitas", false);
            request.setAttribute("errores", errores);
        }
    }
    AyudaCitas ayudaCitas = new AyudaCitas();

    if (esPost) {
        if (esCambioDeEstado) {
            /* ---------- CAMBIAR ESTADO (solo agente) ---------- */
            String idCitaParam = request.getParameter("citaId");
            String nuevoEstadoParam = request.getParameter("nuevoEstado");
            String volver = request.getParameter("volver");

            if (!tieneRol(request, "AGENTE")) {
                response.sendError(HttpServletResponse.SC_FORBIDDEN,
                        "Solo un agente puede gestionar el estado de una cita.");
                return;
            }

            try {
                int idCita = Integer.parseInt(idCitaParam.trim());
                EstadoCita nuevoEstado = EstadoCita.desde(nuevoEstadoParam);

                if (nuevoEstado == null) {
                    response.sendError(HttpServletResponse.SC_BAD_REQUEST, "Estado de cita inválido");
                    return;
                }

                Cita cita = citaDAO.buscarPorId(idCita);
                if (cita == null) {
                    response.sendError(HttpServletResponse.SC_NOT_FOUND, "La cita no existe.");
                    return;
                }

                Inmobiliaria inmobiliaria = inmobiliariaDAO.buscarPorUsuario(usuarioId);
                if (inmobiliaria == null) {
                    response.sendError(HttpServletResponse.SC_FORBIDDEN,
                            "El agente no tiene una inmobiliaria asignada.");
                    return;
                }

                boolean pertenece = false;
                for (Propiedad propiedad : propiedadDAO.listarPorInmobiliaria(inmobiliaria.getId())) {
                    if (propiedad.getId() == cita.getPropiedadId()) {
                        pertenece = true;
                        break;
                    }
                }

                if (!pertenece) {
                    response.sendError(HttpServletResponse.SC_FORBIDDEN,
                            "No puedes gestionar citas de otra inmobiliaria.");
                    return;
                }

                citaDAO.cambiarEstado(idCita, nuevoEstado);
            } catch (NumberFormatException | SQLException e) {
                application.log("Error al cambiar el estado de la cita", e);
            }

            String contexto = request.getContextPath();
            boolean esRutaInterna = volver != null && volver.startsWith(contexto + "/");
            response.sendRedirect(esRutaInterna ? volver : contexto + "/controladores/propiedades.jsp");
            return;
        }

        /* ---------- AGENDAR VISITA (solo cliente) ---------- */
        if (!tieneRol(request, "CLIENTE")) {
            response.sendError(HttpServletResponse.SC_FORBIDDEN,
                    "Solo los clientes pueden solicitar visitas.");
            return;
        }

        String idPropiedadParam = request.getParameter("propiedadId");
        String fechaHoraParam = request.getParameter("fechaHora");

        int propiedadId;
        try {
            propiedadId = Integer.parseInt(idPropiedadParam.trim());
        } catch (NumberFormatException | NullPointerException e) {
            response.sendRedirect(request.getContextPath() + "/controladores/propiedades.jsp");
            return;
        }

        try {
            if (propiedadDAO.buscarPublicadaPorId(propiedadId) == null) {
                response.sendRedirect(request.getContextPath() + "/controladores/propiedades.jsp");
                return;
            }
        } catch (SQLException e) {
            application.log("Error al validar la propiedad antes de agendar", e);
            response.sendRedirect(request.getContextPath() + "/controladores/propiedades.jsp");
            return;
        }

        List<String> errores = new java.util.ArrayList<>();
        LocalDateTime fechaHora = null;

        if (fechaHoraParam == null || fechaHoraParam.isBlank()) {
            errores.add("Selecciona la fecha y hora de la visita.");
        } else {
            try {
                fechaHora = LocalDateTime.parse(fechaHoraParam.trim());
                if (fechaHora.isBefore(LocalDateTime.now())) {
                    errores.add("La fecha y hora de la visita debe ser en el futuro.");
                }
            } catch (DateTimeParseException e) {
                errores.add("La fecha y hora no tiene un formato válido.");
            }
        }

        if (!errores.isEmpty()) {
            try {
                ayudaCitas.volverAFormularioConError(usuarioId, propiedadId, errores);
            } catch (SQLException ignorado) {
                request.setAttribute("citas", Collections.emptyList());
            }
            request.getRequestDispatcher("/citas-propiedad.jsp").forward(request, response);
            return;
        }

        try {
            Cita cita = new Cita();
            cita.setPropiedadId(propiedadId);
            cita.setClienteId(usuarioId);
            cita.setFechaHora(fechaHora);
            cita.setEstado(EstadoCita.SOLICITADA);
            cita.setObservacion(vacioComoNulo(request.getParameter("observacion")));

            citaDAO.agendar(cita);
            response.sendRedirect(request.getContextPath()
                    + "/controladores/citas.jsp?id=" + propiedadId + "&agendada=1");
        } catch (DuplicidadException e) {
            try {
                ayudaCitas.volverAFormularioConError(usuarioId, propiedadId, Arrays.asList(e.getMessage()));
            } catch (SQLException ignorado) {
                request.setAttribute("citas", Collections.emptyList());
            }
            request.getRequestDispatcher("/citas-propiedad.jsp").forward(request, response);
        } catch (SQLException e) {
            application.log("Error al agendar la visita", e);
            try {
                ayudaCitas.volverAFormularioConError(usuarioId, propiedadId,
                        Collections.singletonList("No fue posible agendar la visita en este momento. Intenta de nuevo en unos minutos."));
            } catch (SQLException ignorado) {
                request.setAttribute("citas", Collections.emptyList());
            }
            request.getRequestDispatcher("/citas-propiedad.jsp").forward(request, response);
        }
        return;
    }

    /* ---------- GET ---------- */

    /*
     * Dos pantallas comparten esta página:
     *   sin parámetro id -> "Mis citas" del cliente
     *   con id=X         -> citas de esa propiedad
     *
     * Antes se distinguían por la ruta; ahora, por el parámetro.
     */
    String idParam = request.getParameter("id");

    if (idParam == null || idParam.isBlank()) {
        /* "Mis citas": refuerza el rol CLIENTE que exigía AuthFilter */
        if (!tieneRol(request, "CLIENTE")) {
            response.sendRedirect(request.getContextPath() + "/controladores/acceso-denegado.jsp");
            return;
        }

        try {
            List<Cita> citas = citaDAO.listarPorCliente(usuarioId);
            request.setAttribute("citas", citas);
        } catch (SQLException e) {
            application.log("Error al cargar mis citas", e);
            request.setAttribute("citas", Collections.emptyList());
            request.setAttribute("errorConsulta",
                    "No fue posible cargar tus citas en este momento. Intenta de nuevo en unos minutos.");
        }

        request.getRequestDispatcher("/mis-citas.jsp").forward(request, response);
        return;
    }

    try {
        int id = Integer.parseInt(idParam.trim());

        boolean esCliente = tieneRol(request, "CLIENTE");
        boolean esAgente = tieneRol(request, "AGENTE");

        if (!esCliente && !esAgente) {
            response.sendError(HttpServletResponse.SC_FORBIDDEN,
                    "No tienes permiso para consultar estas citas.");
            return;
        }

        Propiedad propiedad = esAgente
                ? propiedadDAO.buscarPorId(id)
                : propiedadDAO.buscarPublicadaPorId(id);

        if (propiedad == null) {
            request.setAttribute("error", "La propiedad solicitada no existe o no está disponible.");
        } else {
            if (esAgente) {
                Inmobiliaria inmobiliaria = inmobiliariaDAO.buscarPorUsuario(usuarioId);
                if (inmobiliaria == null || propiedad.getInmobiliariaId() != inmobiliaria.getId()) {
                    response.sendError(HttpServletResponse.SC_FORBIDDEN,
                            "No puedes consultar citas de otra inmobiliaria.");
                    return;
                }
            }

            request.setAttribute("propiedad", propiedad);

            if (esAgente) {
                request.setAttribute("citas", citaDAO.listarPorPropiedad(id));
            } else {
                request.setAttribute("citas", citaDAO.listarPorClienteYPropiedad(usuarioId, id));
            }

            request.setAttribute("puedeCrearCita", esCliente);
            request.setAttribute("puedeGestionarCitas", esAgente);
        }
    } catch (NumberFormatException e) {
        request.setAttribute("error", "El identificador de la propiedad no es válido.");
    } catch (SQLException e) {
        application.log("Error al cargar las citas de la propiedad", e);
        request.setAttribute("error", "No fue posible cargar las citas en este momento.");
    }

    request.getRequestDispatcher("/citas-propiedad.jsp").forward(request, response);
%>