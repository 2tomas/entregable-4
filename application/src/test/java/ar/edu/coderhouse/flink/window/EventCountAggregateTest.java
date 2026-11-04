package ar.edu.coderhouse.flink.window;

import ar.edu.coderhouse.flink.model.EnrichedEvent;
import ar.edu.coderhouse.flink.model.PageViewEvent;
import org.junit.jupiter.api.Test;

import java.time.Instant;

import static org.junit.jupiter.api.Assertions.assertEquals;

class EventCountAggregateTest {
    @Test
    void accumulatesWindowMetrics() {
        EventCountAggregate aggregate = new EventCountAggregate();
        EventAccumulator accumulator = aggregate.createAccumulator();

        aggregate.add(event(2L, 8L), accumulator);
        aggregate.add(event(3L, 9L), accumulator);

        EventAccumulator result = aggregate.getResult(accumulator);
        assertEquals("user-1", result.getUserId());
        assertEquals("page_view", result.getEventType());
        assertEquals(2L, result.getCount());
        assertEquals(3L, result.getMaxSequence());
        assertEquals(9L, result.getMaxRunningCount());
    }

    private static EnrichedEvent event(long sequence, long runningCount) {
        return new EnrichedEvent(
                new PageViewEvent(
                        "evt-" + sequence,
                        "page_view",
                        "user-1",
                        sequence,
                        Instant.parse("2026-11-03T12:00:05Z")
                ),
                runningCount
        );
    }
}
