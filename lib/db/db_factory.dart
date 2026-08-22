// Exporta a fábrica de banco correta para a plataforma:
// - Web → IndexedDB (sembast_web)
// - Mobile/Desktop → arquivo (sembast_io)
export 'db_factory_io.dart' if (dart.library.html) 'db_factory_web.dart';
