# Sistema de Gestión Inmobiliaria

Aplicación web para la administración de una inmobiliaria: catálogo público de
propiedades, gestión de inmuebles por parte de los agentes, agendamiento de
visitas, solicitudes con radicación de documentos y reportes.

Construida **íntegramente con JSP y fragmentos JSPF**. El proyecto no contiene
una sola clase Java propia ni declara servlets en el descriptor.

## Arranque rápido

```bash
# 1. Base de datos
mysql -u root -p < database/ddl.sql
mysql -u root -p < database/dml.sql

# 2. Credenciales
cp webapp/WEB-INF/classes/db.properties.example \
   webapp/WEB-INF/classes/db.properties
#    editar ese archivo con el usuario y contraseña de MySQL

# 3. Desplegar en Tomcat 8.5
cp -R webapp TOMCAT_HOME/webapps/inmobiliaria
TOMCAT_HOME/bin/startup.sh
```

Abrir **http://localhost:8080/inmobiliaria/**

Alternativa: desplegar `dist/inmobiliaria.war` directamente, creando dentro el
`db.properties`. No hay nada que compilar: Tomcat traduce las JSP al vuelo.

Los pasos completos, los usuarios de prueba y la configuración del tamaño de
subida están en **[INSTALACION.md](INSTALACION.md)**. Conviene leerlo antes de
la primera ejecución.

## Estructura

```
webapp/
  index.html                 portada, redirige a la landing
  *.jsp                      vistas públicas
  controladores/*.jsp        lógica de cada pantalla
  css/  img/                 recursos estáticos
  WEB-INF/
    negocio/*.jspf           conexión, entidades, acceso a datos y servicios
    seguridad/*.jspf         control de acceso por rol
    views/                   vistas internas
    lib/                     driver de MySQL, JSTL y BCrypt
    web.xml                  descriptor (sin un solo <servlet>)
  META-INF/context.xml       configuración del contexto

database/                    ddl.sql, dml.sql y consultas
docs/                        MER, modelo relacional, diccionario y Scrum
dist/                        .war listo para desplegar (no se versiona)
```

## Decisiones de diseño

- **Sin servlets.** Cada pantalla es un `.jsp` real, así que la URL muestra
  siempre el archivo que se ejecuta. La lógica que antes vivía en servlets está
  en `controladores/`, y lo que hacía el `Filter` está en
  `WEB-INF/seguridad/*.jspf`, incluido al inicio de cada página privada.
- **Control de acceso en el servidor.** Ocultar un botón en el menú no es
  control de acceso: cada página privada vuelve a validar el rol de la sesión.
- **Contraseñas cifradas con BCrypt.** En la tabla `usuario` solo hay hashes.
- **Conexión centralizada.** Un único `db.properties`; ninguna página repite la
  cadena de conexión.
- **Archivos subidos fuera del webapp**, en `TOMCAT_HOME/inmobiliaria-data/`,
  para que sobrevivan a un redespliegue. Las fotos se sirven a través de
  `controladores/media-propiedad.jsp`, que valida el nombre del archivo.

## Requisitos

| Componente | Versión |
|---|---|
| Apache Tomcat | 8.5.x (no 10.x: el proyecto usa `javax.*`) |
| JDK | 17 recomendado; con 21 funciona |
| MySQL | 8.x |

## Subir a GitHub

El repositorio ya está iniciado con un primer commit. Para publicarlo:

```bash
cd inmobiliaria-jsp
git remote add origin https://github.com/USUARIO/REPOSITORIO.git
git branch -M main
git push -u origin main
```

`db.properties` y el `.war` están en el `.gitignore`: las credenciales no se
publican y el artefacto se regenera cuando se necesita.
