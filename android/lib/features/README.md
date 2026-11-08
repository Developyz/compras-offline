# Vistas y ViewModels

Las pantallas conservan datos de demostración. Revisión de ticket ya usa `tickets/viewmodels/revision_ticket_viewmodel.dart`, conectado al dominio; su vista previa recibe la compra preparada y no escribe datos. Los demás módulos mantienen su estado visual de ejemplo.

Los escenarios de lectura se construyen en `lib/demo/revision_demo.dart`. El ViewModel no conoce fixtures, navegación ni conexiones. La View gestiona el ciclo de vida de sus listeners y del ViewModel propio.

Ya existen interfaces de repositorios en `lib/domain/repositories/`. TODO: implementar persistencia transaccional y pruebas antes de conectar el guardado; completar edición, captura/OCR y vinculación. Las Views no abren conexiones.
