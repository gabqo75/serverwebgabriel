
CREATE TABLE administrateur (
    id_admin SERIAL PRIMARY KEY,
    nom_utilisateur VARCHAR(55) UNIQUE NOT NULL,
    email VARCHAR(255) UNIQUE NOT NULL,
    mot_de_passe VARCHAR(255) NOT NULL,
    role VARCHAR(55) NOT NULL CHECK (role IN ('super_admin', 'gestionnaire', 'editeur')), 
    created_at TIMESTAMP WITHOUT TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITHOUT TIME ZONE,
    deleted_at TIMESTAMP WITHOUT TIME ZONE 
);

CREATE UNIQUE INDEX idx_admin_email ON administrateur (email);
CREATE INDEX idx_admin_role ON administrateur (role);

CREATE TABLE client (
    id_client SERIAL PRIMARY KEY,
    nom VARCHAR(255) NOT NULL,
    prenom VARCHAR(255) NOT NULL,
    email VARCHAR(255) UNIQUE NOT NULL,
    mot_de_passe VARCHAR(255) NOT NULL,
    adresse VARCHAR(255),
    ville VARCHAR(55),
    code_postal VARCHAR(10),
    created_at TIMESTAMP WITHOUT TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITHOUT TIME ZONE,
    deleted_at TIMESTAMP WITHOUT TIME ZONE 
);

CREATE UNIQUE INDEX idx_client_email ON client (email);
CREATE INDEX idx_client_localisation ON client (ville, code_postal);

CREATE TABLE categorie (
    id_categorie SERIAL PRIMARY KEY,
    nom VARCHAR(55) UNIQUE NOT NULL, 
    description VARCHAR(255),
    image_url VARCHAR(255),
    created_at TIMESTAMP WITHOUT TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITHOUT TIME ZONE
);

CREATE TABLE produit (
    id_produit SERIAL PRIMARY KEY,
    nom VARCHAR(255) NOT NULL,
    description_detaillee TEXT, 
    prix NUMERIC(10, 2) NOT NULL CHECK (prix > 0.0), 
    stock INTEGER NOT NULL CHECK (stock >= 0),
    stock_reserve INTEGER DEFAULT 0 CHECK (stock_reserve >= 0),
    gestion_stock VARCHAR(55) NOT NULL CHECK (gestion_stock IN ('standard', 'precommande', 'illimite')),
    id_categorie INTEGER,
    created_at TIMESTAMP WITHOUT TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITHOUT TIME ZONE,
    deleted_at TIMESTAMP WITHOUT TIME ZONE,
    
    CONSTRAINT fk_categorie
        FOREIGN KEY(id_categorie)
        REFERENCES categorie(id_categorie)
        ON DELETE SET NULL     
        ON UPDATE CASCADE     
);

CREATE INDEX idx_produit_categorie ON produit (id_categorie);
CREATE UNIQUE INDEX idx_produit_nom_unique ON produit (nom) WHERE deleted_at IS NULL;

CREATE TABLE commande (
    id_commande SERIAL PRIMARY KEY,
    numero VARCHAR(55) UNIQUE NOT NULL,
    statut VARCHAR(55) NOT NULL CHECK (statut IN ('en_attente', 'en_cours', 'livree', 'annulee')), 
    montant_total NUMERIC(10, 2) NOT NULL CHECK (montant_total >= 0.0),
    adresse_livraison VARCHAR(255) NOT NULL,
    ville_livraison VARCHAR(55) NOT NULL,
    code_postal_livraison INTEGER NOT NULL,
    created_at TIMESTAMP WITHOUT TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITHOUT TIME ZONE,
    
    id_client INTEGER NOT NULL,
    CONSTRAINT fk_client
        FOREIGN KEY(id_client)
        REFERENCES client(id_client)
        ON DELETE RESTRICT   
        ON UPDATE CASCADE
);

CREATE INDEX idx_commande_client ON commande (id_client);
CREATE INDEX idx_commande_statut ON commande (statut);

CREATE TABLE ligne_de_commande (
    id_ligne SERIAL PRIMARY KEY,
    quantite INTEGER NOT NULL CHECK (quantite > 0), 
    prix_unitaire NUMERIC(10, 2) NOT NULL CHECK (prix_unitaire > 0.0),
    sous_total NUMERIC(10, 2) NOT NULL CHECK (sous_total > 0.0),
    created_at TIMESTAMP WITHOUT TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITHOUT TIME ZONE,
    
    id_commande INTEGER NOT NULL, 
    id_produit INTEGER NOT NULL,  
    
    CONSTRAINT fk_commande
        FOREIGN KEY(id_commande)
        REFERENCES commande(id_commande)
        ON DELETE CASCADE   
        ON UPDATE CASCADE,
        
    CONSTRAINT fk_produit
        FOREIGN KEY(id_produit)
        REFERENCES produit(id_produit)
        ON DELETE RESTRICT    
        ON UPDATE CASCADE,
        
    CONSTRAINT uc_commande_produit UNIQUE (id_commande, id_produit)
);

CREATE INDEX idx_ligne_commande_produit ON ligne_de_commande (id_produit);