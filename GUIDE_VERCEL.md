# Free Shop v3 : Vercel, thèmes, liens produits (pas à pas)

Fichiers de cette version :
- `schema_v2.sql` : base v2 (boutiques multiples, plusieurs produits, abandons, stats). À lancer UNE fois si ce n'est pas déjà fait.
- `update_v3.sql` : NOUVEAU. Thème par boutique, lien automatique par produit, commande sans e-mail. À lancer une fois, après schema_v2.sql.
- `theme.css` : NOUVEAU. Les 4 thèmes (vert, noir-or, ivoire, bleu-nuit). À mettre à côté de index.html.
- `index.html` : la boutique.
- `benou.html` : le back-office, à renommer ou copier. Sur Vercel il s'ouvre à `/benou`.
- `confidentialite.html` : la politique de confidentialité (liée depuis la boutique). À compléter une fois (voir plus bas).
- `vercel.json` : réglages Vercel (sécurité, admin non indexé).
- `config.js` : GARDE TON PROPRE `config.js` (celui avec tes vraies clés). Ajoute seulement la ligne `COUNTRY_CODE: "229"` (voir étape 3).

----------------------------------------------------------------

## ÉTAPE 1 : mettre à jour la base (Supabase) — 2 min
Garde UN SEUL schéma dans ta base : celui de ces fichiers (colonnes en anglais : `customer_name`, `phone`, `status`…). Ne lance pas le SQL de l'autre version (colonnes `nom`, `telephone`, `statut`) sur le même projet Supabase, les deux se mélangeraient.
1. Si `schema_v2.sql` n'a jamais été lancé : ouvre-le, copie TOUT, SQL Editor → New query → colle → **Run**.
2. Ensuite, fais pareil avec `update_v3.sql` (obligatoire). Tu dois voir « Success ».
3. Dans **Table Editor → products**, chaque produit a maintenant une colonne `slug` (son lien).
3. Vérifie : **Table Editor → shops**. Tu dois voir une ligne « Free Shop » (tes anciens réglages).
Rien n'est supprimé. Ton site actuel continue de marcher pendant ce temps.

## ÉTAPE 2 : tester sur ton PC (gratuit, sans rien déployer)
1. Mets dans un même dossier : `index.html`, `theme.css`, `benou.html`, `config.js` (le tien).
2. Dans VS Code : clic droit sur `index.html` → **Open with Live Server**.
3. Vérifie : ta boutique s'affiche, tes anciens produits sont là. Ajoute un produit au panier, commande-le (commande test), puis regarde : la commande dans l'admin, le message Telegram (il commence par `[Free Shop]`).
4. Ouvre `benou.html` avec Live Server et connecte-toi.
5. Supprime la commande test dans l'admin.

## ÉTAPE 3 : ton `config.js`
Il doit ressembler à ceci (tes vraies valeurs) :
```js
window.FREESHOP = {
  SUPABASE_URL: "https://TON-PROJET.supabase.co",
  SUPABASE_KEY: "TA_CLE_PUBLIQUE",
  CURRENCY: "FCFA",
  COUNTRY_CODE: "229"
};
```
`COUNTRY_CODE` sert aux liens WhatsApp : un numéro local « 0197000000 » devient « 2290197000000 ».

## ÉTAPE 4 : mettre les fichiers sur GitHub
1. Dans ton dépôt, remplace `index.html` et `benou.html`, ajoute `theme.css`, `vercel.json` et `confidentialite.html`. Ne supprime pas `config.js`.
2. **Important :** si tu avais collé à la main le bloc du Pixel Facebook dans l'ancien `index.html`, il a disparu avec le remplacement, et c'est voulu. Le Pixel se règle maintenant dans l'admin (étape 7). N'en colle jamais à la main, sinon chaque visite serait comptée deux fois.
3. **Commit changes**.

## ÉTAPE 5 : Vercel
1. vercel.com → connecte-toi avec GitHub → **Add New → Project** → choisis ton dépôt.
2. **Framework Preset : Other**. Laisse le reste vide. **Deploy**.
3. Tu obtiens une adresse du type `https://ton-projet.vercel.app`.
   - Boutique : `https://ton-projet.vercel.app`
   - Admin : `https://ton-projet.vercel.app/benou`

## ÉTAPE 6 : vérifier en ligne
1. Ouvre la boutique sur ton téléphone, passe une commande test, vérifie l'admin et Telegram, puis supprime la commande.
2. Dans l'admin, mets le bouton « Ajouter à l'écran d'accueil » pour l'ouvrir comme une application.

## ÉTAPE 7 : régler chaque boutique (onglet ⚙️ Boutique)
- Nom, logo, titre et texte d'accueil, WhatsApp, **thème**, **ID du Pixel Facebook** (propre à chaque boutique), monnaie.
- Le **lien de la boutique** est affiché avec un bouton « Copier » : c'est celui à mettre dans tes pubs.
- **Nouvelle boutique** : bouton « ＋ Nouvelle boutique », puis onglet 🛍️ Produits pour ajouter ses produits.

## Le lien direct de chaque produit
Dès que tu ajoutes un produit, son lien est créé tout seul. Dans l'onglet 🛍️ Produits, sous chaque produit : le lien, et les boutons **Copier le lien** et **Ouvrir**. Exemple : `https://ton-projet.vercel.app/?b=free-shop&p=theiere-en-ceramique`.
- Le client qui clique arrive directement sur la fiche du produit, avec les boutons Ajouter / Commander fixés en bas. Il peut fermer la fiche pour voir le reste de la boutique.
- Le lien ne change jamais, même si tu modifies le nom du produit, donc tes anciennes pubs continuent de marcher.
- Si la boutique a un nom de domaine, le lien devient `https://maboutique.com/?p=nom-du-produit`.
- Limite : quand tu colles le lien dans WhatsApp ou Facebook, l'aperçu montre la boutique, pas la photo du produit. Cela demande une petite fonction serveur en plus (je peux la faire si tu veux).

## Changer le thème d'une boutique (site déjà sur Vercel)
Pas besoin de redéployer pour le choix du thème : il est enregistré dans la base.
1. Une seule fois : lance `update_v3.sql` et ajoute `theme.css` sur GitHub (Add file → Upload files → Commit). Vercel republie tout seul en 1 minute.
2. Ensuite : admin (`/benou`) → onglet ⚙️ Boutique → choisis la boutique → **Thème de la boutique** → Enregistrer.
3. Recharge la boutique. Chaque boutique a son propre thème. Si l'ancien thème s'affiche encore, recharge deux fois (le navigateur garde le thème en mémoire pour éviter un clignotement).
4. Pour retoucher une couleur : modifie la valeur dans `theme.css`, puis commit sur GitHub.

## Comment les clients arrivent sur la bonne boutique
- Par le lien : `https://ton-projet.vercel.app/?b=nom-de-la-boutique` (le `nom-de-la-boutique` est affiché dans l'admin).
- Ou par un nom de domaine : ajoute-le dans Vercel (**Settings → Domains**), puis écris le même nom dans le champ « Nom de domaine » de la boutique (sans https://). La boutique s'affichera alors automatiquement sur ce domaine.
- Sans rien de tout ça, c'est la première boutique (ordre 0) qui s'affiche.

## La politique de confidentialité
1. Ouvre `confidentialite.html` dans VS Code et cherche `const LEGAL`.
2. Remplis `responsable` (ton nom ou celui de ton entreprise), `email` (le tien, pour le contact) et `adresse` si tu veux les afficher. Les durées de conservation (3 ans, 90 jours, 24 mois) sont modifiables.
3. Les passages manquants apparaissent en orange sur la page tant que tu n'as rien rempli. Le nom de la boutique et le contact WhatsApp viennent tout seuls de l'admin.
4. Les durées écrites dans la page sont un engagement : pense à supprimer les vieux contacts. Dans Supabase → SQL Editor, tu peux lancer de temps en temps :
```sql
delete from abandoned_carts where updated_at < now() - interval '90 days';
delete from visits where created_at < now() - interval '24 months';
```
5. Ce texte est un modèle de bonne foi, pas un avis juridique. Fais-le relire par un juriste local ou renseigne-toi auprès de l'APDP.

## Les paniers abandonnés
- Quand un client tape un numéro de téléphone valide dans le formulaire, son nom, son numéro, son adresse et son panier sont enregistrés. S'il commande, il disparaît de la liste.
- Onglet 📞 **Abandons** : boutons Appeler et WhatsApp (message déjà rédigé), « Rappelé » et « Supprimer ».
- Le formulaire dit aux clients que leurs coordonnées sont enregistrées pour les recontacter. Appelle-les avec tact.

## Après la migration
- Garde Netlify quelques jours le temps de vérifier que tout marche, puis supprime l'ancien site.
- Quand tout marche, tu peux retirer les anciennes fonctions (facultatif) : dans Supabase SQL Editor, lance
  `drop function if exists place_order(text,text,text,text,int,text); drop function if exists track_visit(text,text,text,text,text,text);`
- Sauvegarde chaque semaine : Supabase → Table Editor → `orders` → Export CSV.

## À savoir sur Vercel gratuit
Le plan gratuit (Hobby) est prévu par Vercel pour un usage personnel, non commercial. Une boutique qui vend relève du plan Pro (environ 20 $ par mois). Tu as choisi de rester sur Hobby : le risque est une suspension du compte, surtout en période de pubs. Garde donc une copie de tes fichiers pour pouvoir republier ailleurs en quelques minutes.
