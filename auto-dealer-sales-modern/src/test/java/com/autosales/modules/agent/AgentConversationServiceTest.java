package com.autosales.modules.agent;

import com.autosales.modules.agent.entity.AgentConversation;
import com.autosales.modules.agent.entity.AgentMessageEntity;
import com.autosales.modules.agent.repository.AgentConversationRepository;
import com.autosales.modules.agent.repository.AgentMessageRepository;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.ArgumentCaptor;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

import java.util.ArrayList;
import java.util.List;
import java.util.Map;
import java.util.Optional;

import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.*;

@ExtendWith(MockitoExtension.class)
class AgentConversationServiceTest {

    @Mock private AgentConversationRepository conversationRepo;
    @Mock private AgentMessageRepository messageRepo;
    @InjectMocks private AgentConversationService service;

    @Test
    void create_assignsUuidAndDerivesTitleFromFirstMessage() {
        when(conversationRepo.save(any(AgentConversation.class))).thenAnswer(inv -> inv.getArgument(0));

        AgentConversation conv = service.create("ADMIN001", "DLR01", "claude-sonnet-4-6",
                "List dealers with aging over 60 days please");

        assertNotNull(conv.getConversationId());
        assertEquals(36, conv.getConversationId().length());
        assertEquals("ADMIN001", conv.getUserId());
        assertEquals("DLR01", conv.getDealerCode());
        assertEquals("List dealers with aging over 60 days please", conv.getTitle());
        assertEquals(0, conv.getTurnCount());
        assertEquals(0, conv.getTokenTotal());
    }

    @Test
    void create_truncatesLongTitles() {
        when(conversationRepo.save(any(AgentConversation.class))).thenAnswer(inv -> inv.getArgument(0));

        String longMsg = "a".repeat(200);
        AgentConversation conv = service.create("U1", null, "m", longMsg);

        assertEquals(58, conv.getTitle().length());
        assertTrue(conv.getTitle().endsWith("…"));
        assertTrue(conv.getTitle().startsWith("a".repeat(57)));
    }

    @Test
    void loadReplayMessages_capsToMaxReplayTurns() {
        // 50 messages in DB; replay should cap to last 20
        List<AgentMessageEntity> all = new ArrayList<>();
        for (int i = 0; i < 50; i++) {
            all.add(AgentMessageEntity.builder()
                    .conversationId("c1").role(i % 2 == 0 ? "user" : "assistant")
                    .content("msg" + i).seq(i).build());
        }
        when(messageRepo.findByConversationIdOrderBySeqAsc("c1")).thenReturn(all);

        List<Map<String, Object>> replay = service.loadReplayMessages("c1");

        assertEquals(20, replay.size());
        assertEquals("msg30", replay.get(0).get("content"));
        assertEquals("msg49", replay.get(19).get("content"));
    }

    @Test
    void loadReplayMessages_returnsAllWhenUnderCap() {
        List<AgentMessageEntity> all = new ArrayList<>();
        for (int i = 0; i < 4; i++) {
            all.add(AgentMessageEntity.builder()
                    .conversationId("c1").role("user").content("m" + i).seq(i).build());
        }
        when(messageRepo.findByConversationIdOrderBySeqAsc("c1")).thenReturn(all);

        List<Map<String, Object>> replay = service.loadReplayMessages("c1");
        assertEquals(4, replay.size());
    }

    @Test
    void appendTurn_savesBothRolesAndIncrementsCounters() {
        AgentConversation conv = AgentConversation.builder()
                .conversationId("c1").userId("U1").model("m")
                .title("t").turnCount(2).tokenTotal(500).build();
        when(conversationRepo.findById("c1")).thenReturn(Optional.of(conv));
        when(messageRepo.countByConversationId("c1")).thenReturn(4L);

        service.appendTurn("c1", "hello", "hi there", 123);

        ArgumentCaptor<AgentMessageEntity> msgCap = ArgumentCaptor.forClass(AgentMessageEntity.class);
        verify(messageRepo, times(2)).save(msgCap.capture());
        List<AgentMessageEntity> saved = msgCap.getAllValues();

        assertEquals("user", saved.get(0).getRole());
        assertEquals("hello", saved.get(0).getContent());
        assertEquals(4, saved.get(0).getSeq());
        assertEquals("assistant", saved.get(1).getRole());
        assertEquals("hi there", saved.get(1).getContent());
        assertEquals(5, saved.get(1).getSeq());

        assertEquals(3, conv.getTurnCount());
        assertEquals(623, conv.getTokenTotal());
        verify(conversationRepo).save(conv);
    }

    @Test
    void appendTurn_clampsNegativeTokensToZero() {
        AgentConversation conv = AgentConversation.builder()
                .conversationId("c1").userId("U1").model("m")
                .title("t").turnCount(0).tokenTotal(100).build();
        when(conversationRepo.findById("c1")).thenReturn(Optional.of(conv));
        when(messageRepo.countByConversationId("c1")).thenReturn(0L);

        service.appendTurn("c1", "q", "a", -50);

        assertEquals(100, conv.getTokenTotal());
    }

    @Test
    void appendTurn_throwsWhenConversationMissing() {
        when(conversationRepo.findById("nope")).thenReturn(Optional.empty());
        assertThrows(IllegalArgumentException.class,
                () -> service.appendTurn("nope", "q", "a", 10));
    }

    @Test
    void delete_removesMessagesThenConversation() {
        service.delete("c1");
        verify(messageRepo).deleteByConversationId("c1");
        verify(conversationRepo).deleteById("c1");
    }

    @Test
    void listForUser_delegatesToRepository() {
        List<AgentConversation> expected = List.of(
                AgentConversation.builder().conversationId("a").userId("U1").build());
        when(conversationRepo.findByUserIdOrderByUpdatedTsDesc("U1")).thenReturn(expected);
        assertSame(expected, service.listForUser("U1"));
    }
}
