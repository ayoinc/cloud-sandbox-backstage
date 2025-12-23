# Backstage Container Status

## Container Status
All Backstage services have been successfully started!

| Container | Status | Port | Health |
|-----------|--------|------|--------|
| backstage-nginx | Up 7 seconds | 80 | healthy |
| backstage-app | Up 13 seconds | 7007 | healthy |
| backstage-postgres | Up 19 seconds | 5432 | healthy |
| backstage-minio | Up 19 seconds | 9000-9001 | healthy |
| backstage-redis | Up 19 seconds | 6379 | healthy |
| backstage-minio-init | Exited (0) | - | completed |

## Access URLs

### Backstage Application
- **Main URL**: http://localhost
- **Direct Backend**: http://localhost:7007 (internal)
- **Health Check**: http://localhost/health → healthy

### Services
- **PostgreSQL**: localhost:5432
- **Redis**: localhost:6379
- **MinIO**: localhost:9000 (API), localhost:9001 (Console)

### MinIO Console
- URL: http://localhost:9001
- Access Key: backstage
- Secret Key: backstage123

## Next Steps

1. **Access Backstage**: Open http://localhost in your browser
2. **Register Components**: 
   - Use `all-components.yaml` from your terraform-modules catalog
   - URL: https://github.com/company/terraform-modules/blob/main/all-components.yaml
3. **Verify TechDocs**: Check that documentation loads for each component
4. **Check Logs** (if needed): `cd /Users/ayodeleajayi/Workspace/backstage && docker logs backstage-app`

## Docker Commands

```bash
# View all logs
docker-compose -f docker-compose.yaml -f docker-compose.services.yaml logs -f

# Restart services
docker-compose -f docker-compose.yaml -f docker-compose.services.yaml restart

# Stop services
docker-compose -f docker-compose.yaml -f docker-compose.services.yaml down

# View specific container logs
docker logs backstage-app
docker logs backstage-postgres
docker logs backstage-nginx
```

## Troubleshooting

If containers are not healthy:
1. Check logs: `docker logs [container-name]`
2. Restart unhealthy service: `docker restart [container-name]`
3. Full restart: `docker-compose down && docker-compose up -d`

## Health Check Endpoints

- **Nginx**: http://localhost/health
- **Backstage**: http://localhost/healthcheck (via nginx)
- **PostgreSQL**: `pg_isready -h localhost -p 5432 -U backstage`
- **Redis**: `redis-cli -p 6379 ping`
- **MinIO**: http://localhost:9000/minio/health/live

All services are running and ready to use!
