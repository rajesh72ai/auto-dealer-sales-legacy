-- V34: Seed F&I deal products for deals in FI, DL, and CT statuses
-- Product types from finance_product table patterns: VSC (Vehicle Service Contract),
-- GAP (GAP Insurance), PPM (Prepaid Maintenance), TWP (Tire & Wheel), PTF (Paint/Fabric)

INSERT INTO fi_deal_product (deal_number, product_seq, product_type, product_name, provider, term_months, mileage_limit, selling_price, dealer_cost, gross_profit) VALUES
-- DL01000001 (DL status) - 3 products
('DL01000001', 1, 'VSC', 'Gold Vehicle Service Contract', 'Ally Premier Protection', 60, 75000, 1895.00, 850.00, 1045.00),
('DL01000001', 2, 'GAP', 'GAP Coverage Plus', 'Ally GAP', 60, NULL, 895.00, 295.00, 600.00),
('DL01000001', 3, 'PPM', 'Prepaid Maintenance 3yr', 'Ford Protect', 36, 45000, 699.00, 495.00, 204.00),

-- DL01000002 (DL status) - 2 products
('DL01000002', 1, 'VSC', 'Platinum Service Contract', 'Ford Protect ESP', 72, 100000, 2495.00, 1100.00, 1395.00),
('DL01000002', 2, 'TWP', 'Tire & Wheel Protection', 'Safe-Guard Products', 60, 60000, 599.00, 195.00, 404.00),

-- DL01000003 (FI status) - products being selected
('DL01000003', 1, 'VSC', 'Silver Service Contract', 'Ally Premier Protection', 48, 60000, 1495.00, 695.00, 800.00),

-- DL02000006 (DL status) - 2 products
('DL02000006', 1, 'VSC', 'ToyotaCare Platinum', 'Toyota Financial', 60, 75000, 1695.00, 780.00, 915.00),
('DL02000006', 2, 'GAP', 'GAP Protection', 'Toyota Financial', 60, NULL, 795.00, 275.00, 520.00),

-- DL02000007 (DL status) - 3 products
('DL02000007', 1, 'VSC', 'ToyotaCare Platinum', 'Toyota Financial', 72, 100000, 2295.00, 1050.00, 1245.00),
('DL02000007', 2, 'PPM', 'ToyotaCare Prepaid Maint', 'Toyota Motor Sales', 36, 45000, 599.00, 420.00, 179.00),
('DL02000007', 3, 'PTF', 'Paint & Fabric Protection', 'Perma-Guard', 60, NULL, 495.00, 95.00, 400.00),

-- DL02000008 (DL status) - 2 products
('DL02000008', 1, 'VSC', 'ToyotaCare Gold', 'Toyota Financial', 48, 60000, 1395.00, 650.00, 745.00),
('DL02000008', 2, 'GAP', 'GAP Protection', 'Toyota Financial', 60, NULL, 795.00, 275.00, 520.00),

-- DL02000009 (FI status - lease) - 1 product
('DL02000009', 1, 'TWP', 'Tire & Wheel Protection', 'Safe-Guard Products', 36, 36000, 399.00, 125.00, 274.00),

-- DL03000011 (DL status) - 2 products
('DL03000011', 1, 'VSC', 'Honda Care VSC', 'Honda Financial', 60, 60000, 1595.00, 720.00, 875.00),
('DL03000011', 2, 'PPM', 'Honda Maintenance Plan', 'Honda Motor Co', 36, 36000, 549.00, 380.00, 169.00),

-- DL03000012 (DL status) - 3 products
('DL03000012', 1, 'VSC', 'Honda Care Platinum', 'Honda Financial', 72, 100000, 2195.00, 980.00, 1215.00),
('DL03000012', 2, 'GAP', 'Honda GAP Coverage', 'Honda Financial', 72, NULL, 895.00, 310.00, 585.00),
('DL03000012', 3, 'TWP', 'Tire & Wheel Bundle', 'Safe-Guard Products', 48, 48000, 499.00, 145.00, 354.00),

-- DL03000013 (DL status) - 2 products
('DL03000013', 1, 'VSC', 'Honda Care Gold', 'Honda Financial', 60, 75000, 1895.00, 850.00, 1045.00),
('DL03000013', 2, 'PTF', 'Interior Protection Pkg', 'Cilajet', 60, NULL, 695.00, 125.00, 570.00),

-- DL04000016 (DL status) - 3 products
('DL04000016', 1, 'VSC', 'GM Protection Plan Plat', 'GM Financial', 72, 100000, 2395.00, 1080.00, 1315.00),
('DL04000016', 2, 'GAP', 'GM GAP Protection', 'GM Financial', 72, NULL, 895.00, 295.00, 600.00),
('DL04000016', 3, 'PPM', 'GM Maintenance Plan', 'GM Parts & Service', 36, 45000, 649.00, 460.00, 189.00),

-- DL04000017 (DL status) - 2 products
('DL04000017', 1, 'VSC', 'GM Protection Plan Gold', 'GM Financial', 60, 75000, 1695.00, 780.00, 915.00),
('DL04000017', 2, 'TWP', 'Tire & Wheel Protection', 'Safe-Guard Products', 60, 60000, 499.00, 145.00, 354.00),

-- DL04000018 (CT status) - 2 products
('DL04000018', 1, 'VSC', 'GM Protection Plan Gold', 'GM Financial', 60, 75000, 1695.00, 780.00, 915.00),
('DL04000018', 2, 'GAP', 'GM GAP Protection', 'GM Financial', 60, NULL, 795.00, 275.00, 520.00),

-- DL05000021 (DL lease) - 1 product
('DL05000021', 1, 'VSC', 'BMW Ultimate Care+', 'BMW Financial', 36, 36000, 1995.00, 1200.00, 795.00),

-- DL05000022 (DL status) - 3 products
('DL05000022', 1, 'VSC', 'BMW Platinum Warranty', 'BMW Financial', 72, 100000, 3495.00, 1800.00, 1695.00),
('DL05000022', 2, 'GAP', 'BMW GAP Protection', 'BMW Financial', 72, NULL, 995.00, 350.00, 645.00),
('DL05000022', 3, 'PPM', 'BMW Ultimate Care', 'BMW Financial', 36, 36000, 899.00, 650.00, 249.00),

-- DL05000023 (DL status) - 2 products
('DL05000023', 1, 'VSC', 'BMW Gold Warranty', 'BMW Financial', 60, 75000, 2495.00, 1300.00, 1195.00),
('DL05000023', 2, 'PTF', 'Paint Protection Film', 'XPEL', 60, NULL, 1295.00, 450.00, 845.00),

-- DL05000024 (FI status - lease) - 1 product
('DL05000024', 1, 'VSC', 'BMW Ultimate Care+', 'BMW Financial', 36, 36000, 2195.00, 1350.00, 845.00);
