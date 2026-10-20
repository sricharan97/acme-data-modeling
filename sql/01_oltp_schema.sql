-- ACME Part 1 — PostgreSQL OLTP schema (3NF)
-- Extracted from the completed notebook for easier reading.
-- Connection: postgresql://postgres:postgres@127.0.0.1:5432/postgres
DROP TABLE IF EXISTS user_ratings CASCADE;
DROP TABLE IF EXISTS purchases CASCADE;
DROP TABLE IF EXISTS customer_addresses CASCADE;
DROP TABLE IF EXISTS customer_emails CASCADE;
DROP TABLE IF EXISTS customer_phones CASCADE;
DROP TABLE IF EXISTS products CASCADE;
DROP TABLE IF EXISTS customers CASCADE;

CREATE TABLE Customers(
  customer_id INT PRIMARY KEY,
  first_name VARCHAR(100) NOT NULL,
  last_name VARCHAR(100) NOT NULL,
  created_at TIMESTAMP NOT NULL
);

CREATE TABLE Products(
    product_id INT PRIMARY KEY,
    product_name VARCHAR(150) NOT NULL,
    product_type VARCHAR(150) NOT NULL,
    description TEXT,
    price DECIMAL(10,2) NOT NULL CHECK(price >= 0.00),
    stock_quantity INT NOT NULL CHECK(stock_quantity >= 0),
    created_at TIMESTAMP NOT NULL
);

CREATE TABLE Customer_Phones(
    phone_id INT PRIMARY KEY,
    customer_id INT NOT NULL REFERENCES Customers(customer_id) ON DELETE CASCADE,
    phone VARCHAR(50) NOT NULL,
    created_at TIMESTAMP NOT NULL,
    CONSTRAINT uq_customer_phone UNIQUE (customer_id, phone)
);

CREATE TABLE Customer_Emails(
    email_id INT PRIMARY KEY,
    customer_id INT NOT NULL REFERENCES Customers(customer_id) ON DELETE CASCADE,
    email VARCHAR(150) NOT NULL,
    created_at TIMESTAMP NOT NULL,
    CONSTRAINT uq_customer_email UNIQUE (customer_id, email)
);

CREATE TABLE Customer_Addresses (
    address_id INT PRIMARY KEY,
    customer_id INT NOT NULL REFERENCES Customers(customer_id) ON DELETE CASCADE,
    address VARCHAR(255) NOT NULL,
    created_at TIMESTAMP NOT NULL,
    CONSTRAINT uq_customer_address UNIQUE (customer_id, address)
);

-- 3NF line-item purchases (CSV flat gear columns unpivoted at load time)
CREATE TABLE Purchases(
    purchase_id INT,
    customer_id INT NOT NULL REFERENCES Customers(customer_id) ON DELETE RESTRICT,
    product_id INT NOT NULL REFERENCES Products(product_id) ON DELETE RESTRICT,
    quantity INT NOT NULL CHECK (quantity > 0),
    unit_price DECIMAL(10, 2) NOT NULL CHECK (unit_price >= 0.00),
    total_price DECIMAL(10, 2) NOT NULL CHECK (total_price >= 0.00),
    purchase_date TIMESTAMP NOT NULL,
    status VARCHAR(50) NOT NULL,
    PRIMARY KEY (purchase_id, product_id)
);

CREATE TABLE User_Ratings (
    rating_id INT PRIMARY KEY,
    customer_id INT NOT NULL REFERENCES Customers(customer_id) ON DELETE CASCADE,
    product_id INT NOT NULL REFERENCES Products(product_id) ON DELETE CASCADE,
    rating INT NOT NULL CHECK (rating >= 1 AND rating <= 5),
    review_text TEXT,
    rating_date TIMESTAMP NOT NULL,
    CONSTRAINT uq_customer_product_rating UNIQUE (customer_id, product_id)
);
