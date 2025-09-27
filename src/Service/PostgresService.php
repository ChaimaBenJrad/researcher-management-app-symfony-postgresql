<?php

namespace App\Service;

class PostgresService
{
    private $connection;

    public function __construct($host, $port, $dbname, $user, $password)
    {
        // Connexion à la base de données PostgreSQL
        $this->connection = pg_connect("host=$host port=$port dbname=$dbname user=$user password=$password");
        if (!$this->connection) {
            throw new \Exception("Unable to connect to the database.");
        }
    }

    // Exécuter une requête SELECT avec des paramètres positionnels
    public function query(string $sql, array $params = [])
    {
        // Remarquez que nous utilisons des paramètres positionnels dans la requête SQL
        // Par exemple, $1, $2, etc.
        $result = pg_query_params($this->connection, $sql, $params);

        // Si la requête échoue, on lance une exception
        if (!$result) {
            throw new \Exception("Query failed: " . pg_last_error($this->connection));
        }

        // Récupérer tous les résultats sous forme de tableau associatif
        return pg_fetch_all($result);
    }

    public function execute(string $sql, array $params = []): void
    {
        // Exécution de la requête avec paramètres
        $result = pg_query_params($this->connection, $sql, $params);
    
        if (!$result) {
            $error = pg_last_error($this->connection);
    
            // Vérifier si l'erreur provient du déclencheur PostgreSQL
            if (str_contains($error, 'Mise à jour ou suppression interdite')) {
                // Lever une exception personnalisée
                throw new \Exception('trigger_error: ' . $error);
            }
    
            // Lever une exception générique pour d'autres erreurs
            throw new \Exception("Query failed: " . $error);
        }
    }
           // src/Service/PostgresService.php

public function addResearcher(array $data): void
{
    $sql = 'CALL researcher_operations.add_chercheur(
                $1, $2, $3, $4, $5, $6, 
                $7, $8, $9, $10
            )';

    // Paramètres positionnels
    $params = [
        $data['chnom'], 
        $data['grade'], 
        $data['statut'], 
        $data['daterecrut'], 
        $data['salaire'], 
        $data['prime'], 
        $data['email'], 
        $data['supno'], 
        $data['labno'], 
        $data['facno']
    ];

    // Exécution de la requête
    $this->execute($sql, $params);
}

// src/Service/PostgresService.php

public function updateResearcherProfile(int $chno, array $data): void
{
    $sql = 'SELECT researcher_operations.update_researcher_profile(
                $1, $2, $3, $4, $5, $6, $7, $8, $9
            )';

    $params = [
        $chno,
        $data['grade'] ?? null,
        $data['statut'] ?? null,
        $data['salaire'] ?? null,
        $data['prime'] ?? null,
        $data['email'] ?? null,
        $data['supno'] ?? null,
        $data['labno'] ?? null,
        $data['facno'] ?? null,
    ];

    $this->execute($sql, $params);
}


}
