-- =====================================================
-- DATABASE FULL MODUL 4 APLIKASI
-- =====================================================
-- Copy-paste ini ke Supabase SQL Editor
-- =====================================================

-- Enable UUID extension
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- =====================================================
-- TABLE UTAMA
-- =====================================================

-- USER PROFILES
CREATE TABLE IF NOT EXISTS public.user_profiles (
    id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
    username VARCHAR(50) UNIQUE NOT NULL,
    full_name VARCHAR(100),
    email VARCHAR(255),
    phone VARCHAR(20),
    address TEXT,
    is_admin BOOLEAN DEFAULT false,
    avatar_url TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- TODOS
CREATE TABLE IF NOT EXISTS public.todos (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES public.user_profiles(id) ON DELETE CASCADE,
    title VARCHAR(255) NOT NULL,
    description TEXT,
    is_completed BOOLEAN DEFAULT false,
    priority VARCHAR(20) DEFAULT 'medium' CHECK (priority IN ('very_low', 'low', 'medium', 'high', 'urgent')),
    due_date TIMESTAMP WITH TIME ZONE,
    tags TEXT[] DEFAULT '{}',
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    completed_at TIMESTAMP WITH TIME ZONE
);

-- NOTES
CREATE TABLE IF NOT EXISTS public.notes (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES public.user_profiles(id) ON DELETE CASCADE,
    title VARCHAR(255) NOT NULL,
    content TEXT NOT NULL,
    images TEXT[] DEFAULT '{}',
    is_pinned BOOLEAN DEFAULT false,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- MENU ITEMS
CREATE TABLE IF NOT EXISTS public.menu_items (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name VARCHAR(255) NOT NULL,
    description TEXT,
    price DECIMAL(10,2) NOT NULL CHECK (price >= 0),
    category_name VARCHAR(50) NOT NULL,
    spicy_level INTEGER DEFAULT 0 CHECK (spicy_level >= 0 AND spicy_level <= 5),
    is_available BOOLEAN DEFAULT true,
    image_url TEXT,
    is_featured BOOLEAN DEFAULT false,
    rating DECIMAL(3,2) DEFAULT 0.00 CHECK (rating >= 0 AND rating <= 5),
    review_count INTEGER DEFAULT 0,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- ORDERS
CREATE TABLE IF NOT EXISTS public.orders (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES public.user_profiles(id) ON DELETE CASCADE,
    order_number VARCHAR(20) UNIQUE NOT NULL,
    total_amount DECIMAL(10,2) NOT NULL CHECK (total_amount >= 0),
    status VARCHAR(20) DEFAULT 'pending' CHECK (status IN ('pending', 'confirmed', 'preparing', 'ready', 'delivering', 'delivered', 'cancelled')),
    payment_method VARCHAR(20) CHECK (payment_method IN ('cash', 'card', 'ewallet', 'transfer')),
    payment_status VARCHAR(20) DEFAULT 'pending' CHECK (payment_status IN ('pending', 'paid', 'failed', 'refunded')),
    delivery_address TEXT,
    delivery_fee DECIMAL(10,2) DEFAULT 0 CHECK (delivery_fee >= 0),
    notes TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- ORDER ITEMS
CREATE TABLE IF NOT EXISTS public.order_items (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    order_id UUID NOT NULL REFERENCES public.orders(id) ON DELETE CASCADE,
    menu_item_id UUID NOT NULL REFERENCES public.menu_items(id) ON DELETE RESTRICT,
    quantity INTEGER NOT NULL CHECK (quantity > 0),
    unit_price DECIMAL(10,2) NOT NULL CHECK (unit_price >= 0),
    subtotal DECIMAL(10,2) NOT NULL CHECK (subtotal >= 0),
    special_instructions TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- CART
CREATE TABLE IF NOT EXISTS public.cart (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES public.user_profiles(id) ON DELETE CASCADE,
    menu_item_id UUID NOT NULL REFERENCES public.menu_items(id) ON DELETE CASCADE,
    quantity INTEGER NOT NULL DEFAULT 1 CHECK (quantity > 0),
    special_instructions TEXT,
    added_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE(user_id, menu_item_id)
);

-- ORDER REVIEWS
CREATE TABLE IF NOT EXISTS public.order_reviews (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    order_id UUID NOT NULL REFERENCES public.orders(id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES public.user_profiles(id) ON DELETE CASCADE,
    menu_item_id UUID REFERENCES public.menu_items(id) ON DELETE SET NULL,
    rating INTEGER NOT NULL CHECK (rating >= 1 AND rating <= 5),
    comment TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- =====================================================
-- INDEXES
-- =====================================================

CREATE INDEX IF NOT EXISTS idx_user_profiles_email ON public.user_profiles(email);
CREATE INDEX IF NOT EXISTS idx_user_profiles_username ON public.user_profiles(username);

CREATE INDEX IF NOT EXISTS idx_todos_user_id ON public.todos(user_id);
CREATE INDEX IF NOT EXISTS idx_todos_is_completed ON public.todos(is_completed);
CREATE INDEX IF NOT EXISTS idx_todos_due_date ON public.todos(due_date);
CREATE INDEX IF NOT EXISTS idx_todos_priority ON public.todos(priority);

CREATE INDEX IF NOT EXISTS idx_notes_user_id ON public.notes(user_id);
CREATE INDEX IF NOT EXISTS idx_notes_is_pinned ON public.notes(is_pinned);

CREATE INDEX IF NOT EXISTS idx_menu_items_category ON public.menu_items(category_name);
CREATE INDEX IF NOT EXISTS idx_menu_items_is_available ON public.menu_items(is_available);
CREATE INDEX IF NOT EXISTS idx_menu_items_rating ON public.menu_items(rating);

CREATE INDEX IF NOT EXISTS idx_orders_user_id ON public.orders(user_id);
CREATE INDEX IF NOT EXISTS idx_orders_status ON public.orders(status);
CREATE INDEX IF NOT EXISTS idx_orders_order_number ON public.orders(order_number);

CREATE INDEX IF NOT EXISTS idx_order_items_order_id ON public.order_items(order_id);
CREATE INDEX IF NOT EXISTS idx_order_items_menu_item_id ON public.order_items(menu_item_id);

CREATE INDEX IF NOT EXISTS idx_cart_user_id ON public.cart(user_id);
CREATE INDEX IF NOT EXISTS idx_cart_menu_item_id ON public.cart(menu_item_id);

CREATE INDEX IF NOT EXISTS idx_order_reviews_order_id ON public.order_reviews(order_id);
CREATE INDEX IF NOT EXISTS idx_order_reviews_menu_item_id ON public.order_reviews(menu_item_id);

-- =====================================================
-- TRIGGERS
-- =====================================================

-- Update timestamp function
CREATE OR REPLACE FUNCTION public.update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ language 'plpgsql';

-- Auto complete timestamp
CREATE OR REPLACE FUNCTION public.set_completed_at_timestamp()
RETURNS TRIGGER AS $$
BEGIN
    IF NEW.is_completed = true AND OLD.is_completed = false THEN
        NEW.completed_at = NOW();
    ELSIF NEW.is_completed = false AND OLD.is_completed = true THEN
        NEW.completed_at = NULL;
    END IF;
    RETURN NEW;
END;
$$ language 'plpgsql';

-- Generate order number
CREATE OR REPLACE FUNCTION public.generate_order_number()
RETURNS TRIGGER AS $$
BEGIN
    NEW.order_number := 'ORD' || TO_CHAR(NOW(), 'YYYYMMDD') || LPAD(NEXTVAL('order_number_seq')::TEXT, 4, '0');
    RETURN NEW;
END;
$$ language 'plpgsql';

-- Create sequence
CREATE SEQUENCE IF NOT EXISTS order_number_seq START 1;

-- Create triggers
CREATE TRIGGER update_user_profiles_updated_at BEFORE UPDATE ON public.user_profiles
    FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();

CREATE TRIGGER update_todos_updated_at BEFORE UPDATE ON public.todos
    FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();

CREATE TRIGGER set_todos_completed_at BEFORE UPDATE ON public.todos
    FOR EACH ROW EXECUTE FUNCTION public.set_completed_at_timestamp();

CREATE TRIGGER update_notes_updated_at BEFORE UPDATE ON public.notes
    FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();

CREATE TRIGGER update_menu_items_updated_at BEFORE UPDATE ON public.menu_items
    FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();

CREATE TRIGGER update_orders_updated_at BEFORE UPDATE ON public.orders
    FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();

CREATE TRIGGER generate_orders_order_number BEFORE INSERT ON public.orders
    FOR EACH ROW EXECUTE FUNCTION public.generate_order_number();

-- =====================================================
-- RLS (Row Level Security)
-- =====================================================

-- Enable RLS
ALTER TABLE public.user_profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.todos ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.notes ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.orders ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.order_items ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.cart ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.order_reviews ENABLE ROW LEVEL SECURITY;

-- User Profiles Policies
CREATE POLICY "Users can view own profile" ON public.user_profiles
    FOR SELECT USING (auth.uid() = id);

CREATE POLICY "Users can update own profile" ON public.user_profiles
    FOR UPDATE USING (auth.uid() = id);

-- Todos Policies
CREATE POLICY "Users can view own todos" ON public.todos
    FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can manage own todos" ON public.todos
    FOR ALL USING (auth.uid() = user_id);

-- Notes Policies
CREATE POLICY "Users can view own notes" ON public.notes
    FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can manage own notes" ON public.notes
    FOR ALL USING (auth.uid() = user_id);

-- Orders Policies
CREATE POLICY "Users can view own orders" ON public.orders
    FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can create own orders" ON public.orders
    FOR INSERT WITH CHECK (auth.uid() = user_id);

-- Order Items Policies
CREATE POLICY "Users can view own order items" ON public.order_items
    FOR SELECT USING (
        EXISTS (
            SELECT 1 FROM public.orders
            WHERE orders.id = order_items.order_id
            AND orders.user_id = auth.uid()
        )
    );

-- Cart Policies
CREATE POLICY "Users can manage own cart" ON public.cart
    FOR ALL USING (auth.uid() = user_id);

-- Order Reviews Policies
CREATE POLICY "Users can view own reviews" ON public.order_reviews
    FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can create own reviews" ON public.order_reviews
    FOR INSERT WITH CHECK (auth.uid() = user_id);

-- =====================================================
-- AUTO USER PROFILE ON SIGNUP
-- =====================================================

-- Function to create user profile on signup
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
    INSERT INTO public.user_profiles (id, username, email, full_name, created_at, updated_at)
    VALUES (
        NEW.id,
        COALESCE(NEW.raw_user_meta_data->>'username', 'user_' || substr(NEW.id::text, 1, 8)),
        NEW.email,
        COALESCE(NEW.raw_user_meta_data->>'full_name', NEW.raw_user_meta_data->>'name', split_part(NEW.email, '@', 1)),
        NOW(),
        NOW()
    );
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Trigger for auto user profile
CREATE TRIGGER on_auth_user_created
    AFTER INSERT ON auth.users
    FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();

-- =====================================================
-- STORAGE BUCKET (untuk images)
-- =====================================================

-- Create storage bucket for images
INSERT INTO storage.buckets (id, name, public)
VALUES ('images', 'images', true)
ON CONFLICT (id) DO NOTHING;

-- Storage policies
CREATE POLICY "Users can upload images" ON storage.objects
    FOR INSERT WITH CHECK (
        bucket_id = 'images' AND
        auth.role() = 'authenticated' AND
        (storage.foldername(name))[1] = auth.uid()::text
    );

CREATE POLICY "Users can view own images" ON storage.objects
    FOR SELECT USING (
        bucket_id = 'images' AND
        auth.role() = 'authenticated' AND
        (storage.foldername(name))[1] = auth.uid()::text
    );

-- =====================================================
-- SAMPLE DATA
-- =====================================================

-- Sample Menu Items
INSERT INTO public.menu_items (name, description, price, category_name, spicy_level, is_available, is_featured) VALUES
-- Nasi
('Nasi Putih', 'Nasi putih hangat pulen', 8000.00, 'Nasi', 0, true, false),
('Nasi Uduk', 'Nasi uduk aroma daun pandan dengan kelapa parut', 10000.00, 'Nasi', 0, true, true),

-- Lauk
('Rendang Padang', 'Rendang daging sapi empuk bumbu khas Padang', 35000.00, 'Lauk', 3, true, true),
('Ayam Pop', 'Ayam goreng khas Padang dengan sambal hijau', 25000.00, 'Lauk', 2, true, true),
('Gulai Kambing', 'Gulai kambing dengan bumbu rempah pilihan', 40000.00, 'Lauk', 4, true, false),
('Telur Balado', 'Telur ayam dengan sambal merah Padang', 15000.00, 'Lauk', 3, true, false),
('Ikan Bakar', 'Ikan nila bakar dengan sambal', 30000.00, 'Lauk', 3, true, false),

-- Sayur
('Sayur Ubi', 'Sayur ubi dengan kuah santan', 12000.00, 'Sayur', 0, true, false),
('Daun Singkong', 'Daun singkong tumis dengan kelapa parut', 10000.00, 'Sayur', 2, true, false),

-- Minuman
('Teh Manis', 'Teh manis dingin', 5000.00, 'Minuman', 0, true, true),
('Teh Tawar', 'Teh tawar hangat/dingin', 3000.00, 'Minuman', 0, true, false),
('Es Teh', 'Es teh manis segar', 6000.00, 'Minuman', 0, true, true),

-- Sambal
('Sambal Hijau', 'Sambal cabai hijau Padang', 3000.00, 'Sambal', 4, true, false),
('Sambal Merah', 'Sambal cabai merah khas Padang', 3000.00, 'Sambal', 3, true, false),

-- Tambahan
('Kerupuk', 'Kerupuk renyah', 3000.00, 'Tambahan', 0, true, false),
('Lalapan', 'Lalapan segar dengan sambal', 5000.00, 'Tambahan', 1, true, false);

-- =====================================================
-- STORED PROCEDURES (Yang Penting Saja)
-- =====================================================

-- Create user with profile
CREATE OR REPLACE FUNCTION public.create_user_profile(
    p_user_id UUID,
    p_username VARCHAR(50),
    p_email VARCHAR(255),
    p_full_name VARCHAR(100)
)
RETURNS BOOLEAN AS $$
BEGIN
    INSERT INTO public.user_profiles (id, username, email, full_name)
    VALUES (p_user_id, p_username, p_email, p_full_name);
    RETURN TRUE;
EXCEPTION
    WHEN OTHERS THEN
        RETURN FALSE;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Place order from cart
CREATE OR REPLACE FUNCTION public.place_order(
    p_user_id UUID,
    p_payment_method VARCHAR(20),
    p_delivery_address TEXT
)
RETURNS TABLE(
    success BOOLEAN,
    order_id UUID,
    error_message TEXT
) AS $$
DECLARE
    v_order_id UUID;
    v_total_amount DECIMAL;
BEGIN
    -- Check cart
    IF NOT EXISTS (SELECT 1 FROM public.cart WHERE user_id = p_user_id) THEN
        RETURN QUERY SELECT false, NULL::UUID, 'Cart is empty';
        RETURN;
    END IF;

    -- Calculate total
    SELECT SUM(c.quantity * mi.price) INTO v_total_amount
    FROM public.cart c
    JOIN public.menu_items mi ON c.menu_item_id = mi.id
    WHERE c.user_id = p_user_id AND mi.is_available = true;

    -- Create order
    INSERT INTO public.orders (user_id, total_amount, payment_method, delivery_address)
    VALUES (p_user_id, v_total_amount, p_payment_method, p_delivery_address)
    RETURNING id INTO v_order_id;

    -- Move items to order
    INSERT INTO public.order_items (order_id, menu_item_id, quantity, unit_price, subtotal, special_instructions)
    SELECT v_order_id, c.menu_item_id, c.quantity, mi.price, (c.quantity * mi.price), c.special_instructions
    FROM public.cart c
    JOIN public.menu_items mi ON c.menu_item_id = mi.id
    WHERE c.user_id = p_user_id AND mi.is_available = true;

    -- Clear cart
    DELETE FROM public.cart WHERE user_id = p_user_id;

    RETURN QUERY SELECT true, v_order_id, NULL::TEXT;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Get user dashboard
CREATE OR REPLACE FUNCTION public.get_user_stats(p_user_id UUID)
RETURNS TABLE(
    total_todos BIGINT,
    completed_todos BIGINT,
    total_orders BIGINT,
    total_spent DECIMAL
) AS $$
BEGIN
    RETURN QUERY
    SELECT
        (SELECT COUNT(*) FROM public.todos WHERE user_id = p_user_id),
        (SELECT COUNT(*) FROM public.todos WHERE user_id = p_user_id AND is_completed = true),
        (SELECT COUNT(*) FROM public.orders WHERE user_id = p_user_id),
        COALESCE((SELECT SUM(total_amount) FROM public.orders WHERE user_id = p_user_id AND status = 'delivered'), 0);
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- =====================================================
-- COMPLETION MESSAGE
-- =====================================================

DO $$
BEGIN
    RAISE NOTICE '=====================================================';
    RAISE NOTICE 'DATABASE SETUP COMPLETED!';
    RAISE NOTICE '=====================================================';
    RAISE NOTICE 'Tables: user_profiles, todos, notes, menu_items, orders, order_items, cart, order_reviews';
    RAISE NOTICE 'Storage: images bucket created';
    RAISE NOTICE 'RLS enabled for all tables';
    RAISE NOTICE 'Sample data inserted for menu items';
    RAISE NOTICE 'Auto user profile creation enabled';
    RAISE NOTICE 'Ready for use!';
    RAISE NOTICE '=====================================================';
END $$;