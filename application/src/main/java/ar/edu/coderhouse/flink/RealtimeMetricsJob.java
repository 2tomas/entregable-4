package ar.edu.coderhouse.flink;

import ar.edu.coderhouse.flink.model.EnrichedEvent;
import ar.edu.coderhouse.flink.model.PageViewEvent;
import ar.edu.coderhouse.flink.model.WindowMetric;
import ar.edu.coderhouse.flink.serde.EventParser;
import ar.edu.coderhouse.flink.serde.MetricToJson;
import ar.edu.coderhouse.flink.sink.CloudWatchLogSink;
import ar.edu.coderhouse.flink.state.UserRunningCountFunction;
import ar.edu.coderhouse.flink.window.EventCountAggregate;
import ar.edu.coderhouse.flink.window.EventWindowResult;
import com.amazonaws.services.kinesisanalytics.runtime.KinesisAnalyticsRuntime;
import org.apache.flink.api.common.eventtime.WatermarkStrategy;
import org.apache.flink.api.common.serialization.SimpleStringSchema;
import org.apache.flink.api.common.typeinfo.Types;
import org.apache.flink.configuration.Configuration;
import org.apache.flink.connector.kinesis.source.KinesisStreamsSource;
import org.apache.flink.connector.kinesis.source.config.KinesisSourceConfigOptions;
import org.apache.flink.streaming.api.datastream.DataStream;
import org.apache.flink.streaming.api.datastream.SingleOutputStreamOperator;
import org.apache.flink.streaming.api.environment.StreamExecutionEnvironment;
import org.apache.flink.streaming.api.windowing.assigners.TumblingEventTimeWindows;
import org.apache.flink.streaming.api.windowing.time.Time;
import org.apache.flink.util.OutputTag;

import java.io.IOException;
import java.time.Duration;
import java.util.Map;
import java.util.Properties;

public final class RealtimeMetricsJob {
    private static final String PROPERTY_GROUP_ID = "InputProperties";
    private static final OutputTag<EnrichedEvent> LATE_EVENTS =
            new OutputTag<EnrichedEvent>("late-events") { };

    private RealtimeMetricsJob() {
    }

    public static void main(String[] args) throws Exception {
        Properties properties = loadApplicationProperties();
        String streamArn = required(properties, "stream.arn");

        long outOfOrderSeconds = positiveLong(properties, "watermark.out.of.orderness.seconds", 10L);
        long idleSeconds = positiveLong(properties, "watermark.idleness.seconds", 30L);
        long windowSeconds = positiveLong(properties, "window.size.seconds", 60L);
        long allowedLatenessSeconds = positiveLong(properties, "window.allowed.lateness.seconds", 30L);
        int sourceParallelism = Math.toIntExact(positiveLong(properties, "source.parallelism", 2L));

        StreamExecutionEnvironment environment = StreamExecutionEnvironment.getExecutionEnvironment();

        Configuration sourceConfiguration = new Configuration();
        sourceConfiguration.set(
                KinesisSourceConfigOptions.READER_TYPE,
                KinesisSourceConfigOptions.ReaderType.POLLING
        );
        sourceConfiguration.set(
                KinesisSourceConfigOptions.STREAM_INITIAL_POSITION,
                KinesisSourceConfigOptions.InitialPosition.valueOf(
                        properties.getProperty("stream.initial.position", "LATEST").toUpperCase()
                )
        );

        KinesisStreamsSource<String> source = KinesisStreamsSource.<String>builder()
                .setStreamArn(streamArn)
                .setDeserializationSchema(new SimpleStringSchema())
                .setSourceConfig(sourceConfiguration)
                .build();

        DataStream<String> rawEvents = environment
                .fromSource(
                        source,
                        WatermarkStrategy.noWatermarks(),
                        "kinesis-source",
                        Types.STRING
                )
                .name("Kinesis source")
                .uid("kinesis-source-v1")
                .setParallelism(sourceParallelism);

        SingleOutputStreamOperator<PageViewEvent> timestampedEvents = rawEvents
                .flatMap(new EventParser())
                .name("Deserialize and validate JSON")
                .uid("json-parser-v1")
                .assignTimestampsAndWatermarks(
                        WatermarkStrategy.<PageViewEvent>forBoundedOutOfOrderness(
                                        Duration.ofSeconds(outOfOrderSeconds))
                                .withTimestampAssigner((event, previousTimestamp) -> event.eventTimestampMillis())
                                .withIdleness(Duration.ofSeconds(idleSeconds))
                )
                .name("Event-time watermarks")
                .uid("event-time-watermarks-v1");

        SingleOutputStreamOperator<EnrichedEvent> statefulEvents = timestampedEvents
                .keyBy(PageViewEvent::getUserId)
                .process(new UserRunningCountFunction())
                .name("KeyedState: running count by user")
                .uid("user-running-count-v1");

        SingleOutputStreamOperator<WindowMetric> metrics = statefulEvents
                .keyBy(event -> event.getEvent().metricKey())
                .window(TumblingEventTimeWindows.of(Time.seconds(windowSeconds)))
                .allowedLateness(Time.seconds(allowedLatenessSeconds))
                .sideOutputLateData(LATE_EVENTS)
                .aggregate(new EventCountAggregate(), new EventWindowResult())
                .name("Tumbling event-time count")
                .uid("tumbling-user-event-count-v1");

        metrics
                .map(new MetricToJson())
                .name("Serialize metric")
                .uid("metric-json-v1")
                .addSink(new CloudWatchLogSink("WINDOW_METRIC"))
                .name("CloudWatch metric log")
                .uid("metric-log-v1");

        metrics.getSideOutput(LATE_EVENTS)
                .map(event -> "LATE_EVENT event_id=" + event.getEvent().getEventId()
                        + " created_at=" + event.getEvent().getCreatedAt())
                .returns(String.class)
                .name("Format late event")
                .uid("late-event-format-v1")
                .addSink(new CloudWatchLogSink("LATE_EVENT"))
                .name("CloudWatch late-event log")
                .uid("late-event-log-v1");

        environment.execute("Coderhouse realtime user metrics");
    }

    private static Properties loadApplicationProperties() throws IOException {
        Map<String, Properties> groups = KinesisAnalyticsRuntime.getApplicationProperties();
        Properties properties = groups.get(PROPERTY_GROUP_ID);
        if (properties == null) {
            throw new IllegalStateException("No existe el property group " + PROPERTY_GROUP_ID);
        }
        return properties;
    }

    private static String required(Properties properties, String key) {
        String value = properties.getProperty(key);
        if (value == null || value.trim().isEmpty()) {
            throw new IllegalArgumentException("Falta la propiedad requerida: " + key);
        }
        return value;
    }

    private static long positiveLong(Properties properties, String key, long defaultValue) {
        long value = Long.parseLong(properties.getProperty(key, Long.toString(defaultValue)));
        if (value < 1) {
            throw new IllegalArgumentException(key + " debe ser mayor que cero");
        }
        return value;
    }
}
