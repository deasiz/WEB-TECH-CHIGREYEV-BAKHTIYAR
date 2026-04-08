ALTER TABLE Members
    ALTER COLUMN is_active SET DEFAULT true;

UPDATE Members SET is_active = true WHERE is_active IS NULL;

ALTER TABLE Members
    ALTER COLUMN username SET NOT NULL;

ALTER TABLE Members
    ADD CONSTRAINT members_username_unique UNIQUE (username);

ALTER TABLE Members
    ALTER COLUMN email SET NOT NULL;

ALTER TABLE Members
    ADD CONSTRAINT members_email_unique UNIQUE (email);

ALTER TABLE Books
    ADD COLUMN condition VARCHAR(30) NOT NULL DEFAULT 'good';

ALTER TABLE Books
    ALTER COLUMN author SET NOT NULL;

ALTER TABLE Books
    ADD CONSTRAINT books_year_pub_check CHECK (year_pub >= 0);

ALTER TABLE Books
    ADD CONSTRAINT books_owner_fk
    FOREIGN KEY (owner_id) REFERENCES Members(id);

ALTER TABLE Books
    ALTER COLUMN condition TYPE VARCHAR(20);

ALTER TABLE Books
    ALTER COLUMN condition TYPE VARCHAR(30);

ALTER TABLE Exchanges
    ADD COLUMN status VARCHAR(20) DEFAULT 'pending';

UPDATE Exchanges SET exchange_date = '2026-01-01' WHERE exchange_date IS NULL;

ALTER TABLE Exchanges
    ALTER COLUMN exchange_date SET NOT NULL;

ALTER TABLE Exchanges
    ADD CONSTRAINT exchanges_exchange_date_check
    CHECK (exchange_date >= '2026-01-01');

ALTER TABLE Exchanges
    ADD CONSTRAINT exchanges_return_date_check
    CHECK (return_date >= '2026-01-01');

ALTER TABLE Exchanges
    ADD CONSTRAINT exchanges_book_fk
    FOREIGN KEY (book_id) REFERENCES Books(id);

ALTER TABLE Exchanges
    ADD CONSTRAINT exchanges_borrower_fk
    FOREIGN KEY (borrower_id) REFERENCES Members(id);

ALTER TABLE Reviews
    ADD CONSTRAINT reviews_rating_check
    CHECK (rating BETWEEN 1 AND 5);

UPDATE Reviews SET review_text = 'No review provided' WHERE review_text IS NULL;

ALTER TABLE Reviews
    ALTER COLUMN review_text SET NOT NULL;

ALTER TABLE Reviews
    ADD CONSTRAINT reviews_book_fk
    FOREIGN KEY (book_id) REFERENCES Books(id);

ALTER TABLE Reviews
    ADD CONSTRAINT reviews_member_fk
    FOREIGN KEY (member_id) REFERENCES Members(id);

ALTER TABLE Books
    DROP CONSTRAINT books_owner_fk;

ALTER TABLE Books
    ADD CONSTRAINT books_owner_fk
    FOREIGN KEY (owner_id) REFERENCES Members(id);

INSERT INTO Members (username, email, joined_date, is_active) VALUES
    ('alice99',   'alice@mail.com',   '2026-01-10', true),
    ('bob_reads', 'bob@mail.com',     '2026-02-01', true),
    ('carol_lit', 'carol@mail.com',   '2026-03-05', false),
    ('dan_books', 'dan@mail.com',     '2026-01-20', true);

INSERT INTO Books (title, author, year_pub, owner_id, condition) VALUES
    ('The Pragmatic Programmer', 'Andy Hunt',     1999, 1, 'good'),
    ('Clean Code',               'Robert Martin', 2008, 2, 'like new'),
    ('Dune',                     'Frank Herbert', 1965, 3, 'worn'),
    ('1984',                     'George Orwell', 1949, 4, 'good');

INSERT INTO Exchanges (book_id, borrower_id, exchange_date, return_date, status) VALUES
    (1, 2, '2026-03-01', '2026-03-15', 'returned'),
    (2, 3, '2026-04-01', '2026-04-20', 'active'),
    (3, 1, '2026-04-05', '2026-05-01', 'pending');

INSERT INTO Reviews (book_id, member_id, rating, review_text, created_at) VALUES
    (1, 2, 5, 'Excellent book, highly recommended!', '2026-03-20'),
    (2, 3, 4, 'Very clean and practical.',           '2026-04-22'),
    (3, 1, 3, 'Classic but dense read.',             '2026-04-10');