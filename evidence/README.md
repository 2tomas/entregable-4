## Evidencia recopilada

- [Flink - running job.png](<Flink - running job.png>): captura del grafo en estado `RUNNING`.
- `application.json`: respuesta de `aws kinesisanalyticsv2 describe-application`.
- `window-metrics.json`: eventos `WINDOW_METRIC` reales recuperados de CloudWatch Logs.
- `checkpoints.json`: checkpoints completados recuperados de CloudWatch Logs.

Los eventos de entrada fueron generados por `scripts/producer.py`. Por seguridad, los JSON reemplazan el ID real de la cuenta y los ARN asociados por el ID ficticio `482731905614`.
