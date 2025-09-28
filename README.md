# researcher-management-app-symfony-postgresql

## Research Management System

A web application built with **Symfony** and **PostgreSQL** to manage research activities of faculty members and researchers in research laboratories. The system provides an intuitive interface to interact with the database and perform common operations like viewing publications along with their corresponding researchers and details.
## Project Overview

This project allows you to manage and explore research-related data, including:

* Researchers and their profiles
* Publications details
* Historical actions on the database

## Database Tables

### CHERCHEUR

| Column     | Description                                                                                                           |
| ---------- | --------------------------------------------------------------------------------------------------------------------- |
| chno       | Researcher ID                                                                                                         |
| chnom      | Researcher name                                                                                                       |
| grade      | E (3rd cycle student), D (Doctorant), A (Assistant), MA (Maître Assistant), MC (Maître de conférence), PR (Professor) |
| statut     | P (Permanent), C (Contractual)                                                                                        |
| daterecrut | Recruitment date                                                                                                      |
| salaire    | Salary                                                                                                                |
| prime      | Bonus                                                                                                                 |
| email      | Email address                                                                                                         |
| supno      | Supervisor ID                                                                                                         |
| labno      | Laboratory ID                                                                                                         |
| facno      | Faculty ID (not necessarily same as laboratory)                                                                       |

### LABORATOIRE

| Column | Description     |
| ------ | --------------- |
| labno  | Laboratory ID   |
| labnom | Laboratory name |
| facno  | Faculty ID      |

### FACULTE

| Column  | Description                       |
| ------- | --------------------------------- |
| facno   | Faculty ID                        |
| facnom  | Short name (e.g., FST, ENSI, ISI) |
| adresse | Faculty location                  |
| libelle | Full faculty name                 |

### PUBLICATION

| Column     | Description                                                                                                  |
| ---------- | ------------------------------------------------------------------------------------------------------------ |
| pubno      | Publication ID (format: AA-NNNN)                                                                             |
| titre      | Title                                                                                                        |
| theme      | Main research theme (e.g., Computer Science, Mathematics)                                                    |
| type       | AS (Scientific Article), PC (Conference Presentation), P (Poster), L (Book), T (Thesis), M (Master’s Thesis) |
| volume     | Number of pages                                                                                              |
| date       | Publication date                                                                                             |
| apparition | Name of conference, journal, or book                                                                         |
| editeur    | Publisher                                                                                                    |

### PUBLIER

| Column | Description                                                   |
| ------ | ------------------------------------------------------------- |
| chno   | Researcher ID                                                 |
| pubno  | Publication ID                                                |
| rang   | Authorship rank (1 = main author, 2 = secondary author, etc.) |

## Project Requirements

1. Create the database tables described above.
2. Insert sample data into all tables.
3. Build a **graphical interface** to allow users to view publications along with their corresponding researchers and details.
4. Implement **triggers** in PostgreSQL to enforce business rules (e.g., restrictions on updates or deletions outside working hours).

## Quick Start

### Install PostgreSQL and pgAdmin

1. **Install PostgreSQL:** Download from [https://www.postgresql.org/download/](https://www.postgresql.org/download/) and follow the installation instructions for your OS.
2. **Install pgAdmin:** Download from [https://www.pgadmin.org/download/](https://www.pgadmin.org/download/) and install it.
3. Launch pgAdmin and create a new server connection with your PostgreSQL credentials.

### Create the database manually

1. In pgAdmin, right-click on `Databases` → `Create` → `Database...`
2. Name your database (e.g., `test`) and click `Save`.

### Implement the SQL script

1. Open the query tool in pgAdmin on your newly created database.
2. Paste your `.sql` script to create tables and insert initial data.
3. Execute the script to initialize your database.

### Clone the repository

```bash
git clone https://github.com/ChaimaBenJrad/researcher-management-system-symfony-postgresql.git
cd project-name
```

### Install dependencies

```bash
composer install
```

### Configure environment

Update `.env` with your PostgreSQL credentials:

```env
DATABASE_URL="postgresql://username:password@127.0.0.1:5432/test?serverVersion=15&charset=utf8"
```

### Locking Dependencies

This project uses **Composer** to manage PHP dependencies.

* `composer.json` defines the packages and version constraints.
* `composer.lock` records the exact versions used when the project was last installed.

> Always run `composer install` (not `composer update`) to ensure you are using the same versions as in this project. This prevents conflicts when Symfony or other libraries have newer releases.

### Start the server

```bash
# Recommended: Symfony CLI
symfony server:start

# Or PHP built-in server
php -S 127.0.0.1:8000 -t public
```

### Open in your browser

```
http://127.0.0.1:8000/researcher
```

Other pages:

| Feature                                   | URL                                                          |
| ----------------------------------------- | ------------------------------------------------------------ |
| Add a researcher                          | `/researcher/add`                                            |
| Update a researcher                       | `/researcher/update/{chno}`                                  |
| View publications of a researcher         | `/researcher/{chno}/publications`                            |
| View bibliography of a publication        | `/publication/{pubno}`                                       |
| Show historical actions                   | `/historique`                                                |
| View all publications                     | `/publications/all`                                          |
| Top researchers                           | `/researchers/top?start_date=YYYY-MM-DD&end_date=YYYY-MM-DD` |

> Replace `{chno}`, `{pubno}`, or `{labno}` with real IDs from your database.

## Tips

* Keep the terminal open while running the server.
* Use Symfony CLI for a smoother development experience.
* Clear the cache if you experience slow loading:

```bash
php bin/console cache:clear
```

## Contributing

Contributions are welcome! Fork the repository and submit pull requests.

## License

This project is licensed under the MIT License.
