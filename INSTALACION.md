# Instalación y ejecución

Aplicación web de gestión inmobiliaria construida **íntegramente con JSP y
fragmentos JSPF**: no contiene ninguna clase Java propia ni declara servlets.

## Requisitos

| Componente | Versión |
|---|---|
| Apache Tomcat | 8.5.x (no 10.x: el proyecto usa el espacio de nombres `javax.*`) |
| JDK | 17 recomendado. Con JDK 21 funciona, pero ver la nota al final |
| MySQL | 8.x |

## 1. Base de datos

```bash
mysql -u root -p < database/ddl.sql
mysql -u root -p < database/dml.sql
```

`ddl.sql` crea el esquema y `dml.sql` carga los datos de prueba.

## 2. Credenciales de conexión

Dentro del `.war`, copia `WEB-INF/classes/db.properties.example` a
`WEB-INF/classes/db.properties` y ajusta usuario y contraseña:

```properties
db.url=jdbc:mysql://localhost:3306/inmobiliaria?useSSL=false&allowPublicKeyRetrieval=true
db.username=root
db.password=TU_PASSWORD
db.driver=com.mysql.cj.jdbc.Driver
```

Es el único archivo que hay que tocar para mover el proyecto de una máquina a
otra. La cadena de conexión está centralizada ahí: ninguna página la repite.

> Si arrancas la aplicación **sin** `db.properties`, verás el mensaje
> "No se encontró el archivo db.properties". Después de crearlo hay que
> **reiniciar Tomcat** (o tocar `WEB-INF/web.xml` para forzar la recarga): la
> configuración se lee una sola vez al iniciar y la JVM recuerda el fallo.

## 3. Despliegue

Copia `inmobiliaria.war` a `TOMCAT_HOME/webapps/` y arranca Tomcat:

```bash
TOMCAT_HOME/bin/startup.sh     # en Windows: startup.bat
```

Abre **http://localhost:8080/inmobiliaria/**

No hace falta compilar nada: al no existir clases Java, Tomcat traduce las JSP
en el primer acceso a cada página.

## 4. Subida de archivos (importante)

El formulario de propiedades y la radicación de documentos envían archivos. Si
una foto supera el límite del servidor, **Tomcat descarta la petición completa**
y el formulario parece llegar vacío.

Por defecto ese límite es de 2 MB. Para subirlo a 25 MB, edita
`TOMCAT_HOME/conf/server.xml` y agrega dos atributos al `<Connector>`:

```xml
<Connector port="8080" protocol="HTTP/1.1"
           connectionTimeout="20000"
           redirectPort="8443"
           maxPostSize="26214400"
           maxSwallowSize="26214400" />
```

Si no se hace, la aplicación no falla: muestra un mensaje explicando que la foto
excede el tamaño permitido. Pero conviene configurarlo antes de una demostración.

## Usuarios de prueba

| Rol | Correo | Contraseña |
|---|---|---|
| Administrador | `admin@inmobiliaria.com` | `admin123` |
| Agente (inmobiliaria 1) | `agente.centro@inmobiliaria.com` | `Clave123*` |
| Agente (inmobiliaria 2) | `agente.norte@inmobiliaria.com` | `Clave123*` |
| Cliente | `maria.rojas@correo.com` | `Clave123*` |

Las contraseñas se guardan cifradas con BCrypt; en la tabla `usuario` solo hay
hashes, nunca texto plano.

## Rutas principales

| Pantalla | URL |
|---|---|
| Landing | `/controladores/index.jsp` |
| Catálogo con filtros | `/controladores/propiedades.jsp` |
| Ficha de propiedad | `/controladores/propiedad-detalle.jsp?id=1` |
| Inicio de sesión | `/controladores/login.jsp` |
| Panel administrador | `/controladores/admin-dashboard.jsp` |
| Panel agente | `/controladores/inmobiliaria-dashboard.jsp` |
| Panel cliente | `/controladores/dashboard.jsp` |

La raíz `/` entra por `index.html`, que redirige a la landing.

## Cómo está organizado

```
controladores/*.jsp          lógica de cada pantalla (antes eran los servlets)
WEB-INF/negocio/*.jspf       conexión, entidades, acceso a datos y servicios
WEB-INF/seguridad/*.jspf     control de acceso por rol (antes el Filter)
WEB-INF/views/               vistas internas a las que se hace forward
*.jsp (raíz)                 vistas públicas
```

El control de acceso vive en el servidor: cada página privada incluye el
fragmento de seguridad que le corresponde. Ocultar un enlace en el menú no es
control de acceso, y por eso la validación se repite en cada página.

## Archivos subidos

Las fotos y los documentos se guardan **fuera del webapp**, en
`TOMCAT_HOME/inmobiliaria-data/`, para que no se borren al volver a desplegar.
La carpeta se crea sola. Si quieres ubicarla en otro sitio, descomenta el
parámetro `carpetaDatos` en `WEB-INF/web.xml` y pon una ruta absoluta.

Las fotos no se sirven como archivos estáticos: pasan por
`controladores/media-propiedad.jsp`, que valida el nombre y bloquea intentos de
salir de la carpeta.

## Nota sobre JDK 21

El compilador de JSP que trae Tomcat 8.5 no logra leer algunas clases del JDK 21
(aparece `ClassFormatException: Failed to load class [java.lang.System]` en el
log). El proyecto está escrito para no depender de esas clases, así que funciona
igual. Si en otro equipo aparece un error de compilación extraño en una JSP,
arrancar Tomcat con un JDK 17 lo resuelve.
