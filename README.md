# Proyecto 10: IAM Cross-Account Access

**Sistema empresarial de control de acceso entre cuentas AWS con least privilege y auditoría.**

---

## 📋 Descripción General

Este proyecto implementa un **sistema de permisos multicuenta** que permite que usuarios de una cuenta AWS accedan a recursos de otra cuenta con permisos controlados y limitados.

**Objetivo:** Aprender a implementar least privilege principle, separar entornos (Dev/Staging/Prod) y auditar accesos con CloudTrail.

---

## 🎯 ¿Qué se espera que pase?

Cuando ejecutes `terraform apply`:

1. ✅ **3 Roles IAM se crean** (ReadOnly, Developer, Auditor)
2. ✅ **Trust Relationships se configuran** (quién puede asumir cada rol)
3. ✅ **Policies se asignan** (qué permisos tiene cada rol)
4. ✅ **S3 bucket se crea** para CloudTrail logs
5. ✅ **CloudTrail se activa** para auditoría
6. ✅ **CloudWatch Log Group se crea** para registros
7. ✅ **Outputs se muestran** con comandos para asumir roles

**Resultado:** Sistema listo para acceso cross-account seguro.

---

## 🏗️ Arquitectura

```
Cuenta A (Production - 905308587972)
│
├─ Rol: CrossAccountReadOnlyRole
│  ├─ Permisos: Lectura total (RDS, EC2, S3, CloudWatch)
│  ├─ Restricción: No puede deletear nada
│  └─ Trust: Solo Cuenta C puede asumir
│
├─ Rol: CrossAccountDeveloperRole
│  ├─ Permisos: Lectura + Escritura limitada
│  ├─ Restricción: No puede cambiar IAM
│  └─ Trust: Solo Cuenta C puede asumir
│
├─ Rol: CrossAccountAuditorRole
│  ├─ Permisos: Ver logs, políticas, presupuestos
│  ├─ Restricción: No puede cambiar nada
│  └─ Trust: Solo Cuenta C puede asumir
│
├─ CloudTrail
│  └─ Audita: Quién asumió qué rol, cuándo, desde dónde
│
└─ S3 Bucket
   └─ Almacena: Logs de CloudTrail

       ↓ (Cross-Account Access)

Cuenta C (Development - 905308587972)
│
└─ Usuario/Rol asume roles de Cuenta A
   ├─ aws sts assume-role --role-arn <readonly-arn>
   ├─ aws sts assume-role --role-arn <developer-arn>
   └─ aws sts assume-role --role-arn <auditor-arn>
```

---

## 📦 Estructura del Proyecto

```
proyecto10-iam-cross-account/
├── providers.tf              # Configuración de AWS
├── variables.tf              # Variables y configuración
├── main.tf                   # Roles, Policies, CloudTrail
├── outputs.tf                # ARNs y comandos útiles
├── terraform.tfvars          # Valores de variables
├── .gitignore                # Archivos a ignorar
└── README.md                 # Este archivo
```

---

## 🚀 Uso Rápido

### Prerequisitos

- **Terraform** 1.0+
- **AWS CLI** configurado
- **Acceso a 2 cuentas AWS** (o 1 para testing)

### Instalación y Despliegue

```bash
# 1. Clona el repositorio
git clone https://github.com/Ferdev49/proyecto10-iam-cross-account.git
cd proyecto10-iam-cross-account

# 2. Edita terraform.tfvars
code terraform.tfvars
# - production_account_id = tu cuenta actual
# - trusted_account_id = cuenta para testing

# 3. Inicializa Terraform
terraform init

# 4. Revisa qué se va a crear
terraform plan

# 5. Crea la infraestructura
terraform apply

# 6. Ve los outputs
terraform output

# 7. Destruye (para evitar costos)
terraform destroy
```

---

## 📊 Componentes Creados

### 1. ReadOnly Role

**Nombre:** `proyecto10-readonly-role`

**Permisos permitidos:**
```
✅ RDS: Ver instancias, clústeres, snapshots
✅ EC2: Ver instancias, volúmenes, security groups
✅ S3: Leer objetos, ver buckets
✅ CloudWatch: Ver métricas y logs
✅ CloudTrail: Ver eventos de auditoría
```

**Restricciones:**
```
❌ No puede deletear nada
❌ No puede modificar BD
❌ No puede terminar instancias
```

**Caso de uso:** Desarrolladores que necesitan ver cómo funciona Production sin poder romper nada.

---

### 2. Developer Role

**Nombre:** `proyecto10-developer-role`

**Permisos permitidos:**
```
✅ RDS: Modificar instancias, crear snapshots
✅ EC2: Rebootear, start/stop instancias
✅ S3: Leer y escribir objetos
✅ CloudWatch: Acceso completo
✅ CloudTrail: Ver auditoría
```

**Restricciones:**
```
❌ No puede asumir roles IAM
❌ No puede crear/eliminar usuarios
❌ No puede deletear BD o instancias
❌ No puede modificar políticas
```

**Caso de uso:** DevOps engineers que pueden escalar y optimizar infrastructure, pero no eliminar.

---

### 3. Auditor Role

**Nombre:** `proyecto10-auditor-role`

**Permisos permitidos:**
```
✅ CloudTrail: Acceso completo (auditoría)
✅ CloudWatch Logs: Ver todos los logs
✅ IAM: Leer políticas y roles
✅ Cost Explorer: Ver costos
✅ Budgets: Ver presupuestos
```

**Restricciones:**
```
❌ No puede cambiar nada
❌ Acceso de solo lectura
❌ Útil para compliance y auditoría
```

**Caso de uso:** Auditors y compliance officers que necesitan investigar quién hizo qué sin poder cambiar nada.

---

### CloudTrail Audit Trail

```
Registra automáticamente:
- Quién asumió un rol
- Cuándo lo asumió
- Desde qué dirección IP
- Qué acciones realizó
- Resultados (éxito/fallo)
```

**Almacenamiento:** S3 bucket `proyecto10-cloudtrail-logs-ACCOUNT_ID`

---

## 🔧 Variables Configurables

Edita `terraform.tfvars`:

```hcl
# Cuenta que contiene los roles (Production)
production_account_id = "905308587972"

# Cuenta que puede asumir los roles (Development)
trusted_account_id = "905308587972"  # (la misma para testing)

# Habilitar CloudTrail para auditoría
enable_cloudtrail = true

# Duración de la sesión cross-account (en segundos)
cross_account_session_duration = 3600  # 1 hora

# Crear roles específicos
create_readonly_role  = true
create_developer_role = true
create_auditor_role   = true
```

---

## 📤 Outputs

Después de `terraform apply`:

```bash
$ terraform output

production_account_id = "905308587972"
trusted_account_id = "905308587972"

readonly_role_arn = "arn:aws:iam::905308587972:role/proyecto10-readonly-role"
readonly_role_name = "proyecto10-readonly-role"

developer_role_arn = "arn:aws:iam::905308587972:role/proyecto10-developer-role"
developer_role_name = "proyecto10-developer-role"

auditor_role_arn = "arn:aws:iam::905308587972:role/proyecto10-auditor-role"
auditor_role_name = "proyecto10-auditor-role"

cloudtrail_s3_bucket = "proyecto10-cloudtrail-logs-905308587972"
cloudtrail_arn = "arn:aws:cloudtrail:us-east-1:905308587972:trail/proyecto10-audit-trail"

iam_audit_log_group = "/aws/iam/proyecto10-audit"

assume_readonly_role_command = "aws sts assume-role --role-arn arn:aws:iam::905308587972:role/proyecto10-readonly-role --role-session-name cross-account-session"

assume_developer_role_command = "aws sts assume-role --role-arn arn:aws:iam::905308587972:role/proyecto10-developer-role --role-session-name cross-account-session"

assume_auditor_role_command = "aws sts assume-role --role-arn arn:aws:iam::905308587972:role/proyecto10-auditor-role --role-session-name cross-account-session"

cross_account_summary = {
  "auditor_role" = "proyecto10-auditor-role"
  "cloudtrail_bucket" = "proyecto10-cloudtrail-logs-905308587972"
  "cloudtrail_enabled" = true
  "developer_role" = "proyecto10-developer-role"
  "production_account_id" = "905308587972"
  "readonly_role" = "proyecto10-readonly-role"
  "session_duration" = 3600
  "trusted_account_id" = "905308587972"
}
```

---

## 🌐 Cómo Asumir Roles

### Opción 1: AWS CLI

```bash
# Asumir ReadOnly Role
aws sts assume-role \
  --role-arn arn:aws:iam::905308587972:role/proyecto10-readonly-role \
  --role-session-name my-session

# Resultado (guarda esto):
{
  "Credentials": {
    "AccessKeyId": "ASIXXXXXXXXXX",
    "SecretAccessKey": "xxxxx",
    "SessionToken": "xxxxx",
    "Expiration": "2024-01-01T15:30:00Z"
  }
}
```

### Opción 2: Usar credenciales temporales

```bash
# Exporta las credenciales obtenidas
export AWS_ACCESS_KEY_ID="ASIXXXXXXXXXX"
export AWS_SECRET_ACCESS_KEY="xxxxx"
export AWS_SESSION_TOKEN="xxxxx"

# Ahora puedes ejecutar AWS CLI con los permisos del rol
aws rds describe-db-instances
```

### Opción 3: AWS Configuration

Agrega a `~/.aws/config`:

```
[profile prod-readonly]
role_arn = arn:aws:iam::905308587972:role/proyecto10-readonly-role
source_profile = default

[profile prod-developer]
role_arn = arn:aws:iam::905308587972:role/proyecto10-developer-role
source_profile = default
```

Luego usa:

```bash
aws rds describe-db-instances --profile prod-readonly
```

---

## 🔍 Auditar Accesos

### Ver quién asumió roles

```bash
# CloudTrail muestra todos los AssumeRole
aws cloudtrail lookup-events \
  --lookup-attributes AttributeKey=EventName,AttributeValue=AssumeRole \
  --max-results 10

# Resultado:
{
  "Events": [
    {
      "EventName": "AssumeRole",
      "EventTime": "2024-01-01T14:30:00Z",
      "Username": "IAM_USER_ID",
      "Resources": [
        {
          "ARN": "arn:aws:iam::905308587972:role/proyecto10-readonly-role",
          "AccountId": "905308587972"
        }
      ]
    }
  ]
}
```

### Ver S3 logs de CloudTrail

```bash
# Listar archivos de CloudTrail
aws s3 ls s3://proyecto10-cloudtrail-logs-905308587972/

# Descargar log
aws s3 cp s3://proyecto10-cloudtrail-logs-905308587972/AWSLogs/... . --recursive
```

---

## 🔐 Seguridad y Best Practices

### ✅ Lo que este proyecto implementa

1. **Least Privilege:** Cada rol tiene solo los permisos necesarios
2. **Explicit Deny:** Restricciones claras (no puede deletear)
3. **Audit Trail:** CloudTrail registra todo
4. **Session Duration:** Tokens expiran automáticamente
5. **Separation of Concerns:** Dev, Staging, Prod en cuentas diferentes

### ⚠️ Mejoras futuras

- Agregar MFA requirement para ciertos roles
- Usar AWS SSO para gestión centralizada
- Implementar permission boundaries
- Agregar IP restrictions en trust policies
- Configurar Resource-Based Policies adicionales

---

## 🧪 Pruebas Manuales

### Test 1: Verificar que el rol existe

```bash
aws iam get-role --role-name proyecto10-readonly-role
```

### Test 2: Ver la trust policy

```bash
aws iam get-role-policy --role-name proyecto10-readonly-role --policy-name proyecto10-readonly-policy
```

### Test 3: Simular acciones permitidas

```bash
# Simula si puedo describir RDS
aws iam simulate-principal-policy \
  --policy-source-arn arn:aws:iam::905308587972:role/proyecto10-readonly-role \
  --action-names rds:DescribeDBInstances \
  --resource-arns "*"

# Resultado: EvalDecision = allowed
```

### Test 4: Simular acciones denegadas

```bash
# Simula si puedo deletear RDS (debería fallar)
aws iam simulate-principal-policy \
  --policy-source-arn arn:aws:iam::905308587972:role/proyecto10-readonly-role \
  --action-names rds:DeleteDBInstance \
  --resource-arns "*"

# Resultado: EvalDecision = implicitDeny
```

## 📚 Recursos Adicionales

- [AWS IAM Documentation](https://docs.aws.amazon.com/iam/)
- [Cross-Account Access](https://docs.aws.amazon.com/IAM/latest/UserGuide/id_roles_common-scenarios_aws-accounts.html)
- [STS AssumeRole](https://docs.aws.amazon.com/STS/latest/APIReference/API_AssumeRole.html)
- [CloudTrail Documentation](https://docs.aws.amazon.com/cloudtrail/)
- [Least Privilege Best Practices](https://docs.aws.amazon.com/IAM/latest/UserGuide/best-practices.html)

---

## 🚀 Próximos Pasos

1. Crear cuentas reales para Development y Production
2. Agregar MFA requirement para ciertos roles
3. Implementar permission boundaries
4. Configurar AWS SSO
5. Crear automated reports de acceso con CloudTrail

---

**Última actualización:** Mayo 27, 2026
**Versión:** 1.0.0
**Estado:** ✅ Completado y Testeado