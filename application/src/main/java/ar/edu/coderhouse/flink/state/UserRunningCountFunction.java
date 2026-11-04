package ar.edu.coderhouse.flink.state;

import ar.edu.coderhouse.flink.model.EnrichedEvent;
import ar.edu.coderhouse.flink.model.PageViewEvent;
import org.apache.flink.api.common.state.ValueState;
import org.apache.flink.api.common.state.ValueStateDescriptor;
import org.apache.flink.configuration.Configuration;
import org.apache.flink.streaming.api.functions.KeyedProcessFunction;
import org.apache.flink.util.Collector;

public class UserRunningCountFunction extends KeyedProcessFunction<String, PageViewEvent, EnrichedEvent> {
    private static final long serialVersionUID = 1L;

    private transient ValueState<Long> runningCount;

    @Override
    public void open(Configuration parameters) {
        ValueStateDescriptor<Long> descriptor = new ValueStateDescriptor<>(
                "user-running-event-count",
                Long.class
        );
        runningCount = getRuntimeContext().getState(descriptor);
    }

    @Override
    public void processElement(PageViewEvent event, Context context, Collector<EnrichedEvent> output)
            throws Exception {
        Long current = runningCount.value();
        long updated = (current == null ? 0L : current) + 1L;
        runningCount.update(updated);
        output.collect(new EnrichedEvent(event, updated));
    }
}
