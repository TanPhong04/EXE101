-- ============================================================================
-- LOCAL BUDDY - PRODUCTION READY SCHEMA
-- PostgreSQL / Supabase Compatible
-- Improved Version:
-- - Proper temporal modeling
-- - Removed UI-only fields
-- - Added indexes
-- - Added constraints
-- - Added auto updated_at triggers
-- - Improved normalization
-- ============================================================================

CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- ============================================================================
-- CLEANUP
-- ============================================================================

DROP TABLE IF EXISTS user_reports CASCADE;
DROP TABLE IF EXISTS experience_images CASCADE;
DROP TABLE IF EXISTS experiences CASCADE;
DROP TABLE IF EXISTS notifications CASCADE;
DROP TABLE IF EXISTS reviews CASCADE;
DROP TABLE IF EXISTS payout_requests CASCADE;
DROP TABLE IF EXISTS earnings_transactions CASCADE;
DROP TABLE IF EXISTS payments CASCADE;
DROP TABLE IF EXISTS cancellations CASCADE;
DROP TABLE IF EXISTS bookings CASCADE;
DROP TABLE IF EXISTS messages CASCADE;
DROP TABLE IF EXISTS conversations CASCADE;
DROP TABLE IF EXISTS availability_slots CASCADE;
DROP TABLE IF EXISTS tourist_profiles CASCADE;
DROP TABLE IF EXISTS buddy_profiles CASCADE;
DROP TABLE IF EXISTS users CASCADE;

DROP TYPE IF EXISTS user_role CASCADE;
DROP TYPE IF EXISTS verification_status CASCADE;
DROP TYPE IF EXISTS booking_status CASCADE;
DROP TYPE IF EXISTS meetup_status CASCADE;
DROP TYPE IF EXISTS payment_status CASCADE;
DROP TYPE IF EXISTS transaction_type CASCADE;
DROP TYPE IF EXISTS payout_status CASCADE;
DROP TYPE IF EXISTS payment_type CASCADE;

-- ============================================================================
-- ENUMS
-- ============================================================================

CREATE TYPE user_role AS ENUM (
    'TRAVELER',
    'BUDDY',
    'ADMIN'
);

CREATE TYPE verification_status AS ENUM (
    'PENDING',
    'VERIFIED',
    'REJECTED'
);

CREATE TYPE booking_status AS ENUM (
    'PENDING',
    'CONFIRMED',
    'COMPLETED',
    'CANCELLED',
    'REJECTED'
);

CREATE TYPE meetup_status AS ENUM (
    'NOT_STARTED',
    'IN_PROGRESS',
    'COMPLETED'
);

CREATE TYPE payment_status AS ENUM (
    'PENDING',
    'HELD',
    'RELEASED',
    'REFUNDED',
    'FAILED'
);

CREATE TYPE payment_type AS ENUM (
    'DEPOSIT',
    'FULL_PAYMENT',
    'REFUND'
);

CREATE TYPE transaction_type AS ENUM (
    'INCOME',
    'PAYOUT'
);

CREATE TYPE payout_status AS ENUM (
    'PENDING',
    'PAID',
    'REJECTED'
);

-- ============================================================================
-- UPDATED_AT TRIGGER
-- ============================================================================

CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
   NEW.updated_at = now();
   RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- ============================================================================
-- USERS
-- ============================================================================

CREATE TABLE users (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),

    email VARCHAR(255) NOT NULL UNIQUE,
    password_hash TEXT NOT NULL,

    full_name VARCHAR(255) NOT NULL,
    phone VARCHAR(20),

    avatar_url TEXT,

    role user_role NOT NULL DEFAULT 'TRAVELER',

    is_buddy BOOLEAN NOT NULL DEFAULT false,
    is_active BOOLEAN NOT NULL DEFAULT true,

    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    deleted_at TIMESTAMPTZ
);

CREATE TRIGGER trg_users_updated_at
BEFORE UPDATE ON users
FOR EACH ROW
EXECUTE FUNCTION update_updated_at_column();

-- ============================================================================
-- BUDDY PROFILES
-- ============================================================================

CREATE TABLE buddy_profiles (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),

    user_id UUID NOT NULL UNIQUE REFERENCES users(id) ON DELETE CASCADE,

    age SMALLINT CHECK(age >= 18 AND age <= 120),

    location VARCHAR(255) NOT NULL,

    latitude NUMERIC(10,7),
    longitude NUMERIC(10,7),

    bio TEXT,

    languages TEXT[] DEFAULT '{}',
    tags TEXT[] DEFAULT '{}',
    interests TEXT[] DEFAULT '{}',

    hourly_rate NUMERIC(10,2) NOT NULL CHECK(hourly_rate >= 0),

    rating NUMERIC(2,1) NOT NULL DEFAULT 5.0
        CHECK(rating >= 0 AND rating <= 5),

    review_count INTEGER NOT NULL DEFAULT 0,

    verification_status verification_status NOT NULL DEFAULT 'PENDING',

    id_card_front_url TEXT,
    id_card_back_url TEXT,

    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TRIGGER trg_buddy_profiles_updated_at
BEFORE UPDATE ON buddy_profiles
FOR EACH ROW
EXECUTE FUNCTION update_updated_at_column();

-- ============================================================================
-- TOURIST PROFILES
-- ============================================================================

CREATE TABLE tourist_profiles (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),

    user_id UUID NOT NULL UNIQUE REFERENCES users(id) ON DELETE CASCADE,

    nationality VARCHAR(100),

    bio TEXT,

    languages TEXT[] DEFAULT '{}',
    interests TEXT[] DEFAULT '{}',

    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TRIGGER trg_tourist_profiles_updated_at
BEFORE UPDATE ON tourist_profiles
FOR EACH ROW
EXECUTE FUNCTION update_updated_at_column();

-- ============================================================================
-- AVAILABILITY
-- ============================================================================

CREATE TABLE availability_slots (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),

    buddy_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,

    start_time TIMESTAMPTZ NOT NULL,
    end_time TIMESTAMPTZ NOT NULL,

    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),

    CONSTRAINT chk_availability_time
        CHECK(end_time > start_time)
);

-- ============================================================================
-- CONVERSATIONS
-- ============================================================================

CREATE TABLE conversations (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),

    traveler_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    buddy_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,

    last_message_id UUID,

    last_message_at TIMESTAMPTZ,

    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),

    CONSTRAINT uq_conversation UNIQUE(traveler_id, buddy_id)
);

CREATE TRIGGER trg_conversations_updated_at
BEFORE UPDATE ON conversations
FOR EACH ROW
EXECUTE FUNCTION update_updated_at_column();

-- ============================================================================
-- MESSAGES
-- ============================================================================

CREATE TABLE messages (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),

    conversation_id UUID NOT NULL
        REFERENCES conversations(id)
        ON DELETE CASCADE,

    sender_id UUID NOT NULL
        REFERENCES users(id)
        ON DELETE CASCADE,

    content TEXT NOT NULL,

    is_offer BOOLEAN NOT NULL DEFAULT false,

    offered_hours INTEGER,
    offered_price NUMERIC(10,2),

    is_read BOOLEAN NOT NULL DEFAULT false,

    created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- ============================================================================
-- BOOKINGS
-- ============================================================================

CREATE TABLE bookings (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),

    traveler_id UUID NOT NULL
        REFERENCES users(id)
        ON DELETE CASCADE,

    buddy_id UUID NOT NULL
        REFERENCES users(id)
        ON DELETE CASCADE,

    title VARCHAR(255) NOT NULL,

    description TEXT,

    location VARCHAR(255) NOT NULL,

    start_time TIMESTAMPTZ NOT NULL,
    end_time TIMESTAMPTZ NOT NULL,

    total_hours INTEGER NOT NULL CHECK(total_hours > 0),

    total_price NUMERIC(10,2) NOT NULL CHECK(total_price >= 0),

    status booking_status NOT NULL DEFAULT 'PENDING',

    meetup_status meetup_status NOT NULL DEFAULT 'NOT_STARTED',

    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),

    CONSTRAINT chk_booking_time
        CHECK(end_time > start_time)
);

CREATE TRIGGER trg_bookings_updated_at
BEFORE UPDATE ON bookings
FOR EACH ROW
EXECUTE FUNCTION update_updated_at_column();

-- ============================================================================
-- CANCELLATIONS
-- ============================================================================

CREATE TABLE cancellations (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),

    booking_id UUID NOT NULL UNIQUE
        REFERENCES bookings(id)
        ON DELETE CASCADE,

    cancelled_by_user_id UUID NOT NULL
        REFERENCES users(id)
        ON DELETE CASCADE,

    reason TEXT,

    refund_amount NUMERIC(10,2) DEFAULT 0
        CHECK(refund_amount >= 0),

    cancellation_fee NUMERIC(10,2) DEFAULT 0
        CHECK(cancellation_fee >= 0),

    created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- ============================================================================
-- PAYMENTS
-- ============================================================================

CREATE TABLE payments (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),

    booking_id UUID NOT NULL
        REFERENCES bookings(id)
        ON DELETE CASCADE,

    payer_id UUID NOT NULL
        REFERENCES users(id)
        ON DELETE CASCADE,

    payment_type payment_type NOT NULL,

    amount NUMERIC(10,2) NOT NULL
        CHECK(amount >= 0),

    status payment_status NOT NULL DEFAULT 'PENDING',

    payment_method VARCHAR(100),

    transaction_reference VARCHAR(255),

    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    paid_at TIMESTAMPTZ
);

-- ============================================================================
-- EARNINGS LEDGER
-- ============================================================================

CREATE TABLE earnings_transactions (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),

    buddy_id UUID NOT NULL
        REFERENCES users(id)
        ON DELETE CASCADE,

    booking_id UUID
        REFERENCES bookings(id)
        ON DELETE SET NULL,

    transaction_type transaction_type NOT NULL,

    amount NUMERIC(10,2) NOT NULL,

    description TEXT,

    created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- ============================================================================
-- PAYOUT REQUESTS
-- ============================================================================

CREATE TABLE payout_requests (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),

    buddy_id UUID NOT NULL
        REFERENCES users(id)
        ON DELETE CASCADE,

    amount NUMERIC(10,2) NOT NULL
        CHECK(amount > 0),

    tax_rate NUMERIC(5,2) NOT NULL DEFAULT 10.00,

    status payout_status NOT NULL DEFAULT 'PENDING',

    bank_name VARCHAR(255) NOT NULL,
    bank_account_name VARCHAR(255) NOT NULL,
    bank_account_number VARCHAR(100) NOT NULL,

    requested_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    processed_at TIMESTAMPTZ
);

-- ============================================================================
-- REVIEWS
-- ============================================================================

CREATE TABLE reviews (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),

    booking_id UUID NOT NULL
        REFERENCES bookings(id)
        ON DELETE CASCADE,

    reviewer_id UUID NOT NULL
        REFERENCES users(id)
        ON DELETE CASCADE,

    reviewee_id UUID NOT NULL
        REFERENCES users(id)
        ON DELETE CASCADE,

    rating SMALLINT NOT NULL
        CHECK(rating BETWEEN 1 AND 5),

    comment TEXT,

    is_public BOOLEAN NOT NULL DEFAULT true,

    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),

    CONSTRAINT uq_review_per_booking
        UNIQUE(booking_id, reviewer_id)
);

-- ============================================================================
-- EXPERIENCES
-- ============================================================================

CREATE TABLE experiences (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),

    traveler_id UUID NOT NULL
        REFERENCES users(id)
        ON DELETE CASCADE,

    buddy_id UUID NOT NULL
        REFERENCES users(id)
        ON DELETE CASCADE,

    title VARCHAR(255) NOT NULL,

    story_content TEXT NOT NULL,

    location VARCHAR(255),

    rating SMALLINT
        CHECK(rating BETWEEN 1 AND 5),

    tags TEXT[] DEFAULT '{}',

    is_pinned BOOLEAN NOT NULL DEFAULT false,

    created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- ============================================================================
-- EXPERIENCE IMAGES (1-to-N Gallery)
-- ============================================================================

CREATE TABLE experience_images (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),

    experience_id UUID NOT NULL
        REFERENCES experiences(id)
        ON DELETE CASCADE,

    image_url TEXT NOT NULL,
    display_order INTEGER DEFAULT 0,

    created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- ============================================================================
-- NOTIFICATIONS
-- ============================================================================

CREATE TABLE notifications (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),

    receiver_id UUID NOT NULL
        REFERENCES users(id)
        ON DELETE CASCADE,

    sender_id UUID
        REFERENCES users(id)
        ON DELETE SET NULL,

    type VARCHAR(100) NOT NULL,

    title VARCHAR(255) NOT NULL,

    content TEXT NOT NULL,

    is_read BOOLEAN NOT NULL DEFAULT false,

    created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- ============================================================================
-- USER REPORTS
-- ============================================================================

CREATE TABLE user_reports (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),

    reported_user_id UUID NOT NULL
        REFERENCES users(id)
        ON DELETE CASCADE,

    reporter_id UUID NOT NULL
        REFERENCES users(id)
        ON DELETE CASCADE,

    reason VARCHAR(255) NOT NULL,

    description TEXT,

    evidence_url TEXT,

    created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- ============================================================================
-- INDEXES
-- ============================================================================

CREATE INDEX idx_users_email
ON users(email);

CREATE INDEX idx_buddy_profiles_user_id
ON buddy_profiles(user_id);

CREATE INDEX idx_availability_buddy_id
ON availability_slots(buddy_id);

CREATE INDEX idx_availability_time
ON availability_slots(start_time, end_time);

CREATE INDEX idx_messages_conversation_id
ON messages(conversation_id);

CREATE INDEX idx_messages_sender_id
ON messages(sender_id);

CREATE INDEX idx_bookings_traveler_id
ON bookings(traveler_id);

CREATE INDEX idx_bookings_buddy_id
ON bookings(buddy_id);

CREATE INDEX idx_bookings_status
ON bookings(status);

CREATE INDEX idx_payments_booking_id
ON payments(booking_id);

CREATE INDEX idx_earnings_buddy_id
ON earnings_transactions(buddy_id);

CREATE INDEX idx_reviews_reviewee
ON reviews(reviewee_id);

CREATE INDEX idx_notifications_receiver
ON notifications(receiver_id);

CREATE INDEX idx_experience_images_experience_id
ON experience_images(experience_id);

-- ============================================================================
-- FOREIGN KEY FIX FOR LAST MESSAGE
-- ============================================================================

ALTER TABLE conversations
ADD CONSTRAINT fk_last_message
FOREIGN KEY(last_message_id)
REFERENCES messages(id)
ON DELETE SET NULL;
