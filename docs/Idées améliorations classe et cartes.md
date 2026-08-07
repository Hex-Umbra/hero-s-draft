### Différenciation et Originalité par Classe
D'après les analyses et comme les classes ont été le premier point abordé lorsque ce projet étais encore a l'étape de prototypages, elles n'ont pas beaucoup changé depuis et leur fonctionnement et quasiment le même pour chaque classe, pas d'originalité, aucune différence, a part le nom, le passif et les hp, c'est comme si on avait juste un skin différent pour les personnages.
- Pour modifier cela il faut voir d'abord les passifs ainsi que les stats de base comme proposés, on verra ensuite pour les cartes par classe ainsi que le blocage de certaines stats ou autre fonctionnalité pour bien avoir de vraies différence entre les classes, qu'il y ait une vraie valeur a choisir une classe par rapport a une autre.
- On vas commencer avec les stats
	- Les PV max sont déjà différents
	- L'attaque de base doit être repasser a 0 pour chaque persos 
	- Il faut voir maintenant pour les autres stats, lesquels valent la peine d'être augmenté de base pour chaque classe.
		- Est ce que les valeurs de mana doivent changer par classe ? Faire un brainstorming ensemble pour vérifier et proposer des idées.
		- La luck restera pour le moment a 0 pour chaque classe, il n'y a aucune raison pour les classes actuelles d'avoir une stats de luck augmenté, cependant pour une nouvelle classe comme "Joueur de dés", la oui il y aura un intérêt de l'augmenter.
		- Les passifs sont un autre gros points que j'aimerais discuter donc on verras juste après
		- Pareil pour le deck de départ et les carte de classes, on verra dans un autre points car c'est important.
		- Les récompenses de stats sont actuellement peut être trop puissantes, surtout celle de mana, il n'y a pas peut être aucun intérêt a avoir plusieurs rareté pour toutes les stats, et voir comment rééquilibrer et la valeur de la stat et la rareté.
		- Quel est l'intérêt de conditionnée les reliques étant donnée que l'on vas déjà conditionner les cartes a jouer ?
		- On supprime l'ancien système complètement des skills car il n'est plus d'actualité, il fait partie du premier protypes, code legacy inutile, a supprimer.
	- **Pour les passifs**
		- Actuellement les 3 passifs d'armure était a la base un test pour voir s'il était possible de rajouter des passifs qui fonctionne a différents moment d'un combat. Cela a fonctionné et a été réutilisé pour le système de reliques. 
		- Maintenant pour l'évolution qui est envisagé, se serait que chaque classe ait des passifs unique, sélectionnables dans le menu de sélection des classes, le joueur clique sur une des classes et il peut ensuite sélectionner un passif parmi les 3 (a voir si avec les amélioration inter-run cela pourrait être augmenté).
			- Par exemple pour le Paladin, on garde le passif actuelle d'armure qui vas très bien avec la classe en elle même. Pour les 2 autres passifs, on pourrait avoir quelque chose qui affecte l'attaque, ou qui augmente la quantité de soins prodigué par les cartes de soins, ou une augmentation de l'attaque quand une carte de soins est joué. 
			- Pour le berserker, on ne garderai pas du tout le passif d'armure actuelle, bien au contraire et c'est la qu'on vas introduire le blocage de certaines stats a certaines classes, comme la stat d'armure qu'il ne pourra plus avoir car le but d'un berserker est d'encaisser les coups pour taper plus fort. Donc en passifs on pourrait avoir justement, moins il a de vie plus il tape fort, ou alors il gagne du vol de vie qui augmente en fonction de ses hp, ou alors quand il se fait taper et qu'il perd un certain % de ses points de vie il gagne une carte frappe pour attaquer.
			- Pour le mage, pareil que le berserker, on enlève le passif d'armure qui n'as aucun intérêt ou on le garde mais on le fait fonctionnement différemment. On pourrait avoir un passif qui augmente son attaque a chaque carte skill joué et le buff reste pour quelques tours OU tout le combat (a débattre), le faire gagner 1 de mana après avoir joué trois cartes skill, mana temporaire (icone et fonctionnalité déjà existante).
		- Ces trois points ne sont que des exemples, il y a tellement de possibilité il faut faire un brainstorming complet pour être sûr que tout soit correct et cohérent avec les classes.
		- En rajoutant ces nouveaux passifs cela viens compléter le conditionnement des récompenses puisque chaque passif aura sa propre récompenses pour l'améliorer (conditionné également par le passif choisi, si plusieurs passifs sont choisi il faut quand même que les récompenses de chaque passif puisse apparaitre).
		- Maintenant pour les cartes
			- D'accord pour d'autres cartes demandant 3 de mana, c'est en effet logique d'avoir des cartes demandant autant de mana que ce que le joueur a 
			- Pour les status appliqués par les cartes en effet, c'est une évolution qui devait déjà être implémenté mais d'autres projets ont remplacé l'ajout de nouvelles cartes. Donc a mettre en place et a conditionner selon les classes également.
			- Pour les raretés, actuellement elles commencent toutes en effet a "common" et le merging des cartes améliore la rareté en améliorant également le nombre de slots de forge. 
			- A quoi cela servirait d'avoir une carte qui cible "none" exactement ?
			- Proposes moi des idées ou des exemples pour : "- Aucune carte ne produit de carte, n'agit sur les piles, n'a d'effet conditionnel/variable, de multi-coups, ou de coût alternatif"
		- Je suis d'accord que l'économie de deck est opposé a la philosophie du jeu, le but étant de merge les cartes pour les améliorer le joueur n'obtiens pas assez de copies des mêmes cartes et pas assez souvent. On pourrait rajouter le fait d'obtenir une nouvelle carte a chaque montée de niveau, mais comment est ce cette carte serait choisi ? 
			- Ok pour l'amélioration du système pour que toutes les cartes partage un socle commun
			- Il faut en effet baisser le nombre de slot d'une carte unique, ou changer comment elles gagnent leur slots étant donnée qu'elles ne peuvent pas être mergés pour en gagner de nouveaux. Je propose donc sois un système d'xp pour les cartes uniques soit qu'elles gagnes un slot en fonction du niveau du joueur.

### Correction a apporter après diagnostics 
Dans le diagnostic plusieurs bugs ont été confirmés, on vas maintenant les corriger. 
- Pour le point A, cela concerne l'évolution du nombre de carte a jouer ainsi que des reliques du jeu donc voir ce qui peut être fait et proposer des idées (brainstorming). 
- Pour le points B et les bugs confirmé, il faut tout corriger.
- Pour le point C, corriger la documentation obsolètes ou divergentes.
- Pour le point D, 
	- Point 1, cela vas avec la section pour l'originalité des classes que l'on vas apporter et améliorer.
	- Point 2, bien remarqué et déjà mentionné plus haut pour l'évolution en rapport.
	- Point 3, Comment élargir le pool ?


Après avoir pris en contexte toutes ces idées, regarde comment on pourrait mixer cela avec les idées proposées dans le brainstorming et comment tout pourrait s'impbriquer les uns avec les autres. Normalement j'ai pris en compte la plupart des idées déjà proposés donc voir si tout parait cohérent.