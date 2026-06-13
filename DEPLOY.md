# Deploy backend EduCoach

## Render

El repositorio incluye `render.yaml` y `EduCoach.API/Dockerfile`.

Variables necesarias:

- `Database__Provider=Postgres`
- `ConnectionStrings__DefaultConnection`
- `Jwt__SecretKey`
- `Jwt__Issuer=EduCoach`
- `Jwt__Audience=EduCoach.Mobile`
- `DeepSeek__BaseUrl` opcional
- `DeepSeek__ApiKey` opcional
- `DeepSeek__Model=deepseek-chat` opcional

## Migraciones

El backend aplica `Database.Migrate()` automaticamente cuando usa proveedor relacional.

Comandos utiles:

```bash
dotnet dotnet-ef migrations list --project ./EduCoach.API/EduCoach.API.csproj --startup-project ./EduCoach.API/EduCoach.API.csproj
dotnet dotnet-ef database update --project ./EduCoach.API/EduCoach.API.csproj --startup-project ./EduCoach.API/EduCoach.API.csproj
```

## Health check

- Ruta: `/health`
- Swagger: `/swagger`
