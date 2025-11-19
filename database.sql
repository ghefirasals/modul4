-- =====================================================
-- COMPLETE DATABASE SCHEMA FOR MODUL 4 APPLICATION
-- =====================================================
-- Copy-paste this entire file to your Supabase SQL Editor
-- =====================================================

-- Enable necessary extensions
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- =====================================================
-- USER PROFILES TABLE
-- =====================================================
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

-- Create index for faster queries
CREATE INDEX IF NOT EXISTS idx_user_profiles_email ON public.user_profiles(email);
CREATE INDEX IF NOT EXISTS idx_user_profiles_username ON public.user_profiles(username);

-- =====================================================
-- TODOS TABLE
-- =====================================================
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
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create indexes for better performance
CREATE INDEX IF NOT EXISTS idx_todos_user_id ON public.todos(user_id);
CREATE INDEX IF NOT EXISTS idx_todos_is_completed ON public.todos(is_completed);
CREATE INDEX IF NOT EXISTS idx_todos_due_date ON public.todos(due_date);
CREATE INDEX IF NOT EXISTS idx_todos_priority ON public.todos(priority);
CREATE INDEX IF NOT EXISTS idx_todos_created_at ON public.todos(created_at);

-- =====================================================
-- NOTES TABLE
-- =====================================================
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

-- Create indexes for better performance
CREATE INDEX IF NOT EXISTS idx_notes_user_id ON public.notes(user_id);
CREATE INDEX IF NOT EXISTS idx_notes_is_pinned ON public.notes(is_pinned);
CREATE INDEX IF NOT EXISTS idx_notes_created_at ON public.notes(created_at);
CREATE INDEX IF NOT EXISTS idx_notes_updated_at ON public.notes(updated_at);

-- =====================================================
-- RESTAURANT MENU ITEMS TABLE
-- =====================================================
CREATE TABLE IF NOT EXISTS public.menu_items (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name VARCHAR(255) NOT NULL,
    description TEXT,
    price DECIMAL(10,2) NOT NULL CHECK (price >= 0),
    category_name VARCHAR(50) NOT NULL,
    spicy_level INTEGER DEFAULT 0 CHECK (spicy_level >= 0 AND spicy_level <= 5),
    is_available BOOLEAN DEFAULT true,
    image_url TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create indexes for better performance
CREATE INDEX IF NOT EXISTS idx_menu_items_category ON public.menu_items(category_name);
CREATE INDEX IF NOT EXISTS idx_menu_items_is_available ON public.menu_items(is_available);
CREATE INDEX IF NOT EXISTS idx_menu_items_price ON public.menu_items(price);

-- =====================================================
-- ORDERS TABLE
-- =====================================================
CREATE TABLE IF NOT EXISTS public.orders (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES public.user_profiles(id) ON DELETE CASCADE,
    total_amount DECIMAL(10,2) NOT NULL CHECK (total_amount >= 0),
    status VARCHAR(20) DEFAULT 'pending' CHECK (status IN ('pending', 'confirmed', 'preparing', 'ready', 'delivered', 'cancelled')),
    delivery_address TEXT,
    delivery_fee DECIMAL(10,2) DEFAULT 0 CHECK (delivery_fee >= 0),
    tax_amount DECIMAL(10,2) DEFAULT 0 CHECK (tax_amount >= 0),
    notes TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create indexes for better performance
CREATE INDEX IF NOT EXISTS idx_orders_user_id ON public.orders(user_id);
CREATE INDEX IF NOT EXISTS idx_orders_status ON public.orders(status);
CREATE INDEX IF NOT EXISTS idx_orders_created_at ON public.orders(created_at);

-- =====================================================
-- ORDER ITEMS TABLE
-- =====================================================
CREATE TABLE IF NOT EXISTS public.order_items (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    order_id UUID NOT NULL REFERENCES public.orders(id) ON DELETE CASCADE,
    menu_item_id UUID NOT NULL REFERENCES public.menu_items(id) ON DELETE RESTRICT,
    quantity INTEGER NOT NULL CHECK (quantity > 0),
    unit_price DECIMAL(10,2) NOT NULL CHECK (unit_price >= 0),
    subtotal DECIMAL(10,2) NOT NULL CHECK (subtotal >= 0),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create indexes for better performance
CREATE INDEX IF NOT EXISTS idx_order_items_order_id ON public.order_items(order_id);
CREATE INDEX IF NOT EXISTS idx_order_items_menu_item_id ON public.order_items(menu_item_id);

-- =====================================================
-- TRIGGERS FOR UPDATED_AT
-- =====================================================

-- Function to update updated_at column
CREATE OR REPLACE FUNCTION public.update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ language 'plpgsql';

-- Create triggers for all tables
CREATE TRIGGER update_user_profiles_updated_at BEFORE UPDATE ON public.user_profiles
    FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();

CREATE TRIGGER update_todos_updated_at BEFORE UPDATE ON public.todos
    FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();

CREATE TRIGGER update_notes_updated_at BEFORE UPDATE ON public.notes
    FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();

CREATE TRIGGER update_menu_items_updated_at BEFORE UPDATE ON public.menu_items
    FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();

CREATE TRIGGER update_orders_updated_at BEFORE UPDATE ON public.orders
    FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();

-- =====================================================
-- RLS (ROW LEVEL SECURITY) POLICIES
-- =====================================================

-- Enable RLS on all tables
ALTER TABLE public.user_profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.todos ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.notes ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.orders ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.order_items ENABLE ROW LEVEL SECURITY;

-- User Profiles Policies
CREATE POLICY "Users can view own profile" ON public.user_profiles
    FOR SELECT USING (auth.uid() = id);

CREATE POLICY "Users can update own profile" ON public.user_profiles
    FOR UPDATE USING (auth.uid() = id);

CREATE POLICY "Users can insert own profile" ON public.user_profiles
    FOR INSERT WITH CHECK (auth.uid() = id);

-- Todos Policies
CREATE POLICY "Users can view own todos" ON public.todos
    FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can create own todos" ON public.todos
    FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update own todos" ON public.todos
    FOR UPDATE USING (auth.uid() = user_id);

CREATE POLICY "Users can delete own todos" ON public.todos
    FOR DELETE USING (auth.uid() = user_id);

-- Notes Policies
CREATE POLICY "Users can view own notes" ON public.notes
    FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can create own notes" ON public.notes
    FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update own notes" ON public.notes
    FOR UPDATE USING (auth.uid() = user_id);

CREATE POLICY "Users can delete own notes" ON public.notes
    FOR DELETE USING (auth.uid() = user_id);

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

-- =====================================================
-- STORAGE BUCKET FOR NOTE IMAGES
-- =====================================================

-- Create storage bucket for note images
INSERT INTO storage.buckets (id, name, public)
VALUES (
    'note-images',
    'note-images',
    true
) ON CONFLICT (id) DO NOTHING;

-- Storage Policies for note-images bucket
CREATE POLICY "Users can upload their own note images" ON storage.objects
    FOR INSERT WITH CHECK (
        bucket_id = 'note-images' AND
        auth.role() = 'authenticated' AND
        (storage.foldername(name))[1] = auth.uid()::text
    );

CREATE POLICY "Users can view their own note images" ON storage.objects
    FOR SELECT USING (
        bucket_id = 'note-images' AND
        auth.role() = 'authenticated' AND
        (storage.foldername(name))[1] = auth.uid()::text
    );

CREATE POLICY "Users can update their own note images" ON storage.objects
    FOR UPDATE USING (
        bucket_id = 'note-images' AND
        auth.role() = 'authenticated' AND
        (storage.foldername(name))[1] = auth.uid()::text
    );

CREATE POLICY "Users can delete their own note images" ON storage.objects
    FOR DELETE USING (
        bucket_id = 'note-images' AND
        auth.role() = 'authenticated' AND
        (storage.foldername(name))[1] = auth.uid()::text
    );

-- Public read policy for note images (to display in app)
CREATE POLICY "Note images are publicly accessible" ON storage.objects
    FOR SELECT USING (
        bucket_id = 'note-images' AND
        auth.role() = 'authenticated'
    );

-- =====================================================
-- SAMPLE DATA FOR TESTING
-- =====================================================

-- Sample Menu Items for Nasi Padang Restaurant
INSERT INTO public.menu_items (name, description, price, category_name, spicy_level, is_available) VALUES
-- Nasi
('Nasi Putih', 'Nasi putih hangat pulen', 8000.00, 'Nasi', 0, true),
('Nasi Uduk', 'Nasi uduk aroma daun pandan', 10000.00, 'Nasi', 0, true),
('Nasi Kuning', 'Nasi kunit kuning khas Indonesia', 10000.00, 'Nasi', 1, true),

-- Lauk
('Rendang Padang', 'Rendang daging sapi empuk bumbu khas Padang', 35000.00, 'Lauk', 3, true),
('Ayam Pop', 'Ayam goreng khas Padang dengan sambal hijau', 25000.00, 'Lauk', 2, true),
('Gulai Kambing', 'Gulai kambing dengan bumbu rempah pilihan', 40000.00, 'Lauk', 4, true),
('Telur Balado', 'Telur ayam dengan sambal merah Padang', 15000.00, 'Lauk', 3, true),
('Ikan Bakar', 'Ikan nila bakar dengan sambal', 30000.00, 'Lauk', 3, true),
('Perkedel', 'Perkedel kentang empuk', 8000.00, 'Lauk', 0, true),

-- Sayur
('Sayur Ubi', 'Sayur ubi dengan kuah santan', 12000.00, 'Sayur', 0, true),
('Daun Singkong', 'Daun singkong tumis dengan kelapa parut', 10000.00, 'Sayur', 2, true),
('Sayur Nangka', 'Sayur nangka muda dengan kuah santan', 15000.00, 'Sayur', 1, true),
('Cah Kangkung', 'Cah kangkung dengan bawang putih', 12000.00, 'Sayur', 1, true),

-- Minuman
('Teh Manis', 'Teh manis dingin', 5000.00, 'Minuman', 0, true),
('Teh Tawar', 'Teh tawar hangat/dingin', 3000.00, 'Minuman', 0, true),
('Es Teh', 'Es teh manis segar', 6000.00, 'Minuman', 0, true),
('Lemon Tea', 'Teh dengan perasan lemon segar', 12000.00, 'Minuman', 0, true),
('Jeruk Hangat', 'Air jeruk hangat dengan madu', 10000.00, 'Minuman', 0, true),
('Air Mineral', 'Air mineral botolan', 5000.00, 'Minuman', 0, true),

-- Sambal
('Sambal Hijau', 'Sambal cabai hijau Padang', 3000.00, 'Sambal', 4, true),
('Sambal Merah', 'Sambal cabai merah khas Padang', 3000.00, 'Sambal', 3, true),
('Sambal Ijo', 'Sambal cabai hijau dengan terasi', 4000.00, 'Sambal', 5, true),
('Sambal Matah', 'Sambal mentah khas Bali', 5000.00, 'Sambal', 2, true),

-- Tambahan
('Kerupuk', 'Kerupuk renyah', 3000.00, 'Tambahan', 0, true),
('Lalapan', 'Lalapan segar dengan sambal', 5000.00, 'Tambahan', 1, true);

-- =====================================================
-- AUTO CREATE USER PROFILE TRIGGER
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

-- Trigger to automatically create user profile on user signup
CREATE TRIGGER on_auth_user_created
    AFTER INSERT ON auth.users
    FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();

-- =====================================================
-- SAMPLE TODO DATA (FOR TESTING)
-- =====================================================

-- This will be populated when users create todos through the app

-- =====================================================
-- VIEWS FOR COMMON QUERIES
-- =====================================================

-- View for user statistics
CREATE OR REPLACE VIEW public.user_stats AS
SELECT
    u.id as user_id,
    u.username,
    u.full_name,
    u.email,
    u.created_at as member_since,
    COUNT(DISTINCT t.id) as total_todos,
    COUNT(DISTINCT CASE WHEN t.is_completed = false THEN t.id END) as active_todos,
    COUNT(DISTINCT n.id) as total_notes,
    COUNT(DISTINCT CASE WHEN n.is_pinned = true THEN n.id END) as pinned_notes,
    COUNT(DISTINCT o.id) as total_orders,
    COALESCE(SUM(CASE WHEN o.status != 'cancelled' THEN o.total_amount ELSE 0 END), 0) as total_spent
FROM public.user_profiles u
LEFT JOIN public.todos t ON u.id = t.user_id
LEFT JOIN public.notes n ON u.id = n.user_id
LEFT JOIN public.orders o ON u.id = o.user_id
GROUP BY u.id, u.username, u.full_name, u.email, u.created_at;

-- =====================================================
-- COMPLETION MESSAGE
-- =====================================================

-- Create a notification that setup is complete
DO $$
BEGIN
    RAISE NOTICE '=====================================================';
    RAISE NOTICE 'DATABASE SETUP COMPLETED SUCCESSFULLY!';
    RAISE NOTICE '=====================================================';
    RAISE NOTICE 'Tables created: user_profiles, todos, notes, menu_items, orders, order_items';
    RAISE NOTICE 'Storage bucket created: note-images';
    RASE NOTICE 'RLS policies enabled for all tables';
    RAISE NOTICE 'Sample data inserted for menu items';
    RAISE NOTICE 'Auto user profile creation enabled';
    RAISE NOTICE '';
    RAISE NOTICE 'Your application should now work correctly!';
    RAISE NOTICE '=====================================================';
END $$;