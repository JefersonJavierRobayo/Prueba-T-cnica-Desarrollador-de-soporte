PARTE A - A2. CORRECCIÓN DEL PROCEDIMIENTO CERRAR_SOLICITUD

===========================================================
Problematica:
El siguiente procedimiento fue creado para cerrar una solicitud cuando existe al menos una gestión
APROBADA. Soporte reporta casos en los que el estado queda actualizado aunque la auditoría no se
registra correctamente.

Objetivo:
1. Validar que la solicitud exista.
2. Evitar procesar solicitudes que ya están PROCESADAS.
3. Verificar que exista al menos una gestión APROBADA.
4. Actualizar la solicitud y registrar la auditoría
   dentro de la misma transacción.
5. Evitar COMMIT dentro del procedimiento.
6. Propagar los errores para facilitar su diagnóstico.

Nota:
El procedimiento no realiza COMMIT. La transacción queda
bajo responsabilidad del proceso que lo invoque.

Motor de base de datos: Oracle SQL.
===========================================================
CREATE OR REPLACE PROCEDURE cerrar_solicitud (
    p_id IN NUMBER
)
AS
    v_estado_actual solicitud.estado%TYPE;
    v_gestiones_aprobadas NUMBER := 0;
BEGIN
    -- Punto de recuperación de la transacción.
    SAVEPOINT sp_cerrar_solicitud;

    -- Validar que la solicitud exista y bloquearla
    -- para evitar modificaciones concurrentes.
    BEGIN
        SELECT estado
        INTO v_estado_actual
        FROM solicitud
        WHERE id_solicitud = p_id
        FOR UPDATE;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            RAISE_APPLICATION_ERROR(
                -20001,
                'La solicitud indicada no existe.'
            );
    END;

    -- Evitar reprocesar solicitudes.
    IF UPPER(v_estado_actual) = 'PROCESADA' THEN
        RETURN;
    END IF;

    -- Validar que exista una gestión aprobada.
    SELECT COUNT(*)
    INTO v_gestiones_aprobadas
    FROM gestion
    WHERE id_solicitud = p_id
      AND UPPER(resultado) = 'APROBADA';

    IF v_gestiones_aprobadas = 0 THEN
        RAISE_APPLICATION_ERROR(
            -20002,
            'No es posible procesar la solicitud: no tiene gestiones aprobadas.'
        );
    END IF;

    -- Actualizar el estado de la solicitud.
    UPDATE solicitud
    SET estado = 'PROCESADA',
        fecha_actualizacion = SYSDATE
    WHERE id_solicitud = p_id;

    -- Registrar la auditoría en la misma transacción.
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
        p_id,
        v_estado_actual,
        'PROCESADA',
        SYSDATE,
        'Cierre automático de solicitud con gestión aprobada'
    );

EXCEPTION
    WHEN OTHERS THEN
        -- Revertir los cambios realizados desde el SAVEPOINT.
        ROLLBACK TO sp_cerrar_solicitud;

        -- No ocultar el error: permitir su identificación.
        RAISE;
END cerrar_solicitud;
/
================================================================================
1. Procedimiento corregido

CREATE OR REPLACE PROCEDURE cerrar_solicitud (
    p_id IN NUMBER
)
AS
    v_estado_actual solicitud.estado%TYPE;
    v_gestiones_aprobadas NUMBER := 0;
BEGIN
    -- Punto de recuperación de la transacción.
    SAVEPOINT sp_cerrar_solicitud;

    -- Validar que la solicitud exista y bloquearla
    -- para evitar modificaciones concurrentes.
    BEGIN
        SELECT estado
        INTO v_estado_actual
        FROM solicitud
        WHERE id_solicitud = p_id
        FOR UPDATE;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            RAISE_APPLICATION_ERROR(
                -20001,
                'La solicitud indicada no existe.'
            );
    END;

    -- Evitar reprocesar solicitudes.
    IF UPPER(v_estado_actual) = 'PROCESADA' THEN
        RETURN;
    END IF;

    -- Validar que exista una gestión aprobada.
    SELECT COUNT(*)
    INTO v_gestiones_aprobadas
    FROM gestion
    WHERE id_solicitud = p_id
      AND UPPER(resultado) = 'APROBADA';

    IF v_gestiones_aprobadas = 0 THEN
        RAISE_APPLICATION_ERROR(
            -20002,
            'No es posible procesar la solicitud: no tiene gestiones aprobadas.'
        );
    END IF;

    -- Actualizar el estado de la solicitud.
    UPDATE solicitud
    SET estado = 'PROCESADA',
        fecha_actualizacion = SYSDATE
    WHERE id_solicitud = p_id;

    -- Registrar la auditoría en la misma transacción.
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
        p_id,
        v_estado_actual,
        'PROCESADA',
        SYSDATE,
        'Cierre automático de solicitud con gestión aprobada'
    );

EXCEPTION
    WHEN OTHERS THEN
        -- Revertir los cambios realizados desde el SAVEPOINT.
        ROLLBACK TO sp_cerrar_solicitud;

        -- No ocultar el error: permitir su identificación.
        RAISE;
END cerrar_solicitud;
/

===========================================================

2. Explicación paso a paso del procedimiento original

El procedimiento original recibe como parámetro el identificador de una solicitud (`p_id`) y busca cerrarla cuando encuentra al menos una gestión con resultado APROBADA.

Su funcionamiento es el siguiente:

Declaración de variables: se define la variable 'v_aprobadas', encargada de almacenar la cantidad de gestiones aprobadas asociadas a la solicitud.

Consulta de gestiones:se ejecuta una consulta 'COUNT(*)' sobre la tabla 'GESTION', filtrando por el identificador de la solicitud y el resultado APROBADA.

Validación de aprobación:si el resultado de la consulta es mayor que cero, el procedimiento continúa con el cierre.

Actualización de la solicitud:se modifica el estado a 'PROCESADA'y se actualiza el campo 'fecha_actualizacion' utilizando 'SYSDATE'.

Confirmación de la transacción:se ejecuta COMMIT, confirmando permanentemente la actualización realizada.

Registro de auditoría:se intenta insertar un registro en AUDITORIA_SOLICITUD con el estado anterior, el nuevo estado, la fecha y el detalle del cierre automático.

Manejo de excepciones:si ocurre un error, el bloque WHEN OTHERS THEN NULL captura la excepción y la ignora, sin informar qué ocurrió.

3. Riesgos y defectos identificados

| Riesgo o defecto | Descripción |
|---|---|
| COMMIT antes de la auditoría |La actualización queda confirmada antes de ejecutar el INSERT de auditoría. |

| Inconsistencia de información | La solicitud puede quedar PROCESADA sin que exista el registro correspondiente en auditoría. |

| Excepciones ignoradas | `WHEN OTHERS THEN NULL` oculta los errores y dificulta el diagnóstico por parte de soporte. |

| Estado anterior fijo | Se registra siempre PENDIENTE, sin consultar el estado real de la solicitud. |

| Falta de validación del identificador | No se controla si la solicitud existe en la tabla SOLICITUD. |

| Falta de control de reprocesamiento | No se valida si la solicitud ya se encuentra PROCESADA. |

| Falta de gestión aprobada | No se informa cuando no existen gestiones con resultado APROBADA. |

| Concurrencia | No se bloquea el registro durante la operación, lo que puede generar conflictos ante ejecuciones simultáneas. |

## 4. Justificación de la solución propuesta

La solución implementada busca garantizar la integridad de la información y mantener la consistencia entre la tabla SOLICITUD y la tabla AUDITORIA_SOLICITUD.
==============================================================================================================
Los principales cambios son:

- Se incorpora `SELECT ... FOR UPDATE` para bloquear la solicitud mientras se realiza 
la operación y evitar modificaciones concurrentes sobre el mismo registro.
- Se valida que el identificador recibido exista en la base de datos.
- Se consulta el estado actual para evitar procesar solicitudes que ya se encuentran PROCESADAS.
- Se comprueba que exista al menos una gestión APROBADA antes de realizar la actualización.
- Se obtiene el estado anterior directamente de la base de datos,
 evitando registrar valores incorrectos en la auditoría.
- Se elimina el `COMMIT` interno para evitar confirmar la actualización antes de registrar la auditoría.
- Se utiliza un `SAVEPOINT` para establecer un punto de recuperación de la transacción.
- Se incorpora `ROLLBACK TO SAVEPOINT` 
para revertir los cambios realizados por el procedimiento si ocurre un error.
- Se utiliza `RAISE` para propagar las excepciones y permitir que sean diagnosticadas por soporte.

============================================================================================

5. Manejo de los escenarios solicitados

**Caso 1. El parámetro p_id no existe**

Si el identificador recibido no corresponde a una solicitud registrada en la tabla SOLICITUD, la consulta genera `NO_DATA_FOUND`.

El procedimiento captura esta excepción y genera el error controlado `-20001`, informando que la solicitud no existe.

**Resultado esperado: no se realiza ninguna actualización ni inserción de auditoría.

**Caso 2. La solicitud ya está PROCESADA**

Antes de verificar las gestiones aprobadas, se consulta el estado actual de la solicitud.

Si el estado es PROCESADA, el procedimiento finaliza mediante `RETURN`, 
evitando realizar nuevamente la actualización y generar registros de auditoría duplicados.

**Resultado esperado:** la solicitud permanece sin modificaciones.

**Caso 3. No existe ninguna gestión APROBADA**

Se ejecuta una consulta `COUNT(*)` para verificar si existe al menos una gestión aprobada asociada al identificador recibido.

Si el resultado es cero, se genera el error controlado `-20002`.

**Resultado esperado:** la solicitud no cambia de estado y no se registra ninguna auditoría.

**Caso 4. Existe al menos una gestión APROBADA**

Si la solicitud existe, no está procesada y tiene al menos una gestión aprobada,
se realiza la actualización del estado y posteriormente se registra la auditoría.

**Resultado esperado:** ambas operaciones quedan pendientes 
dentro de la misma transacción para que puedan confirmarse o revertirse conjuntamente.

**Caso 5. Se presenta un error al insertar la auditoría**

Si ocurre un error durante el INSERT en la tabla AUDITORIA_SOLICITUD, se ejecuta
 `ROLLBACK TO sp_cerrar_solicitud` y se propaga la excepción mediante `RAISE`.

**Resultado esperado:** la actualización realizada por el procedimiento 
también se revierte,evitando que la solicitud quede 
PROCESADA sin su correspondiente auditoría.

===================================================================================

## 6. Validación de la corrección y control transaccional

Para verificar que la solución funciona correctamente, 
realizaría pruebas controladas en un ambiente de desarrollo o pruebas, 
utilizando registros de ejemplo.

### Casos de prueba

| N.º | Escenario | Resultado esperado |
|---|---|---|
| 1 | Solicitud existente con gestión APROBADA. | Estado PROCESADA y auditoría registrada. |
| 2 | Identificador de solicitud inexistente. | Error -20001 y ninguna modificación. |
| 3 | Solicitud que ya está PROCESADA. | No se realiza una actualización adicional. |
| 4 | Solicitud sin gestiones APROBADAS. | Error -20002 y ninguna modificación. |
| 5 | Error durante la inserción de auditoría. | Se revierte la actualización realizada por el procedimiento. |

### Ejemplo de ejecución y validación


BEGIN
    cerrar_solicitud(1001);

    -- Consultar el estado de la solicitud.
    SELECT
        id_solicitud,
        estado,
        fecha_actualizacion
    FROM solicitud
    WHERE id_solicitud = 1001;

    -- Consultar el registro de auditoría.
    SELECT
        id,
        id_solicitud,
        estado_anterior,
        estado_nuevo,
        fecha,
        detalle
    FROM auditoria_solicitud
    WHERE id_solicitud = 1001
    ORDER BY fecha DESC;

    -- Confirmar únicamente después de validar
    -- que la actualización y la auditoría sean correctas.
    COMMIT;

EXCEPTION
    WHEN OTHERS THEN
        -- Revertir la transacción ante cualquier error.
        ROLLBACK;

        -- Mostrar el mensaje para facilitar el diagnóstico.
        DBMS_OUTPUT.PUT_LINE(
            'Error durante el cierre de la solicitud: ' || SQLERRM
        );
END;
/


 ¿Cómo validaría que no se generen transacciones parciales?

1. Ejecutaría el procedimiento con una solicitud que tenga al 
menos una gestión APROBADA.
2. Comprobaría que el estado cambie a PROCESADA.
3. Verificaría que se genere el registro correspondiente en AUDITORIA_SOLICITUD.
4. Simularía un error durante la inserción de auditoría en un ambiente controlado, 
por ejemplo,mediante una restricción que impida temporalmente el INSERT.
5. Verificaría que, ante el error, la actualización realizada
 por el procedimiento también sea revertida.
6. Confirmaría que el error se propague y pueda ser identificado 
mediante el mensaje y la información técnica correspondiente.

¿Cómo garantizaría que los errores sigan siendo diagnosticables por soporte?

- Evitaría utilizar `WHEN OTHERS THEN NULL`, porque oculta las excepciones.
- Utilizaría excepciones específicas para identificar situaciones conocidas, 
como una solicitud inexistente o la ausencia de gestiones aprobadas.
- Mantendría el bloque `WHEN OTHERS` para revertir los cambios y propagar el error.
- Registraría en los logs de la aplicación el identificador de la solicitud, 
la operación ejecutada,la fecha, el mensaje de error y el identificador
de correlación, cuando esté disponible.
- Evitaría almacenar información sensible de los clientes en los registros 
técnicos.
- Mantendría los detalles técnicos disponibles para el equipo de soporte, 
sin exponer información interna al usuario final.

===============================================================================

## 7. Conclusión

La principal falla del procedimiento original es ejecutar el `COMMIT` 
antes de insertar el registro de auditoría,lo que permite que la solicitud 
quede actualizada sin que exista trazabilidad de la operación.

La solución propuesta mantiene la actualización y la auditoría dentro de una misma transacción, 
incorpora validaciones para evitar reprocesamientos, controla los escenarios de error y permite 
identificar las excepciones sin ocultarlas.

De esta manera, se mejora la integridad de la información, 
la trazabilidad de las operaciones y la capacidad de diagnóstico
 del equipo de soporte.

**Consideración técnica:** el `ROLLBACK TO SAVEPOINT` revierte únicamente 
los cambios realizados desde el punto de recuperación establecido 
por el procedimiento. No revierte automáticamente los cambios anteriores que 
pertenezcan a la transacción del proceso que lo invoca. Por esta razón, 
el proceso principal debe administrar correctamente el `COMMIT` o `ROLLBACK` 
de la transacción completa.

=================================================================================