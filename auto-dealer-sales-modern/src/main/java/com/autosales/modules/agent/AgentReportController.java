package com.autosales.modules.agent;

import com.openhtmltopdf.pdfboxout.PdfRendererBuilder;
import org.commonmark.Extension;
import org.commonmark.ext.gfm.tables.TablesExtension;
import org.commonmark.node.Node;
import org.commonmark.parser.Parser;
import org.commonmark.renderer.html.HtmlRenderer;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.http.HttpHeaders;
import org.springframework.http.MediaType;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;

import java.io.ByteArrayOutputStream;
import java.time.LocalDateTime;
import java.time.format.DateTimeFormatter;
import java.util.List;

/**
 * Renders an agent reply (markdown) to a PDF blob. Used by the frontend
 * Download/Email actions — markdown posted in, PDF bytes returned.
 */
@RestController
@RequestMapping("/api/agent/report")
@PreAuthorize("hasAnyRole('ADMIN','MANAGER','SALESPERSON','FINANCE','CLERK','OPERATOR')")
public class AgentReportController {

    private static final Logger log = LoggerFactory.getLogger(AgentReportController.class);
    private static final DateTimeFormatter FILENAME_FMT = DateTimeFormatter.ofPattern("yyyyMMdd-HHmm");

    private final Parser mdParser;
    private final HtmlRenderer htmlRenderer;

    public AgentReportController() {
        List<Extension> extensions = List.of(TablesExtension.create());
        this.mdParser = Parser.builder().extensions(extensions).build();
        this.htmlRenderer = HtmlRenderer.builder().extensions(extensions).build();
    }

    public record ReportRequest(String markdown, String generatedAt, String userPrompt) {}

    @PostMapping(value = "/pdf", produces = MediaType.APPLICATION_PDF_VALUE)
    public ResponseEntity<byte[]> pdf(@RequestBody ReportRequest request) {
        String markdown = request.markdown() == null ? "" : request.markdown();
        String generatedAt = request.generatedAt() != null && !request.generatedAt().isBlank()
                ? request.generatedAt()
                : LocalDateTime.now().toString();
        String userPrompt = request.userPrompt() == null ? "" : request.userPrompt();

        Node mdRoot = mdParser.parse(markdown);
        String bodyHtml = htmlRenderer.render(mdRoot);
        String fullHtml = wrap(bodyHtml, generatedAt, userPrompt);

        try (ByteArrayOutputStream os = new ByteArrayOutputStream()) {
            PdfRendererBuilder builder = new PdfRendererBuilder();
            builder.useFastMode();
            builder.withHtmlContent(fullHtml, null);
            builder.toStream(os);
            builder.run();

            byte[] pdfBytes = os.toByteArray();
            String filename = "autosales-agent-" + LocalDateTime.now().format(FILENAME_FMT) + ".pdf";
            HttpHeaders headers = new HttpHeaders();
            headers.setContentType(MediaType.APPLICATION_PDF);
            headers.setContentDispositionFormData("attachment", filename);
            return ResponseEntity.ok().headers(headers).body(pdfBytes);
        } catch (Exception e) {
            log.error("PDF render failed", e);
            return ResponseEntity.status(500).build();
        }
    }

    private String wrap(String bodyHtml, String generatedAt, String userPrompt) {
        StringBuilder promptBlock = new StringBuilder();
        if (!userPrompt.isBlank()) {
            promptBlock.append("<div class=\"prompt-block\">")
                    .append("<p class=\"prompt-label\">User Request</p>")
                    .append("<p class=\"prompt-text\">").append(escape(userPrompt)).append("</p>")
                    .append("</div>")
                    .append("<p class=\"section-label\">Agent Response</p>");
        }

        return "<!DOCTYPE html><html><head><meta charset=\"UTF-8\"/>"
                + "<style>"
                + "@page { size: A4; margin: 18mm 14mm 18mm 14mm; }"
                + "body { font-family: 'Helvetica', 'Arial', sans-serif; font-size: 10.5pt; color: #1f2937; line-height: 1.5; }"
                + "h1 { color: #5b21b6; font-size: 18pt; border-bottom: 2px solid #ddd6fe; padding-bottom: 4pt; margin-top: 14pt; margin-bottom: 6pt; }"
                + "h2 { color: #5b21b6; font-size: 14pt; margin-top: 12pt; margin-bottom: 4pt; }"
                + "h3 { color: #5b21b6; font-size: 12pt; margin-top: 10pt; margin-bottom: 4pt; }"
                + "p { margin: 6pt 0; }"
                + "ul, ol { margin: 6pt 0; padding-left: 18pt; }"
                + "li { margin: 2pt 0; }"
                + "table { border-collapse: collapse; width: 100%; margin: 8pt 0; font-size: 9pt; }"
                + "th { background: #f5f3ff; color: #5b21b6; text-align: left; border: 1px solid #ddd6fe; padding: 4pt 6pt; font-weight: bold; }"
                + "td { border: 1px solid #e5e7eb; padding: 3pt 6pt; vertical-align: top; }"
                + "code { background: #f5f3ff; padding: 1pt 3pt; font-family: 'Courier New', monospace; font-size: 9pt; }"
                + "pre { background: #f5f3ff; padding: 6pt; font-family: 'Courier New', monospace; font-size: 9pt; }"
                + "blockquote { border-left: 3px solid #a78bfa; padding: 2pt 8pt; color: #4b5563; margin: 8pt 0; }"
                + "hr { border: none; border-top: 1px solid #e5e7eb; margin: 10pt 0; }"
                + ".header { border-bottom: 2px solid #ddd6fe; padding-bottom: 6pt; margin-bottom: 12pt; }"
                + ".title { font-size: 16pt; font-weight: bold; color: #5b21b6; margin: 0; }"
                + ".meta { font-size: 9pt; color: #6b7280; margin-top: 2pt; }"
                + ".prompt-block { background: #faf5ff; border-left: 3px solid #a78bfa; padding: 8pt 10pt; margin-bottom: 12pt; }"
                + ".prompt-label { font-size: 9pt; font-weight: bold; color: #5b21b6; text-transform: uppercase; letter-spacing: 0.5pt; margin: 0 0 3pt 0; }"
                + ".prompt-text { font-size: 11pt; color: #1f2937; font-style: italic; margin: 0; }"
                + ".section-label { font-size: 9pt; font-weight: bold; color: #5b21b6; text-transform: uppercase; letter-spacing: 0.5pt; margin: 0 0 6pt 0; border-bottom: 1px solid #ddd6fe; padding-bottom: 3pt; }"
                + "</style></head><body>"
                + "<div class=\"header\">"
                + "<p class=\"title\">AutoSales Agent Report</p>"
                + "<p class=\"meta\">Generated " + escape(generatedAt) + " &#183; AutoSales Agent (Claude Sonnet 4.6)</p>"
                + "</div>"
                + promptBlock
                + bodyHtml
                + "</body></html>";
    }

    private String escape(String s) {
        return s.replace("&", "&amp;").replace("<", "&lt;").replace(">", "&gt;");
    }
}
