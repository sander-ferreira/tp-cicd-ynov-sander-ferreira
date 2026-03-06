CREATE TABLE IF NOT EXISTS utilisateur (
    id INT AUTO_INCREMENT PRIMARY KEY,
    nom VARCHAR(100) NOT NULL,
    prenom VARCHAR(100) NOT NULL,
    email VARCHAR(255) NOT NULL
);

INSERT INTO utilisateur (nom, prenom, email) VALUES
('Ferreira', 'Sander', 'sander@example.com'),
('Dupont', 'Jean', 'jean.dupont@example.com');
