-- =============================================
-- SQL Script để tạo các bảng cho eShop System
-- Database: PostgreSQL (Neon.tech)
-- =============================================
-- 
-- HƯỚNG DẪN SỬ DỤNG:
-- 1. Chạy từng phần trong database tương ứng:
--    - PART 1: orderingdb
--    - PART 2: identitydb  
--    - PART 3: catalogdb
--    - PART 4: webhooksdb
-- 2. Hoặc chạy toàn bộ script nếu có quyền tạo nhiều databases
-- =============================================

-- =============================================
-- PART 1: ORDERING DATABASE (orderingdb)
-- =============================================

-- Tạo schema nếu chưa tồn tại
CREATE SCHEMA IF NOT EXISTS ordering;

-- =============================================
-- 1. Bảng CardTypes (Loại thẻ thanh toán)
-- =============================================
CREATE TABLE IF NOT EXISTS ordering.cardtypes (
    "Id" INTEGER NOT NULL PRIMARY KEY,
    "Name" VARCHAR(200) NOT NULL
);

-- =============================================
-- 2. Bảng Buyers (Người mua)
-- =============================================
CREATE TABLE IF NOT EXISTS ordering.buyers (
    "Id" INTEGER NOT NULL PRIMARY KEY,
    "IdentityGuid" VARCHAR(200) NOT NULL,
    "Name" TEXT,
    CONSTRAINT "UQ_Buyers_IdentityGuid" UNIQUE ("IdentityGuid")
);

CREATE INDEX IF NOT EXISTS "IX_Buyers_IdentityGuid" ON ordering.buyers ("IdentityGuid");

-- =============================================
-- 3. Bảng PaymentMethods (Phương thức thanh toán)
-- =============================================
CREATE TABLE IF NOT EXISTS ordering.paymentmethods (
    "Id" INTEGER NOT NULL PRIMARY KEY,
    "BuyerId" INTEGER,
    "CardTypeId" INTEGER,
    "Alias" VARCHAR(200),
    "CardNumber" VARCHAR(25) NOT NULL,
    "CardHolderName" VARCHAR(200),
    "Expiration" VARCHAR(25),
    CONSTRAINT "FK_PaymentMethods_Buyers" FOREIGN KEY ("BuyerId") 
        REFERENCES ordering.buyers ("Id") ON DELETE CASCADE,
    CONSTRAINT "FK_PaymentMethods_CardTypes" FOREIGN KEY ("CardTypeId") 
        REFERENCES ordering.cardtypes ("Id")
);

CREATE INDEX IF NOT EXISTS "IX_PaymentMethods_BuyerId" ON ordering.paymentmethods ("BuyerId");
CREATE INDEX IF NOT EXISTS "IX_PaymentMethods_CardTypeId" ON ordering.paymentmethods ("CardTypeId");

-- =============================================
-- 4. Bảng Orders (Đơn hàng)
-- =============================================
CREATE TABLE IF NOT EXISTS ordering.orders (
    "Id" INTEGER NOT NULL PRIMARY KEY,
    "OrderDate" TIMESTAMP NOT NULL,
    "BuyerId" INTEGER,
    "OrderStatus" VARCHAR(30) NOT NULL,
    "Description" TEXT,
    "PaymentMethodId" INTEGER,
    -- Address fields (Value Object)
    "Address_Street" TEXT,
    "Address_City" TEXT,
    "Address_State" TEXT,
    "Address_Country" TEXT,
    "Address_ZipCode" TEXT,
    CONSTRAINT "FK_Orders_Buyers" FOREIGN KEY ("BuyerId") 
        REFERENCES ordering.buyers ("Id"),
    CONSTRAINT "FK_Orders_PaymentMethods" FOREIGN KEY ("PaymentMethodId") 
        REFERENCES ordering.paymentmethods ("Id") ON DELETE RESTRICT
);

CREATE INDEX IF NOT EXISTS "IX_Orders_BuyerId" ON ordering.orders ("BuyerId");
CREATE INDEX IF NOT EXISTS "IX_Orders_PaymentMethodId" ON ordering.orders ("PaymentMethodId");

-- =============================================
-- 5. Bảng OrderItems (Chi tiết đơn hàng)
-- =============================================
CREATE TABLE IF NOT EXISTS ordering."orderItems" (
    "Id" INTEGER NOT NULL PRIMARY KEY,
    "OrderId" INTEGER NOT NULL,
    "ProductId" INTEGER NOT NULL,
    "ProductName" TEXT NOT NULL,
    "PictureUrl" TEXT,
    "UnitPrice" DECIMAL(18,2) NOT NULL,
    "Discount" DECIMAL(18,2) NOT NULL,
    "Units" INTEGER NOT NULL,
    CONSTRAINT "FK_OrderItems_Orders" FOREIGN KEY ("OrderId") 
        REFERENCES ordering.orders ("Id") ON DELETE CASCADE
);

CREATE INDEX IF NOT EXISTS "IX_OrderItems_OrderId" ON ordering."orderItems" ("OrderId");

-- =============================================
-- 6. Bảng Requests (Idempotency - Tránh trùng lặp request)
-- =============================================
CREATE TABLE IF NOT EXISTS ordering.requests (
    "Id" UUID NOT NULL PRIMARY KEY,
    "Name" TEXT NOT NULL,
    "Time" TIMESTAMP NOT NULL
);

-- =============================================
-- 7. Bảng IntegrationEventLog (Log sự kiện tích hợp)
-- =============================================
CREATE TABLE IF NOT EXISTS ordering."IntegrationEventLog" (
    "EventId" UUID NOT NULL PRIMARY KEY,
    "EventTypeName" TEXT NOT NULL,
    "State" INTEGER NOT NULL,
    "TimesSent" INTEGER NOT NULL,
    "CreationTime" TIMESTAMP NOT NULL,
    "Content" TEXT NOT NULL,
    "TransactionId" UUID NOT NULL
);

CREATE INDEX IF NOT EXISTS "IX_IntegrationEventLog_State" ON ordering."IntegrationEventLog" ("State");

-- =============================================
-- 8. Tạo Sequences cho HiLo ID Generation
-- =============================================

-- Sequence cho Orders
CREATE SEQUENCE IF NOT EXISTS ordering.orderseq
    AS INTEGER
    START WITH 1
    INCREMENT BY 10
    MINVALUE 1
    MAXVALUE 2147483647
    CACHE 1;

-- Sequence cho OrderItems
CREATE SEQUENCE IF NOT EXISTS ordering.orderitemseq
    AS INTEGER
    START WITH 1
    INCREMENT BY 10
    MINVALUE 1
    MAXVALUE 2147483647
    CACHE 1;

-- Sequence cho Buyers
CREATE SEQUENCE IF NOT EXISTS ordering.buyerseq
    AS INTEGER
    START WITH 1
    INCREMENT BY 10
    MINVALUE 1
    MAXVALUE 2147483647
    CACHE 1;

-- Sequence cho PaymentMethods
CREATE SEQUENCE IF NOT EXISTS ordering.paymentseq
    AS INTEGER
    START WITH 1
    INCREMENT BY 10
    MINVALUE 1
    MAXVALUE 2147483647
    CACHE 1;

-- =============================================
-- 9. Insert dữ liệu mẫu cho CardTypes
-- =============================================
INSERT INTO ordering.cardtypes ("Id", "Name") 
VALUES (1, 'Visa')
ON CONFLICT ("Id") DO NOTHING;

INSERT INTO ordering.cardtypes ("Id", "Name") 
VALUES (2, 'MasterCard')
ON CONFLICT ("Id") DO NOTHING;

INSERT INTO ordering.cardtypes ("Id", "Name") 
VALUES (3, 'American Express')
ON CONFLICT ("Id") DO NOTHING;

-- =============================================
-- PART 2: IDENTITY DATABASE (identitydb)
-- =============================================

-- =============================================
-- 10. Bảng AspNetRoles (Vai trò người dùng)
-- =============================================
CREATE TABLE IF NOT EXISTS "AspNetRoles" (
    "Id" TEXT NOT NULL PRIMARY KEY,
    "Name" VARCHAR(256),
    "NormalizedName" VARCHAR(256),
    "ConcurrencyStamp" TEXT
);

CREATE UNIQUE INDEX IF NOT EXISTS "RoleNameIndex" ON "AspNetRoles" ("NormalizedName") 
    WHERE "NormalizedName" IS NOT NULL;

-- =============================================
-- 11. Bảng AspNetUsers (Người dùng - Bảng chính)
-- =============================================
CREATE TABLE IF NOT EXISTS "AspNetUsers" (
    "Id" TEXT NOT NULL PRIMARY KEY,
    -- Thông tin đăng nhập cơ bản
    "UserName" VARCHAR(256),
    "NormalizedUserName" VARCHAR(256),
    "Email" VARCHAR(256),
    "NormalizedEmail" VARCHAR(256),
    "EmailConfirmed" BOOLEAN NOT NULL DEFAULT FALSE,
    "PasswordHash" TEXT,
    "SecurityStamp" TEXT,
    "ConcurrencyStamp" TEXT,
    "PhoneNumber" TEXT,
    "PhoneNumberConfirmed" BOOLEAN NOT NULL DEFAULT FALSE,
    "TwoFactorEnabled" BOOLEAN NOT NULL DEFAULT FALSE,
    "LockoutEnd" TIMESTAMPTZ,
    "LockoutEnabled" BOOLEAN NOT NULL DEFAULT FALSE,
    "AccessFailedCount" INTEGER NOT NULL DEFAULT 0,
    -- Thông tin bổ sung từ ApplicationUser
    -- Lưu ý: Form đăng ký chỉ yêu cầu Email, Name, Password
    -- Chỉ giữ lại Name vì có trong form đăng ký
    "Name" TEXT
);

CREATE INDEX IF NOT EXISTS "EmailIndex" ON "AspNetUsers" ("NormalizedEmail");
CREATE UNIQUE INDEX IF NOT EXISTS "UserNameIndex" ON "AspNetUsers" ("NormalizedUserName") 
    WHERE "NormalizedUserName" IS NOT NULL;

-- =============================================
-- 12. Bảng AspNetRoleClaims (Claims của vai trò)
-- =============================================
CREATE TABLE IF NOT EXISTS "AspNetRoleClaims" (
    "Id" SERIAL PRIMARY KEY,
    "RoleId" TEXT NOT NULL,
    "ClaimType" TEXT,
    "ClaimValue" TEXT,
    CONSTRAINT "FK_AspNetRoleClaims_AspNetRoles_RoleId" FOREIGN KEY ("RoleId") 
        REFERENCES "AspNetRoles" ("Id") ON DELETE CASCADE
);

CREATE INDEX IF NOT EXISTS "IX_AspNetRoleClaims_RoleId" ON "AspNetRoleClaims" ("RoleId");

-- =============================================
-- 13. Bảng AspNetUserClaims (Claims của người dùng)
-- =============================================
CREATE TABLE IF NOT EXISTS "AspNetUserClaims" (
    "Id" SERIAL PRIMARY KEY,
    "UserId" TEXT NOT NULL,
    "ClaimType" TEXT,
    "ClaimValue" TEXT,
    CONSTRAINT "FK_AspNetUserClaims_AspNetUsers_UserId" FOREIGN KEY ("UserId") 
        REFERENCES "AspNetUsers" ("Id") ON DELETE CASCADE
);

CREATE INDEX IF NOT EXISTS "IX_AspNetUserClaims_UserId" ON "AspNetUserClaims" ("UserId");

-- =============================================
-- 14. Bảng AspNetUserLogins (Đăng nhập từ bên ngoài - Google, Facebook, etc.)
-- =============================================
CREATE TABLE IF NOT EXISTS "AspNetUserLogins" (
    "LoginProvider" TEXT NOT NULL,
    "ProviderKey" TEXT NOT NULL,
    "ProviderDisplayName" TEXT,
    "UserId" TEXT NOT NULL,
    CONSTRAINT "PK_AspNetUserLogins" PRIMARY KEY ("LoginProvider", "ProviderKey"),
    CONSTRAINT "FK_AspNetUserLogins_AspNetUsers_UserId" FOREIGN KEY ("UserId") 
        REFERENCES "AspNetUsers" ("Id") ON DELETE CASCADE
);

CREATE INDEX IF NOT EXISTS "IX_AspNetUserLogins_UserId" ON "AspNetUserLogins" ("UserId");

-- =============================================
-- 15. Bảng AspNetUserRoles (Quan hệ nhiều-nhiều giữa Users và Roles)
-- =============================================
CREATE TABLE IF NOT EXISTS "AspNetUserRoles" (
    "UserId" TEXT NOT NULL,
    "RoleId" TEXT NOT NULL,
    CONSTRAINT "PK_AspNetUserRoles" PRIMARY KEY ("UserId", "RoleId"),
    CONSTRAINT "FK_AspNetUserRoles_AspNetRoles_RoleId" FOREIGN KEY ("RoleId") 
        REFERENCES "AspNetRoles" ("Id") ON DELETE CASCADE,
    CONSTRAINT "FK_AspNetUserRoles_AspNetUsers_UserId" FOREIGN KEY ("UserId") 
        REFERENCES "AspNetUsers" ("Id") ON DELETE CASCADE
);

CREATE INDEX IF NOT EXISTS "IX_AspNetUserRoles_RoleId" ON "AspNetUserRoles" ("RoleId");

-- =============================================
-- 16. Bảng AspNetUserTokens (Tokens của người dùng - Refresh tokens, etc.)
-- =============================================
CREATE TABLE IF NOT EXISTS "AspNetUserTokens" (
    "UserId" TEXT NOT NULL,
    "LoginProvider" TEXT NOT NULL,
    "Name" TEXT NOT NULL,
    "Value" TEXT,
    CONSTRAINT "PK_AspNetUserTokens" PRIMARY KEY ("UserId", "LoginProvider", "Name"),
    CONSTRAINT "FK_AspNetUserTokens_AspNetUsers_UserId" FOREIGN KEY ("UserId") 
        REFERENCES "AspNetUsers" ("Id") ON DELETE CASCADE
);

-- =============================================
-- PART 3: CATALOG DATABASE (catalogdb)
-- =============================================

-- Tạo extension vector cho AI search (Neon.tech hỗ trợ)
CREATE EXTENSION IF NOT EXISTS vector;

-- =============================================
-- 17. Bảng CatalogBrand (Thương hiệu sản phẩm)
-- =============================================
CREATE TABLE IF NOT EXISTS "CatalogBrand" (
    "Id" SERIAL PRIMARY KEY,
    "Brand" VARCHAR(200) NOT NULL
);

-- =============================================
-- 18. Bảng CatalogType (Loại sản phẩm)
-- =============================================
CREATE TABLE IF NOT EXISTS "CatalogType" (
    "Id" SERIAL PRIMARY KEY,
    "Type" VARCHAR(200) NOT NULL
);

-- =============================================
-- 19. Bảng Catalog (Sản phẩm)
-- =============================================
CREATE TABLE IF NOT EXISTS "Catalog" (
    "Id" SERIAL PRIMARY KEY,
    "Name" VARCHAR(50) NOT NULL,
    "Description" TEXT,
    "Price" DECIMAL(18,2) NOT NULL,
    "PictureFileName" TEXT,
    "CatalogTypeId" INTEGER NOT NULL,
    "CatalogBrandId" INTEGER NOT NULL,
    "AvailableStock" INTEGER NOT NULL DEFAULT 0,
    "RestockThreshold" INTEGER NOT NULL DEFAULT 0,
    "MaxStockThreshold" INTEGER NOT NULL DEFAULT 0,
    "OnReorder" BOOLEAN NOT NULL DEFAULT FALSE,
    "Embedding" vector(384),
    CONSTRAINT "FK_Catalog_CatalogBrand_CatalogBrandId" FOREIGN KEY ("CatalogBrandId") 
        REFERENCES "CatalogBrand" ("Id") ON DELETE CASCADE,
    CONSTRAINT "FK_Catalog_CatalogType_CatalogTypeId" FOREIGN KEY ("CatalogTypeId") 
        REFERENCES "CatalogType" ("Id") ON DELETE CASCADE
);

CREATE INDEX IF NOT EXISTS "IX_Catalog_CatalogBrandId" ON "Catalog" ("CatalogBrandId");
CREATE INDEX IF NOT EXISTS "IX_Catalog_CatalogTypeId" ON "Catalog" ("CatalogTypeId");
CREATE INDEX IF NOT EXISTS "IX_Catalog_Name" ON "Catalog" ("Name");

-- =============================================
-- 20. Bảng IntegrationEventLog cho Catalog
-- =============================================
CREATE TABLE IF NOT EXISTS "IntegrationEventLog" (
    "EventId" UUID NOT NULL PRIMARY KEY,
    "EventTypeName" TEXT NOT NULL,
    "State" INTEGER NOT NULL,
    "TimesSent" INTEGER NOT NULL,
    "CreationTime" TIMESTAMP NOT NULL,
    "Content" TEXT NOT NULL,
    "TransactionId" UUID NOT NULL
);

CREATE INDEX IF NOT EXISTS "IX_IntegrationEventLog_State" ON "IntegrationEventLog" ("State");

-- =============================================
-- PART 4: WEBHOOKS DATABASE (webhooksdb)
-- =============================================

-- =============================================
-- 21. Bảng Subscriptions (Webhook subscriptions)
-- =============================================
CREATE TABLE IF NOT EXISTS "Subscriptions" (
    "Id" SERIAL PRIMARY KEY,
    "Type" INTEGER NOT NULL,
    "Date" TIMESTAMP NOT NULL,
    "DestUrl" TEXT NOT NULL,
    "Token" TEXT,
    "UserId" TEXT NOT NULL
);

CREATE INDEX IF NOT EXISTS "IX_Subscriptions_UserId" ON "Subscriptions" ("UserId");
CREATE INDEX IF NOT EXISTS "IX_Subscriptions_Type" ON "Subscriptions" ("Type");

-- =============================================
-- HOÀN TẤT
-- =============================================
DO $$
BEGIN
    RAISE NOTICE '=========================================';
    RAISE NOTICE 'HOÀN TẤT: Tất cả các bảng đã được tạo!';
    RAISE NOTICE '=========================================';
    RAISE NOTICE 'Lưu ý: Chạy từng PART trong database tương ứng:';
    RAISE NOTICE '  - PART 1: orderingdb';
    RAISE NOTICE '  - PART 2: identitydb';
    RAISE NOTICE '  - PART 3: catalogdb';
    RAISE NOTICE '  - PART 4: webhooksdb';
    RAISE NOTICE '=========================================';
END $$;

