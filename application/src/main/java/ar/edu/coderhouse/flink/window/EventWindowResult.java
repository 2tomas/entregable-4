package ar.edu.coderhouse.flink.window;

import ar.edu.coderhouse.flink.model.WindowMetric;
import org.apache.flink.streaming.api.functions.windowing.ProcessWindowFunction;
import org.apache.flink.streaming.api.windowing.windows.TimeWindow;
import org.apache.flink.util.Collector;

import java.time.Instant;

public class EventWindowResult extends ProcessWindowFunction<EventAccumulator, WindowMetric, String, TimeWindow> {
    private static final long serialVersionUID = 1L;

    @Override
    public void process(
            String key,
            Context context,
            Iterable<EventAccumulator> values,
            Collector<WindowMetric> output) {
        EventAccumulator accumulator = values.iterator().next();
        output.collect(new WindowMetric(
                accumulator.getUserId(),
                accumulator.getEventType(),
                Instant.ofEpochMilli(context.window().getStart()),
                Instant.ofEpochMilli(context.window().getEnd()),
                accumulator.getCount(),
                accumulator.getMaxSequence(),
                accumulator.getMaxRunningCount()
        ));
    }
}
