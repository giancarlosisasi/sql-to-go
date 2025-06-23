-- Blog/CMS database schema with cleanup

-- =============================================
-- DROP TABLES IF THEY EXIST (CASCADE TO HANDLE DEPENDENCIES)
-- =============================================

DROP TABLE IF EXISTS role_permissions CASCADE;
DROP TABLE IF EXISTS user_roles CASCADE;
DROP TABLE IF EXISTS user_profiles CASCADE;
DROP TABLE IF EXISTS post_categories CASCADE;
DROP TABLE IF EXISTS post_tags CASCADE;
DROP TABLE IF EXISTS comments CASCADE;
DROP TABLE IF EXISTS media CASCADE;
DROP TABLE IF EXISTS posts CASCADE;
DROP TABLE IF EXISTS tags CASCADE;
DROP TABLE IF EXISTS categories CASCADE;
DROP TABLE IF EXISTS users CASCADE;
DROP TABLE IF EXISTS permissions CASCADE;
DROP TABLE IF EXISTS roles CASCADE;

-- =============================================
-- CREATE TABLES
-- =============================================

CREATE TABLE roles (
    id SERIAL PRIMARY KEY,
    name VARCHAR(50) NOT NULL UNIQUE,
    description TEXT,
    created_at TIMESTAMP DEFAULT NOW()
);

CREATE TABLE permissions (
    id SERIAL PRIMARY KEY,
    name VARCHAR(100) NOT NULL UNIQUE,
    description TEXT,
    resource VARCHAR(50),
    action VARCHAR(50)
);

CREATE TABLE role_permissions (
    role_id INTEGER REFERENCES roles(id) ON DELETE CASCADE,
    permission_id INTEGER REFERENCES permissions(id) ON DELETE CASCADE,
    PRIMARY KEY (role_id, permission_id)
);

CREATE TABLE users (
    id SERIAL PRIMARY KEY,
    email VARCHAR(255) NOT NULL UNIQUE,
    password_hash VARCHAR(255) NOT NULL,
    username VARCHAR(100) UNIQUE,
    first_name VARCHAR(100),
    last_name VARCHAR(100),
    avatar_url TEXT,
    bio TEXT,
    is_active BOOLEAN DEFAULT true,
    email_verified_at TIMESTAMP,
    last_login_at TIMESTAMP,
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW()
);

CREATE TABLE user_roles (
    user_id INTEGER REFERENCES users(id) ON DELETE CASCADE,
    role_id INTEGER REFERENCES roles(id) ON DELETE CASCADE,
    assigned_at TIMESTAMP DEFAULT NOW(),
    PRIMARY KEY (user_id, role_id)
);

CREATE TABLE user_profiles (
    id SERIAL PRIMARY KEY,
    user_id INTEGER REFERENCES users(id) ON DELETE CASCADE UNIQUE,
    phone VARCHAR(20),
    website VARCHAR(255),
    location VARCHAR(255),
    timezone VARCHAR(50) DEFAULT 'UTC',
    language VARCHAR(10) DEFAULT 'en',
    date_format VARCHAR(20) DEFAULT 'Y-m-d',
    social_links JSONB,
    preferences JSONB,
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW()
);

CREATE TABLE categories (
    id SERIAL PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    slug VARCHAR(100) UNIQUE NOT NULL,
    description TEXT,
    color VARCHAR(7) DEFAULT '#000000',
    parent_id INTEGER REFERENCES categories(id),
    sort_order INTEGER DEFAULT 0,
    is_active BOOLEAN DEFAULT true,
    meta_title VARCHAR(255),
    meta_description TEXT,
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW()
);

CREATE TABLE tags (
    id SERIAL PRIMARY KEY,
    name VARCHAR(100) NOT NULL UNIQUE,
    slug VARCHAR(100) UNIQUE NOT NULL,
    color VARCHAR(7) DEFAULT '#6c757d',
    usage_count INTEGER DEFAULT 0,
    created_at TIMESTAMP DEFAULT NOW()
);

CREATE TABLE posts (
    id SERIAL PRIMARY KEY,
    title VARCHAR(500) NOT NULL,
    slug VARCHAR(500) UNIQUE NOT NULL,
    excerpt TEXT,
    content TEXT,
    featured_image TEXT,
    author_id INTEGER REFERENCES users(id),
    status VARCHAR(20) DEFAULT 'draft' CHECK (status IN ('draft', 'published', 'archived', 'scheduled')),
    visibility VARCHAR(20) DEFAULT 'public' CHECK (visibility IN ('public', 'private', 'password')),
    password VARCHAR(255),
    comment_status VARCHAR(20) DEFAULT 'open' CHECK (comment_status IN ('open', 'closed', 'moderated')),
    published_at TIMESTAMP,
    scheduled_at TIMESTAMP,
    view_count INTEGER DEFAULT 0,
    like_count INTEGER DEFAULT 0,
    comment_count INTEGER DEFAULT 0,
    reading_time INTEGER, -- in minutes
    meta_title VARCHAR(255),
    meta_description TEXT,
    meta_keywords VARCHAR(500),
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW()
);

CREATE TABLE post_categories (
    post_id INTEGER REFERENCES posts(id) ON DELETE CASCADE,
    category_id INTEGER REFERENCES categories(id) ON DELETE CASCADE,
    PRIMARY KEY (post_id, category_id)
);

CREATE TABLE post_tags (
    post_id INTEGER REFERENCES posts(id) ON DELETE CASCADE,
    tag_id INTEGER REFERENCES tags(id) ON DELETE CASCADE,
    PRIMARY KEY (post_id, tag_id)
);

CREATE TABLE comments (
    id SERIAL PRIMARY KEY,
    post_id INTEGER REFERENCES posts(id) ON DELETE CASCADE,
    parent_id INTEGER REFERENCES comments(id),
    author_name VARCHAR(255),
    author_email VARCHAR(255),
    author_url VARCHAR(255),
    author_ip INET,
    user_agent TEXT,
    content TEXT NOT NULL,
    status VARCHAR(20) DEFAULT 'pending' CHECK (status IN ('approved', 'pending', 'spam', 'trash')),
    like_count INTEGER DEFAULT 0,
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW()
);

CREATE TABLE media (
    id SERIAL PRIMARY KEY,
    filename VARCHAR(255) NOT NULL,
    original_name VARCHAR(255),
    mime_type VARCHAR(100),
    file_size INTEGER,
    width INTEGER,
    height INTEGER,
    alt_text VARCHAR(255),
    caption TEXT,
    description TEXT,
    upload_path TEXT NOT NULL,
    uploaded_by INTEGER REFERENCES users(id),
    created_at TIMESTAMP DEFAULT NOW()
);

-- =============================================
-- INSERT SAMPLE DATA
-- =============================================

INSERT INTO roles (name, description) VALUES 
('admin', 'Full system administrator'),
('editor', 'Content editor and moderator'),
('author', 'Content author'),
('subscriber', 'Basic user with read access');

INSERT INTO permissions (name, description, resource, action) VALUES 
('manage_users', 'Manage user accounts', 'users', 'manage'),
('edit_posts', 'Edit all posts', 'posts', 'edit'),
('publish_posts', 'Publish posts', 'posts', 'publish'),
('delete_posts', 'Delete posts', 'posts', 'delete'),
('moderate_comments', 'Moderate comments', 'comments', 'moderate'),
('manage_categories', 'Manage categories', 'categories', 'manage'),
('upload_media', 'Upload media files', 'media', 'upload');

INSERT INTO users (email, password_hash, username, first_name, last_name, is_active, email_verified_at) VALUES 
('admin@blog.com', '$2a$10$example_hash_1', 'admin', 'Admin', 'User', true, NOW()),
('editor@blog.com', '$2a$10$example_hash_2', 'editor', 'Content', 'Editor', true, NOW()),
('author@blog.com', '$2a$10$example_hash_3', 'author', 'Blog', 'Author', true, NOW()),
('user@blog.com', '$2a$10$example_hash_4', 'user', 'Regular', 'User', true, NOW());

INSERT INTO user_profiles (user_id, phone, website, location, timezone, social_links, preferences) VALUES 
(1, '+1-555-0101', 'https://admin.blog.com', 'San Francisco, CA', 'America/Los_Angeles', '{"twitter": "@admin", "linkedin": "/in/admin"}', '{"theme": "dark", "notifications": true}'),
(2, '+1-555-0102', 'https://editor.blog.com', 'New York, NY', 'America/New_York', '{"twitter": "@editor"}', '{"theme": "light", "notifications": true}'),
(3, '+1-555-0103', NULL, 'Austin, TX', 'America/Chicago', '{"github": "author123"}', '{"theme": "auto", "notifications": false}'),
(4, NULL, NULL, 'Remote', 'UTC', NULL, '{"theme": "light"}');

INSERT INTO categories (name, slug, description, color, sort_order) VALUES 
('Technology', 'technology', 'Posts about technology and programming', '#007bff', 1),
('Lifestyle', 'lifestyle', 'Lifestyle and personal development', '#28a745', 2),
('Travel', 'travel', 'Travel experiences and guides', '#ffc107', 3),
('Food', 'food', 'Recipes and food reviews', '#fd7e14', 4),
('Business', 'business', 'Business and entrepreneurship', '#6f42c1', 5),
('Tutorials', 'tutorials', 'Step-by-step tutorials and guides', '#17a2b8', 6);

INSERT INTO tags (name, slug, color, usage_count) VALUES 
('Programming', 'programming', '#007bff', 5),
('JavaScript', 'javascript', '#f7df1e', 3),
('Python', 'python', '#3776ab', 2),
('Go', 'golang', '#00add8', 4),
('Docker', 'docker', '#2496ed', 2),
('Database', 'database', '#336791', 3),
('Travel Tips', 'travel-tips', '#28a745', 2),
('Recipe', 'recipe', '#fd7e14', 1),
('Review', 'review', '#6c757d', 3),
('Tutorial', 'tutorial', '#17a2b8', 8),
('Beginner', 'beginner', '#28a745', 6),
('Advanced', 'advanced', '#dc3545', 2);

INSERT INTO posts (title, slug, excerpt, content, author_id, status, visibility, published_at, view_count, like_count, reading_time) VALUES 
('Getting Started with PostgreSQL and Go', 'getting-started-postgresql-go', 'Learn how to build database-driven applications with PostgreSQL and Go programming language.', 'In this comprehensive tutorial, we will explore how to connect Go applications to PostgreSQL databases, perform CRUD operations, and implement best practices for database management...', 3, 'published', 'public', NOW() - INTERVAL '2 days', 342, 28, 8),

('Building REST APIs with Go and PostgreSQL', 'building-rest-apis-go-postgresql', 'Complete guide to building production-ready REST APIs using Go, PostgreSQL, and modern best practices.', 'Creating robust REST APIs is essential for modern web development. In this tutorial, we will build a complete REST API using Go, PostgreSQL, and industry best practices...', 3, 'published', 'public', NOW() - INTERVAL '5 days', 567, 45, 12),

('Docker for Go Developers', 'docker-go-developers', 'Essential Docker skills every Go developer should know, from basics to advanced deployment strategies.', 'Docker has revolutionized how we develop, test, and deploy applications. For Go developers, Docker offers unique advantages...', 2, 'published', 'public', NOW() - INTERVAL '1 week', 423, 31, 10),

('Database Schema Design Best Practices', 'database-schema-design-best-practices', 'Learn the principles of good database design with practical examples and common pitfalls to avoid.', 'Good database schema design is the foundation of any successful application. In this post, we will explore...', 2, 'published', 'public', NOW() - INTERVAL '10 days', 289, 22, 15),

('My Journey Learning Go Programming', 'my-journey-learning-go', 'Personal story about learning Go programming language, challenges faced, and lessons learned along the way.', 'Six months ago, I decided to learn Go programming language. Coming from a JavaScript background, the transition was both exciting and challenging...', 4, 'published', 'public', NOW() - INTERVAL '2 weeks', 156, 18, 6),

('Advanced Go Concurrency Patterns', 'advanced-go-concurrency-patterns', 'Deep dive into Go''s concurrency model with practical examples of goroutines, channels, and synchronization patterns.', 'Go''s concurrency model is one of its most powerful features. In this advanced tutorial, we explore complex patterns...', 3, 'draft', 'public', NULL, 0, 0, 20),

('Traveling with Technology: Digital Nomad Setup', 'traveling-technology-digital-nomad', 'Essential tech setup for digital nomads and remote workers who want to stay productive while traveling.', 'Working remotely while traveling requires careful planning and the right technology setup. Here''s what I''ve learned...', 4, 'published', 'public', NOW() - INTERVAL '3 days', 234, 15, 7),

('PostgreSQL Performance Optimization Tips', 'postgresql-performance-optimization', 'Practical tips and techniques for optimizing PostgreSQL database performance in production environments.', 'Database performance is crucial for application success. Here are proven techniques for optimizing PostgreSQL...', 2, 'scheduled', 'public', NOW() + INTERVAL '2 days', 0, 0, 14);

INSERT INTO post_categories (post_id, category_id) VALUES 
(1, 1), (1, 6),  -- Technology, Tutorials
(2, 1), (2, 6),  -- Technology, Tutorials  
(3, 1), (3, 6),  -- Technology, Tutorials
(4, 1), (4, 5),  -- Technology, Business
(5, 2),          -- Lifestyle
(6, 1), (6, 6),  -- Technology, Tutorials
(7, 3), (7, 1),  -- Travel, Technology
(8, 1), (8, 5);  -- Technology, Business

INSERT INTO post_tags (post_id, tag_id) VALUES 
(1, 1), (1, 3), (1, 6), (1, 10), (1, 11),     -- Programming, Python, Database, Tutorial, Beginner
(2, 1), (2, 4), (2, 6), (2, 10), (2, 12),     -- Programming, Go, Database, Tutorial, Advanced
(3, 5), (3, 10), (3, 11),                     -- Docker, Tutorial, Beginner
(4, 6), (4, 10), (4, 12),                     -- Database, Tutorial, Advanced
(5, 4), (5, 11),                              -- Go, Beginner
(6, 1), (6, 4), (6, 12),                      -- Programming, Go, Advanced
(7, 7),                                        -- Travel Tips
(8, 6), (8, 12);                              -- Database, Advanced

INSERT INTO comments (post_id, author_name, author_email, content, status, like_count) VALUES 
(1, 'Alice Johnson', 'alice@example.com', 'Great tutorial! This really helped me understand the connection between Go and PostgreSQL. The examples are clear and easy to follow.', 'approved', 5),
(1, 'Bob Smith', 'bob@example.com', 'Thanks for sharing this. I was struggling with database connections in Go, and your explanation made it click for me.', 'approved', 3),
(1, 'Charlie Brown', 'charlie@example.com', 'Could you do a follow-up post about handling migrations in Go applications?', 'approved', 2),
(2, 'Diana Prince', 'diana@example.com', 'Excellent guide! The REST API structure you showed is exactly what I needed for my project.', 'approved', 7),
(2, 'Eve Wilson', 'eve@example.com', 'The error handling patterns you demonstrated are really useful. Thank you!', 'approved', 4),
(3, 'Frank Miller', 'frank@example.com', 'Docker makes so much more sense now. The Go-specific examples were perfect.', 'approved', 6),
(4, 'Grace Lee', 'grace@example.com', 'As a DBA, I appreciate the practical approach to schema design. Well written!', 'approved', 8),
(5, 'Henry Ford', 'henry@example.com', 'Nice personal story. I''m also making the transition to Go and found this encouraging.', 'approved', 3),
(7, 'Ivy Chen', 'ivy@example.com', 'Great tech setup recommendations! I''m planning a nomad trip and this is super helpful.', 'approved', 4);

INSERT INTO role_permissions (role_id, permission_id) VALUES 
(1, 1), (1, 2), (1, 3), (1, 4), (1, 5), (1, 6), (1, 7),  -- admin gets all permissions
(2, 2), (2, 3), (2, 5), (2, 6), (2, 7),                   -- editor gets most permissions
(3, 2), (3, 3), (3, 7),                                   -- author gets limited permissions
(4, 7);                                                    -- subscriber gets minimal permissions

INSERT INTO user_roles (user_id, role_id) VALUES 
(1, 1),  -- admin user has admin role
(2, 2),  -- editor user has editor role  
(3, 3),  -- author user has author role
(4, 4);  -- regular user has subscriber role

INSERT INTO media (filename, original_name, mime_type, file_size, width, height, alt_text, upload_path, uploaded_by) VALUES 
('hero-postgresql-go.jpg', 'postgresql-go-hero.jpg', 'image/jpeg', 245760, 1200, 630, 'PostgreSQL and Go logos', '/uploads/2024/06/', 3),
('rest-api-diagram.png', 'api-architecture.png', 'image/png', 89340, 800, 600, 'REST API architecture diagram', '/uploads/2024/06/', 3),
('docker-containers.jpg', 'docker-setup.jpg', 'image/jpeg', 156890, 1000, 666, 'Docker containers illustration', '/uploads/2024/06/', 2),
('database-schema.png', 'schema-design.png', 'image/png', 67420, 900, 700, 'Database schema diagram', '/uploads/2024/06/', 2),
('nomad-setup.jpg', 'travel-tech-setup.jpg', 'image/jpeg', 198760, 1100, 733, 'Digital nomad workspace setup', '/uploads/2024/06/', 4);

-- =============================================
-- CREATE INDEXES FOR PERFORMANCE
-- =============================================

CREATE INDEX idx_posts_status ON posts(status);
CREATE INDEX idx_posts_published_at ON posts(published_at);
CREATE INDEX idx_posts_author_id ON posts(author_id);
CREATE INDEX idx_comments_post_id ON comments(post_id);
CREATE INDEX idx_comments_status ON comments(status);
CREATE INDEX idx_users_email ON users(email);
CREATE INDEX idx_users_username ON users(username);
CREATE INDEX idx_categories_slug ON categories(slug);
CREATE INDEX idx_tags_slug ON tags(slug);