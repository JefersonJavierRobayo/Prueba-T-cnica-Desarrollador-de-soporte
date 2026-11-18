PARTE A - A3. SCRIPT DE DIAGNÓSTICO Y CORRECCIÓN CONTROLADA

===========================================================

Problemática

Se sospecha que existen solicitudes marcadas como PROCESADA sin 
contar con al menos una gestión cuyo resultado sea APROBADA.

Esta situación puede generar inconsistencias entre el estado 
registrado en la tabla SOLICITUD y la información 
disponible en la tabla GESTION, afectando la trazabilidad y 
confiabilidad de los procesos.

Por esta razón, se requiere identificar los registros potencialmente 
inconsistentes,revisar su información y preparar una corrección controlada
que permita validar los resultados antes de confirmar los cambios.

Objetivo

1. Identificar las solicitudes que se encuentran en estado PROCESADA y 
que no tienen ninguna gestión APROBADA.
2. Mostrar los registros potencialmente inconsistentes antes de realizar 
cualquier modificación.
3. Establecer criterios de selección para evitar afectar solicitudes
 que se encuentren correctamente procesadas.
4. Preparar una corrección controlada sobre los registros 
previamente revisados y autorizados.
5. Registrar cada modificación en la tabla de auditoría.
6. Validar los resultados antes y después de ejecutar la corrección.
7. Permitir revertir los cambios en caso de detectar inconsistencias.

**Motor de base de datos:** Oracle SQL.

**Consideración:** No se debe asumir que todas las solicitudes PROCESADA
sin una gestión APROBADA son necesariamente incorrectas.
Cada registro debe revisarse teniendo en cuenta su historial,
las reglas del negocio y los procedimientos de cierre existentes.

================================================================================

## 1. Diagnóstico de registros potencialmente inconsistentes

El primer paso consiste en consultar las solicitudes que actualmente
se encuentran en estado PROCESADA y que no tienen ninguna gestión con 
resultado APROBADA.

Para esta validación se utiliza `NOT EXISTS`, evitando duplicidades en los 
resultados y comprobando que no exista una gestión aprobada relacionada con la 
solicitud.


================================================================================
PASO 1. DIAGNOSTICO DE SOLICITUDES
================================================================================


SELECT
    s.id_solicitud,
    s.documento,
    s.estado,
    s.fecha_creacion,
    s.fecha_actualizacion,
    s.canal
FROM solicitud s
WHERE UPPER(s.estado) = 'PROCESADA'
  AND NOT EXISTS (
      SELECT 1
      FROM gestion g
      WHERE g.id_solicitud = s.id_solicitud
        AND UPPER(g.resultado) = 'APROBADA'
  )
ORDER BY s.fecha_actualizacion DESC;


**Explicación:**

- Se consulta la tabla `SOLICITUD` para identificar los registros procesados.
- Se utiliza `UPPER(s.estado)` para evitar diferencias por 
mayúsculas y minúsculas.
- Se utiliza `NOT EXISTS` para identificar las solicitudes que no tienen 
gestiones aprobadas.
- Se muestran los datos principales para facilitar la revisión por 
parte del equipo de soporte.

**Resultado esperado:** obtener un listado de solicitudes 
potencialmente inconsistentes, sin modificar información de la base de datos.

===================================================================================

## 2. Cuantificación de registros afectados

Después de identificar los registros, es importante conocer 
cuántas solicitudes cumplen con los criterios del diagnóstico.


================================================================================
PASO 2. CUANTIFICACION DE REGISTROS
======================================================================================


SELECT
    COUNT(*) AS total_solicitudes_inconsistentes
FROM solicitud s
WHERE UPPER(s.estado) = 'PROCESADA'
  AND NOT EXISTS (
      SELECT 1
      FROM gestion g
      WHERE g.id_solicitud = s.id_solicitud
        AND UPPER(g.resultado) = 'APROBADA'
  );


Explicación:

Esta consulta permite conocer la cantidad total de solicitudes que cumplen
 con el criterio de búsqueda.

La información obtenida sirve como referencia para comparar los resultados 
antes y después de ejecutar una posible corrección.

===========================================================

## 3. Criterios de selección y revisión

No todas las solicitudes identificadas deben modificarse automáticamente.
 Antes de realizar cualquier cambio, se debe revisar el 
 historial de gestiones y auditorías.

### Criterios de selección

| Criterio | Validación |
|---|---|
| Estado de la solicitud | Debe encontrarse en PROCESADA. |
| Gestiones aprobadas | No debe existir ninguna gestión con resultado APROBADA. |
| Historial de auditoría | Se debe revisar cómo y cuándo se realizó el cambio de estado. |
| Estado actual | Se debe confirmar que la solicitud no haya cambiado desde el diagnóstico. |
| Reglas del negocio | Se debe validar si existe alguna condición especial que permita procesar la solicitud sin una gestión aprobada. |
| Autorización | La corrección debe contar con aprobación del responsable del proceso. |

### Consulta del historial de gestiones

==================================================================================
PASO 3. CONSULTA DEL HISTORIAL DE GESTIONES
=============================================================================


-- Reemplazar 1001 por el identificador que se desea revisar.

SELECT
    g.id_gestion,
    g.id_solicitud,
    g.tipo,
    g.resultado,
    g.fecha_gestion,
    g.usuario
FROM gestion g
WHERE g.id_solicitud = 1001
ORDER BY g.fecha_gestion DESC;


### Consulta del historial de auditoría

==================================================================================
CONSULTA DEL HISTORIAL DE AUDITORIA
=================================================================================


SELECT
    a.id,
    a.id_solicitud,
    a.estado_anterior,
    a.estado_nuevo,
    a.fecha,
    a.detalle
FROM auditoria_solicitud a
WHERE a.id_solicitud = 1001
ORDER BY a.fecha DESC;


**Explicación:**

Estas consultas permiten revisar las gestiones asociadas a una 
solicitud y conocer los cambios de estado registrados en auditoría.

Con esta información se puede determinar si el estado PROCESADA corresponde
 a una operación válida, a un error de procesamiento o a una inconsistencia
  que requiere regularización.

=========================================================================================

## 4. Propuesta de corrección controlada

Una vez revisados los registros y autorizada la corrección,
se propone utilizar una lista explícita de identificadores previamente validados.

Como medida de seguridad, no se realizará una actualización masiva
 sobre todas las solicitudes encontradas.

Para este ejemplo, los identificadores `781245` y `781246` son valores 
ilustrativos y deben reemplazarse por los registros reales que hayan sido 
revisados y autorizados.

**Supuesto de corrección:** se propone cambiar el estado de PROCESADA a PENDIENTE
 cuando se confirme que la solicitud fue procesada incorrectamente y que debe 
 regresar al flujo normal de gestión. Este cambio debe ser aprobado por el área 
 responsable, ya que el estado correcto podría ser otro dependiendo de las 
 reglas del negocio.


==================================================================================
PASO 4. CORRECCION CONTROLADA
=====================================================================================

IMPORTANTE:
- Ejecutar únicamente en ambiente autorizado.
- Reemplazar los IDs de ejemplo por IDs revisados.
- No confirmar la transacción hasta validar los resultados.

DECLARE
    v_estado_actual solicitud.estado%TYPE;
    v_gestiones_aprobadas NUMBER := 0;
    v_id_solicitud NUMBER;

BEGIN

    SAVEPOINT sp_correccion_a3;

    -- Lista explícita de solicitudes previamente autorizadas.
    FOR r IN (
        SELECT 781245 AS id_solicitud FROM dual
        UNION ALL
        SELECT 781246 AS id_solicitud FROM dual
    )
    LOOP

        v_id_solicitud := r.id_solicitud;

        BEGIN

            -- Consultar y bloquear la solicitud.
            SELECT estado
            INTO v_estado_actual
            FROM solicitud
            WHERE id_solicitud = v_id_solicitud
            FOR UPDATE;

            -- Verificar que continúe en estado PROCESADA.
            IF UPPER(v_estado_actual) = 'PROCESADA' THEN

                -- Comprobar nuevamente que no existan gestiones aprobadas.
                SELECT COUNT(*)
                INTO v_gestiones_aprobadas
                FROM gestion
                WHERE id_solicitud = v_id_solicitud
                  AND UPPER(resultado) = 'APROBADA';

                IF v_gestiones_aprobadas = 0 THEN

                    -- Actualizar el estado de la solicitud.
                    UPDATE solicitud
                    SET estado = 'PENDIENTE',
                        fecha_actualizacion = SYSDATE
                    WHERE id_solicitud = v_id_solicitud;

                    -- Registrar la modificación en auditoría.
                    INSERT INTO auditoria_solicitud (
                        id,
                        id_solicitud,
                        estado_anterior,
                        estado_nuevo,
                        fecha,
                        detalle
                    )
                    VALUES (
                        seq_auditoria.NEXTVAL,
                        v_id_solicitud,
                        v_estado_actual,
                        'PENDIENTE',
                        SYSDATE,
                        'Regularización controlada: solicitud procesada sin gestión aprobada'
                    );

                    DBMS_OUTPUT.PUT_LINE(
                        'Solicitud regularizada: ' || v_id_solicitud
                    );

                ELSE

                    DBMS_OUTPUT.PUT_LINE(
                        'No se modifica la solicitud ' ||
                        v_id_solicitud ||
                        ': existe una gestión aprobada.'
                    );

                END IF;

            ELSE

                DBMS_OUTPUT.PUT_LINE(
                    'No se modifica la solicitud ' ||
                    v_id_solicitud ||
                    ': el estado actual cambió.'
                );

            END IF;

        EXCEPTION
            WHEN NO_DATA_FOUND THEN
                DBMS_OUTPUT.PUT_LINE(
                    'Solicitud inexistente: ' || v_id_solicitud
                );
        END;

    END LOOP;

    DBMS_OUTPUT.PUT_LINE(
        'Proceso finalizado. Pendiente de validación y confirmación.'
    );

EXCEPTION
    WHEN OTHERS THEN

        -- Revertir todas las modificaciones realizadas
        -- desde el punto de recuperación.
        ROLLBACK TO sp_correccion_a3;

        DBMS_OUTPUT.PUT_LINE(
            'Error durante la corrección: ' || SQLERRM
        );

        -- Propagar el error para facilitar el diagnóstico.
        RAISE;

END;
/


**Explicación de la corrección:**

- Se utiliza una lista explícita de identificadores para controlar qué 
solicitudes serán modificadas.
- Se bloquea cada solicitud con `FOR UPDATE` antes de realizar la modificación.
- Se verifica nuevamente que el estado continúe siendo PROCESADA.
- Se comprueba que no exista una gestión APROBADA antes de cambiar el estado.
- Se actualiza únicamente el registro que cumple las condiciones.
- Se registra la modificación en `AUDITORIA_SOLICITUD`.
- Si ocurre un error inesperado, se revierten los cambios realizados desde el 
`SAVEPOINT` y se propaga la excepción.

===========================================================

## 5. Validación posterior a la corrección

Después de ejecutar el bloque PL/SQL,
 se deben consultar nuevamente los registros modificados para comprobar 
 que el estado y la auditoría coincidan.

=========================================================
PASO 5. VALIDACION POSTERIOR
=========================================================

-- Consultar el estado actual de las solicitudes revisadas.

SELECT
    id_solicitud,
    documento,
    estado,
    fecha_actualizacion
FROM solicitud
WHERE id_solicitud IN (781245, 781246);

-- Consultar los registros de auditoría generados.

SELECT
    id,
    id_solicitud,
    estado_anterior,
    estado_nuevo,
    fecha,
    detalle
FROM auditoria_solicitud
WHERE id_solicitud IN (781245, 781246)
ORDER BY fecha DESC;

-- Verificar si continúan existiendo solicitudes
-- PROCESADA sin gestiones APROBADAS.

SELECT
    s.id_solicitud,
    s.estado
FROM solicitud s
WHERE UPPER(s.estado) = 'PROCESADA'
  AND NOT EXISTS (
      SELECT 1
      FROM gestion g
      WHERE g.id_solicitud = s.id_solicitud
        AND UPPER(g.resultado) = 'APROBADA'
  )
ORDER BY s.id_solicitud;


**Explicación:**

La validación posterior permite comprobar:

1. Que las solicitudes autorizadas hayan quedado con el estado esperado.
2. Que cada modificación tenga su correspondiente registro de auditoría.
3. Que no existan inconsistencias entre el estado de la solicitud y las
 gestiones asociadas.
4. Que las solicitudes que no fueron autorizadas permanezcan sin modificaciones.

Es importante tener presente que pueden continuar apareciendo 
solicitudes en el diagnóstico inicial, ya que no todas necesariamente 
deben corregirse.

===========================================================

## 6. Estrategia de reversa o contingencia

Si después de ejecutar la corrección se detecta algún resultado incorrecto, 
se debe evitar confirmar la transacción y ejecutar `ROLLBACK`.

### Opción 1. Reversar antes de confirmar

Mientras la transacción no haya sido confirmada mediante `COMMIT`, 
se pueden revertir las modificaciones realizadas.


Esto permite recuperar el estado anterior de los registros modificados 
dentro de la transacción.

### Opción 2. Reversar después de una confirmación

Si los cambios ya fueron confirmados, un `ROLLBACK` normal no 
permitirá recuperar la información anterior.

En ese escenario se debe:

1. Consultar los registros de auditoría para identificar las solicitudes 
modificadas.
2. Verificar el estado anterior y el estado actual.
3. Solicitar autorización para realizar una corrección compensatoria.
4. Ejecutar una nueva actualización controlada.
5. Registrar el cambio compensatorio en auditoría, sin eliminar los
 registros anteriores.

Ejemplo de consulta para identificar las modificaciones:


SELECT
    id_solicitud,
    estado_anterior,
    estado_nuevo,
    fecha,
    detalle
FROM auditoria_solicitud
WHERE detalle LIKE '%Regularización controlada%'
ORDER BY fecha DESC;


La reversa posterior a un `COMMIT` debe realizarse mediante una operación 
compensatoria autorizada, conservando la trazabilidad histórica.

===========================================================

## 7. Supuestos y consideraciones técnicas

Para desarrollar este script se tuvieron en cuenta los siguientes supuestos:

- La tabla `SOLICITUD` contiene el estado actual de cada solicitud.
- La tabla `GESTION` almacena el historial de gestiones realizadas.
- Una solicitud se considera aprobada cuando existe al menos un registro 
asociado cuyo resultado sea APROBADA.
- La tabla `AUDITORIA_SOLICITUD` permite registrar los cambios de estado.
- La secuencia `SEQ_AUDITORIA` existe y permite generar identificadores 
únicos para la auditoría.
- El estado PENDIENTE es una alternativa de regularización propuesta,
 pero debe ser validada por el área responsable.
- Los identificadores utilizados en el ejemplo son ilustrativos y deben 
sustituirse por registros previamente revisados y autorizados.
- La corrección debe ejecutarse primero en un ambiente de pruebas y 
posteriormente en producción, siguiendo el procedimiento de autorización 
correspondiente.

===========================================================

## 8. Conclusión

La solución propuesta permite identificar las solicitudes que se 
encuentran en estado PROCESADA sin tener una gestión APROBADA asociada, 
utilizando consultas de diagnóstico que no modifican la información
 de la base de datos.

Adicionalmente, se plantea una corrección controlada mediante identificadores 
previamente revisados y autorizados, evitando actualizaciones masivas que 
puedan afectar solicitudes válidas.

La implementación contempla validaciones antes y después de la modificación, 
registro de auditoría, control transaccional y 
mecanismos de reversa o contingencia.

De esta manera, se busca garantizar la integridad de la información, 
conservar la trazabilidad de las operaciones y facilitar el trabajo del equipo
 de soporte en la identificación y solución de inconsistencias.

===========================================================