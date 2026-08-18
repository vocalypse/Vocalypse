[README.md](https://github.com/user-attachments/files/31194963/README.md)
# Vocalypse — Scripts Roblox Premium

Site de vente de scripts **Roblox uniquement**, avec système de prix par durée :

- **1 Jour**
- **1 Semaine**
- **1 Mois**

## Fonctionnalités

- Nom du site : **Vocalypse**
- Uniquement des scripts Roblox
- 3 tarifs par script (jour / semaine / mois)
- Panier fonctionnel
- Design dark moderne
- Responsive (mobile + desktop)
- Livraison instantanée (simulée)

## Comment ouvrir le site

1. Ouvre le fichier `index.html` dans ton navigateur
2. Ou héberge-le sur Netlify / Vercel / GitHub Pages

## Personnaliser les prix et scripts

Ouvre `index.html` → cherche le tableau `const products = [...]`

Chaque script a cette structure :

```js
{
    id: 1,
    name: "Admin System Pro",
    category: "admin",
    description: "...",
    icon: "fas fa-shield-halved",
    color: "from-violet-500 to-purple-600",
    tags: ["Admin", "Commands"],
    prices: { 
        day: 2.99,    // prix 1 jour
        week: 7.99,   // prix 1 semaine
        month: 14.99  // prix 1 mois
    }
}
```

Tu peux facilement modifier les prix, ajouter/supprimer des scripts, changer les noms, etc.

## Catégories disponibles

- Admin
- Utility
- Combat
- Systems
- UI

---

Créé pour toi.
