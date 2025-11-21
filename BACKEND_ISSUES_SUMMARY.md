# Backend Deployment Issues - Summary

## Current Status

✅ **Security Group Rule**: Already configured correctly
- RDS security group `sg-00d7fa46f49856145` allows PostgreSQL (5432) from `10.10.0.0/16`
- Network connectivity should be working

## Two Issues Identified

### Issue 1: Database Connection Timeout ⚠️

**Status**: Security group rule is in place, but connection still failing

**Possible Causes:**
1. **TypeORM Error**: The application crashes before it can establish a database connection
2. **Database Credentials**: Secrets Manager values might be incorrect
3. **Database Name**: The `DB_NAME` environment variable might not match the actual database

**Next Steps to Debug:**
1. Check if the TypeORM error is preventing connection attempts
2. Verify Secrets Manager secret contains correct values:
   ```bash
   aws secretsmanager get-secret-value \
     --secret-id <SECRET_ARN> \
     --region us-west-1 \
     --query SecretString \
     --output text | jq .
   ```
3. Verify `DB_NAME` environment variable matches the actual database name in RDS

### Issue 2: TypeORM Error - "DataSource with name 'default' has already added" ❌

**Status**: Application code issue - needs fix in `OB_backend` repository

**Error:**
```
Error: DataSource with name "default" has already added.
at addTransactionalDataSource (/app/node_modules/typeorm-transactional/src/common/index.ts:203:11)
at dataSourceFactory (/app/dist/main.js:992:95)
```

**Root Cause**: The TypeORM data source is being initialized multiple times, likely due to:
- Module imports causing duplicate initialization
- Hot reload issues
- Incorrect NestJS/TypeORM configuration

**Fix Required**: This needs to be fixed in the application code (`OB_backend` folder):
1. Check `main.ts` or data source configuration
2. Ensure data source is only initialized once
3. Review module imports that might cause duplicate initialization
4. Check if `typeorm-transactional` is configured correctly

## Recommended Action Plan

### Immediate (Fix Database Connection)

1. **Verify Secrets Manager Secret**:
   - Check that the secret ARN in GitHub variable `USW1_DATABASE_SECRET_ARN` is correct
   - Verify the secret contains: `host`, `username`, `password`, `port`
   - Ensure the database name in RDS matches `USW1_DATABASE_NAME`

2. **Check Environment Variables**:
   - Verify `DB_NAME` is set correctly in the task definition
   - Check that all required database connection variables are present

3. **Test Connection Manually** (if possible):
   - Try connecting to RDS from a test instance in the new VPC
   - Verify network connectivity is working

### Long-term (Fix TypeORM Error)

1. **Fix in Application Code**:
   - Review `OB_backend` TypeORM configuration
   - Ensure data source initialization happens only once
   - Fix the duplicate data source issue
   - Rebuild and push new Docker image to ECR

2. **After Fix**:
   - Push updated backend image to ECR
   - Force new ECS deployment
   - Monitor logs for successful startup

## Current Configuration

- **RDS Security Group**: `sg-00d7fa46f49856145` ✅
- **ECS Security Group**: `sg-066471834e5ec22dd` ✅
- **Network Rule**: PostgreSQL (5432) from `10.10.0.0/16` ✅
- **Backend Service**: Running but failing to connect ❌

## Next Steps

1. **First**: Fix the TypeORM error in application code (this might be blocking the connection)
2. **Then**: Verify database credentials and connection parameters
3. **Finally**: Test end-to-end connectivity

The TypeORM error might be preventing the application from even attempting a database connection, which would explain why the security group fix alone didn't resolve the issue.


