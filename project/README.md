# BookGetter - Online Bookstore

A full-featured online bookstore built with Java Servlets and JSP.

## Technology Stack

- **Frontend**: HTML + CSS + JavaScript
- **Backend**: Java (Servlets + JSP)
- **Web Server**: Apache Tomcat
- **Data Storage**: File-based JSON storage
- **Build Tool**: Gradle 8.5
- **Version Control**: Git

## Features

### Customer Features
- User registration and login with role selection (Customer/Admin)
- Browse books by category
- Search books by title, author, or category
- View book details with images
- Add books to shopping cart
- Manage cart (update quantity, remove items)
- Place orders with shipping information
- View order history
- Update profile information

### Admin Features
- Dashboard with statistics (total books, orders, customers, revenue)
- Manage books (add, edit, delete)
- Update order status (pending, shipped, completed)
- View all users
- Image URL support for book covers

## Project Structure

```
bookgetter/
├── src/
│   └── main/
│       ├── java/com/bookgetter/
│       │   ├── models/          # Data models
│       │   ├── servlets/        # HTTP request handlers
│       │   ├── services/        # Business logic
│       │   └── utils/           # Helper utilities
│       └── webapp/
│           ├── css/             # Stylesheets
│           ├── js/              # JavaScript files
│           ├── WEB-INF/         # Web configuration
│           └── *.html           # Frontend pages
├── data/                        # JSON data storage
├── build.gradle                 # Gradle build configuration
└── README.md
```

## Getting Started

### Prerequisites
- Java 17 or higher
- Gradle 8.5 or higher
- Apache Tomcat 10.x

### Installation

1. Clone the repository:
```bash
git clone <repository-url>
cd bookgetter
```

2. Build the project:
```bash
gradle build
```

3. Deploy to Tomcat:
```bash
# Copy the WAR file to Tomcat's webapps directory
cp build/libs/bookgetter.war $TOMCAT_HOME/webapps/
```

4. Start Tomcat:
```bash
$TOMCAT_HOME/bin/startup.sh  # Linux/Mac
$TOMCAT_HOME/bin/startup.bat # Windows
```

5. Access the application:
```
http://localhost:8080/bookgetter/
```

## Data Storage

The application uses file-based JSON storage in the `data/` directory:
- `books.json` - Book catalog (48 books preloaded)
- `users.json` - User accounts
- `orders.json` - Order history
- `carts.json` - Shopping carts

## Default Book Catalog

The application comes preloaded with 48 books across various categories:
- Fiction
- Self-Help
- Thriller
- History
- Biography
- Business
- Science Fiction
- Fantasy
- And more...

All books include:
- Title and author information
- ISBN
- Price in RM (Malaysian Ringgit)
- Category
- Description
- Stock quantity
- Book cover images from Pexels

## User Registration

Users can register with two roles:
1. **Customer** - Can browse, purchase, and manage orders
2. **Admin** - Full access including book and order management

## API Endpoints

- `POST /api/login` - User login
- `POST /api/register` - User registration
- `DELETE /api/login` - Logout
- `GET /api/books` - Get all books
- `GET /api/books?id={id}` - Get book by ID
- `GET /api/books?search={query}` - Search books
- `GET /api/books?category={category}` - Filter by category
- `GET /api/cart` - Get user's cart
- `POST /api/cart` - Add to cart
- `PUT /api/cart` - Update cart item
- `DELETE /api/cart` - Clear cart
- `GET /api/orders` - Get user's orders
- `POST /api/orders` - Place order
- `GET /api/user` - Get user profile
- `PUT /api/user` - Update profile
- `GET /api/admin/stats` - Get dashboard stats (admin only)
- `GET /api/admin/books` - Get all books (admin only)
- `POST /api/admin/books` - Add book (admin only)
- `PUT /api/admin/books/{id}` - Update book (admin only)
- `DELETE /api/admin/books/{id}` - Delete book (admin only)
- `GET /api/admin/orders` - Get all orders (admin only)
- `PUT /api/admin/orders/{id}` - Update order status (admin only)
- `GET /api/admin/users` - Get all users (admin only)

## Design

The application features a modern, professional design with:
- Blue and teal color scheme
- Responsive layout
- Smooth animations and transitions
- Clean, intuitive user interface
- Mobile-friendly design

## License

This project is for educational purposes.
