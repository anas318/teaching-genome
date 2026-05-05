# Deployment Guide - Teaching Genome

Production deployment options from quick-start to enterprise.

---

## Quick Start (30 minutes)

**Best for**: Testing, small teams, prototyping

### 1. Deploy Frontend to Vercel

```bash
# Install Vercel CLI
npm install -g vercel

# Login to Vercel
vercel login

# Deploy
vercel
```

**Configuration**:
- Framework: Next.js
- Build Command: `npm run build`
- Install Command: `npm install`

**Environment Variables** (in Vercel dashboard):
```
NEXT_PUBLIC_SUPABASE_URL=https://your-project.supabase.co
NEXT_PUBLIC_SUPABASE_ANON_KEY=eyJhbGc...
NEXT_PUBLIC_N8N_BASE_URL=https://your-n8n.com
NEXT_PUBLIC_N8N_WEBHOOK_URL=https://your-n8n.com/webhook/...
```

**Result**: App deployed at `teaching-genome.vercel.app`

---

## Standard Setup (2-3 hours)

**Best for**: Production use, 1,000+ users

### Architecture
```
┌────────────────┐
│   Vercel       │ (Frontend)
│  Next.js app   │
└────────┬───────┘
         │
┌────────▼───────────┐
│   Supabase         │ (Database + Auth)
│   Cloud Postgres   │
└────────┬───────────┘
         │
┌────────▼───────────┐
│   n8n Cloud        │ (Workflows)
│   or self-hosted   │
└────────┬───────────┘
         │
┌────────▼───────────┐
│  Google Gemini API │ (AI)
└────────────────────┘
```

### Step 1: Supabase (Hosted)
1. Go to [supabase.com](https://supabase.com)
2. Create new project
3. Run SQL setup (see [SETUP.md](./SETUP.md))
4. Create storage bucket for PDFs
5. Copy credentials to Vercel

### Step 2: Frontend (Vercel)
```bash
# Connect GitHub repo
vercel link

# Set production env vars
vercel env add NEXT_PUBLIC_SUPABASE_URL
vercel env add NEXT_PUBLIC_SUPABASE_ANON_KEY
vercel env add NEXT_PUBLIC_N8N_BASE_URL
vercel env add NEXT_PUBLIC_N8N_WEBHOOK_URL

# Deploy
git push origin main
```

### Step 3: n8n (Cloud or Self-Hosted)

**Option A: n8n Cloud**
1. Sign up at [n8n.cloud](https://n8n.cloud)
2. Create workflow (see [ARCHITECTURE.md](./ARCHITECTURE.md))
3. Configure credentials (Supabase, Gemini)
4. Get webhook URLs
5. Test with cURL:
   ```bash
   curl -X POST https://your-n8n.com/webhook/teaching-genome \
     -H "Content-Type: application/json" \
     -d '{"course_id": "test"}'
   ```

**Option B: Self-Hosted (Railway)**
```bash
# Push to Railway
npm install -g railway
railway link
railway up

# Environment
railway variables set \
  DB_TYPE=sqlite \
  N8N_USER_MANAGEMENT_DISABLED=true
```

---

## Enterprise Setup (5-7 hours)

**Best for**: Organizations with 10,000+ users, HIPAA/compliance needs

### Architecture
```
┌─────────────────────────────┐
│   CloudFlare CDN            │ (Global caching)
└────────────────┬────────────┘
                 │
┌────────────────▼────────────┐
│   Docker + Kubernetes       │ (Orchestration)
├─────────────────────────────┤
│ Frontend Pods (3+)          │
│ Worker Pods (5+)            │
│ Cache (Redis)               │
└────────────────┬────────────┘
                 │
┌────────────────▼────────────┐
│ PostgreSQL (Managed)        │
│ Auto-scaling, backups       │
└─────────────────────────────┘
```

### 1. Database (AWS RDS or Google Cloud SQL)

```bash
# Create PostgreSQL instance
# - 4 CPU, 16GB RAM
# - Multi-AZ for redundancy
# - Automated backups every 6 hours
# - Cost: $200-400/month
```

**Migration**:
```bash
# Dump Supabase
pg_dump postgresql://... > backup.sql

# Restore to RDS
psql postgresql://rds-endpoint/db < backup.sql
```

### 2. Backend (Docker + Kubernetes)

**Dockerfile**:
```dockerfile
FROM node:18-alpine

WORKDIR /app
COPY package*.json ./
RUN npm ci --only=production

COPY . .
RUN npm run build

EXPOSE 3000
CMD ["npm", "start"]
```

**Kubernetes Deployment** (`k8s/deployment.yaml`):
```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: teaching-genome-frontend
spec:
  replicas: 3
  selector:
    matchLabels:
      app: teaching-genome
  template:
    metadata:
      labels:
        app: teaching-genome
    spec:
      containers:
      - name: frontend
        image: your-registry/teaching-genome:latest
        ports:
        - containerPort: 3000
        env:
        - name: NEXT_PUBLIC_SUPABASE_URL
          valueFrom:
            secretKeyRef:
              name: app-secrets
              key: supabase-url
        resources:
          requests:
            memory: "256Mi"
            cpu: "250m"
          limits:
            memory: "512Mi"
            cpu: "500m"
```

**Deploy**:
```bash
# Build image
docker build -t your-registry/teaching-genome:latest .
docker push your-registry/teaching-genome:latest

# Deploy to Kubernetes
kubectl apply -f k8s/deployment.yaml
kubectl apply -f k8s/service.yaml
```

### 3. Workflow Engine (n8n on Docker)

```yaml
version: '3.8'
services:
  n8n:
    image: n8nio/n8n:latest
    ports:
      - "5678:5678"
    environment:
      - DB_TYPE=postgres
      - DB_POSTGRESDB_HOST=postgres
      - DB_POSTGRESDB_PORT=5432
      - DB_POSTGRESDB_DATABASE=n8n
      - DB_POSTGRESDB_USER=n8n
      - DB_POSTGRESDB_PASSWORD=${N8N_DB_PASSWORD}
      - N8N_USER_MANAGEMENT_DISABLED=false
    depends_on:
      - postgres
  
  postgres:
    image: postgres:15
    environment:
      - POSTGRES_USER=n8n
      - POSTGRES_PASSWORD=${N8N_DB_PASSWORD}
      - POSTGRES_DB=n8n
    volumes:
      - postgres_data:/var/lib/postgresql/data

volumes:
  postgres_data:
```

### 4. Caching Layer (Redis)

```yaml
cache:
  image: redis:7-alpine
  ports:
    - "6379:6379"
  volumes:
    - redis_data:/data

volumes:
  redis_data:
```

**In Next.js**:
```typescript
import Redis from 'ioredis';

const redis = new Redis(process.env.REDIS_URL);

export async function getCachedCourse(courseId: string) {
  const cached = await redis.get(`course:${courseId}`);
  if (cached) return JSON.parse(cached);
  
  const data = await supabase
    .from('courses')
    .select('*')
    .eq('id', courseId)
    .single();
  
  await redis.setex(`course:${courseId}`, 3600, JSON.stringify(data));
  return data;
}
```

### 5. SSL/TLS (Let's Encrypt + nginx)

```nginx
server {
    listen 443 ssl http2;
    server_name teaching-genome.com;

    ssl_certificate /etc/letsencrypt/live/teaching-genome.com/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/teaching-genome.com/privkey.pem;
    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_ciphers HIGH:!aNULL:!MD5;

    location / {
        proxy_pass http://localhost:3000;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
    }
}
```

---

## Monitoring & Logging

### Sentry (Error Tracking)
```bash
npm install @sentry/nextjs
```

**In pages/_app.tsx**:
```typescript
import * as Sentry from "@sentry/nextjs";

Sentry.init({
  dsn: process.env.NEXT_PUBLIC_SENTRY_DSN,
  environment: process.env.NODE_ENV,
  tracesSampleRate: 0.1,
});
```

### CloudWatch (AWS)
```bash
# Ship logs to CloudWatch
docker run -d \
  --log-driver=awslogs \
  --log-opt awslogs-group=/ecs/teaching-genome \
  --log-opt awslogs-region=us-east-1 \
  your-image
```

### Prometheus + Grafana (Metrics)
```yaml
prometheus:
  image: prom/prometheus
  volumes:
    - ./prometheus.yml:/etc/prometheus/prometheus.yml
  ports:
    - "9090:9090"

grafana:
  image: grafana/grafana
  ports:
    - "3000:3000"
  environment:
    - GF_SECURITY_ADMIN_PASSWORD=${GRAFANA_PASSWORD}
```

---

## Cost Estimate

### Quick Start (Monthly)
- Vercel Free: $0
- Supabase Free: $0
- n8n Free: $0
- **Total: $0** (limited usage)

### Standard (Monthly)
- Vercel: $20 (Hobby plan)
- Supabase: $25 (Pro plan)
- n8n Cloud: $40 (Free + $10 pro features)
- Google Gemini: ~$10 (pay-as-you-go)
- **Total: ~$95/month**

### Enterprise (Monthly)
- Kubernetes (EKS/GKE): $150
- Database (RDS): $300
- CDN (CloudFlare): $50
- n8n Self-hosted: $20
- Monitoring (Sentry + DataDog): $50
- **Total: $570/month + $20/1K API calls**

---

## Post-Deployment Checklist

- [ ] SSL certificate configured
- [ ] Database backups automated
- [ ] Error tracking (Sentry) enabled
- [ ] Rate limiting configured
- [ ] CORS policies set correctly
- [ ] Secrets stored in env vars
- [ ] Logs centralized (CloudWatch/ELK)
- [ ] Health checks configured
- [ ] Uptime monitoring (UptimeRobot)
- [ ] Load testing completed (k6, Apache JMeter)
- [ ] Security audit passed (OWASP Top 10)
- [ ] Disaster recovery plan documented

---

## Troubleshooting

### High Memory Usage
```bash
# Check Node.js memory limit
node --max-old-space-size=4096 npm start

# Or in Dockerfile
ENV NODE_OPTIONS="--max-old-space-size=4096"
```

### Database Connection Errors
```bash
# Test connection
psql postgresql://user:pass@host/db -c "SELECT 1"

# Check connection pool
PGBOUNCER_POOL_MODE=transaction
```

### Slow PDF Generation
```bash
# Add caching layer
# See Redis example above

# Monitor n8n execution time
# Dashboard → Execution history
```

---

<div align="center">

**Need help deploying? Open an issue or ask in Discussions!** 🚀

</div>
