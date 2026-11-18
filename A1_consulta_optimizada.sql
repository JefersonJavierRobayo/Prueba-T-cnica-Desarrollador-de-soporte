PARTE A - A1. DIAGNOSTICO DE CONSULTA LENTA
===========================================================
Problematica:
La siguiente consulta alimenta la pantalla de pendientes. 
En producción procesa aproximadamente 2,5
millones de solicitudes y 14 millones de registros de gestión.

Objetivo:
Analizar y optimizar la consulta que alimenta la pantalla
de solicitudes pendientes.

Volumen aproximado:
- 2.5 millones de solicitudes.
- 14 millones de registros de gestion.

Motor de base de datos: Oracle SQL.
===========================================================
SELECT s.id_solicitud,
 s.documento,
 s.estado,
 s.fecha_creacion,
 (SELECT MAX(g.fecha_gestion)
 FROM gestion g
 WHERE g.id_solicitud = s.id_solicitud) AS ultima_gestion
 FROM solicitud s
 WHERE TRUNC(s.fecha_creacion) >= TRUNC(SYSDATE - 30)
 AND UPPER(s.estado) <> 'CERRADA'
 AND s.documento IN (
 SELECT c.documento
 FROM cliente c
 WHERE NVL(c.activo, 'N') = 'S'
 )
 ORDER BY s.fecha_creacion DESC;
*/
Índices actualmente informados:
PK_SOLICITUD(id_solicitud)
IDX_SOLICITUD_FECHA(fecha_creacion)
IDX_SOLICITUD_ESTADO(estado)
PK_CLIENTE(documento)
IDX_GESTION_SOLICITUD(id_solicitud)

===========================================================
1. DIAGNOSTICO DE PROBLEMAS IDENTIFICADOS
===========================================================

PROBLEMA 1: USO DE TRUNC SOBRE FECHA_CREACION

La condicion TRUNC(s.fecha_creacion) aplica una funcion
sobre la columna, lo que puede impedir el aprovechamiento
eficiente del indice IDX_SOLICITUD_FECHA mediante un
INDEX RANGE SCAN convencional.

PROBLEMA 2: USO DE UPPER SOBRE ESTADO

La funcion UPPER(s.estado) puede dificultar el uso directo
del indice IDX_SOLICITUD_ESTADO.

Si los estados se almacenan en mayusculas, se puede
comparar directamente con 'CERRADA'.

PROBLEMA 3: SUBCONSULTA CORRELACIONADA

La consulta obtiene MAX(fecha_gestion) para cada solicitud.

Con millones de registros, esta operacion puede generar
multiples accesos a la tabla GESTION, dependiendo del
numero de solicitudes que cumplan los filtros.

PROBLEMA 4: USO INNECESARIO DE NVL

NVL(c.activo, 'N') = 'S' no es necesario porque los
registros NULL tampoco cumplen la condicion de activo = 'S'.

Se puede utilizar directamente c.activo = 'S'.

PROBLEMA 5: USO DE IN

La condicion IN puede reemplazarse por EXISTS para expresar
la validacion de existencia de un cliente activo.

Oracle puede optimizar ambas alternativas, por lo que
se debe comparar su plan de ejecucion real.

PROBLEMA 6: ORDENAMIENTO DE RESULTADOS

ORDER BY s.fecha_creacion DESC puede generar operaciones
de ordenamiento costosas cuando el volumen de resultados
es elevado.

Se debe revisar el consumo de memoria y espacio temporal.

PROBLEMA 7: ESTADISTICAS Y CARDINALIDAD

Es necesario verificar que las estadisticas de tablas
e indices esten actualizadas para que Oracle pueda
seleccionar un plan de ejecucion adecuado.

===========================================================
2. CONSULTA SQL OPTIMIZADA
===========================================================

SELECT
    s.id_solicitud,
    s.documento,
    s.estado,
    s.fecha_creacion,

    (
        SELECT MAX(g.fecha_gestion)
        FROM gestion g
        WHERE g.id_solicitud = s.id_solicitud
    ) AS ultima_gestion

FROM solicitud s

WHERE s.fecha_creacion >= TRUNC(SYSDATE) - 30

  AND s.estado <> 'CERRADA'

  AND EXISTS (
      SELECT 1
      FROM cliente c
      WHERE c.documento = s.documento
        AND c.activo = 'S'
  )

ORDER BY s.fecha_creacion DESC;

===========================================================
3. JUSTIFICACION DE LAS MEJORAS
===========================================================

1. Se elimina TRUNC de la columna fecha_creacion,
   permitiendo que Oracle pueda aprovechar el indice
   existente sobre dicha columna.

2. Se elimina UPPER de estado, suponiendo que los estados
   estan almacenados en mayusculas.

3. Se reemplaza IN por EXISTS para expresar directamente
   la existencia de un cliente activo.

4. Se elimina NVL porque no es necesario para validar
   registros cuyo activo sea igual a 'S'.

5. Se conserva MAX para obtener la fecha de gestion
   mas reciente de cada solicitud.

6. Se mantiene el ordenamiento solicitado por el negocio.

NOTA:
La condicion de fecha conserva el limite inferior de la
consulta original, incluyendo posibles fechas futuras.
Si el negocio requiere excluir fechas futuras, se debe
agregar un limite superior.

===========================================================
4. EVIDENCIAS QUE SE DEBEN REVISAR
===========================================================

Antes de aplicar el cambio en produccion revisaria:

A. PLAN DE EJECUCION:
   Identificar FULL TABLE SCAN, INDEX RANGE SCAN,
   operaciones SORT y accesos a GESTION.

B. TIEMPO DE EJECUCION:
   Comparar la duracion de la consulta original y optimizada.

C. LECTURAS:
   Revisar buffer gets y lecturas fisicas.

D. CARDINALIDAD:
   Comparar filas estimadas y filas reales.

E. ESTADISTICAS:
   Verificar la fecha de actualizacion de las estadisticas
   de las tablas e indices.

F. VOLUMEN:
   Identificar la cantidad de solicitudes de los ultimos
   30 dias y la cantidad de gestiones por solicitud.

G. RECURSOS:
   Revisar consumo de CPU, memoria y espacio temporal TEMP.

===========================================================
5. CONSULTA PARA REVISAR EL PLAN DE EJECUCION
===========================================================

Ejecutar despues de consultar la sentencia optimizada.
Requiere permisos para consultar el cursor.

SELECT *
FROM TABLE(
    DBMS_XPLAN.DISPLAY_CURSOR(
        NULL,
        NULL,
        'ALLSTATS LAST +PEEKED_BINDS'
    )
);

===========================================================
6. PROPUESTA DE INDICE ADICIONAL
===========================================================

Se propone evaluar un indice compuesto sobre GESTION.

No crearlo directamente en produccion sin validar
previamente el plan de ejecucion y su beneficio.

CREATE INDEX IDX_GESTION_SOL_FECHA
ON GESTION (ID_SOLICITUD, FECHA_GESTION);


JUSTIFICACION DEL INDICE:

- Facilita la busqueda de gestiones por solicitud.
- Permite disponer de fecha_gestion dentro del indice.
- Puede mejorar la operacion MAX(fecha_gestion).
- Puede reducir accesos adicionales a la tabla GESTION.

RIESGOS OPERATIVOS:

- Incrementa el espacio de almacenamiento.
- Aumenta el costo de INSERT, UPDATE y DELETE.
- Su construccion consume recursos de la base de datos.
- Puede ser parcialmente redundante con el indice actual
  IDX_GESTION_SOLICITUD.

Por lo anterior, su implementacion depende de las
mediciones y del plan de ejecucion real.

===========================================================
7. CONCLUSION
===========================================================

La optimizacion propuesta busca reducir operaciones
innecesarias, facilitar el aprovechamiento de los indices
existentes y mejorar la legibilidad de la consulta.
Antes de implementar los cambios en produccion se deben
realizar pruebas comparativas en un ambiente controlado,
validando que los resultados funcionales sean equivalentes
y que exista una mejora medible en el rendimiento.
La creacion de nuevos indices debe justificarse mediante
evidencia del plan de ejecucion y el impacto sobre las
operaciones de escritura.
===========================================================
