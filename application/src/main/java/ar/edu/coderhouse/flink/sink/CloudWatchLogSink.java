package ar.edu.coderhouse.flink.sink;

import org.apache.flink.streaming.api.functions.sink.RichSinkFunction;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

/**
 * Writes job results through SLF4J so Managed Service for Apache Flink forwards
 * them to the configured CloudWatch log stream. The managed runtime can ignore
 * System.out, which makes DataStream#print unsuitable for execution evidence.
 */
public final class CloudWatchLogSink extends RichSinkFunction<String> {
    private static final Logger LOG = LoggerFactory.getLogger(CloudWatchLogSink.class);

    private final String prefix;

    public CloudWatchLogSink(String prefix) {
        this.prefix = prefix;
    }

    @Override
    public void invoke(String value, Context context) {
        LOG.info("{} {}", prefix, value);
    }
}
