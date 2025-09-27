<?php
// src/Service/DatabaseConnection.php
namespace App\Service;

use PDO;

class DatabaseConnection
{
    private $connection;

    public function __construct(string $dsn, string $username, string $password)
    {
        // Créer une nouvelle connexion PDO
        $this->connection = new PDO($dsn, $username, $password);
        $this->connection->setAttribute(PDO::ATTR_ERRMODE, PDO::ERRMODE_EXCEPTION);
    }

    public function getConnection(): PDO
    {
        return $this->connection;
    }
}
