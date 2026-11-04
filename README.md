# Pre-entrega 4: procesamiento stateful con Amazon Managed Flink

Esta entrega es una evolucion directa de la **pre-entrega 2**. Conserva la VPC, IAM, Kinesis Data Stream, KMS, Firehose y el Data Lake S3, y agrega una aplicacion de Amazon Managed Service for Apache Flink que consume el mismo stream en paralelo con Firehose.

```text
                              +--> Firehose --> S3 Bronze
Producer --> Kinesis (2 shards)
                              +--> Managed Flink 1.20
                                     |
                                     +--> Watermarks / Event Time
                                     +--> KeyedState por usuario
                                     +--> Ventanas tumbling
                                     +--> CloudWatch Logs
```

Firehose sigue archivando los eventos crudos en S3. Flink agrega una segunda rama de consumo para calcular metricas stateful en tiempo real sin reemplazar la ingesta anterior.

## Logica de negocio

Los eventos mantienen el contrato de la entrega 2:

```json
{
  "event_id": "2bde09ca-3d01-478f-9af3-d40a67b18ff0",
  "event_type": "page_view",
  "user_id": "user-0001",
  "sequence": 42,
  "created_at": "2026-11-03T15:20:12.123Z"
}
```

El job realiza lo siguiente:

1. Consume y deserializa JSON desde `terraform-kinesis-dev` mediante el conector Kinesis para Flink 1.20.
2. Usa `created_at` como event time y genera watermarks con 10 segundos de desorden permitido.
3. Marca shards sin actividad como idle despues de 30 segundos para que no bloqueen el avance del watermark global.
4. Mantiene un `ValueState<Long>` por `user_id` con el total procesado para ese usuario.
5. Agrupa por `user_id + event_type` en ventanas tumbling de 60 segundos.
6. Acepta 30 segundos adicionales de lateness y envia eventos definitivamente tardios al side output `LATE_EVENT`.
7. Escribe cada metrica como JSON en CloudWatch Logs con el prefijo `WINDOW_METRIC`.

Ejemplo de salida:

```json
{
  "metric_type": "user_event_count",
  "user_id": "user-0001",
  "event_type": "page_view",
  "window_start": "2026-11-03T15:20:00Z",
  "window_end": "2026-11-03T15:21:00Z",
  "event_count": 7,
  "last_sequence": 42,
  "user_running_count": 18
}
```

## Estructura incremental

```text
Bootstrap/                       Backend remoto S3 de Terraform (entrega 2)
environments/dev/                Composicion unica del ambiente
modules/network/                 VPC, subredes y endpoint S3 (entrega 2)
modules/identity/                Roles de procesamiento/auditoria (entrega 2)
modules/storage/                 Data Lake S3 cifrado y versionado (entrega 2)
modules/kinesis/                 Kinesis, KMS, Firehose y alarmas (entrega 2)
modules/managed-flink/           S3 de artefactos, IAM, logs y Managed Flink
application/                     Aplicacion Java y pruebas unitarias
scripts/producer.py              Productor compatible con el contrato anterior
scripts/collect-evidence.ps1     Recoleccion de estado y logs
evidencia-s3.txt                 Evidencia historica de la entrega 2 en LocalStack
evidence/                        Evidencia real de esta entrega
```

El archivo [evidencia-s3.txt](evidencia-s3.txt) se conserva como evidencia historica del recorrido Kinesis/Firehose/S3 hecho en la entrega 2. La evidencia de Managed Flink debe generarse en AWS real.

## Infraestructura integrada

Un unico `terraform apply` en `environments/dev` crea:

- La infraestructura base de red e identidad.
- Un Data Lake privado, versionado y cifrado.
- Kinesis Data Stream con dos shards y cifrado KMS.
- Firehose hacia la capa Bronze de S3.
- Alarmas de throughput de Kinesis.
- Bucket privado/versionado para el fat JAR.
- Rol de ejecucion de Flink con permisos minimos sobre Kinesis, KMS, S3 y CloudWatch.
- `aws_kinesisanalyticsv2_application` con checkpoints, snapshots, monitoring y paralelismo.

El modulo Kinesis ahora expone `stream_arn` y `kms_key_arn`; esas salidas alimentan directamente al modulo Managed Flink. No se busca ni se duplica un stream externo.

## Checkpoints y snapshots

La aplicacion configura:

| Parametro | Valor |
|---|---:|
| Checkpointing | habilitado |
| Intervalo | 60 segundos |
| Pausa minima | 5 segundos |
| Modo administrado | exactly-once |
| Snapshots automaticos | habilitados |
| Restore | ultimo snapshot |

Amazon Managed Service for Apache Flink almacena checkpoints y savepoints durables en un bucket S3 propiedad del servicio. La API no permite elegir una ruta S3 propia para checkpoints. El bucket creado por `modules/managed-flink` contiene el JAR versionado, no los checkpoints.

Los operadores tienen `uid` estables para que Flink pueda mapear su estado durante actualizaciones y restores.

## Paralelismo y KPUs

| Parametro | Valor | Motivo |
|---|---:|---|
| Shards Kinesis | 2 | Configuracion conservada de la entrega 2 |
| `parallelism` | 2 | Una subtarea de source por shard |
| `parallelism_per_kpu` | 2 | Configuracion economica de desarrollo |
| KPUs iniciales | 1 | `ceil(2 / 2)` |
| Auto scaling | deshabilitado | Costos y comportamiento reproducibles |

La aplicacion no se conecta a la VPC porque solo consume servicios AWS administrados. La VPC de la entrega 2 se conserva para futuras fuentes/sinks privados. Si se agrega una base de datos privada, debe configurarse `vpc_configuration` y la salida correspondiente mediante NAT o VPC endpoints.

## Diferencia con la validacion anterior en LocalStack

La pre-entrega 2 se valido con LocalStack. Managed Service for Apache Flink y su dashboard no estan emulados de forma suficiente para esta entrega, por lo que el ambiente `environments/dev` fue adecuado para AWS real:

- Se eliminaron credenciales `test` y endpoints `localhost:4566` del provider.
- Los nombres de buckets incluyen el ID de cuenta para evitar colisiones globales.
- El backend S3 se configura mediante `backend.hcl` y locking nativo (`use_lockfile`).
- La aplicacion se puede dejar detenida con `start_application = false` para evitar consumo de KPUs.

## Requisitos

- Cuenta AWS y AWS CLI v2 autenticada.
- Terraform 1.5 o superior.
- JDK 11 o 17 y Maven 3.9.
- Python 3.11.

## 1. Construir y probar la aplicacion

```powershell
cd application
mvn clean verify
cd ..
```

El artefacto queda en:

```text
application/target/realtime-metrics-flink-1.0.0.jar
```

## 2. Crear el backend remoto

```powershell
cd Bootstrap
Copy-Item terraform.tfvars.example terraform.tfvars
# Editar state_bucket_name con un nombre globalmente unico.
terraform init
terraform validate
terraform plan -out=bootstrap.tfplan
terraform apply bootstrap.tfplan
cd ..
```

## 3. Configurar el ambiente

```powershell
cd environments\dev
Copy-Item backend.hcl.example backend.hcl
Copy-Item terraform.tfvars.example terraform.tfvars
```

Reemplazar el ID `123456789012` en ambos archivos y decidir si `start_application` debe ser `true`. Iniciar la aplicacion genera consumo facturable de KPUs.

## 4. Desplegar la infraestructura completa

```powershell
terraform init -backend-config=backend.hcl -reconfigure
terraform fmt -check -recursive
terraform validate
terraform plan -out=dev.tfplan
terraform apply dev.tfplan
```

## 5. Generar trafico con desorden temporal

```powershell
cd ..\..
python -m pip install -r scripts\requirements.txt
python scripts\producer.py --records 120 --users 10 --late-every 10
```

Para producir eventos definitivamente tardios cuando el watermark ya avanzo:

```powershell
python scripts\producer.py --records 20 --late-every 1 --late-seconds 120
```

## 6. Validar y recolectar evidencia

```powershell
aws kinesisanalyticsv2 describe-application `
  --application-name coderhouse-dev-realtime-metrics `
  --query "ApplicationDetail.[ApplicationStatus,RuntimeEnvironment]"

.\scripts\collect-evidence.ps1
```

En AWS Console abrir **Managed Service for Apache Flink > coderhouse-dev-realtime-metrics > Apache Flink dashboard** y capturar:

- El grafo con `Kinesis source`, `KeyedState: running count by user` y `Tumbling event-time count`.
- Checkpoints completados.
- Registros `WINDOW_METRIC` en CloudWatch.

Las instrucciones de sanitizacion y nombres de archivos estan en [evidence/README.md](evidence/README.md).

## Costos y limpieza

Managed Flink, Kinesis, Firehose, CloudWatch y S3 pueden generar cargos. Despues de capturar la evidencia:

```powershell
cd environments\dev
terraform destroy
```

No destruir `Bootstrap` mientras el backend siga almacenando estados Terraform.

## Referencias

- [Managed Service for Apache Flink: configuracion y state backend](https://docs.aws.amazon.com/managed-flink/latest/java/reference-flink-settings.title.html)
- [Managed Service for Apache Flink: tolerancia a fallos](https://docs.aws.amazon.com/managed-flink/latest/java/how-fault.html)
- [Terraform: aws_kinesisanalyticsv2_application](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/kinesisanalyticsv2_application)
