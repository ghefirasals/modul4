-- Database Schema for Aplikasi Jualan Nasi Padang
-- Copy and paste this SQL script in your Supabase SQL Editor

-- Enable UUID extension
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- Users profile table (extends auth.users)
CREATE TABLE IF NOT EXISTS user_profiles (
  id UUID REFERENCES auth.users(id) PRIMARY KEY,
  username VARCHAR(50) UNIQUE NOT NULL,
  full_name VARCHAR(100),
  phone VARCHAR(15),
  address TEXT,
  is_admin BOOLEAN DEFAULT FALSE,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Menu categories table
CREATE TABLE IF NOT EXISTS menu_categories (
  id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
  name VARCHAR(50) NOT NULL,
  description TEXT,
  icon_url VARCHAR(255),
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Menu items table
CREATE TABLE IF NOT EXISTS menu_items (
  id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
  category_id UUID REFERENCES menu_categories(id),
  name VARCHAR(100) NOT NULL,
  description TEXT,
  price DECIMAL(10,2) NOT NULL,
  image_url VARCHAR(255),
  is_available BOOLEAN DEFAULT TRUE,
  spicy_level INTEGER DEFAULT 0, -- 0-5 level of spiciness
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Orders table
CREATE TABLE IF NOT EXISTS orders (
  id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
  user_id UUID REFERENCES user_profiles(id),
  order_number VARCHAR(20) UNIQUE NOT NULL,
  total_amount DECIMAL(10,2) NOT NULL,
  status VARCHAR(20) DEFAULT 'pending', -- pending, processing, ready, completed, cancelled
  delivery_address TEXT,
  notes TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Order items table
CREATE TABLE IF NOT EXISTS order_items (
  id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
  order_id UUID REFERENCES orders(id),
  menu_item_id UUID REFERENCES menu_items(id),
  quantity INTEGER NOT NULL,
  price_per_item DECIMAL(10,2) NOT NULL,
  subtotal DECIMAL(10,2) NOT NULL,
  special_instructions TEXT
);

-- Cart table (for temporary storage)
CREATE TABLE IF NOT EXISTS cart_items (
  id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
  user_id UUID REFERENCES user_profiles(id),
  menu_item_id UUID REFERENCES menu_items(id),
  quantity INTEGER NOT NULL,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  UNIQUE(user_id, menu_item_id)
);

-- Insert default menu categories
INSERT INTO menu_categories (name, description, icon_url) VALUES
('Nasi', 'Berbagai macam pilihan nasi', 'https://example.com/rice.png'),
('Lauk', 'Pilihan lauk pauk khas Padang', 'https://example.com/lauk.png'),
('Sayur', 'Sayuran khas Padang', 'https://example.com/sayur.png'),
('Minuman', 'Minuman pelengkap', 'https://example.com/drink.png'),
('Sambal', 'Berbagai jenis sambal', 'https://example.com/sambal.png')
ON CONFLICT DO NOTHING;

-- Insert sample menu items
INSERT INTO menu_items (category_id, name, description, price, spicy_level) VALUES
((SELECT id FROM menu_categories WHERE name = 'Nasi'), 'Nasi Putih', 'Nasi putih hangat', 8000, 0),
((SELECT id FROM menu_categories WHERE name = 'Nasi'), 'Nasi Hijau', 'Nasi dengan daun suji', 12000, 0),
((SELECT id FROM menu_categories WHERE name = 'Lauk'), 'Rendang Padang', 'Rendang daging sapi empuk', 35000, 3),
((SELECT id FROM menu_categories WHERE name = 'Lauk'), 'Ayam Pop', 'Ayam goreng khas Padang', 25000, 0),
((SELECT id FROM menu_categories WHERE name = 'Lauk'), 'Gulai Kambing', 'Gulai kambing dengan bumbu khas', 40000, 4),
((SELECT id FROM menu_categories WHERE name = 'Lauk'), 'Telur Balado', 'Telur dengan sambal merah', 15000, 3),
((SELECT id FROM menu_categories WHERE name = 'Sayur'), 'Sayur Ubi', 'Sayur ubi dengan santan', 12000, 0),
((SELECT id FROM menu_categories WHERE name = 'Sayur'), 'Daun Singkong', 'Daun singkong tumis', 10000, 2),
((SELECT id FROM menu_categories WHERE name = 'Sayur'), 'Cah Kangkung', 'Kangkung cah bawang putih', 15000, 1),
((SELECT id FROM menu_categories WHERE name = 'Minuman'), 'Teh Manis', 'Teh manis dingin', 5000, 0),
((SELECT id FROM menu_categories WHERE name = 'Minuman'), 'Es Teh Lemon', 'Teh dengan perasan lemon', 10000, 0),
((SELECT id FROM menu_categories WHERE name = 'Sambal'), 'Sambal Hijau', 'Sambal cabai hijau', 3000, 4),
((SELECT id FROM menu_categories WHERE name = 'Sambal'), 'Sambal Merah', 'Sambal cabai merah', 3000, 3)
ON CONFLICT DO NOTHING;

-- Create indexes for better performance
CREATE INDEX IF NOT EXISTS idx_menu_items_category ON menu_items(category_id);
CREATE INDEX IF NOT EXISTS idx_menu_items_available ON menu_items(is_available);
CREATE INDEX IF NOT EXISTS idx_orders_user ON orders(user_id);
CREATE INDEX IF NOT EXISTS idx_orders_status ON orders(status);
CREATE INDEX IF NOT EXISTS idx_order_items_order ON order_items(order_id);
CREATE INDEX IF NOT EXISTS idx_cart_items_user ON cart_items(user_id);

-- Create function to automatically update updated_at timestamp
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ language 'plpgsql';

-- Create triggers for updated_at
CREATE TRIGGER update_user_profiles_updated_at BEFORE UPDATE ON user_profiles FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_menu_items_updated_at BEFORE UPDATE ON menu_items FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_orders_updated_at BEFORE UPDATE ON orders FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- Row Level Security (RLS) Policies
ALTER TABLE user_profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE orders ENABLE ROW LEVEL SECURITY;
ALTER TABLE order_items ENABLE ROW LEVEL SECURITY;
ALTER TABLE cart_items ENABLE ROW LEVEL SECURITY;

-- Policy for user_profiles: users can only see their own profile, admin can see all
CREATE POLICY "Users can view own profile" ON user_profiles FOR SELECT USING (auth.uid() = id OR
  EXISTS (SELECT 1 FROM user_profiles WHERE id = auth.uid() AND is_admin = TRUE));

CREATE POLICY "Users can update own profile" ON user_profiles FOR UPDATE USING (auth.uid() = id);
CREATE POLICY "Users can insert own profile" ON user_profiles FOR INSERT WITH CHECK (auth.uid() = id);

-- Policy for orders: users can only see their own orders, admin can see all
CREATE POLICY "Users can view own orders" ON orders FOR SELECT USING (user_id = auth.uid() OR
  EXISTS (SELECT 1 FROM user_profiles WHERE id = auth.uid() AND is_admin = TRUE));

CREATE POLICY "Users can create own orders" ON orders FOR INSERT WITH CHECK (user_id = auth.uid());
CREATE POLICY "Users can update own orders" ON orders FOR UPDATE USING (user_id = auth.uid());

-- Policy for order_items: users can only see order items from their orders
CREATE POLICY "Users can view own order items" ON order_items FOR SELECT USING (
  EXISTS (SELECT 1 FROM orders WHERE id = order_items.order_id AND user_id = auth.uid())
);

-- Policy for cart_items: users can only manage their own cart
CREATE POLICY "Users can manage own cart" ON cart_items FOR ALL USING (user_id = auth.uid());

-- Notes table for cloud-based notes with image support
CREATE TABLE IF NOT EXISTS notes (
  id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
  user_id UUID REFERENCES user_profiles(id) ON DELETE CASCADE,
  title VARCHAR(255) NOT NULL,
  content TEXT,
  images TEXT[] DEFAULT '{}',
  is_pinned BOOLEAN DEFAULT FALSE,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create indexes for notes
CREATE INDEX IF NOT EXISTS idx_notes_user ON notes(user_id);
CREATE INDEX IF NOT EXISTS idx_notes_pinned ON notes(user_id, is_pinned);
CREATE INDEX IF NOT EXISTS idx_notes_updated ON notes(user_id, updated_at DESC);

-- Create trigger for notes updated_at
CREATE TRIGGER update_notes_updated_at BEFORE UPDATE ON notes FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- Row Level Security for notes
ALTER TABLE notes ENABLE ROW LEVEL SECURITY;

-- Policy for notes: users can only manage their own notes
CREATE POLICY "Users can manage own notes" ON notes FOR ALL USING (user_id = auth.uid());

-- Grant access to notes
GRANT ALL ON notes TO authenticated;
GRANT SELECT ON notes TO anon;

-- Create view for menu items with category info
CREATE OR REPLACE VIEW menu_items_with_category AS
SELECT
  mi.id,
  mi.name,
  mi.description,
  mi.price,
  mi.image_url,
  mi.is_available,
  mi.spicy_level,
  mi.created_at,
  mi.updated_at,
  mc.name as category_name,
  mc.icon_url as category_icon
FROM menu_items mi
JOIN menu_categories mc ON mi.category_id = mc.id;

-- Todo items table for cloud-based todo management
CREATE TABLE IF NOT EXISTS todos (
  id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
  user_id UUID REFERENCES user_profiles(id) ON DELETE CASCADE,
  title VARCHAR(255) NOT NULL,
  description TEXT,
  is_completed BOOLEAN DEFAULT FALSE,
  priority VARCHAR(20) DEFAULT 'medium', -- low, medium, high
  due_date TIMESTAMP WITH TIME ZONE,
  tags TEXT[] DEFAULT '{}',
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create indexes for todos
CREATE INDEX IF NOT EXISTS idx_todos_user ON todos(user_id);
CREATE INDEX IF NOT EXISTS idx_todos_completed ON todos(user_id, is_completed);
CREATE INDEX IF NOT EXISTS idx_todos_priority ON todos(user_id, priority);
CREATE INDEX IF NOT EXISTS idx_todos_due_date ON todos(user_id, due_date);

-- Create trigger for todos updated_at
CREATE TRIGGER update_todos_updated_at BEFORE UPDATE ON todos FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- Row Level Security for todos
ALTER TABLE todos ENABLE ROW LEVEL SECURITY;

-- Policy for todos: users can only manage their own todos
CREATE POLICY "Users can manage own todos" ON todos FOR ALL USING (user_id = auth.uid());

-- Grant access to todos
GRANT ALL ON todos TO authenticated;
GRANT SELECT ON todos TO anon;

-- Grant access to views
GRANT SELECT ON menu_items_with_category TO authenticated;
GRANT SELECT ON menu_items TO authenticated, anon;
GRANT SELECT ON menu_categories TO authenticated, anon;