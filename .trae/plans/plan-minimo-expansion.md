# Plan Minimo de Expansion

Fecha: 2026-06-19
Estado: Draft
Esfuerzo estimado total: 8-14 horas

## Objetivo

Expandir la app sin sobreingenieria ni redisenos grandes. El orden es:

1. Meter mas contenido real.
2. Aprovechar mejor el historial con modos de practica utiles.
3. Quitar una deuda tecnica puntual cuando ya haga falta.

## Estado actual resumido

- El backend ya soporta temas, preguntas, diagnostico, practica, historial, recomendacion y progreso.
- El mayor limite actual no es la arquitectura, sino la cantidad de contenido.
- Hoy solo hay 2 temas sembrados en `EduCoach.API/Data/SeedData.cs`.
- La pantalla de practica aun tiene temas hardcodeados en `educoach_app/lib/features/practice/presentation/practice_screen.dart`.
- Ya existe historial y detalle de respuestas, asi que "repasar errores" encaja bien sin rehacer el flujo.

## Fase 1: Mas contenido

### Objetivo

Dar mas valor visible rapido, sin tocar la arquitectura base.

### Alcance

- Agregar 2 temas nuevos.
- Agregar mas preguntas a `Fracciones`.
- Agregar mas preguntas a `Algebra Basica`.
- Incluir preguntas de diagnostico y practica por nivel para los nuevos temas.
- Actualizar la lista visible de temas en Flutter para que aparezcan los nuevos.

### Resultado esperado

- La app deja de sentirse pequena o repetitiva.
- Hay mas variedad en practica y diagnostico.
- Se mantiene el flujo actual sin cambios estructurales.

### Estimacion

Media.

## Fase 2: Repaso de errores y practica mixta

### Objetivo

Reutilizar mejor el historial ya existente para que la app ensene mejor con lo que el usuario falla.

### Alcance

- Crear modo `Repasar errores` usando respuestas incorrectas guardadas.
- Crear una practica mixta simple o recomendada ampliada usando logica ya existente.
- Reutilizar la misma UI de sesion de practica para no duplicar pantallas.
- Agregar acceso minimo desde inicio o desde practica.

### Resultado esperado

- El usuario puede practicar justo lo que mas le cuesta.
- La app gana utilidad real sin necesidad de IA nueva ni modelos complejos.
- Se aprovecha mejor lo que ya esta guardado en historial y respuestas.

### Estimacion

Media.

## Fase 3: Catalogo dinamico de temas

### Objetivo

Eliminar la dependencia de temas hardcodeados en Flutter.

### Alcance

- Exponer un endpoint simple para listar temas.
- Consumir esos temas desde `educoach_api.dart`.
- Reemplazar la lista fija `_topics` en `practice_screen.dart`.
- Mantener la misma experiencia visual, agregando solo carga, error y reintento.

### Resultado esperado

- Agregar un tema nuevo en backend deja de requerir tocar Flutter.
- Se reduce mantenimiento manual.
- El sistema queda listo para seguir creciendo sin redisenar.

### Estimacion

Media-baja.

## Orden recomendado

1. Fase 1 primero, porque hoy el cuello de botella es contenido.
2. Fase 2 despues, porque reutiliza historial y progreso ya existentes.
3. Fase 3 al final, porque mejora mantenimiento pero no bloquea valor inmediato.

## Riesgos reales

- Si se agregan temas pero no se actualiza Flutter en fases tempranas, no quedaran visibles.
- Si un tema o nivel tiene pocas preguntas, algunas sesiones pueden repetirse demasiado.
- Si `Repasar errores` no encuentra datos previos, debe mostrar un estado vacio claro.

## Fuera de alcance

- Panel administrador.
- CMS de preguntas.
- Motor adaptativo avanzado por subtema.
- Rediseno grande de base de datos.
- Multimedia por pregunta.
- Orquestador o agente IA mas complejo.

## Criterio de terminado

### Fase 1

- La app muestra 2 temas nuevos.
- Cada tema nuevo permite diagnostico y practica sin errores.
- Los temas actuales tienen mas variedad de preguntas.

### Fase 2

- Existe un modo para repasar errores previos.
- Existe una variante simple de practica mixta o mejor recomendada.
- El flujo reutiliza la sesion actual sin romper historial ni progreso.

### Fase 3

- La lista de temas deja de estar hardcodeada en Flutter.
- Los temas se cargan desde backend con manejo basico de error.

## Archivo base a tocar en implementacion futura

- `EduCoach.API/Data/SeedData.cs`
- `EduCoach.API/Services/PracticeService.cs`
- `EduCoach.API/Controllers/PracticeController.cs`
- `educoach_app/lib/core/api/educoach_api.dart`
- `educoach_app/lib/features/practice/presentation/practice_screen.dart`
- `educoach_app/lib/features/home/presentation/home_screen.dart`

## Nota final

La idea no es hacer "mas sistema", sino hacer la app mas util con el menor cambio razonable. Si hubiera que empezar ya, el mejor primer paso es la Fase 1.
