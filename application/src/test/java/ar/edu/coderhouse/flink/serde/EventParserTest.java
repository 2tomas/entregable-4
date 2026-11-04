package ar.edu.coderhouse.flink.serde;

import ar.edu.coderhouse.flink.model.PageViewEvent;
import org.apache.flink.util.Collector;
import org.junit.jupiter.api.Test;

import java.util.ArrayList;
import java.util.List;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertTrue;

class EventParserTest {
    private final EventParser parser = new EventParser();

    @Test
    void parsesValidEventAndUsesCreatedAtAsEventTime() {
        List<PageViewEvent> output = new ArrayList<>();
        String json = "{\"event_id\":\"evt-1\",\"event_type\":\"page_view\","
                + "\"user_id\":\"user-1\",\"sequence\":7,"
                + "\"created_at\":\"2026-11-03T12:00:05Z\"}";

        parser.flatMap(json, collector(output));

        assertEquals(1, output.size());
        assertEquals("user-1", output.get(0).getUserId());
        assertEquals(7L, output.get(0).getSequence());
        assertEquals(1793707205000L, output.get(0).eventTimestampMillis());
    }

    @Test
    void discardsMalformedEventWithoutFailingTheJob() {
        List<PageViewEvent> output = new ArrayList<>();

        parser.flatMap("{not-json}", collector(output));

        assertTrue(output.isEmpty());
    }

    private static Collector<PageViewEvent> collector(List<PageViewEvent> output) {
        return new Collector<PageViewEvent>() {
            @Override
            public void collect(PageViewEvent event) {
                output.add(event);
            }

            @Override
            public void close() {
            }
        };
    }
}
