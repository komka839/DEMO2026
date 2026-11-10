-- Схема базы данных: 7 связанных таблиц (пример интернет-магазина)
-- PostgreSQL

-- 1. Пользователи (клиенты)
CREATE TABLE users (
    user_id       BIGSERIAL PRIMARY KEY,
    email         VARCHAR(255) NOT NULL UNIQUE,
    password_hash VARCHAR(255) NOT NULL,
    first_name    VARCHAR(100) NOT NULL,
    last_name     VARCHAR(100) NOT NULL,
    phone         VARCHAR(20),
    created_at    TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at    TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- 2. Категории товаров (иерархия: родительская категория)
CREATE TABLE categories (
    category_id   BIGSERIAL PRIMARY KEY,
    name          VARCHAR(100) NOT NULL UNIQUE,
    description   TEXT,
    parent_id     BIGINT REFERENCES categories(category_id) ON DELETE SET NULL,
    created_at    TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- 3. Товары
CREATE TABLE products (
    product_id    BIGSERIAL PRIMARY KEY,
    category_id   BIGINT NOT NULL REFERENCES categories(category_id) ON DELETE RESTRICT,
    sku           VARCHAR(50) NOT NULL UNIQUE,
    name          VARCHAR(200) NOT NULL,
    description   TEXT,
    price         NUMERIC(12,2) NOT NULL CHECK (price >= 0),
    stock_qty     INT NOT NULL DEFAULT 0 CHECK (stock_qty >= 0),
    is_active     BOOLEAN NOT NULL DEFAULT TRUE,
    created_at    TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at    TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- 4. Заказы
CREATE TABLE orders (
    order_id      BIGSERIAL PRIMARY KEY,
    user_id       BIGINT NOT NULL REFERENCES users(user_id) ON DELETE RESTRICT,
    status        VARCHAR(20) NOT NULL DEFAULT 'pending'
                  CHECK (status IN ('pending','paid','shipped','delivered','cancelled')),
    total_amount  NUMERIC(12,2) NOT NULL DEFAULT 0 CHECK (total_amount >= 0),
    shipping_address TEXT NOT NULL,
    created_at    TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at    TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- 5. Позиции заказа (связь заказ ↔ товар, many-to-many через промежуточную таблицу)
CREATE TABLE order_items (
    order_item_id BIGSERIAL PRIMARY KEY,
    order_id      BIGINT NOT NULL REFERENCES orders(order_id) ON DELETE CASCADE,
    product_id    BIGINT NOT NULL REFERENCES products(product_id) ON DELETE RESTRICT,
    quantity      INT NOT NULL CHECK (quantity > 0),
    unit_price    NUMERIC(12,2) NOT NULL CHECK (unit_price >= 0),
    -- Снапшот цены на момент заказа
    CONSTRAINT uq_order_product UNIQUE (order_id, product_id)
);

-- 6. Платежи
CREATE TABLE payments (
    payment_id    BIGSERIAL PRIMARY KEY,
    order_id      BIGINT NOT NULL REFERENCES orders(order_id) ON DELETE CASCADE,
    amount        NUMERIC(12,2) NOT NULL CHECK (amount > 0),
    method        VARCHAR(30) NOT NULL CHECK (method IN ('card','bank_transfer','cash','wallet')),
    status        VARCHAR(20) NOT NULL DEFAULT 'pending'
                  CHECK (status IN ('pending','completed','failed','refunded')),
    transaction_ref VARCHAR(100),
    paid_at       TIMESTAMPTZ,
    created_at    TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- 7. Отзывы на товары
CREATE TABLE reviews (
    review_id     BIGSERIAL PRIMARY KEY,
    product_id    BIGINT NOT NULL REFERENCES products(product_id) ON DELETE CASCADE,
    user_id       BIGINT NOT NULL REFERENCES users(user_id) ON DELETE CASCADE,
    rating        SMALLINT NOT NULL CHECK (rating BETWEEN 1 AND 5),
    title         VARCHAR(200),
    body          TEXT,
    is_verified   BOOLEAN NOT NULL DEFAULT FALSE,
    created_at    TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at    TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    CONSTRAINT uq_user_product_review UNIQUE (user_id, product_id)
);

-- Индексы для частых запросов
CREATE INDEX idx_products_category ON products(category_id);
CREATE INDEX idx_orders_user ON orders(user_id);
CREATE INDEX idx_orders_status ON orders(status);
CREATE INDEX idx_order_items_order ON order_items(order_id);
CREATE INDEX idx_order_items_product ON order_items(product_id);
CREATE INDEX idx_payments_order ON payments(order_id);
CREATE INDEX idx_reviews_product ON reviews(product_id);

-- Комментарии к таблицам (для документации)
COMMENT ON TABLE users        IS 'Покупатели';
COMMENT ON TABLE categories   IS 'Категории товаров (поддерживает вложенность через parent_id)';
COMMENT ON TABLE products     IS 'Каталог товаров';
COMMENT ON TABLE orders       IS 'Заказы покупателей';
COMMENT ON TABLE order_items  IS 'Строки заказа (товары в заказе)';
COMMENT ON TABLE payments     IS 'Платежи по заказам';
COMMENT ON TABLE reviews      IS 'Отзывы покупателей на товары';