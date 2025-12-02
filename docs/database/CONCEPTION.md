1) Pourquoi stocker le prix unitaire dans la table des lignes de commande plutôt que d'utiliser directement le prix du produit ?

Stocker le prix unitaire  dans la table ligne de commande est une pratique que j'ai utilisé pour des raisons d'historisation et d'intégrité des données.
Le prix d'un produit peut changer au fil du temps avec des promotions ou des augmentations. Si une commande a été passée il y a un an, elle doit refléter le prix auquel le produit a été vendu à ce moment-là. Si nous utilisions toujours le prix actuel du produit, le montant total de la commande historique deviendrait faux.
Et puis, une fois la commande passée, ses détails, y compris le prix unitaire convenu, doivent rester figés pour des raisons comptables et légales.

2) Quelle stratégie avez-vous choisie pour gérer les suppressions ? Justifiez vos choix pour chaque relation.

La stratégie de gestion des suppressions est définie par les clauses ON DELETE des contraintes de clé étrangère . Voici les choix effectués pour les relations de votre modèle :

Pourquoi j'ai utilisé "ON DELETE SET NULL"
Relation : produit -> categorie
Si une catégorie est supprimée, on ne veut pas supprimer tous les produits qui y étaient associés. On préfère  que le champ id_categorie dans la table produit soit NULL. Cela permet aux produits de rester dans la base de données sans catégorie associée, en attendant potentiellement d'être réaffectés.

Pourquoi j'ai utilisé "ON DELETE RESTRICT"
Relation : commande -> client 
Relation : ligne_de_commande -> produit 
Pour Client, il est interdit de supprimer un client tant qu'il existe des commandes associées dans la table commande. C'est essentiel pour maintenir l'intégrité de l'historique des ventes et des documents légaux. Le client doit d'abord être "désactivé" ou ses commandes archivées.

Pour Produit, il est interdit de supprimer un produit tant qu'il est référencé dans au moins une ligne de commande. Cela garantit que l'historique de la commande reste cohérent et que l'on sait toujours quel produit a été acheté.

Pourquoi j'ai utilisé "ON DELETE CASCADE"
Relation : ligne_de_commande -> commande 
Si une commande est supprimée , toutes les lignes de commande qui lui sont rattachées doivent être automatiquement supprimées. Une ligne de commande n'a pas de sens si la commande parente n'existe plus.

Pourquoi j'ai utilisé "Soft Delete"
Pour les tables administrateur et client, une stratégie de soft delete (ajouter une colonne deleted_at TIMESTAMP) est pertinent car cela permet de désactiver un compte au lieu de le supprimer définitivement. L'utilisateur ne pourrait plus se connecter, mais toutes ses données (commandes, etc.) seraient conservées, préservant ainsi l'intégrité des relations ON DELETE RESTRICT.

3) Comment gérez-vous les stocks ?

Que se passe-t-il si un client commande un produit en rupture de stock ?

Le code SQL vérifie uniquement si le produit existe (id_produit est une clé étrangère valide) et si la quantité commandée est supérieure à zéro. Ce sera coté application de notre site e-commerce que on pourra bloquer l'achat d'un produit en rupture de stock

Quand le stock est-il décrémenté (panier, validation, paiement) ?

Au moment du Panier / Validation de la Commande 
Le stock est réservé dès que le client confirme son panier ou initie le processus de validation, mais avant le paiement.
L'ajout du produit à la table ligne_de_commande et le statut de la commande passent à 'panier' ou 'en_attente'.

Pour la décrémentation: 
Le champ produit.stock est décrémenté de la quantité commandée. Cela retire immédiatement l'article du stock disponible pour les autres clients.
Le champ produit.stock_reserve est incrémenté de la même quantité. Cela indique que cette quantité est maintenant en attente d'être payée.
L'objectif est de garantir au client que le produit ne sera pas vendu à quelqu'un d'autre pendant qu'il saisit ses informations de paiement.

Au moment du Paiement 
Le paiement réussi finalise la vente et lève la réservation, car l'article est considéré comme définitivement vendu.
Le paiement est validé, et le statut de la commande passe à 'en_cours' (ou un statut similaire de confirmation).

Pour la décrémentation:
Le champ produit.stock ne change pas, car il a déjà été décrémenté à l'étape précédente.
Le champ produit.stock_reserve est décrémenté de la quantité commandée. Cette quantité est soustraite de la réservation, car les articles ne sont plus simplement "réservés" ; ils sont sortis du système.

Dans le cas d'une annulation ou d'un échec de Paiement
Si le paiement échoue ou si la commande est annulée : le statut de la commande passe à 'annulee'.

Et si il y a réapprovisionnement, le champ produit.stock est incrémenté de la quantité commandée (remise en vente du produit) et produit.stock_reserve est décrémenté (annulation de la réservation).

4) Avez-vous prévu des index ? Lesquels et pourquoi ?

Index sur les Emails (idx_admin_email, idx_client_email) : j'ai appliqué des index uniques sont appliqués aux colonnes email des tables administrateur et client. Ils garantissent l'unicité de l'email pour chaque utilisateur et optimisent la vitesse de recherche  pour l'authentification et la connexion.

Index sur les Rôles (idx_admin_role) : j'ai défini un index sur la colonne role de la table administrateur pour accélérer le filtrage et la récupération des administrateurs basés sur leur niveau d'autorisation.

Index sur la Localisation Client (idx_client_localisation) j'ai crée un index composite sur les colonnes ville et code_postal de la table client, pour me faciliter l'analyse et la segmentation des clients par zone géographique.

Index sur les Clés Étrangères (idx_produit_categorie, idx_commande_client, idx_ligne_commande_produit) j'ai appliqué des index aux colonnes qui servent de clés étrangères (id_categorie, id_client, id_produit). J'ai fait ça pour optimiser la performance des jointures entre les tables (par exemple, trouver tous les produits d'une catégorie ou toutes les commandes d'un client).

Index sur le Statut des Commandes (idx_commande_statut) j'ai crée un index sur la colonne statut de la table commande pour permettre une recherche rapide des commandes selon leur état actuel (ex : toutes les commandes 'en_attente').

Contrainte d'Unicité Ligne de Commande (uc_commande_produit) j'ai appliqué une contrainte d'unicité sur la combinaison de id_commande et id_produit pour empêcher un produit d'être listé plusieurs fois dans la même commande.


5) Comment assurez-vous l'unicité du numéro de commande ?
L'unicité du numéro de commande est assurée par deux contraintes dans la définition de la table commande :
Contrainte UNIQUE : Le champ numero VARCHAR(55) est défini comme UNIQUE.
Contrainte NOT NULL : Il est également obligatoire d'avoir un numéro.
Cette combinaison garantit qu'il ne peut exister qu'une seule commande avec un numéro spécifique dans toute la base de données. Le numéro de commande sera généralement généré par l'application ou la base de données .


6) Quelles sont les extensions possibles de votre modèle ?
Le modèle actuel est un bon point de départ, mais il peut être étendu pour offrir plus de fonctionnalités :

1. Gestion de plusieurs adresses par client
Nouvelle Table : adresse_client

Champs : id_adresse, id_client (FK), rue, ville, code_postal, est_defaut (boolean), type ('livraison', 'facturation').

Modification : La table commande devra référencer l'id_adresse utilisée pour la livraison au lieu de stocker directement les champs d'adresse.

Nouvelle colonne dans commande : id_adresse_livraison (FK vers adresse_client).

2. Historique des prix
Nouvelle Table : historique_prix

Champs : id_historique, id_produit (FK), ancien_prix (NUMERIC), nouveau_prix (NUMERIC), date_debut (TIMESTAMP).

Utilité : Permet de tracer quand et comment le prix catalogue d'un produit a évolué.

3. Avis clients
Nouvelle Table : avis_client

Champs : id_avis, id_client (FK), id_produit (FK), note (INTEGER CHECK 1-5), commentaire (TEXT), date_soumission (TIMESTAMP).

Ajout : Une colonne de statistiques dans la table produit pour le score moyen et le nombre d'avis.

4. Images multiples par produit
Nouvelle Table : image_produit

Champs : id_image, id_produit (FK), url_image (VARCHAR), ordre (INTEGER), est_principale (BOOLEAN).

Modification : Supprimer image_url de la table categorie (ou laisser pour l'image d'en-tête de la catégorie, mais utiliser la nouvelle table pour les produits).










