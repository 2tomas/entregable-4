package ar.edu.coderhouse.flink.window;

import ar.edu.coderhouse.flink.model.EnrichedEvent;
import org.apache.flink.api.common.functions.AggregateFunction;

public class EventCountAggregate implements AggregateFunction<EnrichedEvent, EventAccumulator, EventAccumulator> {
    private static final long serialVersionUID = 1L;

    @Override
    public EventAccumulator createAccumulator() {
        return new EventAccumulator();
    }

    @Override
    public EventAccumulator add(EnrichedEvent value, EventAccumulator accumulator) {
        accumulator.setUserId(value.getEvent().getUserId());
        accumulator.setEventType(value.getEvent().getEventType());
        accumulator.setCount(accumulator.getCount() + 1L);
        accumulator.setMaxSequence(Math.max(accumulator.getMaxSequence(), value.getEvent().getSequence()));
        accumulator.setMaxRunningCount(Math.max(accumulator.getMaxRunningCount(), value.getUserRunningCount()));
        return accumulator;
    }

    @Override
    public EventAccumulator getResult(EventAccumulator accumulator) {
        return accumulator;
    }

    @Override
    public EventAccumulator merge(EventAccumulator left, EventAccumulator right) {
        EventAccumulator merged = new EventAccumulator();
        merged.setUserId(left.getUserId() != null ? left.getUserId() : right.getUserId());
        merged.setEventType(left.getEventType() != null ? left.getEventType() : right.getEventType());
        merged.setCount(left.getCount() + right.getCount());
        merged.setMaxSequence(Math.max(left.getMaxSequence(), right.getMaxSequence()));
        merged.setMaxRunningCount(Math.max(left.getMaxRunningCount(), right.getMaxRunningCount()));
        return merged;
    }
}
