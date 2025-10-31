-- Schema for banquanao e-commerce project
-- MySQL 8.0 compatible
-- Drop existing tables (respecting FK order)
SET NAMES utf8mb4;
SET FOREIGN_KEY_CHECKS=0;

DROP TABLE IF EXISTS payments;
DROP TABLE IF EXISTS reply;
DROP TABLE IF EXISTS binhluan;
DROP TABLE IF EXISTS cart;
DROP TABLE IF EXISTS bill;
DROP TABLE IF EXISTS user_product_history;
DROP TABLE IF EXISTS sanpham;
DROP TABLE IF EXISTS danhmuc;
DROP TABLE IF EXISTS taikhoan;

SET FOREIGN_KEY_CHECKS=1;

-- Users
CREATE TABLE taikhoan (
  id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  name VARCHAR(100) NOT NULL,
  password VARCHAR(255) NOT NULL,
  email VARCHAR(150) NOT NULL,
  address VARCHAR(255) DEFAULT NULL,
  telephone VARCHAR(20) DEFAULT NULL,
  role TINYINT DEFAULT 0, -- 0: user, 1: admin (inferred)
  reset_token_hash VARCHAR(255) DEFAULT NULL,
  reset_token_expires_at DATETIME DEFAULT NULL,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  UNIQUE KEY uq_taikhoan_email (email),
  KEY idx_taikhoan_name (name)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Categories
CREATE TABLE danhmuc (
  id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  name VARCHAR(255) NOT NULL,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Products
CREATE TABLE sanpham (
  id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  iddm INT UNSIGNED NOT NULL,
  name VARCHAR(255) NOT NULL,
  price DECIMAL(12,2) NOT NULL DEFAULT 0.00,
  image VARCHAR(255) DEFAULT NULL,
  description TEXT,
  file_names TEXT DEFAULT NULL, -- comma-separated list of image filenames
  info TEXT DEFAULT NULL,
  view INT UNSIGNED NOT NULL DEFAULT 0,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  CONSTRAINT fk_sanpham_danhmuc FOREIGN KEY (iddm) REFERENCES danhmuc(id) ON DELETE CASCADE ON UPDATE CASCADE,
  KEY idx_sanpham_iddm (iddm),
  FULLTEXT KEY ft_sanpham_name_desc (name, description)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- User browsing history
CREATE TABLE user_product_history (
  id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  user_id INT UNSIGNED NOT NULL,
  product_id INT UNSIGNED NOT NULL,
  product_name VARCHAR(255) NOT NULL,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT fk_history_user FOREIGN KEY (user_id) REFERENCES taikhoan(id) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT fk_history_product FOREIGN KEY (product_id) REFERENCES sanpham(id) ON DELETE CASCADE ON UPDATE CASCADE,
  KEY idx_history_user_created (user_id, created_at)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Orders (bills)
CREATE TABLE bill (
  id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  idcustomer INT UNSIGNED NOT NULL,
  bill_name VARCHAR(255) NOT NULL,
  bill_address VARCHAR(255) NOT NULL,
  bill_email VARCHAR(150) NOT NULL,
  bill_tel VARCHAR(30) NOT NULL,
  grandtotal DECIMAL(12,2) NOT NULL DEFAULT 0.00,
  payment_method VARCHAR(50) NOT NULL,
  bill_date DATETIME NOT NULL,
  bill_status TINYINT NOT NULL DEFAULT 0, -- 0:new,1:shipping,2:done
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT fk_bill_user FOREIGN KEY (idcustomer) REFERENCES taikhoan(id) ON DELETE RESTRICT ON UPDATE CASCADE,
  KEY idx_bill_user (idcustomer)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Cart items
CREATE TABLE cart (
  id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  username VARCHAR(100) NOT NULL,
  idpro INT UNSIGNED NOT NULL,
  image VARCHAR(255) DEFAULT NULL,
  name VARCHAR(255) NOT NULL,
  price DECIMAL(12,2) NOT NULL,
  quantity INT UNSIGNED NOT NULL DEFAULT 1,
  totalprice DECIMAL(12,2) NOT NULL,
  grandtotal DECIMAL(12,2) NOT NULL,
  id_order INT UNSIGNED NOT NULL,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT fk_cart_product FOREIGN KEY (idpro) REFERENCES sanpham(id) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT fk_cart_bill FOREIGN KEY (id_order) REFERENCES bill(id) ON DELETE CASCADE ON UPDATE CASCADE,
  KEY idx_cart_order (id_order)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Comments
CREATE TABLE binhluan (
  id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  content TEXT NOT NULL,
  idpro INT UNSIGNED NOT NULL,
  iduser INT UNSIGNED NOT NULL,
  commentdate DATETIME NOT NULL,
  images TEXT DEFAULT NULL,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT fk_binhluan_product FOREIGN KEY (idpro) REFERENCES sanpham(id) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT fk_binhluan_user FOREIGN KEY (iduser) REFERENCES taikhoan(id) ON DELETE CASCADE ON UPDATE CASCADE,
  KEY idx_binhluan_pro_date (idpro, commentdate)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Replies
CREATE TABLE reply (
  id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  userid INT UNSIGNED NOT NULL,
  cmtid INT UNSIGNED NOT NULL,
  rep_content TEXT NOT NULL,
  rep_date DATETIME NOT NULL,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT fk_reply_user FOREIGN KEY (userid) REFERENCES taikhoan(id) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT fk_reply_comment FOREIGN KEY (cmtid) REFERENCES binhluan(id) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Payments
CREATE TABLE payments (
  id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  stripe_session_id VARCHAR(191) NOT NULL,
  total_amount DECIMAL(12,2) NOT NULL,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  UNIQUE KEY uq_payments_stripe_session (stripe_session_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Seed minimal data
INSERT INTO danhmuc (name) VALUES
('Shirts'),('Pants'),('Accessories');

INSERT INTO taikhoan (name, password, email, role) VALUES
('admin', 'admin', 'admin@example.com', 1),
('user', 'user', 'user@example.com', 0);

INSERT INTO sanpham (iddm, name, price, image, description) VALUES
(1, 'Sample Shirt', 199000, 'default.jpg', 'A sample shirt'),
(2, 'Sample Pants', 299000, 'default.jpg', 'A sample pants');

-- Example order and cart
INSERT INTO bill (idcustomer, bill_name, bill_address, bill_email, bill_tel, grandtotal, payment_method, bill_date, bill_status)
VALUES (2, 'User', '123 Street', 'user@example.com', '0123456789', 498000, 'COD', NOW(), 0);

INSERT INTO cart (username, idpro, image, name, price, quantity, totalprice, grandtotal, id_order)
VALUES ('user', 1, 'default.jpg', 'Sample Shirt', 199000, 1, 199000, 498000, 1),
       ('user', 2, 'default.jpg', 'Sample Pants', 299000, 1, 299000, 498000, 1);
