# Prueba-T-cnica-Desarrollador-de-soporte

## IAS Software

**Candidato:** Jeferson Javier Robayo Sandoval  
**Lenguaje:** Java,SQL,PL/SQL 
**Herramientas:** Visual Studio Code

---

## 1. Descripción del proyecto

Este proyecto tiene como finalidad analizar, diagnosticar y corregir posibles errores en un servicio Java y el uso de analisis de base de datos SQL, encargado de consultar solicitudes, así como proponer y desarrollar pruebas automatizadas para verificar el funcionamiento de la solución.


## 2. Objetivos

- Identificar posibles errores en el código Java.
- Prevenir excepciones relacionadas con valores nulos.
- Validar listas vacías antes de acceder a sus elementos.
- Mejorar el manejo de excepciones.
- Garantizar la correcta consulta de solicitudes y sus gestiones.
- Implementar pruebas automatizadas para validar los escenarios identificados.
- Documentar las decisiones técnicas y alternativas de solución.

## 3. Tecnologías utilizadas

| Tecnología | Uso |
|---|---|
| Java 17 | Lenguaje de programación. |
| Visual Studio Code | Edición y desarrollo del código. |
| Git | Control de versiones. |
| GitHub | Almacenamiento y seguimiento del proyecto. |

## 4. Estructura del proyecto

```text
IAS_Prueba_Tecnica/
│
├── pom.xml
├── README.md
│
├── B1_Diagnostico/
│   ├── SolicitudService.java
│   └── Respuesta_B1.md
│
└── B2_Pruebas/
    ├── SolicitudServiceTest.java
    └── Respuesta_B2.md
```

## 5. B1. Lectura de código y diagnóstico

Se analizó el método `consultar(Long id)`, encargado de obtener la información de una solicitud y construir un objeto `SolicitudDto`.

### Problemas identificados

- Uso de `orElse(null)` sin validar la existencia de la solicitud.
- Posibilidad de que el cliente asociado sea nulo.
- Posibilidad de que el nombre del cliente sea nulo o esté vacío.
- Acceso a una lista sin comprobar si contiene elementos.
- Falta de garantía de que la primera gestión corresponda a la más reciente.

### Soluciones propuestas

- Validación del identificador recibido.
- Uso de `orElseThrow()` para controlar solicitudes inexistentes.
- Validación del cliente y su nombre.
- Comprobación de listas nulas o vacías.
- Selección de la gestión con la fecha más reciente.
- Manejo controlado de excepciones.

## 6. B2. Verificación de la corrección

Se definieron escenarios de prueba utilizando JUnit 5 y Mockito para comprobar el comportamiento del servicio.

### Casos de prueba

| Código | Escenario | Resultado esperado |
|---|---|---|
| CP01 | Solicitud existente con gestiones. | Retorna correctamente la información de la solicitud. |
| CP02 | Solicitud inexistente. | Genera una excepción controlada. |
| CP03 | Solicitud sin gestiones. | Identifica la ausencia de gestiones. |
| CP04 | Solicitud sin cliente asociado. | Controla la ausencia del cliente. |
| CP05 | Cliente con nombre nulo o vacío. | Genera una excepción controlada. |
| CP06 | Identificador nulo. | Genera una excepción por argumento inválido. |
| CP07 | Gestiones sin fecha válida. | Identifica que no existen fechas disponibles. |

### Herramientas de pruebas

- Assertions para comprobar los resultados esperados.
- Verificación de interacciones para comprobar que no se realicen consultas innecesarias.
## 7. Decisiones técnicas

Durante el análisis se identificó que el principal inconveniente estaba relacionado con el acceso a objetos que podían contener valores nulos.

Se seleccionó el uso de validaciones preventivas y excepciones controladas para evitar errores inesperados y mejorar la estabilidad del servicio.

También se propuso obtener la gestión más reciente mediante una comparación de fechas, evitando depender del orden en que los registros son devueltos por el repositorio.

Ejecución del proyecto

### 8 Requisitos previos

- Tener instalado Java 17 o superior.
- Tener instalado Maven.
- Contar con Visual Studio Code o un entorno de desarrollo Java.

### Comandos Maven

Compilar el proyecto:

```bash
mvn clean compile
```

Ejecutar las pruebas automatizadas:

```bash
mvn test
```

Generar el paquete:

```bash
mvn clean package
```

Los resultados de las pruebas pueden consultarse en:

```text
target/surefire-reports/
```

## 9. Conclusión

El desarrollo de esta actividad permitió identificar oportunidades de mejora en el manejo de excepciones, validación de datos y tratamiento de colecciones en Java, SQL.

La solución propuesta busca mejorar la estabilidad, legibilidad y mantenibilidad del servicio, complementando las correcciones con escenarios de prueba que permitan verificar su comportamiento.

El proyecto documenta las decisiones técnicas tomadas y las alternativas consideradas para garantizar una solución clara, controlada y verificable.