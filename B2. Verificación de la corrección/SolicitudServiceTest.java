
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

import java.time.LocalDateTime;
import java.util.List;
import java.util.Optional;

import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.Mockito.*;

@ExtendWith(MockitoExtension.class)
class SolicitudServiceTest {

    @Mock
    private SolicitudRepository repository;

    @Mock
    private GestionRepository gestionRepository;

    @InjectMocks
    private SolicitudService service;

    @Test
    void consultarSolicitudExistenteConGestiones() {

        Long id = 781245L;

        Solicitud solicitud = mock(Solicitud.class);
        Cliente cliente = mock(Cliente.class);

        Gestion gestionAntigua = mock(Gestion.class);
        Gestion gestionReciente = mock(Gestion.class);

        LocalDateTime fechaAntigua =
            LocalDateTime.of(2026, 11, 5, 10, 0);

        LocalDateTime fechaReciente =
            LocalDateTime.of(2026, 11, 6, 9, 0);

        when(repository.findById(id))
            .thenReturn(Optional.of(solicitud));

        when(solicitud.getId()).thenReturn(id);
        when(solicitud.getCliente()).thenReturn(cliente);
        when(solicitud.getEstado()).thenReturn(null);
        when(cliente.getNombre()).thenReturn("Juan Perez");

        when(gestionRepository.findBySolicitudId(id))
            .thenReturn(List.of(gestionAntigua, gestionReciente));

        when(gestionAntigua.getFechaGestion())
            .thenReturn(fechaAntigua);

        when(gestionReciente.getFechaGestion())
            .thenReturn(fechaReciente);

        SolicitudDto resultado = service.consultar(id);

        assertNotNull(resultado);
        assertEquals(id, resultado.getId());
        assertEquals("Juan Perez", resultado.getNombreCliente());
        assertEquals(fechaReciente, resultado.getFechaGestion());
    }

    @Test
    void consultarSolicitudInexistente() {

        Long id = 999999L;

        when(repository.findById(id))
            .thenReturn(Optional.empty());

        assertThrows(RuntimeException.class,
            () -> service.consultar(id));

        verify(gestionRepository, never())
            .findBySolicitudId(anyLong());
    }

    @Test
    void consultarSolicitudSinGestiones() {

        Long id = 781245L;

        Solicitud solicitud = mock(Solicitud.class);
        Cliente cliente = mock(Cliente.class);

        when(repository.findById(id))
            .thenReturn(Optional.of(solicitud));

        when(solicitud.getId()).thenReturn(id);
        when(solicitud.getCliente()).thenReturn(cliente);
        when(solicitud.getEstado()).thenReturn(null);
        when(cliente.getNombre()).thenReturn("Juan Perez");

        when(gestionRepository.findBySolicitudId(id))
            .thenReturn(List.of());

        assertThrows(IllegalStateException.class,
            () -> service.consultar(id));
    }
}