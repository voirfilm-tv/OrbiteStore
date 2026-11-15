import SwiftUI
import AppKit

// Explicitly external editorial suggestions. They are never presented as
// GitHub Releases or silently passed to the OrbitStore installer.
struct OrbitSpotlightApp: Identifiable {
    let name: String
    let category: String
    let genre: String
    let subtitle: String
    let source: String
    let link: String
    let steamID: Int?
    let symbol: String

    var id: String { category + ":" + name }
    var artworkURL: URL? {
        guard let steamID else { return nil }
        return URL(string: "https://shared.fastly.steamstatic.com/store_item_assets/steam/apps/\(steamID)/header.jpg")
    }
    var officialURL: URL? { URL(string: link) }
}

// Independent from the installable GitHub feed: a user can discover a game
// from Steam or an office app from its publisher without a fabricated DMG.
enum OrbitSpotlights {
    // Stable publisher/boutique links. These are editorial discoveries, not
    // OrbitStore download assets or endorsements.
    static let all: [OrbitSpotlightApp] = [
        .init(name:"Tabletop Simulator",category:"Jeux",genre:"Jeux de plateau",
              subtitle:"Plateaux, cartes et jeux multijoueur",source:"Steam",
              link:"https://store.steampowered.com/app/286160/",steamID:286160,symbol:"die.face.5.fill"),
        .init(name:"MONOPOLY : adaptations Mac",category:"Jeux",genre:"Jeux de plateau",
              subtitle:"Explorer les versions et contrôler leur compatibilité Mac",source:"Recherche Steam",
              link:"https://store.steampowered.com/search/?term=MONOPOLY&os=mac",steamID:nil,symbol:"die.face.6.fill"),
        .init(name:"Board Game Arena",category:"Jeux",genre:"Jeux de plateau",
              subtitle:"Jeux de société en ligne, depuis le navigateur",source:"Web",
              link:"https://boardgamearena.com/",steamID:nil,symbol:"suit.club.fill"),
        .init(name:"Balatro",category:"Jeux",genre:"Jeux de plateau",
              subtitle:"Cartes, combinaisons et roguelike",source:"Steam",
              link:"https://store.steampowered.com/app/2379780/",steamID:2379780,symbol:"suit.spade.fill"),
        .init(name:"Civilization VI",category:"Jeux",genre:"Stratégie",
              subtitle:"Construire un empire et maîtriser la diplomatie",source:"Steam",
              link:"https://store.steampowered.com/app/289070/",steamID:289070,symbol:"globe.europe.africa.fill"),
        .init(name:"Total War: WARHAMMER III",category:"Jeux",genre:"Stratégie",
              subtitle:"Batailles de grande ampleur et stratégie",source:"Steam",
              link:"https://store.steampowered.com/app/1142710/",steamID:1142710,symbol:"shield.fill"),
        .init(name:"Hearts of Iron IV",category:"Jeux",genre:"Stratégie",
              subtitle:"Grande stratégie et Seconde Guerre mondiale",source:"Steam",
              link:"https://store.steampowered.com/app/394360/",steamID:394360,symbol:"flag.fill"),
        .init(name:"Crusader Kings III",category:"Jeux",genre:"Stratégie",
              subtitle:"Dynasties, royaumes et intrigues médiévales",source:"Steam",
              link:"https://store.steampowered.com/app/1151640/",steamID:1151640,symbol:"crown.fill"),
        .init(name:"Stellaris",category:"Jeux",genre:"Stratégie",
              subtitle:"Diplomatie et exploration spatiale",source:"Steam",
              link:"https://store.steampowered.com/app/281990/",steamID:281990,symbol:"sparkle"),
        .init(name:"Europa Universalis IV",category:"Jeux",genre:"Stratégie",
              subtitle:"Gestion de nations à travers les siècles",source:"Steam",
              link:"https://store.steampowered.com/app/236850/",steamID:236850,symbol:"globe.fill"),
        .init(name:"Northgard",category:"Jeux",genre:"Stratégie",
              subtitle:"Survie, conquête et stratégie viking",source:"Steam",
              link:"https://store.steampowered.com/app/466560/",steamID:466560,symbol:"shield.fill"),
        .init(name:"0 A.D.",category:"Jeux",genre:"Stratégie",
              subtitle:"Stratégie historique gratuite et open source",source:"Éditeur",
              link:"https://play0ad.com/download/",steamID:nil,symbol:"flag.2.crossed"),
        .init(name:"Stardew Valley",category:"Jeux",genre:"Gestion",
              subtitle:"Ferme, village et coopération",source:"Steam",
              link:"https://store.steampowered.com/app/413150/",steamID:413150,symbol:"leaf.fill"),
        .init(name:"RimWorld",category:"Jeux",genre:"Gestion",
              subtitle:"Construire, gérer et défendre sa colonie",source:"Steam",
              link:"https://store.steampowered.com/app/294100/",steamID:294100,symbol:"house.fill"),
        .init(name:"Factorio",category:"Jeux",genre:"Gestion",
              subtitle:"Chaînes de production et automatisation",source:"Steam",
              link:"https://store.steampowered.com/app/427520/",steamID:427520,symbol:"gearshape.2.fill"),
        .init(name:"Cities: Skylines",category:"Jeux",genre:"Gestion",
              subtitle:"Concevoir et administrer une ville",source:"Steam",
              link:"https://store.steampowered.com/app/255710/",steamID:255710,symbol:"building.2.fill"),
        .init(name:"The Sims 4",category:"Jeux",genre:"Simulation",
              subtitle:"Créer des personnages et organiser leur vie",source:"Éditeur",
              link:"https://www.ea.com/games/the-sims/the-sims-4",steamID:nil,symbol:"house.fill"),
        .init(name:"Minecraft Java",category:"Jeux",genre:"Simulation",
              subtitle:"Construction et exploration en monde ouvert",source:"Éditeur",
              link:"https://www.minecraft.net/fr-fr/download",steamID:nil,symbol:"cube.fill"),
        .init(name:"Terraria",category:"Jeux",genre:"Action",
              subtitle:"Exploration et aventures en 2D",source:"Steam",
              link:"https://store.steampowered.com/app/105600/",steamID:105600,symbol:"hammer.fill"),
        .init(name:"Hollow Knight",category:"Jeux",genre:"Action",
              subtitle:"Aventure et exploration dessinées à la main",source:"Steam",
              link:"https://store.steampowered.com/app/367520/",steamID:367520,symbol:"moon.stars.fill"),
        .init(name:"Don't Starve Together",category:"Jeux",genre:"Simulation",
              subtitle:"Survie coopérative dans un monde étrange",source:"Steam",
              link:"https://store.steampowered.com/app/322330/",steamID:322330,symbol:"flame.fill"),
        .init(name:"Baldur's Gate 3",category:"Jeux",genre:"Rôle",
              subtitle:"Grand jeu de rôle et choix narratifs",source:"Steam",
              link:"https://store.steampowered.com/app/1086940/",steamID:1086940,symbol:"dice.fill"),
        .init(name:"SuperTuxKart",category:"Jeux",genre:"Course",
              subtitle:"Courses de karting open source",source:"Éditeur",
              link:"https://supertuxkart.net/",steamID:nil,symbol:"car.fill"),
        .init(name:"LibreOffice",category:"Bureautique",genre:"",
              subtitle:"Writer, Calc et Impress sans abonnement",source:"Éditeur",
              link:"https://www.libreoffice.org/download/download-libreoffice/",steamID:nil,symbol:"doc.on.doc.fill"),
        .init(name:"Microsoft 365",category:"Bureautique",genre:"",
              subtitle:"Word, Excel, PowerPoint et Outlook",source:"Éditeur",
              link:"https://www.microsoft.com/fr-fr/microsoft-365",steamID:nil,symbol:"square.grid.2x2.fill"),
        .init(name:"ONLYOFFICE Desktop Editors",category:"Bureautique",genre:"",
              subtitle:"Documents, feuilles de calcul et présentations",source:"Éditeur",
              link:"https://www.onlyoffice.com/desktop.aspx",steamID:nil,symbol:"doc.text.fill"),
        .init(name:"Apple Pages",category:"Bureautique",genre:"",
              subtitle:"Rédaction et mise en page sur Mac",source:"Mac App Store",
              link:"https://apps.apple.com/fr/app/pages/id409201541",steamID:nil,symbol:"doc.richtext"),
        .init(name:"Apple Numbers",category:"Bureautique",genre:"",
              subtitle:"Tableurs et rapports visuels",source:"Mac App Store",
              link:"https://apps.apple.com/fr/app/numbers/id409203825",steamID:nil,symbol:"tablecells.fill"),
        .init(name:"Apple Keynote",category:"Bureautique",genre:"",
              subtitle:"Présentations et animations",source:"Mac App Store",
              link:"https://apps.apple.com/fr/app/keynote/id409183694",steamID:nil,symbol:"rectangle.on.rectangle"),
        .init(name:"Notion",category:"Bureautique",genre:"",
              subtitle:"Notes, projets et wikis partagés",source:"Éditeur",
              link:"https://www.notion.com/desktop",steamID:nil,symbol:"square.and.pencil"),
        .init(name:"Obsidian",category:"Bureautique",genre:"",
              subtitle:"Notes liées et base de connaissances",source:"Éditeur",
              link:"https://obsidian.md/download",steamID:nil,symbol:"point.3.connected.trianglepath.dotted"),
        .init(name:"draw.io",category:"Bureautique",genre:"",
              subtitle:"Schémas, organigrammes et diagrammes",source:"Éditeur",
              link:"https://www.drawio.com/",steamID:nil,symbol:"square.on.square"),
        .init(name:"PDFgear",category:"Bureautique",genre:"",
              subtitle:"Lire, annoter et manipuler des PDF",source:"Éditeur",
              link:"https://www.pdfgear.com/",steamID:nil,symbol:"doc.richtext"),
        .init(name:"Joplin",category:"Bureautique",genre:"",
              subtitle:"Notes et synchronisation indépendante",source:"Éditeur",
              link:"https://joplinapp.org/",steamID:nil,symbol:"note.text"),
        .init(name:"Zotero",category:"Bureautique",genre:"",
              subtitle:"Documents de recherche et bibliographies",source:"Éditeur",
              link:"https://www.zotero.org/download/",steamID:nil,symbol:"books.vertical.fill"),
        .init(name:"Raycast",category:"Productivité",genre:"",
              subtitle:"Recherche, commandes et flux de travail Mac",source:"Éditeur",
              link:"https://www.raycast.com/",steamID:nil,symbol:"bolt.fill"),
        .init(name:"Alfred",category:"Productivité",genre:"",
              subtitle:"Lanceur et automatisations au clavier",source:"Éditeur",
              link:"https://www.alfredapp.com/",steamID:nil,symbol:"magnifyingglass"),
        .init(name:"Things 3",category:"Productivité",genre:"",
              subtitle:"Gestion de tâches et de projets personnelle",source:"Éditeur",
              link:"https://culturedcode.com/things/",steamID:nil,symbol:"checklist"),
        .init(name:"Todoist",category:"Productivité",genre:"",
              subtitle:"Listes et rappels synchronisés",source:"Éditeur",
              link:"https://todoist.com/downloads",steamID:nil,symbol:"checkmark.circle.fill"),
        .init(name:"TickTick",category:"Productivité",genre:"",
              subtitle:"Tâches, calendrier et habitudes",source:"Éditeur",
              link:"https://ticktick.com/",steamID:nil,symbol:"checkmark.seal.fill"),
        .init(name:"Notion",category:"Productivité",genre:"",
              subtitle:"Projets et tableaux collaboratifs",source:"Éditeur",
              link:"https://www.notion.com/desktop",steamID:nil,symbol:"rectangle.3.group.fill"),
        .init(name:"Trello",category:"Productivité",genre:"",
              subtitle:"Gestion de projets en tableaux Kanban",source:"Web",
              link:"https://trello.com/",steamID:nil,symbol:"square.grid.3x2.fill"),
        .init(name:"Obsidian",category:"Productivité",genre:"",
              subtitle:"Organiser ses idées sans cloud obligatoire",source:"Éditeur",
              link:"https://obsidian.md/download",steamID:nil,symbol:"note.text"),
        .init(name:"Maccy",category:"Productivité",genre:"",
              subtitle:"Historique du presse-papiers pour Mac",source:"Éditeur",
              link:"https://maccy.app/",steamID:nil,symbol:"doc.on.clipboard"),
        .init(name:"Espanso",category:"Productivité",genre:"",
              subtitle:"Expansion de texte et raccourcis",source:"Éditeur",
              link:"https://espanso.org/",steamID:nil,symbol:"text.cursor"),
        .init(name:"Affinity",category:"Création",genre:"",
              subtitle:"Design, photographie et mise en page",source:"Éditeur",
              link:"https://www.affinity.studio/",steamID:nil,symbol:"paintbrush.pointed.fill"),
        .init(name:"Adobe Creative Cloud",category:"Création",genre:"",
              subtitle:"Suite Photoshop, Illustrator et Premiere Pro",source:"Éditeur",
              link:"https://www.adobe.com/fr/creativecloud.html",steamID:nil,symbol:"paintpalette.fill"),
        .init(name:"Blender",category:"Création",genre:"",
              subtitle:"Modélisation, animation et rendu 3D",source:"Éditeur",
              link:"https://www.blender.org/download/",steamID:nil,symbol:"cube.transparent.fill"),
        .init(name:"DaVinci Resolve",category:"Création",genre:"",
              subtitle:"Montage, étalonnage et audio professionnels",source:"Éditeur",
              link:"https://www.blackmagicdesign.com/products/davinciresolve",steamID:nil,symbol:"film.fill"),
        .init(name:"Final Cut Pro",category:"Création",genre:"",
              subtitle:"Montage vidéo optimisé pour Mac",source:"Éditeur",
              link:"https://www.apple.com/fr/final-cut-pro/",steamID:nil,symbol:"film.stack.fill"),
        .init(name:"CapCut",category:"Création",genre:"",
              subtitle:"Montage vidéo et formats réseaux sociaux",source:"Éditeur",
              link:"https://www.capcut.com/tools/desktop-video-editor",steamID:nil,symbol:"video.fill"),
        .init(name:"OBS Studio",category:"Création",genre:"",
              subtitle:"Enregistrement et diffusion en direct",source:"Éditeur",
              link:"https://obsproject.com/download",steamID:nil,symbol:"record.circle.fill"),
        .init(name:"Canva",category:"Création",genre:"",
              subtitle:"Affiches, présentations et créations visuelles",source:"Web",
              link:"https://www.canva.com/",steamID:nil,symbol:"rectangle.stack.fill"),
        .init(name:"Figma",category:"Création",genre:"",
              subtitle:"Interfaces, maquettes et prototypes",source:"Éditeur",
              link:"https://www.figma.com/downloads/",steamID:nil,symbol:"rectangle.on.rectangle.angled"),
        .init(name:"Kdenlive",category:"Création",genre:"",
              subtitle:"Montage vidéo libre et multipiste",source:"Éditeur",
              link:"https://kdenlive.org/en/download/",steamID:nil,symbol:"film"),
        .init(name:"Shotcut",category:"Création",genre:"",
              subtitle:"Montage vidéo libre multiplateforme",source:"Éditeur",
              link:"https://shotcut.org/download/",steamID:nil,symbol:"scissors"),
        .init(name:"Gifski",category:"Création",genre:"",
              subtitle:"Générer des GIF de haute qualité",source:"Éditeur",
              link:"https://sindresorhus.com/gifski",steamID:nil,symbol:"photo.stack"),
        .init(name:"Adobe Photoshop",category:"Graphisme",genre:"",
              subtitle:"Retouche photo et création graphique",source:"Éditeur",
              link:"https://www.adobe.com/fr/products/photoshop.html",steamID:nil,symbol:"photo.artframe"),
        .init(name:"Affinity",category:"Graphisme",genre:"",
              subtitle:"Retouche, illustration et design",source:"Éditeur",
              link:"https://www.affinity.studio/",steamID:nil,symbol:"paintbrush.fill"),
        .init(name:"Pixelmator Pro",category:"Graphisme",genre:"",
              subtitle:"Retouche et composition sur Mac",source:"Éditeur",
              link:"https://www.pixelmator.com/pro/",steamID:nil,symbol:"photo.fill"),
        .init(name:"GIMP",category:"Graphisme",genre:"",
              subtitle:"Éditeur d'images open source",source:"Éditeur",
              link:"https://www.gimp.org/downloads/",steamID:nil,symbol:"paintbrush.pointed.fill"),
        .init(name:"Krita",category:"Graphisme",genre:"",
              subtitle:"Peinture numérique et illustration",source:"Éditeur",
              link:"https://krita.org/en/download/",steamID:nil,symbol:"pencil.and.scribble"),
        .init(name:"Inkscape",category:"Graphisme",genre:"",
              subtitle:"Illustration vectorielle open source",source:"Éditeur",
              link:"https://inkscape.org/release/",steamID:nil,symbol:"scribble.variable"),
        .init(name:"darktable",category:"Graphisme",genre:"",
              subtitle:"Traitement et classement de photos RAW",source:"Éditeur",
              link:"https://www.darktable.org/install/",steamID:nil,symbol:"camera.filters"),
        .init(name:"Figma",category:"Graphisme",genre:"",
              subtitle:"UI et maquettes collaboratives",source:"Éditeur",
              link:"https://www.figma.com/downloads/",steamID:nil,symbol:"rectangle.portrait.fill"),
        .init(name:"Canva",category:"Graphisme",genre:"",
              subtitle:"Visuels marketing et contenus sociaux",source:"Web",
              link:"https://www.canva.com/",steamID:nil,symbol:"paintpalette.fill"),
        .init(name:"Upscayl",category:"Graphisme",genre:"",
              subtitle:"Agrandissement d'images avec IA locale",source:"Éditeur",
              link:"https://upscayl.org/",steamID:nil,symbol:"arrow.up.left.and.arrow.down.right"),
        .init(name:"Spotify",category:"Audio & musique",genre:"",
              subtitle:"Musique, playlists et podcasts",source:"Éditeur",
              link:"https://www.spotify.com/fr/download/mac/",steamID:nil,symbol:"music.note.list"),
        .init(name:"Apple Music",category:"Audio & musique",genre:"",
              subtitle:"Musique et bibliothèque intégrée à macOS",source:"Inclus macOS",
              link:"https://www.apple.com/fr/apple-music/",steamID:nil,symbol:"music.note"),
        .init(name:"Audacity",category:"Audio & musique",genre:"",
              subtitle:"Édition et enregistrement audio libre",source:"Éditeur",
              link:"https://www.audacityteam.org/download/",steamID:nil,symbol:"waveform"),
        .init(name:"GarageBand",category:"Audio & musique",genre:"",
              subtitle:"Création musicale accessible",source:"Mac App Store",
              link:"https://apps.apple.com/fr/app/garageband/id682658836",steamID:nil,symbol:"pianokeys"),
        .init(name:"Logic Pro",category:"Audio & musique",genre:"",
              subtitle:"Production musicale et mixage sur Mac",source:"Éditeur",
              link:"https://www.apple.com/fr/logic-pro/",steamID:nil,symbol:"waveform.path"),
        .init(name:"REAPER",category:"Audio & musique",genre:"",
              subtitle:"Station audio multipiste puissante",source:"Éditeur",
              link:"https://www.reaper.fm/download.php",steamID:nil,symbol:"slider.horizontal.3"),
        .init(name:"MuseScore Studio",category:"Audio & musique",genre:"",
              subtitle:"Création et lecture de partitions",source:"Éditeur",
              link:"https://musescore.org/en/download",steamID:nil,symbol:"music.quarternote.3"),
        .init(name:"Mixxx",category:"Audio & musique",genre:"",
              subtitle:"Mixage DJ libre et contrôleurs",source:"Éditeur",
              link:"https://mixxx.org/download/",steamID:nil,symbol:"hifispeaker.fill"),
        .init(name:"LMMS",category:"Audio & musique",genre:"",
              subtitle:"Production de beats et synthétiseurs",source:"Éditeur",
              link:"https://lmms.io/download",steamID:nil,symbol:"music.mic"),
        .init(name:"Ocenaudio",category:"Audio & musique",genre:"",
              subtitle:"Édition audio simple et rapide",source:"Éditeur",
              link:"https://www.ocenaudio.com/download",steamID:nil,symbol:"waveform.path"),
        .init(name:"VLC",category:"Multimédia",genre:"",
              subtitle:"Lecteur vidéo et audio universel",source:"Éditeur",
              link:"https://www.videolan.org/vlc/",steamID:nil,symbol:"play.rectangle.fill"),
        .init(name:"IINA",category:"Multimédia",genre:"",
              subtitle:"Lecteur vidéo moderne, conçu pour Mac",source:"Éditeur",
              link:"https://iina.io/",steamID:nil,symbol:"play.rectangle"),
        .init(name:"Infuse",category:"Multimédia",genre:"",
              subtitle:"Lecteur de médiathèques et de serveurs",source:"Éditeur",
              link:"https://firecore.com/infuse",steamID:nil,symbol:"play.tv"),
        .init(name:"Plex",category:"Multimédia",genre:"",
              subtitle:"Bibliothèque de films et séries personnels",source:"Éditeur",
              link:"https://www.plex.tv/media-server-downloads/",steamID:nil,symbol:"tv.fill"),
        .init(name:"Jellyfin",category:"Multimédia",genre:"",
              subtitle:"Lecture de sa médiathèque auto-hébergée",source:"Éditeur",
              link:"https://jellyfin.org/downloads/",steamID:nil,symbol:"server.rack"),
        .init(name:"Kodi",category:"Multimédia",genre:"",
              subtitle:"Centre multimédia personnalisable",source:"Éditeur",
              link:"https://kodi.tv/download/",steamID:nil,symbol:"rectangle.stack"),
        .init(name:"HandBrake",category:"Multimédia",genre:"",
              subtitle:"Encoder et convertir des vidéos",source:"Éditeur",
              link:"https://handbrake.fr/downloads.php",steamID:nil,symbol:"film"),
        .init(name:"LosslessCut",category:"Multimédia",genre:"",
              subtitle:"Découpe vidéo sans réencodage",source:"Éditeur",
              link:"https://github.com/mifi/lossless-cut",steamID:nil,symbol:"scissors"),
        .init(name:"Elmedia Player",category:"Multimédia",genre:"",
              subtitle:"Lecture de médias sur macOS",source:"Éditeur",
              link:"https://www.elmedia-video-player.com/",steamID:nil,symbol:"play.square"),
        .init(name:"OBS Studio",category:"Multimédia",genre:"",
              subtitle:"Capture vidéo et diffusion en direct",source:"Éditeur",
              link:"https://obsproject.com/download",steamID:nil,symbol:"record.circle"),
        .init(name:"Anki",category:"Éducation",genre:"",
              subtitle:"Flashcards et répétition espacée",source:"Éditeur",
              link:"https://apps.ankiweb.net/",steamID:nil,symbol:"rectangle.on.rectangle"),
        .init(name:"Zotero",category:"Éducation",genre:"",
              subtitle:"Références et bibliographies",source:"Éditeur",
              link:"https://www.zotero.org/download/",steamID:nil,symbol:"books.vertical.fill"),
        .init(name:"GeoGebra",category:"Éducation",genre:"",
              subtitle:"Mathématiques et géométrie interactives",source:"Éditeur",
              link:"https://www.geogebra.org/download",steamID:nil,symbol:"function"),
        .init(name:"Stellarium",category:"Éducation",genre:"",
              subtitle:"Planétarium et exploration du ciel",source:"Éditeur",
              link:"https://stellarium.org/",steamID:nil,symbol:"star.circle.fill"),
        .init(name:"Scratch",category:"Éducation",genre:"",
              subtitle:"Apprentissage ludique de la programmation",source:"Web",
              link:"https://scratch.mit.edu/",steamID:nil,symbol:"puzzlepiece.fill"),
        .init(name:"Khan Academy",category:"Éducation",genre:"",
              subtitle:"Cours et exercices gratuits",source:"Web",
              link:"https://fr.khanacademy.org/",steamID:nil,symbol:"graduationcap.fill"),
        .init(name:"Duolingo",category:"Éducation",genre:"",
              subtitle:"Apprendre des langues depuis le navigateur",source:"Web",
              link:"https://fr.duolingo.com/",steamID:nil,symbol:"character.book.closed"),
        .init(name:"GCompris",category:"Éducation",genre:"",
              subtitle:"Jeux éducatifs pour enfants",source:"Éditeur",
              link:"https://gcompris.net/downloads-fr.html",steamID:nil,symbol:"gamecontroller.fill"),
        .init(name:"MuseScore Studio",category:"Éducation",genre:"",
              subtitle:"Apprendre et écrire des partitions",source:"Éditeur",
              link:"https://musescore.org/en/download",steamID:nil,symbol:"music.note"),
        .init(name:"KeePassXC",category:"Sécurité",genre:"",
              subtitle:"Gestionnaire de mots de passe hors ligne",source:"Éditeur",
              link:"https://keepassxc.org/download/",steamID:nil,symbol:"key.fill"),
        .init(name:"1Password",category:"Sécurité",genre:"",
              subtitle:"Coffre-fort de mots de passe et passkeys",source:"Éditeur",
              link:"https://1password.com/downloads/mac/",steamID:nil,symbol:"lock.square.fill"),
        .init(name:"Bitwarden",category:"Sécurité",genre:"",
              subtitle:"Mots de passe et partage sécurisé",source:"Éditeur",
              link:"https://bitwarden.com/download/",steamID:nil,symbol:"lock.shield.fill"),
        .init(name:"Proton VPN",category:"Sécurité",genre:"",
              subtitle:"VPN avec applications pour Mac",source:"Éditeur",
              link:"https://protonvpn.com/download-macos",steamID:nil,symbol:"network.badge.shield.half.filled"),
        .init(name:"Mullvad VPN",category:"Sécurité",genre:"",
              subtitle:"VPN orienté confidentialité",source:"Éditeur",
              link:"https://mullvad.net/fr/download/vpn/macos",steamID:nil,symbol:"shield.lefthalf.filled"),
        .init(name:"Cryptomator",category:"Sécurité",genre:"",
              subtitle:"Chiffrer des fichiers synchronisés",source:"Éditeur",
              link:"https://cryptomator.org/downloads/",steamID:nil,symbol:"lock.doc"),
        .init(name:"VeraCrypt",category:"Sécurité",genre:"",
              subtitle:"Créer des volumes de fichiers chiffrés",source:"Éditeur",
              link:"https://veracrypt.io/en/Downloads.html",steamID:nil,symbol:"externaldrive.fill.badge.person.crop"),
        .init(name:"LuLu",category:"Sécurité",genre:"",
              subtitle:"Pare-feu sortant libre pour macOS",source:"Éditeur",
              link:"https://objective-see.org/products/lulu.html",steamID:nil,symbol:"shield.fill"),
        .init(name:"Malwarebytes",category:"Sécurité",genre:"",
              subtitle:"Protection et analyse anti-malware",source:"Éditeur",
              link:"https://www.malwarebytes.com/mac",steamID:nil,symbol:"checkmark.shield.fill"),
        .init(name:"Proton Pass",category:"Sécurité",genre:"",
              subtitle:"Identifiants et passkeys chiffrés",source:"Éditeur",
              link:"https://proton.me/pass",steamID:nil,symbol:"key.horizontal.fill"),
        .init(name:"LocalSend",category:"Réseau",genre:"",
              subtitle:"Envoyer des fichiers entre appareils locaux",source:"Éditeur",
              link:"https://localsend.org/",steamID:nil,symbol:"arrow.left.arrow.right"),
        .init(name:"Tailscale",category:"Réseau",genre:"",
              subtitle:"Réseau privé entre appareils",source:"Éditeur",
              link:"https://tailscale.com/download/mac",steamID:nil,symbol:"network"),
        .init(name:"RustDesk",category:"Réseau",genre:"",
              subtitle:"Accès à distance open source",source:"Éditeur",
              link:"https://rustdesk.com/",steamID:nil,symbol:"desktopcomputer"),
        .init(name:"AnyDesk",category:"Réseau",genre:"",
              subtitle:"Prise en main à distance",source:"Éditeur",
              link:"https://anydesk.com/fr/downloads/mac-os",steamID:nil,symbol:"display"),
        .init(name:"Cyberduck",category:"Réseau",genre:"",
              subtitle:"SFTP, FTP, WebDAV et cloud",source:"Éditeur",
              link:"https://cyberduck.io/",steamID:nil,symbol:"folder.badge.gearshape"),
        .init(name:"Transmission",category:"Réseau",genre:"",
              subtitle:"Client BitTorrent léger",source:"Éditeur",
              link:"https://transmissionbt.com/download",steamID:nil,symbol:"arrow.down.circle"),
        .init(name:"qBittorrent",category:"Réseau",genre:"",
              subtitle:"Client BitTorrent complet",source:"Éditeur",
              link:"https://www.qbittorrent.org/download",steamID:nil,symbol:"arrow.down.circle.fill"),
        .init(name:"Wireshark",category:"Réseau",genre:"",
              subtitle:"Analyser le trafic réseau",source:"Éditeur",
              link:"https://www.wireshark.org/download.html",steamID:nil,symbol:"waveform.path.ecg"),
        .init(name:"Termius",category:"Réseau",genre:"",
              subtitle:"SSH et administration de serveurs",source:"Éditeur",
              link:"https://termius.com/download/macos",steamID:nil,symbol:"terminal"),
        .init(name:"Speedtest",category:"Réseau",genre:"",
              subtitle:"Tester la vitesse de connexion",source:"Éditeur",
              link:"https://www.speedtest.net/apps/desktop",steamID:nil,symbol:"speedometer"),
        .init(name:"Mozilla Firefox",category:"Internet",genre:"",
              subtitle:"Navigateur indépendant et personnalisable",source:"Éditeur",
              link:"https://www.mozilla.org/fr/firefox/new/",steamID:nil,symbol:"globe"),
        .init(name:"Google Chrome",category:"Internet",genre:"",
              subtitle:"Navigateur web et compte Google",source:"Éditeur",
              link:"https://www.google.com/chrome/",steamID:nil,symbol:"globe"),
        .init(name:"Brave",category:"Internet",genre:"",
              subtitle:"Navigateur et blocage de contenus",source:"Éditeur",
              link:"https://brave.com/fr/download/",steamID:nil,symbol:"shield.lefthalf.filled"),
        .init(name:"Vivaldi",category:"Internet",genre:"",
              subtitle:"Navigateur hautement personnalisable",source:"Éditeur",
              link:"https://vivaldi.com/fr/download/",steamID:nil,symbol:"safari"),
        .init(name:"Zen Browser",category:"Internet",genre:"",
              subtitle:"Navigateur moderne et espaces de travail",source:"Éditeur",
              link:"https://zen-browser.app/download/",steamID:nil,symbol:"rectangle.split.3x1"),
        .init(name:"Arc",category:"Internet",genre:"",
              subtitle:"Navigateur orienté espaces de travail",source:"Éditeur",
              link:"https://arc.net/",steamID:nil,symbol:"globe.desk"),
        .init(name:"Tor Browser",category:"Internet",genre:"",
              subtitle:"Navigation via le réseau Tor",source:"Éditeur",
              link:"https://www.torproject.org/download/",steamID:nil,symbol:"network.badge.shield.half.filled"),
        .init(name:"Thunderbird",category:"Internet",genre:"",
              subtitle:"Courriels, calendrier et contacts",source:"Éditeur",
              link:"https://www.thunderbird.net/fr/",steamID:nil,symbol:"envelope.fill"),
        .init(name:"Signal",category:"Internet",genre:"",
              subtitle:"Messagerie chiffrée avec application Mac",source:"Éditeur",
              link:"https://signal.org/download/",steamID:nil,symbol:"bubble.left.and.bubble.right.fill"),
        .init(name:"WhatsApp",category:"Internet",genre:"",
              subtitle:"Messagerie et appels sur ordinateur",source:"Éditeur",
              link:"https://www.whatsapp.com/download",steamID:nil,symbol:"message.fill"),
        .init(name:"Rectangle",category:"Utilitaires",genre:"",
              subtitle:"Ranger les fenêtres aux raccourcis clavier",source:"Éditeur",
              link:"https://rectangleapp.com/",steamID:nil,symbol:"rectangle.split.2x1"),
        .init(name:"AppCleaner",category:"Utilitaires",genre:"",
              subtitle:"Supprimer les apps et leurs fichiers liés",source:"Éditeur",
              link:"https://freemacsoft.net/appcleaner/",steamID:nil,symbol:"trash.fill"),
        .init(name:"Keka",category:"Utilitaires",genre:"",
              subtitle:"Compresser et extraire des archives",source:"Éditeur",
              link:"https://www.keka.io/fr/",steamID:nil,symbol:"archivebox.fill"),
        .init(name:"The Unarchiver",category:"Utilitaires",genre:"",
              subtitle:"Extraire des archives classiques",source:"Mac App Store",
              link:"https://apps.apple.com/fr/app/the-unarchiver/id425424353",steamID:nil,symbol:"archivebox"),
        .init(name:"Pearcleaner",category:"Utilitaires",genre:"",
              subtitle:"Désinstaller proprement des apps Mac",source:"Éditeur",
              link:"https://github.com/alienator88/Pearcleaner",steamID:nil,symbol:"trash.slash"),
        .init(name:"Stats",category:"Utilitaires",genre:"",
              subtitle:"Statistiques matérielles dans la barre des menus",source:"Éditeur",
              link:"https://github.com/exelban/stats",steamID:nil,symbol:"chart.xyaxis.line"),
        .init(name:"OnyX",category:"Utilitaires",genre:"",
              subtitle:"Maintenance et paramètres de macOS",source:"Éditeur",
              link:"https://www.titanium-software.fr/en/onyx.html",steamID:nil,symbol:"wrench.and.screwdriver"),
        .init(name:"MonitorControl",category:"Utilitaires",genre:"",
              subtitle:"Contrôler la luminosité des moniteurs",source:"Éditeur",
              link:"https://github.com/MonitorControl/MonitorControl",steamID:nil,symbol:"display"),
        .init(name:"BetterTouchTool",category:"Utilitaires",genre:"",
              subtitle:"Automatiser gestes et raccourcis",source:"Éditeur",
              link:"https://folivora.ai/",steamID:nil,symbol:"hand.tap.fill"),
        .init(name:"UTM",category:"Utilitaires",genre:"",
              subtitle:"Machines virtuelles pour Mac",source:"Éditeur",
              link:"https://mac.getutm.app/",steamID:nil,symbol:"desktopcomputer"),
        .init(name:"AltTab",category:"Personnalisation",genre:"",
              subtitle:"Bascule de fenêtres façon Windows",source:"Éditeur",
              link:"https://alt-tab-macos.netlify.app/",steamID:nil,symbol:"square.grid.2x2"),
        .init(name:"Ice",category:"Personnalisation",genre:"",
              subtitle:"Organiser les icônes de barre des menus",source:"Éditeur",
              link:"https://github.com/jordanbaird/Ice",steamID:nil,symbol:"menubar.rectangle"),
        .init(name:"Karabiner-Elements",category:"Personnalisation",genre:"",
              subtitle:"Remapper le clavier en profondeur",source:"Éditeur",
              link:"https://karabiner-elements.pqrs.org/",steamID:nil,symbol:"keyboard"),
        .init(name:"HazeOver",category:"Personnalisation",genre:"",
              subtitle:"Mettre en valeur la fenêtre active",source:"Éditeur",
              link:"https://hazeover.com/",steamID:nil,symbol:"eye"),
        .init(name:"Rectangle",category:"Personnalisation",genre:"",
              subtitle:"Organiser rapidement l'espace de travail",source:"Éditeur",
              link:"https://rectangleapp.com/",steamID:nil,symbol:"rectangle.split.2x1"),
        .init(name:"Mac Mouse Fix",category:"Personnalisation",genre:"",
              subtitle:"Améliorer gestes et défilement de souris",source:"Éditeur",
              link:"https://macmousefix.com/",steamID:nil,symbol:"computermouse"),
        .init(name:"Raycast",category:"Personnalisation",genre:"",
              subtitle:"Personnaliser lancement et raccourcis",source:"Éditeur",
              link:"https://www.raycast.com/",steamID:nil,symbol:"bolt"),
        .init(name:"Übersicht",category:"Personnalisation",genre:"",
              subtitle:"Widgets personnalisés sur le bureau",source:"Éditeur",
              link:"https://tracesof.net/uebersicht/",steamID:nil,symbol:"macwindow"),
        .init(name:"Itsycal",category:"Personnalisation",genre:"",
              subtitle:"Calendrier discret dans la barre des menus",source:"Éditeur",
              link:"https://www.mowglii.com/itsycal/",steamID:nil,symbol:"calendar"),
        .init(name:"VoiceOver (macOS)",category:"Accessibilité",genre:"",
              subtitle:"Lecteur d'écran intégré à macOS",source:"Inclus macOS",
              link:"https://www.apple.com/fr/accessibility/vision/",steamID:nil,symbol:"eye.fill"),
        .init(name:"Dictée vocale (macOS)",category:"Accessibilité",genre:"",
              subtitle:"Rédiger du texte à la voix",source:"Inclus macOS",
              link:"https://www.apple.com/fr/accessibility/speech/",steamID:nil,symbol:"mic.fill"),
        .init(name:"Karabiner-Elements",category:"Accessibilité",genre:"",
              subtitle:"Remapper et simplifier le clavier",source:"Éditeur",
              link:"https://karabiner-elements.pqrs.org/",steamID:nil,symbol:"keyboard"),
        .init(name:"Mac Mouse Fix",category:"Accessibilité",genre:"",
              subtitle:"Adapter les gestes et le défilement",source:"Éditeur",
              link:"https://macmousefix.com/",steamID:nil,symbol:"computermouse"),
        .init(name:"LinearMouse",category:"Accessibilité",genre:"",
              subtitle:"Personnaliser la vitesse de la souris",source:"Éditeur",
              link:"https://linearmouse.app/",steamID:nil,symbol:"cursorarrow"),
        .init(name:"MonitorControl",category:"Accessibilité",genre:"",
              subtitle:"Ajuster luminosité et contraste des écrans",source:"Éditeur",
              link:"https://github.com/MonitorControl/MonitorControl",steamID:nil,symbol:"sun.max.fill"),
        .init(name:"BetterTouchTool",category:"Accessibilité",genre:"",
              subtitle:"Raccourcis gestuels et actions personnalisées",source:"Éditeur",
              link:"https://folivora.ai/",steamID:nil,symbol:"hand.draw"),
        .init(name:"HazeOver",category:"Accessibilité",genre:"",
              subtitle:"Limiter les distractions visuelles",source:"Éditeur",
              link:"https://hazeover.com/",steamID:nil,symbol:"eye"),
        .init(name:"Visual Studio Code",category:"Développement",genre:"",
              subtitle:"Éditeur de code et extensions",source:"Éditeur",
              link:"https://code.visualstudio.com/download",steamID:nil,symbol:"chevron.left.forwardslash.chevron.right"),
        .init(name:"Xcode",category:"Développement",genre:"",
              subtitle:"Développer pour macOS et iOS",source:"Mac App Store",
              link:"https://apps.apple.com/fr/app/xcode/id497799835",steamID:nil,symbol:"hammer.fill"),
        .init(name:"Zed",category:"Développement",genre:"",
              subtitle:"Éditeur de code collaboratif rapide",source:"Éditeur",
              link:"https://zed.dev/download",steamID:nil,symbol:"chevron.left.forwardslash.chevron.right"),
        .init(name:"JetBrains Toolbox",category:"Développement",genre:"",
              subtitle:"Gérer les IDE JetBrains",source:"Éditeur",
              link:"https://www.jetbrains.com/toolbox-app/",steamID:nil,symbol:"hammer"),
        .init(name:"Docker Desktop",category:"Développement",genre:"",
              subtitle:"Conteneurs et environnements de dev",source:"Éditeur",
              link:"https://www.docker.com/products/docker-desktop/",steamID:nil,symbol:"shippingbox"),
        .init(name:"GitHub Desktop",category:"Développement",genre:"",
              subtitle:"Git avec une interface graphique",source:"Éditeur",
              link:"https://desktop.github.com/",steamID:nil,symbol:"arrow.triangle.branch"),
        .init(name:"Postman",category:"Développement",genre:"",
              subtitle:"Tester et documenter des API",source:"Éditeur",
              link:"https://www.postman.com/downloads/",steamID:nil,symbol:"network"),
        .init(name:"Bruno",category:"Développement",genre:"",
              subtitle:"Collection d'API stockées avec les projets",source:"Éditeur",
              link:"https://www.usebruno.com/downloads",steamID:nil,symbol:"point.3.connected.trianglepath.dotted"),
        .init(name:"iTerm2",category:"Développement",genre:"",
              subtitle:"Terminal avancé pour macOS",source:"Éditeur",
              link:"https://iterm2.com/",steamID:nil,symbol:"terminal.fill"),
        .init(name:"Insomnia",category:"Développement",genre:"",
              subtitle:"Clients REST, GraphQL et gRPC",source:"Éditeur",
              link:"https://insomnia.rest/download",steamID:nil,symbol:"network"),
        .init(name:"Steam",category:"Lanceurs & émulation",genre:"",
              subtitle:"Catalogue de jeux PC et Mac",source:"Éditeur",
              link:"https://store.steampowered.com/about/",steamID:nil,symbol:"gamecontroller.fill"),
        .init(name:"Heroic Games Launcher",category:"Lanceurs & émulation",genre:"",
              subtitle:"Bibliothèques Epic et GOG",source:"Éditeur",
              link:"https://heroicgameslauncher.com/",steamID:nil,symbol:"gamecontroller"),
        .init(name:"itch.io",category:"Lanceurs & émulation",genre:"",
              subtitle:"Découvrir et gérer les jeux indépendants",source:"Éditeur",
              link:"https://itch.io/app",steamID:nil,symbol:"arcade.stick"),
        .init(name:"Prism Launcher",category:"Lanceurs & émulation",genre:"",
              subtitle:"Profils et modpacks Minecraft",source:"Éditeur",
              link:"https://prismlauncher.org/download/",steamID:nil,symbol:"cube.fill"),
        .init(name:"OpenEmu",category:"Lanceurs & émulation",genre:"",
              subtitle:"Émulation rétro avec interface macOS",source:"Éditeur",
              link:"https://openemu.org/",steamID:nil,symbol:"arcade.stick"),
        .init(name:"RetroArch",category:"Lanceurs & émulation",genre:"",
              subtitle:"Front-end d'émulation configurable",source:"Éditeur",
              link:"https://www.retroarch.com/",steamID:nil,symbol:"arcade.stick"),
        .init(name:"CrossOver",category:"Lanceurs & émulation",genre:"",
              subtitle:"Exécuter certaines apps Windows sur Mac",source:"Éditeur",
              link:"https://www.codeweavers.com/crossover",steamID:nil,symbol:"desktopcomputer")
    ]
    static let games = all.filter { $0.category == "Jeux" }
    static let office = all.filter { $0.category == "Bureautique" }
    static func forCategory(_ category:String) -> [OrbitSpotlightApp] {
        all.filter { $0.category == category }
    }
}

private struct OrbitSpotlightGroup: Identifiable {
    let id: String
    let apps: [OrbitSpotlightApp]
}

struct OrbitSpotlightShelf: View {
    let section: String
    let gameGenre: String

    var query: String = ""

    private var groups: [OrbitSpotlightGroup] {
        let q = query.trimmingCharacters(in:.whitespacesAndNewlines)
        func relevant(_ items:[OrbitSpotlightApp]) -> [OrbitSpotlightApp] {
            items.filter { item in
                (section != "Jeux" || gameGenre == "Tous" || item.genre == gameGenre) &&
                (q.isEmpty || [item.name,item.subtitle,item.genre,item.category]
                    .contains(where:{ $0.localizedCaseInsensitiveContains(q) }))
            }
        }
        if !q.isEmpty {
            return [.init(id:"Résultats parmi les suggestions",apps:relevant(
                section == "Découvrir" || section == "Tout" ? OrbitSpotlights.all :
                    OrbitSpotlights.forCategory(section)))]
        }
        if section == "Découvrir" || section == "Tout" {
            return [
                .init(id:"Jeux qui valent le détour",apps:Array(OrbitSpotlights.games.prefix(8))),
                .init(id:"Bureautique au quotidien",apps:Array(OrbitSpotlights.office.prefix(8))),
                .init(id:"Gagner du temps sur Mac",apps:Array(OrbitSpotlights.forCategory("Productivité").prefix(8))),
                .init(id:"Créer, monter, dessiner",apps:Array(OrbitSpotlights.forCategory("Création").prefix(8)))
            ]
        }
        return [.init(id:section == "Jeux" ? "Les jeux à connaître" : "Applications recommandées",
                      apps:relevant(OrbitSpotlights.forCategory(section)))]
    }

    var body: some View {
        ForEach(groups) { group in
            if !group.apps.isEmpty {
                VStack(alignment:.leading,spacing:10) {
                    HStack(alignment:.firstTextBaseline) {
                        Text(group.id).font(.title2.bold())
                        Spacer()
                        Text("Sélection éditoriale").font(.caption).foregroundStyle(.secondary)
                    }
                    ScrollView(.horizontal,showsIndicators:false) {
                        LazyHStack(spacing:13) {
                            ForEach(group.apps) { app in
                                Button {
                                    guard let url=app.officialURL,
                                          url.scheme == "https" else { return }
                                    NSWorkspace.shared.open(url)
                                } label: {
                                    VStack(alignment:.leading,spacing:8) {
                                        ZStack {
                                            RoundedRectangle(cornerRadius:13)
                                                .fill(LinearGradient(
                                                    colors:[Color.indigo.opacity(0.20),Color.purple.opacity(0.10)],
                                                    startPoint:.topLeading,endPoint:.bottomTrailing))
                                            if let url=app.artworkURL {
                                                AsyncImage(url:url) { image in
                                                    image.resizable().scaledToFill()
                                                } placeholder: {
                                                    Image(systemName:app.symbol)
                                                        .font(.system(size:35))
                                                        .foregroundStyle(.indigo)
                                                }
                                                .frame(width:228,height:103).clipped()
                                            } else {
                                                Image(systemName:app.symbol)
                                                    .font(.system(size:36,weight:.medium))
                                                    .foregroundStyle(.indigo)
                                            }
                                        }.frame(height:103).clipShape(RoundedRectangle(cornerRadius:13))
                                        Text(app.name).font(.subheadline.bold()).lineLimit(1)
                                            .foregroundStyle(.primary)
                                        Text(app.subtitle).font(.caption).foregroundStyle(.secondary)
                                            .lineLimit(2).frame(height:33,alignment:.topLeading)
                                        HStack {
                                            Label(app.source,systemImage:"arrow.up.right.square")
                                                .font(.caption2.weight(.medium))
                                            Spacer()
                                            if !app.genre.isEmpty {
                                                Text(app.genre).font(.caption2)
                                            }
                                        }.foregroundStyle(.indigo)
                                    }
                                    .padding(11).frame(width:248,alignment:.leading)
                                    .background(Color(nsColor:.controlBackgroundColor),
                                                in:RoundedRectangle(cornerRadius:18))
                                    .overlay(RoundedRectangle(cornerRadius:18)
                                        .stroke(.primary.opacity(0.07)))
                                }.buttonStyle(.plain)
                                .help("Ouvrir la fiche officielle (installation externe)")
                            }
                        }.padding(.vertical,2)
                    }
                    Text("Boutiques et éditeurs externes : vérifie les exigences macOS et le prix avant de télécharger. OrbitStore ne les installe pas automatiquement.")
                        .font(.caption2).foregroundStyle(.secondary)
                }
            }
        }
    }
}
