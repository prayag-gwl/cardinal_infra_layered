# ALB Configuration Summary - PROD Environment

## ✅ Configuration Complete

The ALB module has been updated to match the exact PROD requirements with host-based routing and no pgAdmin configuration.

---

## 📋 ALB Configuration

### ALB Details
- **Name**: `cardinal-alb-public`
- **Scheme**: Internet-facing
- **Type**: Application Load Balancer

### Listeners

#### 1. HTTP:80
- **Action**: Redirect all traffic to HTTPS:443 using HTTP_301
- **No additional rules**: Simple redirect only

#### 2. HTTPS:443
- **SSL Certificate**: Uses `frontend_certificate_arn` or `backend_certificate_arn` variable
- **SSL Policy**: `ELBSecurityPolicy-TLS13-1-2-2021-06`
- **Listener Rules** (priority ordered):

| Priority | Condition | Action |
|----------|-----------|--------|
| 1 | Host header == `beta.cedu.app` | Forward to `tg-cardinal-frontend-3000` |
| 2 | Host header == `api.cedu.app` | Forward to `tg-cardinal-backend-3000` |
| Default | (no match) | Forward to `tg-cardinal-frontend-3000` |

---

## 🎯 Target Groups

### Frontend Target Group
- **Name**: `tg-cardinal-frontend-3000`
- **Port**: 3000
- **Protocol**: HTTP
- **Health Check Path**: `/health`
- **Matcher**: 200-399

### Backend Target Group
- **Name**: `tg-cardinal-backend-3000`
- **Port**: 3000
- **Protocol**: HTTP
- **Health Check Path**: `/api/cardinal-education-service/v1/health`
- **Matcher**: 200-399

---

## ❌ Removed/Not Included

- ✅ **No pgAdmin configuration** - All pgAdmin listeners, target groups, and rules removed
- ✅ **No HTTP:81 listener** - Only HTTP:80 and HTTPS:443
- ✅ **No path-based rules** - Removed `/api/*` path pattern rule
- ✅ **No pgAdmin host headers** - No `pgadmin.dev.cedu.app` rules

---

## 📝 Files Updated

### 1. `modules/alb/main.tf`
- Updated HTTP listener to always redirect to HTTPS
- Removed path-based `/api/*` rule
- Added host-based routing rules:
  - Priority 1: `beta.cedu.app` → frontend TG
  - Priority 2: `api.cedu.app` → backend TG
- Default action on HTTPS: forward to frontend TG
- Target group names: `tg-cardinal-frontend-3000` and `tg-cardinal-backend-3000`

### 2. `modules/alb/variables.tf`
- Added `frontend_host_header` variable (default: empty)
- Added `backend_host_header` variable (default: empty)

### 3. `modules/alb/outputs.tf`
- Added `https_listener_arn` output
- Added `http_listener_arn` output

### 4. `stacks/prod/main.tf`
- Updated ALB module call:
  - Name: `cardinal-alb-public`
  - Added `frontend_host_header` = `beta.cedu.app`
  - Added `backend_host_header` = `api.cedu.app`
  - Always redirect HTTP to HTTPS

### 5. `stacks/prod/variables.tf`
- Added `frontend_host_header` variable (default: `beta.cedu.app`)
- Added `backend_host_header` variable (default: `api.cedu.app`)

### 6. `stacks/prod/outputs.tf`
- Updated `prod_alb_dns` → `prod_alb_dns_name`
- Added `https_listener_arn` output
- Added `http_listener_arn` output

### 7. `stacks/prod/terraform.tfvars`
- Added `frontend_host_header = "beta.cedu.app"`
- Added `backend_host_header = "api.cedu.app"`

---

## 🔄 Routing Behavior

### Request Flow

1. **HTTP Request (port 80)**
   ```
   http://beta.cedu.app → Redirect 301 → https://beta.cedu.app
   http://api.cedu.app  → Redirect 301 → https://api.cedu.app
   ```

2. **HTTPS Request (port 443)**
   ```
   https://beta.cedu.app → Priority 1 → tg-cardinal-frontend-3000
   https://api.cedu.app  → Priority 2 → tg-cardinal-backend-3000
   https://anything-else → Default    → tg-cardinal-frontend-3000
   ```

---

## ✅ Verification Checklist

- [x] ALB name is `cardinal-alb-public`
- [x] HTTP:80 redirects to HTTPS:443
- [x] HTTPS:443 has host-based routing
- [x] Priority 1: `beta.cedu.app` → frontend TG
- [x] Priority 2: `api.cedu.app` → backend TG
- [x] Default action: frontend TG
- [x] Target group names: `tg-cardinal-frontend-3000` and `tg-cardinal-backend-3000`
- [x] No pgAdmin configuration
- [x] No HTTP:81 listener
- [x] No path-based rules
- [x] Certificate applied to HTTPS:443 only
- [x] Outputs include listener ARNs

---

## 🚀 Next Steps

1. **Set Certificate ARN**: Update `USW1_FRONTEND_CERTIFICATE_ARN` or `USW1_BACKEND_CERTIFICATE_ARN` in GitHub variables
2. **Deploy**: Run Terraform plan/apply
3. **Verify**: Test routing:
   - `https://beta.cedu.app` should route to frontend
   - `https://api.cedu.app` should route to backend
   - `http://beta.cedu.app` should redirect to HTTPS

---

## 📌 Important Notes

1. **Host Headers**: The host headers (`beta.cedu.app` and `api.cedu.app`) must be configured in your DNS to point to the ALB DNS name.

2. **Certificate**: The ACM certificate must cover both domains:
   - `beta.cedu.app`
   - `api.cedu.app`
   - Or use a wildcard certificate: `*.cedu.app`

3. **Target Groups**: The target groups are automatically created with the exact names specified:
   - `tg-cardinal-frontend-3000`
   - `tg-cardinal-backend-3000`

4. **No Path-Based Routing**: All routing is now host-based. Path-based rules have been removed.

