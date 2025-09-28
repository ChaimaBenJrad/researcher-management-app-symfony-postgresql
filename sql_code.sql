CREATE TABLE faculte (
    facno SERIAL PRIMARY KEY,      
    facnom VARCHAR(10) NOT NULL,   
    adresse VARCHAR(255),          
    libelle VARCHAR(255)           
);
CREATE TABLE laboratoire (
    labno SERIAL PRIMARY KEY,      
    labnom VARCHAR(255) NOT NULL,  
    facno INT,                     
    CONSTRAINT fk_facno FOREIGN KEY (facno) REFERENCES faculte(facno)  
);
CREATE TABLE chercheur (
    chno SERIAL PRIMARY KEY,      
    chnom VARCHAR(255) NOT NULL,  
    grade VARCHAR(10) CHECK (grade IN ('E', 'D', 'A', 'MA', 'MC', 'PR')),  
    statut VARCHAR(10) CHECK (statut IN ('P', 'C')),  -- Statut
    daterecrut DATE,             
    salaire DECIMAL(10, 2),      
    prime DECIMAL(10, 2),        
    email VARCHAR(255) UNIQUE,   
    supno INT,                   
    labno INT,                   
    facno INT,                   
    CONSTRAINT fk_supno FOREIGN KEY (supno) REFERENCES chercheur(chno),
    CONSTRAINT fk_labno FOREIGN KEY (labno) REFERENCES laboratoire(labno),
    CONSTRAINT fk_facno FOREIGN KEY (facno) REFERENCES faculte(facno)
);

CREATE TABLE publication (
    pubno VARCHAR(9) PRIMARY KEY, 
    titre VARCHAR(255) NOT NULL,  
    theme VARCHAR(255),           
    type VARCHAR(10) CHECK (type IN ('AS', 'PC', 'P', 'L', 'T', 'M')), 
    volume INT,                    
    date DATE,                     
    apparition VARCHAR(255),       
    editeur VARCHAR(255),          
    CONSTRAINT check_pubno_format CHECK (pubno ~ '^[0-9]{2}-[0-9]{4}$') 
);
CREATE TABLE publier (
    chno INT,                     
    pubno VARCHAR(9),             
    rang INT ,  
    PRIMARY KEY (chno, pubno),     
    CONSTRAINT fk_chno FOREIGN KEY (chno) REFERENCES chercheur(chno),  
    CONSTRAINT fk_pubno FOREIGN KEY (pubno) REFERENCES publication(pubno) 
);

INSERT INTO faculte (facnom, adresse, libelle)
VALUES
    ('FST', 'El Manar, Tunis', 'Faculté des Sciences de Tunis'),
    ('ENSI', '456 Rue de l Ecole', 'École Nationale Supérieure d Informatique'),
    ('ISI', 'Ariana', 'Institut des Sciences Informatiques');
INSERT INTO laboratoire (labnom, facno)
VALUES
    ('Laboratoire de Recherche en Informatique', 1), 
    ('Laboratoire de Mathématiques Appliquées', 2),  
    ('Laboratoire de Biotechnologie', 3);           
INSERT INTO chercheur (chnom, grade, statut, daterecrut, salaire, prime, email, supno, labno, facno)
VALUES
    ('Claire J', 'MA', 'P', '2017-04-01', 3500, 500, 'claire.j@example.com', NULL, 1, 1),  
    ('Alain M', 'A', 'P', '2019-04-10', 3000, 400, 'alain.m@example.com', 1, 2, 2), 
    ('Mike L', 'D', 'C', '2015-01-18', 4000, 600, 'mike.L@example.com', 2, 3, 3); 
INSERT INTO publication (pubno, titre, theme, type, volume, date, apparition, editeur)
VALUES
    ('23-0001', 'Recherche sur Le Big Data', 'Informatique', 'AS', 79, '2020-08-02', 'Journal Data', 'Editeur La connaissance'),
    ('22-0002', 'Théorie de Descente de Gradient', 'Mathématiques', 'L', 140, '2024-06-02', 'Les Mathématiques', 'Editeur Les Sciences'),
    ('24-0003', 'ML et IA', 'Informatique', 'T', 200, '2022-09-03', 'Conférence AI', 'Editeur La Gloire');

INSERT INTO publier (chno, pubno, rang)
VALUES
    (1, '23-0001', 1),  
    (2, '23-0001', 2),  
    (2, '22-0002', 1),
    (3, '24-0003', 1);

CREATE TABLE historique_chercheurs (
    id SERIAL PRIMARY KEY,     
    chno INT,                 
    chnom VARCHAR(255),       
    grade VARCHAR(10),
    statut VARCHAR(10),
    daterecrut DATE,
    salaire DECIMAL(10, 2),
    prime DECIMAL(10, 2),     
    email VARCHAR(255),       
    supno INT,                
    labno INT,                
    facno INT,                
    action_type VARCHAR(10),  
    action_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP);

CREATE SCHEMA researcher_operations;

CREATE OR REPLACE FUNCTION log_chercheur_changes()
RETURNS TRIGGER AS $$
BEGIN    INSERT INTO historique_chercheurs (
        chno, chnom, grade, statut, daterecrut, salaire, prime, email, supno, labno, facno, action_type
    )
    VALUES (
        OLD.chno, OLD.chnom, OLD.grade, OLD.statut, OLD.daterecrut, OLD.salaire, OLD.prime, OLD.email, OLD.supno, OLD.labno, OLD.facno,
        TG_OP 
    );

    RETURN OLD; 
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER before_chercheur_change
BEFORE UPDATE OR DELETE ON chercheur
FOR EACH ROW
EXECUTE FUNCTION log_chercheur_changes();



CREATE OR REPLACE PROCEDURE researcher_operations.add_chercheur(
    chnom VARCHAR, grade VARCHAR, statut VARCHAR, daterecrut DATE, salaire DECIMAL, prime DECIMAL, 
    email VARCHAR, supno INT, labno INT, facno INT
)
AS $$
BEGIN
    INSERT INTO chercheur (chnom, grade, statut, daterecrut, salaire, prime, email, supno, labno, facno)
    VALUES (chnom, grade, statut, daterecrut, salaire, prime, email, supno, labno, facno);
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION researcher_operations.update_researcher_profile(
    p_chno INT,
    p_grade VARCHAR,
    p_statut VARCHAR,
    p_salaire DECIMAL(10, 2),
    p_prime DECIMAL(10, 2),
    p_email VARCHAR,
    p_supno INT,
    p_labno INT,
    p_facno INT
)
RETURNS VOID AS $$
BEGIN
    UPDATE chercheur
    SET 
        grade = COALESCE(p_grade, grade),  
        statut = COALESCE(p_statut, statut),  
        salaire = COALESCE(p_salaire, salaire),
        prime = COALESCE(p_prime, prime),
        email = COALESCE(p_email, email),
        supno = COALESCE(p_supno, supno),
        labno = COALESCE(p_labno, labno),
        facno = COALESCE(p_facno, facno)
    WHERE chno = p_chno;  
END;
$$ LANGUAGE plpgsql;


CREATE OR REPLACE FUNCTION get_top_researchers_by_publications(start_date DATE, end_date DATE)
RETURNS TABLE (
    facno INT,                 
    facnom VARCHAR,             
    labno INT,                 
    labnom VARCHAR,            
    chno INT,                  
    chnom VARCHAR,            
    publication_count INT      
) AS $$
DECLARE
    researcher_cursor CURSOR FOR
    SELECT
        f.facno,
        f.facnom,
        l.labno,
        l.labnom,
        c.chno,
        c.chnom,
        COUNT(p.pubno) AS publication_count
    FROM faculte f
    JOIN laboratoire l ON l.facno = f.facno
    JOIN chercheur c ON c.labno = l.labno
    JOIN publier pu ON pu.chno = c.chno
    JOIN publication p ON p.pubno = pu.pubno
    WHERE p.date BETWEEN start_date AND end_date  
    GROUP BY f.facno, f.facnom, l.labno, l.labnom, c.chno, c.chnom
    HAVING COUNT(p.pubno) = (
        SELECT MAX(pub_count)
        FROM (
            SELECT COUNT(pu.pubno) AS pub_count
            FROM publier pu
            JOIN publication p ON pu.pubno = p.pubno
            WHERE p.date BETWEEN start_date AND end_date
            GROUP BY pu.chno
        ) AS max_count
    )
    ORDER BY publication_count DESC;

BEGIN
    OPEN researcher_cursor;

    LOOP
        FETCH researcher_cursor INTO facno, facnom, labno, labnom, chno, chnom, publication_count;
        EXIT WHEN NOT FOUND; 

        RETURN NEXT;
    END LOOP;

    CLOSE researcher_cursor;

    RETURN;
END;
$$ LANGUAGE plpgsql;


CREATE OR REPLACE FUNCTION researcher_operations.delete_chercheur(chno1 INT)
RETURNS VOID AS $$
DECLARE
    researcher RECORD;
BEGIN
    FOR researcher IN 
        SELECT chno, chnom
        FROM chercheur
        WHERE chno = chno1
    LOOP
        RAISE NOTICE 'Suppression du chercheur: ID = %, Nom = %', researcher.chno, researcher.chnom;
        DELETE FROM chercheur WHERE chno = researcher.chno;
    END LOOP;
END;
$$ LANGUAGE plpgsql;


UPDATE chercheur
SET salaire = 5000
WHERE chno = 1;
select * from chercheur where chno=1;



CREATE OR REPLACE FUNCTION researcher_operations.check_supervisor_capacity()
RETURNS TRIGGER AS $$
BEGIN
    IF NEW.grade = 'D' THEN
        RAISE NOTICE 'Nombre de doctorants déjà encadrés par le directeur: %', 
            (SELECT COUNT(*) FROM chercheur WHERE supno = NEW.supno AND grade = 'D');

        IF (SELECT COUNT(*) FROM chercheur WHERE supno = NEW.supno AND grade = 'D') >= 20 THEN
            RAISE EXCEPTION 'Le directeur a déjà atteint sa capacité maximale pour les doctorants';
        END IF;
    END IF;

    IF NEW.grade = 'E' THEN
        RAISE NOTICE 'Nombre d''étudiants de 3ème cycle déjà encadrés par le directeur: %',
            (SELECT COUNT(*) FROM chercheur WHERE supno = NEW.supno AND grade = 'E');
        
        IF (SELECT COUNT(*) FROM chercheur WHERE supno = NEW.supno AND grade = 'E') >= 30 THEN
            RAISE EXCEPTION 'Le directeur a déjà atteint sa capacité maximale pour les étudiants de 3ème cycle';
        END IF;
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;


INSERT INTO chercheur (chnom, grade, statut, daterecrut, salaire, prime, email, supno, labno, facno)
VALUES
('Alice M', 'D', 'P', '2020-01-15', 2500, 300, 'alice.m@example.com', 1, 1, 1),
('Bob D', 'D', 'P', '2020-03-22', 2600, 350, 'bob.d@example.com', 1, 1, 1),
('Claire B', 'D', 'P', '2020-05-30', 2700, 400, 'claire.b@example.com', 1, 1, 1),
('David M', 'D', 'P', '2020-07-18', 2800, 450, 'david.m@example.com', 1, 1, 1),
('Emma P', 'D', 'P', '2020-09-12', 2900, 500, 'emma.p@example.com', 1, 1, 1),
('Fabien L', 'D', 'P', '2021-01-03', 3000, 550, 'fabien.l@example.com', 1, 1, 1),
('Gabrielle R', 'D', 'P', '2021-02-20', 3100, 600, 'gabrielle.r@example.com', 1, 1, 1),
('Hugo C', 'D', 'P', '2021-04-15', 3200, 650, 'hugo.c@example.com', 1, 1, 1),
('Isabelle S', 'D', 'P', '2021-06-01', 3300, 700, 'isabelle.s@example.com', 1, 1, 1),
('Julien F', 'D', 'P', '2021-07-30', 3400, 750, 'julien.f@example.com', 1, 1, 1),
('Karine N', 'D', 'P', '2021-09-10', 3500, 800, 'karine.n@example.com', 1, 1, 1),
('Louis F', 'D', 'P', '2021-10-05', 3600, 850, 'louis.f@example.com', 1, 1, 1),
('Marie D', 'D', 'P', '2022-01-12', 3700, 900, 'marie.d@example.com', 1, 1, 1),
('Nathan S', 'D', 'P', '2022-02-25', 3800, 950, 'nathan.s@example.com', 1, 1, 1),
('Olivia L', 'D', 'P', '2022-04-16', 3900, 1000, 'olivia.l@example.com', 1, 1, 1),
('Pauline G', 'D', 'P', '2022-06-07', 4000, 1050, 'pauline.g@example.com', 1, 1, 1),
('Quentin R', 'D', 'P', '2022-07-25', 4100, 1100, 'quentin.r@example.com', 1, 1, 1),
('Roxane H', 'D', 'P', '2022-09-15', 4200, 1150, 'roxane.h@example.com', 1, 1, 1),
('Simon L', 'D', 'P', '2022-11-10', 4300, 1200, 'simon.l@example.com', 1, 1, 1),
('Thomas B', 'D', 'P', '2023-01-02', 4400, 1250, 'thomas.b@example.com', 1, 1, 1),
('Ursula V', 'D', 'P', '2023-01-02', 4400, 1250, 'ursula.v@example.com', 1, 1, 1);


CREATE TRIGGER check_supervisor_capacity_trigger_005
BEFORE INSERT OR UPDATE ON chercheur
FOR EACH ROW
EXECUTE FUNCTION researcher_operations.check_supervisor_capacity();


CREATE OR REPLACE FUNCTION researcher_operations.check_salary_increase()
RETURNS TRIGGER AS $$
BEGIN
    RAISE NOTICE 'Trigger executed: OLD.salaire = %, NEW.salaire = %', OLD.salaire, NEW.salaire;
    RAISE NOTICE 'Trigger context: TG_OP = %, TG_WHEN = %, TG_LEVEL = %', TG_OP, TG_WHEN, TG_LEVEL;

    IF NEW.salaire < OLD.salaire THEN
        RAISE EXCEPTION 'La diminution du salaire d''un chercheur est interdite (Ancien salaire: %, Nouveau salaire: %)',
            OLD.salaire, NEW.salaire;
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;
CREATE TRIGGER prevent_salary_decrease
BEFORE UPDATE OF salaire ON chercheur
FOR EACH ROW
EXECUTE FUNCTION researcher_operations.check_salary_increase();


CREATE OR REPLACE FUNCTION check_working_hours()
RETURNS TRIGGER AS $$
DECLARE
    current_day INTEGER;
    current_hour INTEGER;
BEGIN
    current_day := EXTRACT(DOW FROM CURRENT_TIMESTAMP)::INTEGER;

    current_hour := EXTRACT(HOUR FROM CURRENT_TIMESTAMP)::INTEGER;

    IF (current_day IN (1, 2, 3, 4, 5)) AND (current_hour BETWEEN 8 AND 18) THEN
        RETURN NEW;
    ELSE
        RAISE EXCEPTION 'Mise à jour interdite. Les mises à jour ne peuvent être effectuées que pendant les jours ouvrables (Lundi-Vendredi) entre 08h et 18h.';
    END IF;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER check_update_time
BEFORE UPDATE OR INSERT OR DELETE ON chercheur
FOR EACH ROW
EXECUTE FUNCTION check_working_hours();


ALTER TABLE publier
DROP CONSTRAINT IF EXISTS fk_chno;

ALTER TABLE publier
ADD CONSTRAINT fk_chno
FOREIGN KEY (chno) REFERENCES chercheur(chno)
ON DELETE CASCADE;

DROP TRIGGER IF EXISTS check_update_time ON chercheur;