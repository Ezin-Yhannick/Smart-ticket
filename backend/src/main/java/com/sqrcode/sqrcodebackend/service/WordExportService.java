package com.sqrcode.sqrcodebackend.service;

import com.google.zxing.BarcodeFormat;
import com.google.zxing.client.j2se.MatrixToImageConfig;
import com.google.zxing.client.j2se.MatrixToImageWriter;
import com.google.zxing.common.BitMatrix;
import com.google.zxing.qrcode.QRCodeWriter;
import com.sqrcode.sqrcodebackend.entity.Event;
import com.sqrcode.sqrcodebackend.entity.Ticket;
import com.sqrcode.sqrcodebackend.entity.TicketCategory;
import com.sqrcode.sqrcodebackend.repository.EventRepository;
import com.sqrcode.sqrcodebackend.repository.TicketCategoryRepository;
import com.sqrcode.sqrcodebackend.repository.TicketRepository;
import lombok.RequiredArgsConstructor;
import org.apache.poi.util.Units;
import org.apache.poi.xwpf.usermodel.*;
import org.openxmlformats.schemas.wordprocessingml.x2006.main.*;
import org.springframework.stereotype.Service;

import java.io.ByteArrayInputStream;
import java.io.ByteArrayOutputStream;
import java.math.BigInteger;
import java.time.LocalDate;
import java.time.format.DateTimeFormatter;
import java.util.List;
import java.util.Locale;

@Service
@RequiredArgsConstructor
public class WordExportService {

    private final EventRepository eventRepository;
    private final TicketRepository ticketRepository;
    private final TicketCategoryRepository ticketCategoryRepository;

    private static final DateTimeFormatter DATE_FMT =
            DateTimeFormatter.ofPattern("dd MMM yyyy", Locale.FRENCH);

    // Dimensions en EMU (1mm = 36000 EMU)
    // Concert Large  : 210mm × 90mm
    // Standard       : 140mm × 50mm
    private static final long CONCERT_W = 210L * 36000;
    private static final long CONCERT_H = 90L  * 36000;
    private static final long STD_W     = 140L * 36000;
    private static final long STD_H     = 50L  * 36000;

    // Largeurs colonnes en DXA (1mm ≈ 56.7 DXA)
    // Concert  : info=7560 DXA (~133mm) | sep=56 (~1mm) | qr=2268 (~40mm) | stub=1134 (~20mm)
    // Standard : info=5670 DXA (~100mm) | sep=56        | qr=1701 (~30mm) | stub=850 (~15mm)
    private static final int[] CONCERT_COLS = {7560, 56, 2268, 1134};
    private static final int[] STD_COLS     = {5670, 56, 1701, 850};

    public byte[] exportTicketsToWord(Long eventId, String filterType,
                                      Long categoryId) throws Exception {

        Event event = eventRepository.findById(eventId)
                .orElseThrow(() -> new RuntimeException("Événement introuvable"));

        List<Ticket> tickets;
        if (categoryId != null) {
            TicketCategory cat = ticketCategoryRepository.findById(categoryId)
                    .orElseThrow(() -> new RuntimeException("Catégorie introuvable"));
            tickets = ticketRepository.findByEventAndCategory(event, cat);
        } else {
            tickets = ticketRepository.findByEvent(event);
        }

        if (filterType.equals("non_vendus")) {
            tickets = tickets.stream()
                    .filter(t -> t.getStatus() == Ticket.TicketStatus.NON_VENDU)
                    .toList();
        }

        boolean isConcert = event.getType().equalsIgnoreCase("concert")
                || event.getType().equalsIgnoreCase("festival");

        XWPFDocument doc = new XWPFDocument();

        // Page en paysage
        setPageLandscape(doc, isConcert);

        // En-tête discret
        XWPFParagraph header = doc.createParagraph();
        header.setAlignment(ParagraphAlignment.CENTER);
        header.setSpacingAfter(160);
        XWPFRun hr = header.createRun();
        hr.setText("SMART-TICKET  ·  "
                + event.getName().toUpperCase()
                + "  ·  " + tickets.size() + " ticket(s)");
        hr.setFontFamily("Helvetica");
        hr.setFontSize(8);
        hr.setColor("AAAAAA");
        hr.setBold(false);

        // Un ticket par ligne (format paysage oblige)
        for (Ticket ticket : tickets) {
            addTicketRow(doc, ticket, event, isConcert);
            // Espace entre tickets
            XWPFParagraph spacer = doc.createParagraph();
            spacer.setSpacingAfter(120);
        }

        ByteArrayOutputStream out = new ByteArrayOutputStream();
        doc.write(out);
        doc.close();
        return out.toByteArray();
    }

    // ══════════════════════════════════════════════════════
    // UN TICKET = UNE LIGNE DE TABLEAU (4 colonnes)
    // [INFOS] | [SÉPARATEUR] | [QR CODE] | [STUB]
    // ══════════════════════════════════════════════════════
    private void addTicketRow(XWPFDocument doc, Ticket ticket,
                              Event event, boolean isConcert) throws Exception {

        int[] cols = isConcert ? CONCERT_COLS : STD_COLS;
        int qrSizePt = isConcert ? 148 : 90; // taille QR en points (~mm)

        String hex    = ticket.getCategory().getColor().replaceAll("#", "");
        String cat    = ticket.getCategory().getName().toUpperCase();
        String price  = formatPrice(ticket.getPrice());
        String from   = ticket.getValidFrom().format(DATE_FMT);
        String to     = ticket.getValidTo().format(DATE_FMT);
        String serial = ticket.getSerialNumber();

        XWPFTable row = doc.createTable(1, 4);
        row.setWidth("100%");
        setTableBorders(row, "FFFFFF"); // bordure blanche = invisible

        // Cellule de largeur
        for (int i = 0; i < 4; i++) {
            setCellWidth(row.getRow(0).getCell(i), cols[i]);
        }

        // ── CELLULE 1 : INFOS ──
        XWPFTableCell infoCell = row.getRow(0).getCell(0);
        setCellBackground(infoCell, "FFFFFF");
        setCellBorderLeft(infoCell, hex, 30); // bande colorée à gauche
        setCellMargins(infoCell, 200, 200, 200, 300);

        if (isConcert) {
            buildConcertInfo(infoCell, event, cat, hex, price, from, to, serial);
        } else {
            buildStandardInfo(infoCell, event, cat, hex, price, from, to, serial);
        }

        // ── CELLULE 2 : SÉPARATEUR VERTICAL POINTILLÉ ──
        XWPFTableCell sepCell = row.getRow(0).getCell(1);
        setCellBackground(sepCell, "F5F5F5");
        // Ligne pointillée via bordures gauche/droite
        setCellBorderSide(sepCell, "DDDDDD", "left",  4);
        setCellBorderSide(sepCell, "DDDDDD", "right", 4);

        // ── CELLULE 3 : QR CODE ──
        XWPFTableCell qrCell = row.getRow(0).getCell(2);
        setCellBackground(qrCell, "FFFFFF");
        setCellMargins(qrCell, 150, 150, 150, 150);
        qrCell.setVerticalAlignment(XWPFTableCell.XWPFVertAlign.CENTER);

        byte[] qr = generateQRCode(ticket.getUuid(),
                isConcert ? 280 : 180);

        XWPFParagraph qrPara = qrCell.getParagraphs().get(0);
        qrPara.setAlignment(ParagraphAlignment.CENTER);
        qrPara.setSpacingBefore(0);
        qrPara.setSpacingAfter(40);
        XWPFRun qrRun = qrPara.createRun();
        qrRun.addPicture(
                new ByteArrayInputStream(qr),
                XWPFDocument.PICTURE_TYPE_PNG,
                ticket.getUuid(),
                Units.toEMU(qrSizePt),
                Units.toEMU(qrSizePt)
        );

        // Code court sous le QR
        XWPFParagraph codePara = qrCell.addParagraph();
        codePara.setAlignment(ParagraphAlignment.CENTER);
        codePara.setSpacingAfter(0);
        XWPFRun codeRun = codePara.createRun();
        codeRun.setText("Ticket Code");
        codeRun.setFontFamily("Helvetica");
        codeRun.setFontSize(6);
        codeRun.setColor("AAAAAA");

        XWPFParagraph uuidPara = qrCell.addParagraph();
        uuidPara.setAlignment(ParagraphAlignment.CENTER);
        XWPFRun uuidRun = uuidPara.createRun();
        uuidRun.setText(ticket.getUuid().substring(0, 8).toUpperCase());
        uuidRun.setFontFamily("Helvetica");
        uuidRun.setFontSize(isConcert ? 9 : 7);
        uuidRun.setBold(true);
        uuidRun.setColor("222222");

        // ── CELLULE 4 : STUB (talon) ──
        XWPFTableCell stubCell = row.getRow(0).getCell(3);
        setCellBackground(stubCell, hex); // fond couleur catégorie
        setCellMargins(stubCell, 150, 80, 150, 80);
        stubCell.setVerticalAlignment(XWPFTableCell.XWPFVertAlign.CENTER);

        // Texte vertical simulé (rotatif non supporté → texte empilé)
        XWPFParagraph stubPara = stubCell.getParagraphs().get(0);
        stubPara.setAlignment(ParagraphAlignment.CENTER);
        XWPFRun stubRun = stubPara.createRun();
        stubRun.setText("ADMIT");
        stubRun.setFontFamily("Helvetica");
        stubRun.setFontSize(isConcert ? 9 : 6);
        stubRun.setBold(true);
        stubRun.setColor("FFFFFF");

        XWPFParagraph stubPara2 = stubCell.addParagraph();
        stubPara2.setAlignment(ParagraphAlignment.CENTER);
        XWPFRun stubRun2 = stubPara2.createRun();
        stubRun2.setText("ONE");
        stubRun2.setFontFamily("Helvetica");
        stubRun2.setFontSize(isConcert ? 9 : 6);
        stubRun2.setBold(true);
        stubRun2.setColor("FFFFFF");

        XWPFParagraph stubCatPara = stubCell.addParagraph();
        stubCatPara.setAlignment(ParagraphAlignment.CENTER);
        XWPFRun stubCatRun = stubCatPara.createRun();
        stubCatRun.setText("─");
        stubCatRun.setFontFamily("Helvetica");
        stubCatRun.setFontSize(8);
        stubCatRun.setColor("FFFFFF");

        XWPFParagraph stubCatPara2 = stubCell.addParagraph();
        stubCatPara2.setAlignment(ParagraphAlignment.CENTER);
        XWPFRun stubCatRun2 = stubCatPara2.createRun();
        stubCatRun2.setText(cat.length() > 6
                ? cat.substring(0, 6) : cat);
        stubCatRun2.setFontFamily("Helvetica");
        stubCatRun2.setFontSize(isConcert ? 7 : 5);
        stubCatRun2.setBold(true);
        stubCatRun2.setColor("FFFFFF");
    }

    // ══════════════════════════════════════════════════════
    // INFOS CONCERT (210mm × 90mm)
    // ══════════════════════════════════════════════════════
    private void buildConcertInfo(XWPFTableCell cell, Event event,
                                  String cat, String hex, String price,
                                  String from, String to, String serial) {

        // Badge catégorie
        XWPFParagraph catPara = cell.getParagraphs().get(0);
        catPara.setAlignment(ParagraphAlignment.LEFT);
        catPara.setSpacingAfter(80);
        XWPFRun catRun = catPara.createRun();
        catRun.setText("  " + cat + "  ");
        catRun.setBold(true);
        catRun.setFontFamily("Helvetica");
        catRun.setFontSize(9);
        catRun.setColor(hex);

        // Nom événement (grande taille)
        XWPFParagraph namePara = addPara(cell, ParagraphAlignment.LEFT, 60);
        XWPFRun nameRun = namePara.createRun();
        nameRun.setText(event.getName());
        nameRun.setBold(true);
        nameRun.setFontFamily("Helvetica");
        nameRun.setFontSize(18);
        nameRun.setColor("111111");

        // Description / lieu
        XWPFParagraph locPara = addPara(cell, ParagraphAlignment.LEFT, 120);
        XWPFRun locRun = locPara.createRun();
        locRun.setText(event.getLocation());
        locRun.setFontFamily("Helvetica");
        locRun.setFontSize(9);
        locRun.setColor("777777");

        // Dates (style image 2 : date | date avec pipe)
        XWPFParagraph datePara = addPara(cell, ParagraphAlignment.LEFT, 100);
        XWPFRun dateRun = datePara.createRun();
        dateRun.setText(from + "   |   " + to);
        dateRun.setBold(true);
        dateRun.setFontFamily("Helvetica");
        dateRun.setFontSize(10);
        dateRun.setColor("222222");

        // Prix
        XWPFParagraph pricePara = addPara(cell, ParagraphAlignment.LEFT, 60);
        XWPFRun priceRun = pricePara.createRun();
        priceRun.setText(price + " FCFA");
        priceRun.setBold(true);
        priceRun.setFontFamily("Helvetica");
        priceRun.setFontSize(13);
        priceRun.setColor(hex);

        // Numéro de série
        XWPFParagraph snPara = addPara(cell, ParagraphAlignment.LEFT, 0);
        XWPFRun snRun = snPara.createRun();
        snRun.setText(serial
                + "  ·  Non remboursable  ·  Valable une seule fois");
        snRun.setFontFamily("Helvetica");
        snRun.setFontSize(6);
        snRun.setColor("BBBBBB");
        snRun.setItalic(true);
    }

    // ══════════════════════════════════════════════════════
    // INFOS STANDARD (140mm × 50mm) — compact
    // ══════════════════════════════════════════════════════
    private void buildStandardInfo(XWPFTableCell cell, Event event,
                                   String cat, String hex, String price,
                                   String from, String to, String serial) {

        // Catégorie + nom événement sur la même ligne
        XWPFParagraph namePara = cell.getParagraphs().get(0);
        namePara.setAlignment(ParagraphAlignment.LEFT);
        namePara.setSpacingAfter(40);

        XWPFRun catRun = namePara.createRun();
        catRun.setText("[" + cat + "]  ");
        catRun.setBold(true);
        catRun.setFontFamily("Helvetica");
        catRun.setFontSize(7);
        catRun.setColor(hex);

        XWPFRun nameRun = namePara.createRun();
        nameRun.setText(event.getName());
        nameRun.setBold(true);
        nameRun.setFontFamily("Helvetica");
        nameRun.setFontSize(10);
        nameRun.setColor("111111");

        // Lieu
        XWPFParagraph locPara = addPara(cell, ParagraphAlignment.LEFT, 40);
        XWPFRun locRun = locPara.createRun();
        locRun.setText(event.getLocation());
        locRun.setFontFamily("Helvetica");
        locRun.setFontSize(7);
        locRun.setColor("888888");

        // Prix + dates sur la même ligne
        XWPFParagraph infoLine = addPara(cell, ParagraphAlignment.LEFT, 40);

        XWPFRun priceRun = infoLine.createRun();
        priceRun.setText(price + " FCFA");
        priceRun.setBold(true);
        priceRun.setFontFamily("Helvetica");
        priceRun.setFontSize(11);
        priceRun.setColor(hex);

        XWPFRun sepRun = infoLine.createRun();
        sepRun.setText("   |   ");
        sepRun.setFontFamily("Helvetica");
        sepRun.setFontSize(9);
        sepRun.setColor("CCCCCC");

        XWPFRun dateRun = infoLine.createRun();
        dateRun.setText(from + " → " + to);
        dateRun.setFontFamily("Helvetica");
        dateRun.setFontSize(8);
        dateRun.setColor("444444");

        // Numéro de série
        XWPFParagraph snPara = addPara(cell, ParagraphAlignment.LEFT, 0);
        XWPFRun snRun = snPara.createRun();
        snRun.setText(serial + "  ·  Non remboursable");
        snRun.setFontFamily("Helvetica");
        snRun.setFontSize(6);
        snRun.setColor("BBBBBB");
        snRun.setItalic(true);
    }

    // ══════════════════════════════════════════════════════
    // UTILITAIRES
    // ══════════════════════════════════════════════════════

    private XWPFParagraph addPara(XWPFTableCell cell,
                                  ParagraphAlignment align, int spacingAfter) {
        XWPFParagraph p = cell.addParagraph();
        p.setAlignment(align);
        p.setSpacingAfter(spacingAfter);
        p.setSpacingBefore(0);
        return p;
    }

    private byte[] generateQRCode(String text, int size) throws Exception {
        QRCodeWriter writer = new QRCodeWriter();
        BitMatrix matrix = writer.encode(
                text, BarcodeFormat.QR_CODE, size, size);
        ByteArrayOutputStream out = new ByteArrayOutputStream();
        MatrixToImageConfig config = new MatrixToImageConfig(
                0xFF111111, 0xFFFFFFFF);
        MatrixToImageWriter.writeToStream(matrix, "PNG", out, config);
        return out.toByteArray();
    }

    private String formatPrice(Integer price) {
        if (price == null) return "0";
        return String.format("%,d", price).replace(",", " ");
    }

    private void setCellWidth(XWPFTableCell cell, int widthDxa) {
        CTTcPr tcPr = cell.getCTTc().isSetTcPr()
                ? cell.getCTTc().getTcPr()
                : cell.getCTTc().addNewTcPr();
        CTTblWidth w = tcPr.isSetTcW()
                ? tcPr.getTcW() : tcPr.addNewTcW();
        w.setW(BigInteger.valueOf(widthDxa));
        w.setType(STTblWidth.DXA);
    }

    private void setCellBackground(XWPFTableCell cell, String colorHex) {
        CTTcPr tcPr = cell.getCTTc().isSetTcPr()
                ? cell.getCTTc().getTcPr()
                : cell.getCTTc().addNewTcPr();
        CTShd shd = tcPr.isSetShd()
                ? tcPr.getShd() : tcPr.addNewShd();
        shd.setFill(colorHex);
        shd.setColor(colorHex);
        shd.setVal(STShd.CLEAR);
    }

    private void setCellMargins(XWPFTableCell cell,
                                int top, int right, int bottom, int left) {
        CTTcPr tcPr = cell.getCTTc().isSetTcPr()
                ? cell.getCTTc().getTcPr()
                : cell.getCTTc().addNewTcPr();
        CTTcMar mar = tcPr.isSetTcMar()
                ? tcPr.getTcMar() : tcPr.addNewTcMar();
        setMarginVal(mar.isSetTop()
                ? mar.getTop() : mar.addNewTop(), top);
        setMarginVal(mar.isSetRight()
                ? mar.getRight() : mar.addNewRight(), right);
        setMarginVal(mar.isSetBottom()
                ? mar.getBottom() : mar.addNewBottom(), bottom);
        setMarginVal(mar.isSetLeft()
                ? mar.getLeft() : mar.addNewLeft(), left);
    }

    private void setMarginVal(CTTblWidth w, int val) {
        w.setW(BigInteger.valueOf(val));
        w.setType(STTblWidth.DXA);
    }

    private void setCellBorderLeft(XWPFTableCell cell,
                                   String color, int thickness) {
        CTTcPr tcPr = cell.getCTTc().isSetTcPr()
                ? cell.getCTTc().getTcPr()
                : cell.getCTTc().addNewTcPr();
        CTTcBorders borders = tcPr.isSetTcBorders()
                ? tcPr.getTcBorders() : tcPr.addNewTcBorders();
        CTBorder left = borders.isSetLeft()
                ? borders.getLeft() : borders.addNewLeft();
        left.setVal(STBorder.SINGLE);
        left.setColor(color);
        left.setSz(BigInteger.valueOf(thickness));
    }

    private void setCellBorderSide(XWPFTableCell cell, String color,
                                   String side, int thickness) {
        CTTcPr tcPr = cell.getCTTc().isSetTcPr()
                ? cell.getCTTc().getTcPr()
                : cell.getCTTc().addNewTcPr();
        CTTcBorders borders = tcPr.isSetTcBorders()
                ? tcPr.getTcBorders() : tcPr.addNewTcBorders();
        CTBorder b;
        if (side.equals("left")) {
            b = borders.isSetLeft()
                    ? borders.getLeft() : borders.addNewLeft();
        } else {
            b = borders.isSetRight()
                    ? borders.getRight() : borders.addNewRight();
        }
        b.setVal(STBorder.DASHED);
        b.setColor(color);
        b.setSz(BigInteger.valueOf(thickness));
    }

    private void setTableBorders(XWPFTable table, String color) {
        CTTbl ctTbl = table.getCTTbl();
        CTTblPr tblPr = ctTbl.getTblPr() != null
                ? ctTbl.getTblPr()
                : ctTbl.addNewTblPr();
        CTTblBorders borders = tblPr.getTblBorders() != null
                ? tblPr.getTblBorders()
                : tblPr.addNewTblBorders();

        for (CTBorder b : new CTBorder[]{
                borders.isSetTop() ? borders.getTop() : borders.addNewTop(),
                borders.isSetBottom() ? borders.getBottom() : borders.addNewBottom(),
                borders.isSetLeft() ? borders.getLeft() : borders.addNewLeft(),
                borders.isSetRight() ? borders.getRight() : borders.addNewRight(),
                borders.isSetInsideH() ? borders.getInsideH() : borders.addNewInsideH(),
                borders.isSetInsideV() ? borders.getInsideV() : borders.addNewInsideV(),
        }) {
            b.setVal(STBorder.SINGLE);
            b.setColor(color);
            b.setSz(BigInteger.valueOf(2));
        }
    }

    private void setPageLandscape(XWPFDocument doc, boolean isConcert) {
        CTSectPr sectPr = doc.getDocument().getBody().isSetSectPr()
                ? doc.getDocument().getBody().getSectPr()
                : doc.getDocument().getBody().addNewSectPr();

        CTPageSz pgSz = sectPr.isSetPgSz()
                ? sectPr.getPgSz() : sectPr.addNewPgSz();

        // A4 paysage par défaut (le contenu est en tableau formaté)
        pgSz.setW(BigInteger.valueOf(16840)); // A4 largeur
        pgSz.setH(BigInteger.valueOf(11900)); // A4 hauteur
        pgSz.setOrient(STPageOrientation.LANDSCAPE);

        CTPageMar mar = sectPr.isSetPgMar()
                ? sectPr.getPgMar() : sectPr.addNewPgMar();
        mar.setTop(BigInteger.valueOf(500));
        mar.setBottom(BigInteger.valueOf(500));
        mar.setLeft(BigInteger.valueOf(500));
        mar.setRight(BigInteger.valueOf(500));
    }
}