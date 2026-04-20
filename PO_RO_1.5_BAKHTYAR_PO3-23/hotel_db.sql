-- ============================================================
-- DATABASE: hotel_db
-- SCHEMA: hospitality
-- ============================================================

CREATE SCHEMA IF NOT EXISTS hospitality;

-- ============================================================
-- TABLES (без изменений)
-- ============================================================

CREATE TABLE IF NOT EXISTS hospitality.hotel (
    hotel_id SERIAL NOT NULL,
    name VARCHAR(100) NOT NULL,
    address VARCHAR(200) NOT NULL,
    phone VARCHAR(20) NOT NULL,
    star_rating SMALLINT NOT NULL DEFAULT 3,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT pk_hotel PRIMARY KEY (hotel_id),
    CONSTRAINT chk_hotel_stars CHECK (star_rating BETWEEN 1 AND 5)
);

CREATE TABLE IF NOT EXISTS hospitality.roomtype (
    roomtype_id SERIAL NOT NULL,
    type_name VARCHAR(100) NOT NULL,
    base_price NUMERIC(10,2) NOT NULL DEFAULT 0.00,
    description TEXT,
    CONSTRAINT pk_roomtype PRIMARY KEY (roomtype_id),
    CONSTRAINT chk_roomtype_price CHECK (base_price >= 0)
);

CREATE TABLE IF NOT EXISTS hospitality.room (
    room_id SERIAL NOT NULL,
    hotel_id INT NOT NULL,
    roomtype_id INT NOT NULL,
    floor_number SMALLINT NOT NULL DEFAULT 1,
    status VARCHAR(20) NOT NULL DEFAULT 'AVAILABLE',
    CONSTRAINT pk_room PRIMARY KEY (room_id),
    CONSTRAINT fk_room_hotel FOREIGN KEY (hotel_id) REFERENCES hospitality.hotel(hotel_id) ON DELETE RESTRICT ON UPDATE CASCADE,
    CONSTRAINT fk_room_type FOREIGN KEY (roomtype_id) REFERENCES hospitality.roomtype(roomtype_id) ON DELETE RESTRICT ON UPDATE CASCADE,
    CONSTRAINT chk_room_status CHECK (status IN ('AVAILABLE','OCCUPIED','MAINTENANCE'))
);

CREATE TABLE IF NOT EXISTS hospitality.customer (
    customer_id SERIAL NOT NULL,
    first_name VARCHAR(50) NOT NULL,
    last_name VARCHAR(50) NOT NULL,
    full_name VARCHAR(101) GENERATED ALWAYS AS (first_name || ' ' || last_name) STORED,
    email VARCHAR(100) NOT NULL,
    phone VARCHAR(30),
    passport_number VARCHAR(30) NOT NULL,
    loyalty_points INT NOT NULL DEFAULT 0,
    CONSTRAINT pk_customer PRIMARY KEY (customer_id),
    CONSTRAINT uq_customer_email UNIQUE (email),
    CONSTRAINT uq_customer_passport UNIQUE (passport_number)
);

CREATE TABLE IF NOT EXISTS hospitality.booking (
    booking_id SERIAL NOT NULL,
    customer_id INT NOT NULL,
    check_in DATE NOT NULL,
    check_out DATE NOT NULL,
    total_amount NUMERIC(10,2) NOT NULL DEFAULT 0.00,
    status VARCHAR(20) NOT NULL DEFAULT 'CONFIRMED',
    notes TEXT,
    CONSTRAINT pk_booking PRIMARY KEY (booking_id),
    CONSTRAINT fk_booking_customer FOREIGN KEY (customer_id) REFERENCES hospitality.customer(customer_id) ON DELETE RESTRICT ON UPDATE CASCADE,
    CONSTRAINT chk_booking_dates CHECK (check_out > check_in),
    CONSTRAINT chk_booking_amount CHECK (total_amount >= 0),
    CONSTRAINT chk_booking_status CHECK (status IN ('CONFIRMED','CANCELLED','COMPLETED'))
);

CREATE TABLE IF NOT EXISTS hospitality.booking_room (
    booking_id INT NOT NULL,
    room_id INT NOT NULL,
    price_per_night NUMERIC(10,2) NOT NULL DEFAULT 0.00,
    CONSTRAINT pk_booking_room PRIMARY KEY (booking_id, room_id),
    CONSTRAINT fk_br_booking FOREIGN KEY (booking_id) REFERENCES hospitality.booking(booking_id) ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT fk_br_room FOREIGN KEY (room_id) REFERENCES hospitality.room(room_id) ON DELETE RESTRICT ON UPDATE CASCADE,
    CONSTRAINT chk_br_price CHECK (price_per_night >= 0)
);

CREATE TABLE IF NOT EXISTS hospitality.payment (
    payment_id SERIAL NOT NULL,
    booking_id INT NOT NULL,
    payment_date DATE NOT NULL DEFAULT CURRENT_DATE,
    amount NUMERIC(10,2) NOT NULL,
    method VARCHAR(50) NOT NULL DEFAULT 'CASH',
    CONSTRAINT pk_payment PRIMARY KEY (payment_id),
    CONSTRAINT fk_payment_booking FOREIGN KEY (booking_id) REFERENCES hospitality.booking(booking_id) ON DELETE RESTRICT ON UPDATE CASCADE,
    CONSTRAINT chk_payment_amount CHECK (amount > 0),
    CONSTRAINT chk_payment_method CHECK (method IN ('CASH','CARD','ONLINE'))
);

CREATE TABLE IF NOT EXISTS hospitality.staff (
    staff_id SERIAL NOT NULL,
    hotel_id INT NOT NULL,
    first_name VARCHAR(50) NOT NULL,
    last_name VARCHAR(50) NOT NULL,
    role VARCHAR(50) NOT NULL DEFAULT 'GENERAL',
    phone VARCHAR(20),
    email VARCHAR(100) UNIQUE,
    CONSTRAINT pk_staff PRIMARY KEY (staff_id),
    CONSTRAINT fk_staff_hotel FOREIGN KEY (hotel_id) REFERENCES hospitality.hotel(hotel_id) ON DELETE RESTRICT ON UPDATE CASCADE,
    CONSTRAINT chk_staff_role CHECK (role IN ('ADMIN','RECEPTION','CLEANER','MANAGER','GENERAL'))
);

CREATE TABLE IF NOT EXISTS hospitality.service (
    service_id SERIAL NOT NULL,
    service_name VARCHAR(100) NOT NULL,
    price NUMERIC(10,2) NOT NULL DEFAULT 0.00,
    CONSTRAINT pk_service PRIMARY KEY (service_id),
    CONSTRAINT chk_service_price CHECK (price >= 0)
);

CREATE TABLE IF NOT EXISTS hospitality.roomservice_order (
    order_id SERIAL NOT NULL,
    booking_id INT NOT NULL,
    staff_id INT,
    order_date TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT pk_rs_order PRIMARY KEY (order_id),
    CONSTRAINT fk_rso_booking FOREIGN KEY (booking_id) REFERENCES hospitality.booking(booking_id) ON DELETE RESTRICT ON UPDATE CASCADE,
    CONSTRAINT fk_rso_staff FOREIGN KEY (staff_id) REFERENCES hospitality.staff(staff_id) ON DELETE SET NULL ON UPDATE CASCADE
);

CREATE TABLE IF NOT EXISTS hospitality.roomservice_orderitem (
    order_id INT NOT NULL,
    service_id INT NOT NULL,
    quantity INT NOT NULL DEFAULT 1,
    unit_price NUMERIC(10,2) NOT NULL DEFAULT 0.00,
    line_total NUMERIC(10,2) GENERATED ALWAYS AS (quantity * unit_price) STORED,
    CONSTRAINT pk_rs_orderitem PRIMARY KEY (order_id, service_id),
    CONSTRAINT fk_rsoi_order FOREIGN KEY (order_id) REFERENCES hospitality.roomservice_order(order_id) ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT fk_rsoi_service FOREIGN KEY (service_id) REFERENCES hospitality.service(service_id) ON DELETE RESTRICT ON UPDATE CASCADE,
    CONSTRAINT chk_rsoi_qty CHECK (quantity > 0)
);

CREATE TABLE IF NOT EXISTS hospitality.checkout (
    check_id SERIAL NOT NULL,
    room_id INT NOT NULL UNIQUE,
    check_in TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    check_out TIMESTAMP,
    CONSTRAINT pk_checkout PRIMARY KEY (check_id),
    CONSTRAINT fk_checkout_room FOREIGN KEY (room_id) REFERENCES hospitality.room(room_id) ON DELETE RESTRICT ON UPDATE CASCADE,
    CONSTRAINT chk_checkout_dates CHECK (check_out IS NULL OR check_out > check_in)
);



-- 1. Add email to staff (was forgotten in the initial design).
--    UNIQUE ensures no two staff members share a login email.
ALTER TABLE hospitality.staff
    ADD COLUMN IF NOT EXISTS email VARCHAR(100) UNIQUE;

-- 2. Widen customer.phone from VARCHAR(20) to VARCHAR(30)
--    to accommodate international dialling codes like +7 701 123 45 67.
ALTER TABLE hospitality.customer
    ALTER COLUMN phone TYPE VARCHAR(30);

-- 3. Change the default payment method from CARD to CASH
--    to reflect that most on-site payments are made in cash.
ALTER TABLE hospitality.payment
    ALTER COLUMN method SET DEFAULT 'CASH';

-- 4. Add a loyalty_points column to customer for a rewards programme.
--    DEFAULT 0 means existing rows automatically get 0 points.
ALTER TABLE hospitality.customer
    ADD COLUMN IF NOT EXISTS loyalty_points INT NOT NULL DEFAULT 0;

-- 5. Add a notes column to booking for special guest requests
--    (e.g. "late check-in", "extra bed"). TEXT allows unlimited length.
ALTER TABLE hospitality.booking
    ADD COLUMN IF NOT EXISTS notes TEXT;


-- ============================================================
-- TRUNCATE (в правильном порядке)
-- ============================================================

TRUNCATE TABLE hospitality.checkout CASCADE;
TRUNCATE TABLE hospitality.roomservice_orderitem CASCADE;
TRUNCATE TABLE hospitality.roomservice_order CASCADE;
TRUNCATE TABLE hospitality.payment CASCADE;
TRUNCATE TABLE hospitality.booking_room CASCADE;
TRUNCATE TABLE hospitality.booking CASCADE;
TRUNCATE TABLE hospitality.room CASCADE;
TRUNCATE TABLE hospitality.staff CASCADE;
TRUNCATE TABLE hospitality.service CASCADE;
TRUNCATE TABLE hospitality.customer CASCADE;
TRUNCATE TABLE hospitality.roomtype CASCADE;
TRUNCATE TABLE hospitality.hotel CASCADE;

-- ============================================================
-- INSERT DATA (простые INSERT)
-- ============================================================

-- Hotels
INSERT INTO hospitality.hotel (hotel_id, name, address, phone, star_rating) VALUES
(1, 'Renaissance Atyrau Hotel', 'Atyrau, Satpayev St 15', '+77010000001', 5),
(2, 'River Palace Hotel', 'Atyrau, Aiteke Bi St 55', '+77010000002', 4),
(3, 'Sultan Palace Hotel', 'Atyrau, Abulkhair Khan Ave', '+77010000003', 5),
(4, 'Renaissance Aktau Hotel', 'Aktau, Microdistrict 9', '+77010000004', 5),
(5, 'Caspian Riviera Hotel', 'Aktau, Seaside Area', '+77010000005', 4),
(6, 'Hampton by Hilton Astana', 'Astana, Mangilik El 43', '+77010000006', 4),
(7, 'Comfort Hotel Astana', 'Astana, Kosmonavtov 60', '+77010000007', 4),
(8, 'Rixos Almaty', 'Almaty, Seifullin Ave 506', '+77010000008', 5),
(9, 'InterContinental Almaty', 'Almaty, Zheltoksan 181', '+77010000009', 5),
(10, 'Hotel Kazakhstan', 'Almaty, Dostyk Ave 52', '+77010000010', 4);

-- Room Types
INSERT INTO hospitality.roomtype (roomtype_id, type_name, base_price, description) VALUES
(1, 'Standard', 20000, 'Basic room with essential amenities'),
(2, 'Deluxe', 35000, 'Improved comfort with city view'),
(3, 'Suite', 60000, 'Spacious luxury suite'),
(4, 'Family', 45000, 'Extra-large room for families'),
(5, 'Presidential', 120000, 'Top-floor luxury with butler service');

-- Rooms
INSERT INTO hospitality.room (room_id, hotel_id, roomtype_id, floor_number, status) VALUES
(1, 1, 1, 1, 'AVAILABLE'),
(2, 1, 2, 2, 'AVAILABLE'),
(3, 2, 1, 1, 'AVAILABLE'),
(4, 3, 3, 3, 'AVAILABLE'),
(5, 4, 2, 2, 'AVAILABLE'),
(6, 5, 1, 1, 'AVAILABLE'),
(7, 6, 2, 3, 'AVAILABLE'),
(8, 7, 1, 2, 'AVAILABLE'),
(9, 8, 3, 5, 'AVAILABLE'),
(10, 9, 5, 7, 'AVAILABLE');

-- Customers
INSERT INTO hospitality.customer (customer_id, first_name, last_name, email, phone, passport_number) VALUES
(1, 'Райымбек', 'Саламат', 'salamat@mail.com', '+77011111111', 'KZ1234561'),
(2, 'Санжар', 'Турланов', 'sanzhar@mail.com', '+77011111112', 'KZ1234562'),
(3, 'Бахтияр', 'Чигреев', 'bakhtiyar@mail.com', '+77011111113', 'KZ1234563'),
(4, 'Рауан', 'Туретаев', 'rauan@mail.com', '+77011111114', 'KZ1234564'),
(5, 'Темирлан', 'Гизатов', 'temirlan@mail.com', '+77011111115', 'KZ1234565'),
(6, 'Ахад', 'Темир', 'ahad@mail.com', '+77011111116', 'KZ1234566'),
(7, 'Азат', 'Хамитов', 'azat@mail.com', '+77011111117', 'KZ1234567'),
(8, 'Дамир', 'Габитов', 'damir@mail.com', '+77011111118', 'KZ1234568'),
(9, 'Диас', 'Ермеков', 'dias@mail.com', '+77011111119', 'KZ1234569');

-- Bookings
INSERT INTO hospitality.booking (booking_id, customer_id, check_in, check_out, total_amount, status) VALUES
(1, 1, '2026-04-10', '2026-04-12', 40000, 'CONFIRMED'),
(2, 2, '2026-04-11', '2026-04-13', 70000, 'CONFIRMED'),
(3, 3, '2026-04-12', '2026-04-14', 120000, 'CONFIRMED'),
(4, 4, '2026-04-13', '2026-04-15', 50000, 'CONFIRMED'),
(5, 5, '2026-04-14', '2026-04-16', 60000, 'CONFIRMED');

-- Booking Rooms
INSERT INTO hospitality.booking_room (booking_id, room_id, price_per_night) VALUES
(1, 1, 20000),
(2, 2, 35000),
(3, 4, 60000),
(4, 5, 25000),
(5, 9, 60000);

-- Payments
INSERT INTO hospitality.payment (payment_id, booking_id, payment_date, amount, method) VALUES
(1, 1, '2026-04-10', 40000, 'CASH'),
(2, 2, '2026-04-11', 70000, 'CARD'),
(3, 3, '2026-04-12', 120000, 'CASH'),
(4, 4, '2026-04-13', 50000, 'ONLINE'),
(5, 5, '2026-04-14', 60000, 'CARD');

-- Staff
INSERT INTO hospitality.staff (staff_id, hotel_id, first_name, last_name, role, phone, email) VALUES
(1, 1, 'Адиль', 'Сериков', 'ADMIN', '+77012222221', 'adil@renaissance-atyrau.kz'),
(2, 2, 'Нуржан', 'Касымов', 'RECEPTION', '+77012222222', 'nurzhan@riverpalace.kz'),
(3, 3, 'Ерлан', 'Ахметов', 'CLEANER', '+77012222223', 'yerlan@sultanpalace.kz'),
(4, 8, 'Айгуль', 'Бекова', 'MANAGER', '+77012222224', 'aigul@rixos.kz'),
(5, 6, 'Данияр', 'Сатов', 'RECEPTION', '+77012222225', 'daniyar@hilton-astana.kz'),
(6, 9, 'Мадина', 'Оразова', 'ADMIN', '+77012222226', 'madina@intercont-almaty.kz');

-- Services
INSERT INTO hospitality.service (service_id, service_name, price) VALUES
(1, 'Breakfast', 5000),
(2, 'Spa', 15000),
(3, 'Laundry', 3000),
(4, 'Room Cleaning', 2000);

-- Room Service Orders
INSERT INTO hospitality.roomservice_order (order_id, booking_id, staff_id, order_date) VALUES
(1, 1, 1, '2026-04-10 10:00'),
(2, 2, 2, '2026-04-11 12:00'),
(3, 3, 3, '2026-04-12 09:00'),
(4, 4, 4, '2026-04-13 11:30');

-- Room Service Order Items
INSERT INTO hospitality.roomservice_orderitem (order_id, service_id, quantity, unit_price) VALUES
(1, 1, 2, 5000),
(1, 3, 1, 3000),
(2, 2, 1, 15000),
(3, 4, 1, 2000),
(4, 1, 3, 5000);

-- Checkouts
INSERT INTO hospitality.checkout (check_id, room_id, check_in, check_out) VALUES
(1, 1, '2026-04-10 14:00', '2026-04-12 12:00'),
(2, 2, '2026-04-11 14:00', '2026-04-13 12:00'),
(3, 4, '2026-04-12 15:00', '2026-04-14 11:00'),
(4, 5, '2026-04-13 14:00', NULL);
