<?php
namespace App\Controller;

use App\Service\PostgresService;
use Symfony\Bundle\FrameworkBundle\Controller\AbstractController;
use Symfony\Component\HttpFoundation\Request;
use Symfony\Component\HttpFoundation\Response;
use Symfony\Component\Routing\Annotation\Route;
use Psr\Log\LoggerInterface;
use App\Service\DatabaseConnection;


class ResearcherController extends AbstractController
{
    private PostgresService $postgresService;
    private LoggerInterface $logger;

    // Injection des services Postgres et Logger via le constructeur
    public function __construct(PostgresService $postgresService, LoggerInterface $logger)
    {
        $this->postgresService = $postgresService;
        $this->logger = $logger;
    }

    // Route pour afficher la liste des chercheurs
    #[Route('/researcher', name: 'researcher_index')]
    public function index(): Response
    {
        $sql = 'SELECT * FROM chercheur';
        $researchers = $this->postgresService->query($sql);

        return $this->render('researcher/index.html.twig', [
            'researchers' => $researchers,
        ]);
    }

    // Route pour afficher les publications d'un chercheur
    #[Route('/researcher/{chno}/publications', name: 'researcher_publications')]
    public function publications(int $chno): Response
    {
        $sql = 'SELECT p.pubno, p.titre, p.date, p.theme, p.type
                FROM publication p
                JOIN publier pu ON pu.pubno = p.pubno
                WHERE pu.chno = $1';
        $params = [$chno];
        $publications = $this->postgresService->query($sql, $params);

        return $this->render('researcher/publications.html.twig', [
            'publications' => $publications,
            'chno' => $chno,
        ]);
    }

    // Route pour afficher la bibliographie d'une publication donnée
    #[Route('/publication/{pubno}', name: 'publication_bibliography')]
    public function showBibliography(string $pubno): Response
    {
        $sql = 'SELECT c.chnom, pu.rang
                FROM chercheur c
                JOIN publier pu ON pu.chno = c.chno
                WHERE pu.pubno = $1';
        $params = [$pubno];
        $bibliography = $this->postgresService->query($sql, $params);

        return $this->render('researcher/bibliography.html.twig', [
            'bibliography' => $bibliography,
            'pubno' => $pubno,
        ]);
    }

    // Route pour afficher les chercheurs d'un laboratoire donné
    #[Route('/laboratory/{labno}/researchers', name: 'laboratory_researchers')]
    public function showResearchersInLab(int $labno): Response
    {
        $sql = 'SELECT chno, chnom, grade
                FROM chercheur
                WHERE labno = $1';
        $params = [$labno];
        $researchers = $this->postgresService->query($sql, $params);

        return $this->render('researcher/researchers.html.twig', [
            'researchers' => $researchers,
            'labno' => $labno,
        ]);
    }

    // Route pour afficher l'historique des chercheurs
    #[Route('/historique', name: 'historique_chercheurs')]
    public function showHistorique(): Response
    {
        $sql = 'SELECT * FROM historique_chercheurs ORDER BY action_date DESC';
        $historique = $this->postgresService->query($sql);

        return $this->render('researcher/historique.html.twig', [
            'historique' => $historique,
        ]);
    }

    // Route pour afficher toutes les publications
    #[Route('/publications/all', name: 'all_publications')]
    public function showAllPublications(): Response
    {
        $sql = 'SELECT * FROM publication';
        $publications = $this->postgresService->query($sql);

        return $this->render('researcher/all_publications.html.twig', [
            'publications' => $publications,
        ]);
    }


    #[Route('/researcher/add', name: 'researcher_add')]
public function add(Request $request): Response
{
    // Si la méthode est POST (formulaire soumis)
    if ($request->isMethod('POST')) {
        $data = $request->request->all();

        try {
            // SQL pour ajouter un chercheur, y compris email, labno et facno
            $sql = 'INSERT INTO chercheur (chnom, grade, statut, salaire, prime, supno, email, labno, facno) 
                    VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9)';
            $params = [
                $data['chnom'], $data['grade'], $data['statut'], $data['salaire'], 
                $data['prime'], $data['supno'], $data['email'], $data['labno'], $data['facno']
            ];

            // Exécuter l'ajout dans la base de données
            $this->postgresService->execute($sql, $params);

            // Rediriger vers la page d'index après l'ajout réussi
            return $this->redirectToRoute('researcher_index'); // Utilisez le nom de la route pour l'index
        } catch (\PDOException $e) {
            // Gérer les erreurs
            $this->logger->error('Erreur lors de l\'ajout du chercheur : ' . $e->getMessage());

            // Vérifier l'exception pour des erreurs spécifiques (comme les horaires)
            if (str_contains($e->getMessage(), 'Mise à jour interdite')) {
                return $this->render('researcher/add.html.twig', [
                    'errorMessage' => "Pas de possibilité d'ajout",
                    'errorDetails' => "Les ajouts ne peuvent être effectuées que pendant les jours ouvrables",
                ]);
            }

            // Pour d'autres erreurs
            return $this->render('researcher/erreur_date.html.twig', [
                'errorMessage' => 'Erreur : Ajout interdit en dehors des horaires de travail.',
                'errorDetails' => 'Les ajouts peuvent seulement être effectués du lundi au vendredi entre 08h et 18h.',
            ]);
        }
    }

    // Si ce n'est pas une demande POST, afficher le formulaire
    return $this->render('researcher/add.html.twig', [
        'errorMessage' => null,
        'errorDetails' => null,
    ]);
}

    
#[Route('/researcher/update/{chno}', name: 'researcher_update')]
public function update(Request $request, int $chno): Response
{
    // Si le formulaire est soumis
    if ($request->isMethod('POST')) {
        $data = $request->request->all();

        try {
            // SQL pour mettre à jour le chercheur
            $sql = 'UPDATE chercheur SET chnom = $1, grade = $2, statut = $3, salaire = $4, prime = $5, supno = $6 WHERE chno = $7';
            $params = [
                $data['chnom'], $data['grade'], $data['statut'], $data['salaire'], $data['prime'], $data['supno'], $chno
            ];

            // Exécution de la mise à jour
            $this->postgresService->execute($sql, $params);

            // Rediriger vers la liste des chercheurs après une mise à jour réussie
            return $this->redirectToRoute('researcher_index'); // Redirection
        } catch (\PDOException $e) {
            // Capturer l'exception levée par le trigger ou autre erreur
            $this->logger->error('Erreur lors de la mise à jour du chercheur : ' . $e->getMessage());

            // Afficher l'erreur dans la vue si elle provient du trigger
            if (str_contains($e->getMessage(), 'Mise à jour interdite')) {
                return $this->render('researcher/erreur_date.html.twig', [
                    'errorMessage' => 'Erreur : Mise à jour interdite en dehors des heures de travail.',
                    'errorDetails' => 'Les mises à jour peuvent seulement être effectuées du lundi au vendredi entre 08h et 18h.',
                ]);
            }

            // Autres erreurs (par exemple une erreur de base de données)
            return $this->render('researcher/error.html.twig', [
                'errorMessage' => 'Une erreur s’est produite lors de la mise à jour du chercheur.',
                'errorDetails' => $e->getMessage(),
            ]);
        }
    }

    // Récupérer les informations du chercheur pour pré-remplir le formulaire
    $sql = 'SELECT * FROM chercheur WHERE chno = $1';
    $researcher = $this->postgresService->query($sql, [$chno])[0];

    // Afficher le formulaire de mise à jour
    return $this->render('researcher/edit.html.twig', [
        'researcher' => $researcher,
    ]);
}
    


    #[Route('/researcher/delete/{chno}', name: 'researcher_delete')]
    public function delete(int $chno): Response
    {
        try {
            // Tentative de suppression du chercheur
            $sql = 'DELETE FROM chercheur WHERE chno = $1';
            $this->postgresService->execute($sql, [$chno]);
    
            // Redirection après succès
            return $this->redirectToRoute('researcher_index');
        } catch (\Exception $e) {
            // Vérifier si l'erreur provient du déclencheur PostgreSQL
            if (str_contains($e->getMessage(), 'trigger_error')) {
                $this->logger->error('Tentative de suppression en dehors des heures de travail.');
    
                return $this->render('researcher/erreur_date.html.twig', [
                    'errorMessage' => 'Erreur : Suppression interdite en dehors des heures de travail.',
                    'errorDetails' => ['Les suppressions peuvent seulement être effectuées du lundi au vendredi entre 08h et 18h.'],
                ]);
            }
    
            // Enregistrer toute autre erreur
            $this->logger->error('Erreur lors de la suppression du chercheur : ' . $e->getMessage());
    
            // Rediriger vers une page d'erreur générique
            return $this->render('researcher/erreur_date.html.twig', [
                'errorMessage' => 'Une erreur s’est produite lors de la suppression du chercheur.',
                'errorDetails' => ['Suppression interdite. Les supressions ne peuvent être effectuées que pendant les jours ouvrables (Lundi-Vendredi) entre 08h et 18h'],
            ]);
        }
    }

    #[Route('/researchers/top', name: 'researchers_top')]
public function topResearchers(Request $request): Response
{
    try {
        // Récupérer les dates de début et de fin depuis les paramètres de la requête
        $startDate = $request->query->get('start_date', '2024-01-01'); // Exemple de valeur par défaut
        $endDate = $request->query->get('end_date', '2024-12-31');     // Exemple de valeur par défaut

        // Appeler la fonction SQL avec les paramètres
        $sql = 'SELECT * FROM get_top_researchers_by_publications($1, $2)';
        $topResearchers = $this->postgresService->query($sql, [$startDate, $endDate]);

        // Passer les résultats au template pour l'affichage
        return $this->render('researcher/top.html.twig', [
            'topResearchers' => $topResearchers,
            'startDate' => $startDate,
            'endDate' => $endDate,
        ]);
    } catch (\Exception $e) {
        // Enregistrer l'erreur
        $this->logger->error('Erreur lors de la récupération des meilleurs chercheurs : ' . $e->getMessage());

        // Rediriger vers une page d'erreur
        return $this->render('researcher/error.html.twig', [
            'errorMessage' => 'Une erreur s’est produite lors de la récupération des meilleurs chercheurs.',
            'errorDetails' => $e->getMessage(),
        ]);
    }
}

        }    