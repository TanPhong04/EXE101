-- ===========================================================================
-- DATABASE SCHEMA FOR LOCAL BUDDY BACKEND
-- This schema matches the frontend mock database (db.json) and UI features 100%.
-- Designed for PostgreSQL. All tables are created with appropriate constraints.
-- ===========================================================================

-- Enable UUID extension
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- ==========================================
-- 1. ENUMS AND CUSTOM TYPES
-- ==========================================

-- User roles as defined by distinct cases in the UI
CREATE TYPE public.user_role AS ENUM (
  'TRAVELER',
  'BUDDY',
  'ADMIN'
);

-- Buddy profile verification status
CREATE TYPE public.buddy_status AS ENUM (
  'PENDING',
  'VERIFIED',
  'UNVERIFIED'
);

-- Booking status representation
CREATE TYPE public.booking_status AS ENUM (
  'PENDING',
  'CONFIRMED',
  'COMPLETED',
  'CANCELLED',
  'REJECTED'
);

-- Meetup live tracking status
CREATE TYPE public.meetup_status AS ENUM (
  'NOT_STARTED',
  'IN_PROGRESS',
  'COMPLETED'
);

-- Payment status representation
CREATE TYPE public.payment_status AS ENUM (
  'PENDING',
  'HELD',
  'RELEASED',
  'REFUNDED'
);

-- Transaction types for buddy earnings ledger
CREATE TYPE public.transaction_type AS ENUM (
  'INCOME',
  'PAYOUT'
);

-- Payout requests status
CREATE TYPE public.payout_status AS ENUM (
  'PENDING',
  'PAID'
);


-- ==========================================
-- 2. CORE TABLES
-- ==========================================

-- core users table for authentication and basic profile info
CREATE TABLE public.users (
  id uuid NOT NULL DEFAULT uuid_generate_v4(),
  email character varying NOT NULL UNIQUE,
  password_hash text NOT NULL,
  name character varying NOT NULL, -- Matches "name" in db.json
  phone character varying,
  avatar_url text, -- Store base64 or CDN URL
  role public.user_role NOT NULL DEFAULT 'TRAVELER'::public.user_role,
  is_active boolean NOT NULL DEFAULT true,
  created_at timestamp with time zone NOT NULL DEFAULT now(),
  updated_at timestamp with time zone NOT NULL DEFAULT now(),
  CONSTRAINT users_pkey PRIMARY KEY (id)
);

-- buddy specific profile details
CREATE TABLE public.buddy_profiles (
  id uuid NOT NULL DEFAULT uuid_generate_v4(),
  user_id uuid NOT NULL UNIQUE,
  age smallint CHECK (age >= 18 AND age <= 120),
  location character varying NOT NULL, -- Matches location string ("Hanoi, Vietnam")
  rating numeric DEFAULT 5.0 CHECK (rating >= 0.0 AND rating <= 5.0),
  review_count integer NOT NULL DEFAULT 0,
  languages text[] NOT NULL DEFAULT '{}', -- E.g. {"Vietnamese", "English"}
  description text, -- Matches "description" in db.json
  tags text[] DEFAULT '{}', -- E.g. {"Street Food", "Coffee Lover"}
  interests text[] DEFAULT '{}', -- E.g. {"Bike Tours", "Craft Beer"}
  price numeric NOT NULL DEFAULT 0.0 CHECK (price >= 0.0), -- Hourly rate, e.g. 8.0
  availability text, -- Text representation of schedule/availability
  id_card_front text, -- Base64/CDN URL
  id_card_back text, -- Base64/CDN URL
  verification_status public.buddy_status NOT NULL DEFAULT 'PENDING'::public.buddy_status,
  created_at timestamp with time zone NOT NULL DEFAULT now(),
  updated_at timestamp with time zone NOT NULL DEFAULT now(),
  CONSTRAINT buddy_profiles_pkey PRIMARY KEY (id),
  CONSTRAINT buddy_profiles_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id) ON DELETE CASCADE
);

-- tourist specific profile details (Travelers)
CREATE TABLE public.tourist_profiles (
  id uuid NOT NULL DEFAULT uuid_generate_v4(),
  user_id uuid NOT NULL UNIQUE,
  age smallint CHECK (age >= 0 AND age <= 120),
  nationality character varying,
  location character varying, -- Current location, e.g., "Hue, Vietnam"
  languages text[] DEFAULT '{}',
  interests text[] DEFAULT '{}', -- E.g., {"History", "Cuisine", "Old Quarter"}
  description text, -- Bio/Intro description
  verification_status public.buddy_status NOT NULL DEFAULT 'PENDING'::public.buddy_status,
  created_at timestamp with time zone NOT NULL DEFAULT now(),
  updated_at timestamp with time zone NOT NULL DEFAULT now(),
  CONSTRAINT tourist_profiles_pkey PRIMARY KEY (id),
  CONSTRAINT tourist_profiles_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id) ON DELETE CASCADE
);

-- buddy availability date-time slots
CREATE TABLE public.availability (
  id uuid NOT NULL DEFAULT uuid_generate_v4(),
  user_id uuid NOT NULL, -- References the buddy's user ID
  date date NOT NULL,
  start_time time without time zone NOT NULL,
  end_time time without time zone NOT NULL,
  is_booked boolean NOT NULL DEFAULT false,
  created_at timestamp with time zone NOT NULL DEFAULT now(),
  CONSTRAINT availability_pkey PRIMARY KEY (id),
  CONSTRAINT availability_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id) ON DELETE CASCADE
);


-- ==========================================
-- 3. CHAT SYSTEM
-- ==========================================

-- active chat conversation channels
CREATE TABLE public.conversations (
  id uuid NOT NULL DEFAULT uuid_generate_v4(),
  buddy_id uuid NOT NULL,
  user_id uuid NOT NULL, -- The traveler
  last_msg text, -- Cache for rendering conversation list faster
  last_msg_time varchar, -- Matches "time" string, e.g. "Just now"
  unread boolean NOT NULL DEFAULT false,
  created_at timestamp with time zone NOT NULL DEFAULT now(),
  updated_at timestamp with time zone NOT NULL DEFAULT now(),
  CONSTRAINT conversations_pkey PRIMARY KEY (id),
  CONSTRAINT conversations_buddy_id_fkey FOREIGN KEY (buddy_id) REFERENCES public.users(id) ON DELETE CASCADE,
  CONSTRAINT conversations_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id) ON DELETE CASCADE
);

-- messages inside conversations
CREATE TABLE public.messages (
  id uuid NOT NULL DEFAULT uuid_generate_v4(),
  conversation_id uuid NOT NULL,
  sender_id uuid NOT NULL,
  type varchar NOT NULL CHECK (type IN ('sent', 'received')),
  text text NOT NULL, -- Content of the message
  is_offer boolean NOT NULL DEFAULT false, -- If it is a booking offer
  hours integer, -- Offer specific hours
  price numeric, -- Offer specific price
  sent_at timestamp with time zone NOT NULL DEFAULT now(),
  time_display varchar, -- E.g. "10:15 AM"
  is_read boolean NOT NULL DEFAULT false,
  CONSTRAINT messages_pkey PRIMARY KEY (id),
  CONSTRAINT messages_conversation_id_fkey FOREIGN KEY (conversation_id) REFERENCES public.conversations(id) ON DELETE CASCADE,
  CONSTRAINT messages_sender_id_fkey FOREIGN KEY (sender_id) REFERENCES public.users(id) ON DELETE CASCADE
);


-- ==========================================
-- 4. BOOKINGS & FINANCIAL LEDGER
-- ==========================================

-- bookings system for scheduled meetups
CREATE TABLE public.bookings (
  id uuid NOT NULL DEFAULT uuid_generate_v4(),
  buddy_id uuid NOT NULL,
  user_id uuid NOT NULL, -- Traveler's user ID
  title character varying NOT NULL, -- E.g. "Hanoi Secret Street Food Discovery"
  status public.booking_status NOT NULL DEFAULT 'PENDING'::public.booking_status,
  booking_date varchar NOT NULL, -- Matches string representation e.g. "Oct 24, 2023"
  booking_time varchar NOT NULL, -- E.g. "09:00 AM"
  hours integer NOT NULL DEFAULT 1 CHECK (hours > 0),
  price numeric NOT NULL DEFAULT 0.0 CHECK (price >= 0.0), -- Total price of the tour
  location character varying NOT NULL, -- E.g. "Hanoi Old Quarter"
  meetup_status public.meetup_status NOT NULL DEFAULT 'NOT_STARTED'::public.meetup_status,
  created_at timestamp with time zone NOT NULL DEFAULT now(),
  updated_at timestamp with time zone NOT NULL DEFAULT now(),
  CONSTRAINT bookings_pkey PRIMARY KEY (id),
  CONSTRAINT bookings_buddy_id_fkey FOREIGN KEY (buddy_id) REFERENCES public.users(id) ON DELETE CASCADE,
  CONSTRAINT bookings_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id) ON DELETE CASCADE
);

-- booking requests system
CREATE TABLE public.booking_requests (
  id uuid NOT NULL DEFAULT uuid_generate_v4(),
  buddy_id uuid NOT NULL,
  customer_name varchar NOT NULL, -- E.g., "Robert Smith"
  received_time_text varchar, -- E.g., "Received 2 hours ago"
  activity varchar NOT NULL, -- E.g., "Hanoi Authentic Local Life"
  type varchar NOT NULL, -- E.g., "CULTURAL TOUR"
  booking_date varchar NOT NULL, -- E.g. "Oct 24, 2023"
  booking_time_text varchar NOT NULL, -- E.g. "09:00 AM (4h)"
  guests_text varchar NOT NULL, -- E.g. "2 Adults"
  languages varchar, -- E.g. "English"
  price_text varchar NOT NULL, -- E.g. "$80.00 Total"
  message text, -- Traveler message
  image_url text, -- Photo/cover image
  status varchar NOT NULL DEFAULT 'pending', -- 'pending' | 'accepted' | 'declined'
  created_at timestamp with time zone NOT NULL DEFAULT now(),
  CONSTRAINT booking_requests_pkey PRIMARY KEY (id),
  CONSTRAINT booking_requests_buddy_id_fkey FOREIGN KEY (buddy_id) REFERENCES public.users(id) ON DELETE CASCADE
);

-- cancellation reports/logs
CREATE TABLE public.cancellations (
  id uuid NOT NULL DEFAULT uuid_generate_v4(),
  booking_id uuid NOT NULL UNIQUE,
  cancelled_by varchar NOT NULL, -- E.g., 'TRAVELER' or 'BUDDY'
  cancelled_by_user_id uuid NOT NULL,
  reason text, -- Cancellation reason
  refund_amount numeric NOT NULL DEFAULT 0.0 CHECK (refund_amount >= 0.0),
  cancellation_fee numeric NOT NULL DEFAULT 0.0 CHECK (cancellation_fee >= 0.0),
  cancelled_at timestamp with time zone NOT NULL DEFAULT now(),
  CONSTRAINT cancellations_pkey PRIMARY KEY (id),
  CONSTRAINT cancellations_booking_id_fkey FOREIGN KEY (booking_id) REFERENCES public.bookings(id) ON DELETE CASCADE,
  CONSTRAINT cancellations_user_id_fkey FOREIGN KEY (cancelled_by_user_id) REFERENCES public.users(id) ON DELETE CASCADE
);

-- payment transactions for bookings (including deposits / escrows)
CREATE TABLE public.payments (
  id uuid NOT NULL DEFAULT uuid_generate_v4(),
  booking_id uuid NOT NULL UNIQUE,
  payer_id uuid NOT NULL,
  amount numeric NOT NULL CHECK (amount >= 0.0),
  deposit_amount numeric NOT NULL DEFAULT 0.0,
  deposit_pct numeric NOT NULL DEFAULT 30.00,
  remaining_amount numeric NOT NULL DEFAULT 0.0,
  status public.payment_status NOT NULL DEFAULT 'PENDING'::public.payment_status,
  payment_method character varying,
  transaction_ref character varying,
  escrow_held boolean NOT NULL DEFAULT true,
  deposited_at timestamp with time zone,
  fully_paid_at timestamp with time zone,
  released_at timestamp with time zone,
  created_at timestamp with time zone NOT NULL DEFAULT now(),
  updated_at timestamp with time zone NOT NULL DEFAULT now(),
  CONSTRAINT payments_pkey PRIMARY KEY (id),
  CONSTRAINT public_payments_booking_id_fkey FOREIGN KEY (booking_id) REFERENCES public.bookings(id) ON DELETE CASCADE,
  CONSTRAINT public_payments_payer_id_fkey FOREIGN KEY (payer_id) REFERENCES public.users(id) ON DELETE CASCADE
);

-- financial transactions (Ledger for Buddy earnings & wallets)
CREATE TABLE public.earnings_transactions (
  id uuid NOT NULL DEFAULT uuid_generate_v4(),
  buddy_id uuid NOT NULL,
  type public.transaction_type NOT NULL, -- 'income' or 'payout'
  amount numeric NOT NULL, -- Positive for income, negative for payout
  target character varying, -- E.g., "Bank Transfer" or "Booking #123"
  date_display character varying, -- Date display format, e.g. "Oct 24"
  created_at timestamp with time zone NOT NULL DEFAULT now(),
  CONSTRAINT earnings_transactions_pkey PRIMARY KEY (id),
  CONSTRAINT earnings_transactions_buddy_id_fkey FOREIGN KEY (buddy_id) REFERENCES public.users(id) ON DELETE CASCADE
);

-- payout requests submitted by buddies
CREATE TABLE public.payout_requests (
  id uuid NOT NULL DEFAULT uuid_generate_v4(),
  buddy_id uuid NOT NULL,
  amount numeric NOT NULL CHECK (amount > 0.0), -- Gross amount requested
  tax_rate numeric NOT NULL DEFAULT 0.10, -- E.g. 0.10 for 10% withholding tax
  status public.payout_status NOT NULL DEFAULT 'PENDING'::public.payout_status,
  bank_name character varying NOT NULL,
  bank_account_number character varying NOT NULL,
  bank_account_name character varying NOT NULL,
  requested_at timestamp with time zone NOT NULL DEFAULT now(),
  paid_at timestamp with time zone,
  CONSTRAINT payout_requests_pkey PRIMARY KEY (id),
  CONSTRAINT payout_requests_buddy_id_fkey FOREIGN KEY (buddy_id) REFERENCES public.users(id) ON DELETE CASCADE
);


-- ==========================================
-- 5. SOCIAL & NOTIFICATIONS
-- ==========================================

-- reviews and ratings left by travelers
CREATE TABLE public.reviews (
  id uuid NOT NULL DEFAULT uuid_generate_v4(),
  booking_id uuid NOT NULL,
  reviewer_id uuid NOT NULL,
  reviewee_id uuid NOT NULL,
  rating smallint NOT NULL CHECK (rating >= 1 AND rating <= 5),
  comment text,
  is_public boolean NOT NULL DEFAULT true,
  created_at timestamp with time zone NOT NULL DEFAULT now(),
  CONSTRAINT reviews_pkey PRIMARY KEY (id),
  CONSTRAINT reviews_booking_id_fkey FOREIGN KEY (booking_id) REFERENCES public.bookings(id) ON DELETE CASCADE,
  CONSTRAINT reviews_reviewer_id_fkey FOREIGN KEY (reviewer_id) REFERENCES public.users(id) ON DELETE CASCADE,
  CONSTRAINT reviews_reviewee_id_fkey FOREIGN KEY (reviewee_id) REFERENCES public.users(id) ON DELETE CASCADE
);

-- traveler experiences shared publicly (stories)
CREATE TABLE public.experiences (
  id uuid NOT NULL DEFAULT uuid_generate_v4(),
  title character varying NOT NULL,
  traveler_name character varying NOT NULL,
  traveler_avatar text,
  image character varying NOT NULL, -- Main visual, E.g. "/assets/img/hoian.jpg"
  location character varying NOT NULL, -- E.g., "Hoi An, Vietnam"
  date character varying NOT NULL, -- E.g., "2024-03-10"
  tags text[] DEFAULT '{}', -- E.g. {"Culture", "Craft", "Hoi An"}
  story_content text NOT NULL,
  buddy_id uuid NOT NULL,
  buddy_name character varying NOT NULL,
  rating smallint CHECK (rating >= 1 AND rating <= 5),
  pinned boolean NOT NULL DEFAULT false,
  created_at timestamp with time zone NOT NULL DEFAULT now(),
  CONSTRAINT experiences_pkey PRIMARY KEY (id),
  CONSTRAINT experiences_buddy_id_fkey FOREIGN KEY (buddy_id) REFERENCES public.users(id) ON DELETE CASCADE
);

-- push notifications to users
CREATE TABLE public.notifications (
  id uuid NOT NULL DEFAULT uuid_generate_v4(),
  receiver_id uuid NOT NULL,
  sender_id uuid,
  type character varying NOT NULL, -- E.g., 'booking'
  title character varying NOT NULL,
  description text NOT NULL,
  color character varying, -- Tailwind CSS theme color, e.g. "bg-primary/10 text-primary"
  time_text character varying, -- E.g., "5m ago"
  unread boolean NOT NULL DEFAULT true,
  created_at timestamp with time zone NOT NULL DEFAULT now(),
  CONSTRAINT notifications_pkey PRIMARY KEY (id),
  CONSTRAINT notifications_receiver_id_fkey FOREIGN KEY (receiver_id) REFERENCES public.users(id) ON DELETE CASCADE,
  CONSTRAINT notifications_sender_id_fkey FOREIGN KEY (sender_id) REFERENCES public.users(id) ON DELETE SET NULL
);

-- report user logs to maintain safety
CREATE TABLE public.user_reports (
  id uuid NOT NULL DEFAULT uuid_generate_v4(),
  reported_user_id uuid NOT NULL,
  reporter_id uuid NOT NULL,
  reason character varying NOT NULL, -- E.g., "Inappropriate behavior", "Harassment"
  description text, -- Additional details
  evidence_url text, -- Upload evidence attachment
  created_at timestamp with time zone NOT NULL DEFAULT now(),
  CONSTRAINT user_reports_pkey PRIMARY KEY (id),
  CONSTRAINT user_reports_reported_user_id_fkey FOREIGN KEY (reported_user_id) REFERENCES public.users(id) ON DELETE CASCADE,
  CONSTRAINT user_reports_reporter_id_fkey FOREIGN KEY (reporter_id) REFERENCES public.users(id) ON DELETE CASCADE
);
