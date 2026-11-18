import java.util.List;
import java.util.Comparator;


public class SolicitudService {

    public SolicitudDto consultar(Long id) {

        if (id == null) {
            throw new IllegalArgumentException(
                "El identificador es obligatorio"
            );
        }

        Solicitud solicitud = repository.findById(id)
            .orElseThrow(() -> new RuntimeException(
                "No se encontró la solicitud"
            ));

        if (solicitud.getCliente() == null) {
            throw new IllegalStateException(
                "La solicitud no tiene un cliente asociado"
            );
        }

        String nombreCliente = solicitud.getCliente().getNombre();

        if (nombreCliente == null || nombreCliente.trim().isEmpty()) {
            throw new IllegalStateException(
                "El nombre del cliente no es válido"
            );
        }

        nombreCliente = nombreCliente.trim();

        List<Gestion> gestiones =
            gestionRepository.findBySolicitudId(id);

        if (gestiones == null || gestiones.isEmpty()) {
            throw new IllegalStateException(
                "La solicitud no tiene gestiones registradas"
            );
        }

        Gestion ultima = gestiones.stream()
            .filter(g -> g.getFechaGestion() != null)
            .max(Comparator.comparing(Gestion::getFechaGestion))
            .orElseThrow(() -> new IllegalStateException(
                "No existen gestiones con fecha válida"
            ));

        return new SolicitudDto(
            solicitud.getId(),
            nombreCliente,
            solicitud.getEstado(),
            ultima.getFechaGestion()
        );
    }
}