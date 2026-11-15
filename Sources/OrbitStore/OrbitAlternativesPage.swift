import SwiftUI
import AppKit

// Transparent alternatives: a scoped replacement rather than a claim of
// feature parity. Every card links to a publisher or actual Mac package entry.
private struct OrbitReplacement: Identifiable {
    let name:String
    let category:String
    let replaces:String
    let summary:String
    let url:String
    let repository:String?
    let kind:String
    let symbol:String
    var id:String { category + ":" + name + ":" + replaces }
}

private enum OrbitReplacementLibrary {
    static let all:[OrbitReplacement] = [
        .init(name:"GIMP",category:"Graphisme",replaces:"Adobe Photoshop",
              summary:"Retouche et composition de photos",url:"https://www.gimp.org/",
              repository:"GNOME/gimp",kind:"Éditeur",symbol:"paintbrush.pointed.fill"),
        .init(name:"Krita",category:"Graphisme",replaces:"Adobe Fresco",
              summary:"Peinture numérique et illustration",url:"https://krita.org/",
              repository:"KDE/krita",kind:"Éditeur",symbol:"paintpalette.fill"),
        .init(name:"Inkscape",category:"Graphisme",replaces:"Adobe Illustrator",
              summary:"Dessin vectoriel professionnel",url:"https://inkscape.org/",
              repository:"inkscape/inkscape",kind:"Éditeur",symbol:"scribble.variable"),
        .init(name:"darktable",category:"Graphisme",replaces:"Adobe Lightroom",
              summary:"Développement et gestion des photos RAW",url:"https://www.darktable.org/",
              repository:"darktable-org/darktable",kind:"Éditeur",symbol:"camera.filters"),
        .init(name:"RawTherapee",category:"Graphisme",replaces:"Adobe Lightroom",
              summary:"Développement avancé de fichiers RAW",url:"https://rawtherapee.com/",
              repository:"Beep6581/RawTherapee",kind:"Éditeur",symbol:"camera.fill"),
        .init(name:"Penpot",category:"Graphisme",replaces:"Figma",
              summary:"Conception d'interfaces et collaboration web",url:"https://penpot.app/",
              repository:"penpot/penpot",kind:"Web",symbol:"rectangle.on.rectangle"),
        .init(name:"Photopea",category:"Graphisme",replaces:"Adobe Photoshop",
              summary:"Éditeur d'images dans le navigateur",url:"https://www.photopea.com/",
              repository:nil,kind:"Web",symbol:"photo.artframe"),
        .init(name:"Scribus",category:"Graphisme",replaces:"Adobe InDesign",
              summary:"Mise en page de documents et magazines",url:"https://www.scribus.net/",
              repository:nil,kind:"Éditeur",symbol:"doc.richtext"),
        .init(name:"Upscayl",category:"Graphisme",replaces:"Topaz Gigapixel",
              summary:"Agrandissement d'images par modèles locaux",url:"https://upscayl.org/",
              repository:"upscayl/upscayl",kind:"Éditeur",symbol:"arrow.up.left.and.arrow.down.right"),
        .init(name:"Kdenlive",category:"Création",replaces:"Adobe Premiere Pro",
              summary:"Montage vidéo libre multipiste",url:"https://kdenlive.org/",
              repository:"KDE/kdenlive",kind:"Éditeur",symbol:"film.fill"),
        .init(name:"Shotcut",category:"Création",replaces:"Adobe Premiere Pro",
              summary:"Montage vidéo complet et multiplateforme",url:"https://shotcut.org/",
              repository:"mltframework/shotcut",kind:"Éditeur",symbol:"film"),
        .init(name:"DaVinci Resolve",category:"Création",replaces:"Adobe Premiere Pro",
              summary:"Montage, étalonnage et mixage professionnels",url:"https://www.blackmagicdesign.com/products/davinciresolve",
              repository:nil,kind:"Éditeur",symbol:"video.fill"),
        .init(name:"Blender",category:"Création",replaces:"Cinema 4D",
              summary:"Modélisation, animation et rendu 3D",url:"https://www.blender.org/",
              repository:"blender/blender",kind:"Éditeur",symbol:"cube.fill"),
        .init(name:"Natron",category:"Création",replaces:"Adobe After Effects",
              summary:"Composition et effets visuels nodaux",url:"https://natrongithub.github.io/",
              repository:"NatronGitHub/Natron",kind:"Éditeur",symbol:"sparkles.tv"),
        .init(name:"OpenShot",category:"Création",replaces:"iMovie",
              summary:"Montage vidéo accessible aux débutants",url:"https://www.openshot.org/",
              repository:"OpenShot/openshot-qt",kind:"Éditeur",symbol:"scissors"),
        .init(name:"OBS Studio",category:"Création",replaces:"ScreenFlow (capture)",
              summary:"Capturer et diffuser l'écran, sans remplacer le montage",url:"https://obsproject.com/",
              repository:"obsproject/obs-studio",kind:"Éditeur",symbol:"record.circle"),
        .init(name:"LosslessCut",category:"Création",replaces:"Adobe Media Encoder (découpe)",
              summary:"Découper des vidéos sans les réencoder",url:"https://github.com/mifi/lossless-cut",
              repository:"mifi/lossless-cut",kind:"Éditeur",symbol:"scissors"),
        .init(name:"Gifski",category:"Création",replaces:"Adobe Photoshop (GIF)",
              summary:"Créer des GIF haute qualité depuis une vidéo",url:"https://sindresorhus.com/gifski",
              repository:"sindresorhus/Gifski",kind:"Éditeur",symbol:"photo.stack"),
        .init(name:"LibreOffice",category:"Bureautique",replaces:"Microsoft Office",
              summary:"Documents, tableurs et présentations",url:"https://www.libreoffice.org/",
              repository:nil,kind:"Éditeur",symbol:"doc.on.doc.fill"),
        .init(name:"ONLYOFFICE",category:"Bureautique",replaces:"Microsoft 365",
              summary:"Suite bureautique compatible avec les formats Office",url:"https://www.onlyoffice.com/desktop.aspx",
              repository:nil,kind:"Éditeur",symbol:"doc.text.fill"),
        .init(name:"Apple Pages",category:"Bureautique",replaces:"Microsoft Word",
              summary:"Documents et mise en page sur Mac",url:"https://apps.apple.com/fr/app/pages/id409201541",
              repository:nil,kind:"Mac App Store",symbol:"doc.richtext"),
        .init(name:"Apple Numbers",category:"Bureautique",replaces:"Microsoft Excel",
              summary:"Tableurs et tableaux interactifs",url:"https://apps.apple.com/fr/app/numbers/id409203825",
              repository:nil,kind:"Mac App Store",symbol:"tablecells.fill"),
        .init(name:"Apple Keynote",category:"Bureautique",replaces:"Microsoft PowerPoint",
              summary:"Diaporamas et présentations",url:"https://apps.apple.com/fr/app/keynote/id409183694",
              repository:nil,kind:"Mac App Store",symbol:"rectangle.on.rectangle"),
        .init(name:"draw.io",category:"Bureautique",replaces:"Microsoft Visio",
              summary:"Diagrammes, flux et organigrammes",url:"https://www.drawio.com/",
              repository:"jgraph/drawio-desktop",kind:"Éditeur",symbol:"square.on.square"),
        .init(name:"PDFgear",category:"Bureautique",replaces:"Adobe Acrobat",
              summary:"Lire, annoter et traiter des PDF courants",url:"https://www.pdfgear.com/",
              repository:nil,kind:"Éditeur",symbol:"doc.richtext"),
        .init(name:"MarkText",category:"Bureautique",replaces:"Typora",
              summary:"Éditeur Markdown avec aperçu direct",url:"https://github.com/marktext/marktext",
              repository:"marktext/marktext",kind:"Éditeur",symbol:"text.book.closed"),
        .init(name:"Zettlr",category:"Bureautique",replaces:"Typora",
              summary:"Éditeur Markdown pour rédaction longue",url:"https://www.zettlr.com/",
              repository:"Zettlr/Zettlr",kind:"Éditeur",symbol:"text.book.closed.fill"),
        .init(name:"Joplin",category:"Bureautique",replaces:"Evernote",
              summary:"Notes synchronisées et organisées",url:"https://joplinapp.org/",
              repository:"laurent22/joplin",kind:"Éditeur",symbol:"note.text"),
        .init(name:"AFFiNE",category:"Bureautique",replaces:"Notion",
              summary:"Documents, tableaux et tableaux blancs",url:"https://affine.pro/",
              repository:"toeverything/AFFiNE",kind:"Éditeur",symbol:"square.and.pencil"),
        .init(name:"AppFlowy",category:"Bureautique",replaces:"Notion",
              summary:"Espaces de notes et gestion de projets",url:"https://appflowy.com/",
              repository:"AppFlowy-IO/AppFlowy",kind:"Éditeur",symbol:"rectangle.3.group.fill"),
        .init(name:"Logseq",category:"Bureautique",replaces:"Roam Research",
              summary:"Connaissances liées et notes structurées",url:"https://logseq.com/",
              repository:"logseq/logseq",kind:"Éditeur",symbol:"point.3.connected.trianglepath.dotted"),
        .init(name:"Obsidian",category:"Bureautique",replaces:"Evernote",
              summary:"Notes locales liées et personnalisables",url:"https://obsidian.md/",
              repository:"obsidianmd/obsidian-releases",kind:"Éditeur",symbol:"note.text"),
        .init(name:"Standard Notes",category:"Bureautique",replaces:"Evernote",
              summary:"Notes privées et chiffrement",url:"https://standardnotes.com/",
              repository:"standardnotes/app",kind:"Éditeur",symbol:"lock.doc"),
        .init(name:"Raycast",category:"Productivité",replaces:"Spotlight",
              summary:"Lanceur, commandes et extensions",url:"https://www.raycast.com/",
              repository:nil,kind:"Éditeur",symbol:"bolt.fill"),
        .init(name:"Alfred",category:"Productivité",replaces:"Spotlight",
              summary:"Lancement et workflows au clavier",url:"https://www.alfredapp.com/",
              repository:nil,kind:"Éditeur",symbol:"magnifyingglass"),
        .init(name:"Rectangle",category:"Productivité",replaces:"Magnet",
              summary:"Gestion des fenêtres aux raccourcis clavier",url:"https://rectangleapp.com/",
              repository:"rxhanson/Rectangle",kind:"Éditeur",symbol:"rectangle.split.2x1"),
        .init(name:"Maccy",category:"Productivité",replaces:"Paste",
              summary:"Historique de presse-papiers léger",url:"https://maccy.app/",
              repository:"p0deje/Maccy",kind:"Éditeur",symbol:"doc.on.clipboard"),
        .init(name:"Espanso",category:"Productivité",replaces:"TextExpander",
              summary:"Raccourcis et expansion de texte",url:"https://espanso.org/",
              repository:"espanso/espanso",kind:"Éditeur",symbol:"text.cursor"),
        .init(name:"Todoist",category:"Productivité",replaces:"Microsoft To Do",
              summary:"Tâches, étiquettes et calendriers",url:"https://todoist.com/",
              repository:nil,kind:"Éditeur",symbol:"checklist"),
        .init(name:"Actual Budget",category:"Productivité",replaces:"YNAB",
              summary:"Suivi budgétaire local et auto-hébergeable",url:"https://actualbudget.org/",
              repository:"actualbudget/actual",kind:"Éditeur",symbol:"chart.pie"),
        .init(name:"AFFiNE",category:"Productivité",replaces:"Notion",
              summary:"Espace créatif pour idées et projets",url:"https://affine.pro/",
              repository:"toeverything/AFFiNE",kind:"Éditeur",symbol:"note.text"),
        .init(name:"Nextcloud",category:"Productivité",replaces:"Google Drive",
              summary:"Cloud de fichiers et collaboration auto-hébergée",url:"https://nextcloud.com/",
              repository:"nextcloud/server",kind:"Auto-hébergé",symbol:"cloud.fill"),
        .init(name:"Jitsi Meet",category:"Productivité",replaces:"Zoom",
              summary:"Visioconférences accessibles par navigateur",url:"https://meet.jit.si/",
              repository:"jitsi/jitsi-meet",kind:"Web",symbol:"video.fill"),
        .init(name:"REAPER",category:"Audio & musique",replaces:"Pro Tools",
              summary:"Production audio multipiste, licence payante",url:"https://www.reaper.fm/",
              repository:nil,kind:"Éditeur",symbol:"waveform"),
        .init(name:"Ardour",category:"Audio & musique",replaces:"Logic Pro",
              summary:"Enregistrement et mixage multipiste",url:"https://ardour.org/",
              repository:"Ardour/ardour",kind:"Éditeur",symbol:"waveform.path"),
        .init(name:"Audacity",category:"Audio & musique",replaces:"Adobe Audition",
              summary:"Montage et enregistrement audio",url:"https://www.audacityteam.org/",
              repository:"audacity/audacity",kind:"Éditeur",symbol:"waveform"),
        .init(name:"Ocenaudio",category:"Audio & musique",replaces:"Adobe Audition (édition simple)",
              summary:"Éditeur audio facile à prendre en main",url:"https://www.ocenaudio.com/",
              repository:nil,kind:"Éditeur",symbol:"waveform.path"),
        .init(name:"LMMS",category:"Audio & musique",replaces:"FL Studio",
              summary:"Création de beats et synthétiseurs",url:"https://lmms.io/",
              repository:"LMMS/lmms",kind:"Éditeur",symbol:"music.note"),
        .init(name:"MuseScore Studio",category:"Audio & musique",replaces:"Sibelius",
              summary:"Composition et édition de partitions",url:"https://musescore.org/",
              repository:"musescore/MuseScore",kind:"Éditeur",symbol:"music.quarternote.3"),
        .init(name:"Mixxx",category:"Audio & musique",replaces:"djay Pro",
              summary:"Mixage DJ et compatibilité contrôleurs",url:"https://mixxx.org/",
              repository:"mixxxdj/mixxx",kind:"Éditeur",symbol:"hifispeaker.fill"),
        .init(name:"IINA",category:"Multimédia",replaces:"QuickTime Player",
              summary:"Lecture vidéo avec formats avancés",url:"https://iina.io/",
              repository:"iina/iina",kind:"Éditeur",symbol:"play.rectangle"),
        .init(name:"VLC",category:"Multimédia",replaces:"Lecteurs propriétaires",
              summary:"Lecture de nombreux codecs vidéo et audio",url:"https://www.videolan.org/vlc/",
              repository:nil,kind:"Éditeur",symbol:"play.rectangle.fill"),
        .init(name:"HandBrake",category:"Multimédia",replaces:"Adobe Media Encoder",
              summary:"Transcodage et conversion de vidéos",url:"https://handbrake.fr/",
              repository:"HandBrake/HandBrake",kind:"Éditeur",symbol:"film"),
        .init(name:"Jellyfin",category:"Multimédia",replaces:"Plex",
              summary:"Serveur de médias personnels sans abonnement",url:"https://jellyfin.org/",
              repository:"jellyfin/jellyfin",kind:"Auto-hébergé",symbol:"server.rack"),
        .init(name:"Kodi",category:"Multimédia",replaces:"Plex (lecteur)",
              summary:"Centre multimédia et bibliothèque locale",url:"https://kodi.tv/",
              repository:"xbmc/xbmc",kind:"Éditeur",symbol:"tv.fill"),
        .init(name:"Navidrome",category:"Multimédia",replaces:"Spotify (musique personnelle)",
              summary:"Diffuser sa propre bibliothèque audio",url:"https://www.navidrome.org/",
              repository:"navidrome/navidrome",kind:"Auto-hébergé",symbol:"music.note.house"),
        .init(name:"Infuse",category:"Multimédia",replaces:"Plex (lecture)",
              summary:"Lire des films depuis des serveurs et NAS",url:"https://firecore.com/infuse",
              repository:nil,kind:"Éditeur",symbol:"play.tv"),
        .init(name:"Mozilla Firefox",category:"Internet",replaces:"Google Chrome",
              summary:"Navigateur indépendant et libre",url:"https://www.mozilla.org/fr/firefox/",
              repository:nil,kind:"Éditeur",symbol:"globe"),
        .init(name:"Brave",category:"Internet",replaces:"Google Chrome",
              summary:"Navigateur avec protections intégrées",url:"https://brave.com/fr/",
              repository:"brave/brave-browser",kind:"Éditeur",symbol:"shield.fill"),
        .init(name:"Vivaldi",category:"Internet",replaces:"Google Chrome",
              summary:"Navigateur très personnalisable",url:"https://vivaldi.com/fr/",
              repository:nil,kind:"Éditeur",symbol:"globe"),
        .init(name:"Zen Browser",category:"Internet",replaces:"Arc Browser",
              summary:"Navigateur avec espaces et interface épurée",url:"https://zen-browser.app/",
              repository:"zen-browser/desktop",kind:"Éditeur",symbol:"rectangle.split.3x1"),
        .init(name:"Thunderbird",category:"Internet",replaces:"Microsoft Outlook",
              summary:"Courrier, calendrier et contacts",url:"https://www.thunderbird.net/fr/",
              repository:nil,kind:"Éditeur",symbol:"envelope.fill"),
        .init(name:"Signal",category:"Internet",replaces:"WhatsApp",
              summary:"Messagerie privée multiplateforme",url:"https://signal.org/",
              repository:"signalapp/Signal-Desktop",kind:"Éditeur",symbol:"message.fill"),
        .init(name:"Tor Browser",category:"Internet",replaces:"Google Chrome (vie privée)",
              summary:"Navigation via le réseau Tor",url:"https://www.torproject.org/",
              repository:nil,kind:"Éditeur",symbol:"network"),
        .init(name:"Bitwarden",category:"Sécurité",replaces:"1Password",
              summary:"Gestionnaire de mots de passe et passkeys",url:"https://bitwarden.com/",
              repository:"bitwarden/clients",kind:"Éditeur",symbol:"lock.shield.fill"),
        .init(name:"KeePassXC",category:"Sécurité",replaces:"1Password",
              summary:"Coffre-fort local de mots de passe",url:"https://keepassxc.org/",
              repository:"keepassxreboot/keepassxc",kind:"Éditeur",symbol:"key.fill"),
        .init(name:"Cryptomator",category:"Sécurité",replaces:"Boxcryptor",
              summary:"Chiffrement local de fichiers cloud",url:"https://cryptomator.org/",
              repository:"cryptomator/cryptomator",kind:"Éditeur",symbol:"lock.doc"),
        .init(name:"VeraCrypt",category:"Sécurité",replaces:"BitLocker (conteneurs)",
              summary:"Volumes chiffrés multiplateformes",url:"https://veracrypt.io/",
              repository:"veracrypt/VeraCrypt",kind:"Éditeur",symbol:"externaldrive.fill"),
        .init(name:"Mullvad VPN",category:"Sécurité",replaces:"NordVPN",
              summary:"VPN axé sur la confidentialité",url:"https://mullvad.net/fr",
              repository:"mullvad/mullvadvpn-app",kind:"Éditeur",symbol:"network.badge.shield.half.filled"),
        .init(name:"Proton VPN",category:"Sécurité",replaces:"NordVPN",
              summary:"VPN avec application Mac",url:"https://protonvpn.com/",
              repository:"ProtonVPN/mac-app",kind:"Éditeur",symbol:"shield.fill"),
        .init(name:"LuLu",category:"Sécurité",replaces:"Little Snitch (règles de sortie)",
              summary:"Pare-feu sortant macOS gratuit",url:"https://objective-see.org/products/lulu.html",
              repository:"objective-see/LuLu",kind:"Éditeur",symbol:"lock.shield"),
        .init(name:"LocalSend",category:"Réseau",replaces:"AirDrop (hors Apple)",
              summary:"Transfert direct entre Mac, Windows et mobile",url:"https://localsend.org/",
              repository:"localsend/localsend",kind:"Éditeur",symbol:"arrow.left.arrow.right"),
        .init(name:"RustDesk",category:"Réseau",replaces:"TeamViewer",
              summary:"Accès à distance et contrôle d'écran",url:"https://rustdesk.com/",
              repository:"rustdesk/rustdesk",kind:"Éditeur",symbol:"desktopcomputer"),
        .init(name:"Cyberduck",category:"Réseau",replaces:"FileZilla Pro",
              summary:"Transfert SFTP, WebDAV et stockage cloud",url:"https://cyberduck.io/",
              repository:"iterate-ch/cyberduck",kind:"Éditeur",symbol:"folder"),
        .init(name:"Transmission",category:"Réseau",replaces:"µTorrent",
              summary:"Client torrent léger et libre",url:"https://transmissionbt.com/",
              repository:"transmission/transmission",kind:"Éditeur",symbol:"arrow.down.circle"),
        .init(name:"qBittorrent",category:"Réseau",replaces:"µTorrent",
              summary:"Client torrent riche et sans publicité",url:"https://www.qbittorrent.org/",
              repository:"qbittorrent/qBittorrent",kind:"Éditeur",symbol:"arrow.down.circle.fill"),
        .init(name:"Tailscale",category:"Réseau",replaces:"Hamachi",
              summary:"Réseau privé chiffré entre appareils",url:"https://tailscale.com/",
              repository:"tailscale/tailscale",kind:"Éditeur",symbol:"network"),
        .init(name:"Keka",category:"Utilitaires",replaces:"WinRAR",
              summary:"Archivage et décompression",url:"https://www.keka.io/fr/",
              repository:nil,kind:"Éditeur",symbol:"archivebox.fill"),
        .init(name:"AppCleaner",category:"Utilitaires",replaces:"CleanMyMac (désinstallation)",
              summary:"Supprimer une application et ses fichiers annexes",url:"https://freemacsoft.net/appcleaner/",
              repository:nil,kind:"Éditeur",symbol:"trash.fill"),
        .init(name:"Pearcleaner",category:"Utilitaires",replaces:"CleanMyMac (désinstallation)",
              summary:"Nettoyer les restes d'applications",url:"https://github.com/alienator88/Pearcleaner",
              repository:"alienator88/Pearcleaner",kind:"Éditeur",symbol:"trash"),
        .init(name:"Stats",category:"Utilitaires",replaces:"iStat Menus",
              summary:"Surveillance CPU, mémoire et ventilateurs",url:"https://github.com/exelban/stats",
              repository:"exelban/stats",kind:"Éditeur",symbol:"chart.xyaxis.line"),
        .init(name:"UTM",category:"Utilitaires",replaces:"Parallels Desktop",
              summary:"Virtualiser ou émuler d'autres systèmes",url:"https://mac.getutm.app/",
              repository:"utmapp/UTM",kind:"Éditeur",symbol:"desktopcomputer"),
        .init(name:"MonitorControl",category:"Utilitaires",replaces:"Lunar (luminosité)",
              summary:"Régler la luminosité des écrans externes",url:"https://github.com/MonitorControl/MonitorControl",
              repository:"MonitorControl/MonitorControl",kind:"Éditeur",symbol:"sun.max.fill"),
        .init(name:"Ice",category:"Personnalisation",replaces:"Bartender",
              summary:"Organiser les icônes de la barre des menus",url:"https://github.com/jordanbaird/Ice",
              repository:"jordanbaird/Ice",kind:"Éditeur",symbol:"menubar.rectangle"),
        .init(name:"AltTab",category:"Personnalisation",replaces:"Alt+Tab Windows",
              summary:"Naviguer entre les fenêtres ouvertes",url:"https://alt-tab-macos.netlify.app/",
              repository:"alt-tab-macos/alt-tab-macos",kind:"Éditeur",symbol:"square.grid.2x2"),
        .init(name:"Rectangle",category:"Personnalisation",replaces:"Magnet",
              summary:"Positionner et redimensionner les fenêtres",url:"https://rectangleapp.com/",
              repository:"rxhanson/Rectangle",kind:"Éditeur",symbol:"rectangle.split.2x1"),
        .init(name:"Mac Mouse Fix",category:"Personnalisation",replaces:"SteerMouse",
              summary:"Personnaliser défilement et gestes de souris",url:"https://macmousefix.com/",
              repository:"mac-mouse-fix/mac-mouse-fix",kind:"Éditeur",symbol:"computermouse"),
        .init(name:"Itsycal",category:"Personnalisation",replaces:"Fantastical (mini-calendrier)",
              summary:"Calendrier de barre des menus",url:"https://www.mowglii.com/itsycal/",
              repository:nil,kind:"Éditeur",symbol:"calendar"),
        .init(name:"Karabiner-Elements",category:"Accessibilité",replaces:"Réglages clavier avancés",
              summary:"Changer et adapter les touches du clavier",url:"https://karabiner-elements.pqrs.org/",
              repository:"pqrs-org/Karabiner-Elements",kind:"Éditeur",symbol:"keyboard"),
        .init(name:"LinearMouse",category:"Accessibilité",replaces:"SteerMouse (défilement)",
              summary:"Ajuster les mouvements de souris",url:"https://linearmouse.app/",
              repository:"linearmouse/linearmouse",kind:"Éditeur",symbol:"cursorarrow"),
        .init(name:"HazeOver",category:"Accessibilité",replaces:"Modes concentration",
              summary:"Atténuer les fenêtres inactives",url:"https://hazeover.com/",
              repository:nil,kind:"Éditeur",symbol:"eye"),
        .init(name:"MonitorControl",category:"Accessibilité",replaces:"Lunar (luminosité)",
              summary:"Contrôle de l'écran externe",url:"https://github.com/MonitorControl/MonitorControl",
              repository:"MonitorControl/MonitorControl",kind:"Éditeur",symbol:"sun.max"),
        .init(name:"VoiceOver",category:"Accessibilité",replaces:"Lecteurs d'écran tiers",
              summary:"Lecteur d'écran intégré à macOS",url:"https://www.apple.com/fr/accessibility/vision/",
              repository:nil,kind:"Inclus macOS",symbol:"eye.fill"),
        .init(name:"Anki",category:"Éducation",replaces:"Quizlet",
              summary:"Cartes de mémorisation et révisions",url:"https://apps.ankiweb.net/",
              repository:"ankitects/anki",kind:"Éditeur",symbol:"rectangle.on.rectangle"),
        .init(name:"Zotero",category:"Éducation",replaces:"EndNote",
              summary:"Sources, bibliographies et citations",url:"https://www.zotero.org/",
              repository:"zotero/zotero",kind:"Éditeur",symbol:"books.vertical.fill"),
        .init(name:"GeoGebra",category:"Éducation",replaces:"Outils de maths propriétaires",
              summary:"Mathématiques et géométrie dynamiques",url:"https://www.geogebra.org/",
              repository:nil,kind:"Éditeur",symbol:"function"),
        .init(name:"Stellarium",category:"Éducation",replaces:"Star Walk",
              summary:"Planétarium et ciel nocturne",url:"https://stellarium.org/",
              repository:"Stellarium/stellarium",kind:"Éditeur",symbol:"star.fill"),
        .init(name:"GCompris",category:"Éducation",replaces:"Jeux éducatifs payants",
              summary:"Activités et mini-jeux pédagogiques",url:"https://gcompris.net/",
              repository:nil,kind:"Éditeur",symbol:"gamecontroller"),
        .init(name:"VSCodium",category:"Développement",replaces:"Visual Studio Code",
              summary:"Distribution de VS Code sans télémétrie Microsoft par défaut",url:"https://vscodium.com/",
              repository:"VSCodium/vscodium",kind:"Éditeur",symbol:"chevron.left.forwardslash.chevron.right"),
        .init(name:"Zed",category:"Développement",replaces:"Visual Studio Code",
              summary:"Éditeur rapide pour programmation",url:"https://zed.dev/",
              repository:"zed-industries/zed",kind:"Éditeur",symbol:"chevron.left.forwardslash.chevron.right"),
        .init(name:"DBeaver",category:"Développement",replaces:"DataGrip",
              summary:"Client de bases de données",url:"https://dbeaver.io/",
              repository:"dbeaver/dbeaver",kind:"Éditeur",symbol:"externaldrive"),
        .init(name:"Bruno",category:"Développement",replaces:"Postman",
              summary:"Collection et tests d'API dans le dépôt",url:"https://www.usebruno.com/",
              repository:"usebruno/bruno",kind:"Éditeur",symbol:"network"),
        .init(name:"Insomnia",category:"Développement",replaces:"Postman",
              summary:"Tester les APIs HTTP et GraphQL",url:"https://insomnia.rest/",
              repository:"Kong/insomnia",kind:"Éditeur",symbol:"network"),
        .init(name:"GitHub Desktop",category:"Développement",replaces:"Sourcetree",
              summary:"Interface Git pour les repositories",url:"https://desktop.github.com/",
              repository:"desktop/desktop",kind:"Éditeur",symbol:"arrow.triangle.branch"),
        .init(name:"Hoppscotch",category:"Développement",replaces:"Postman",
              summary:"Tests d'API dans le navigateur",url:"https://hoppscotch.io/",
              repository:"hoppscotch/hoppscotch",kind:"Web",symbol:"network"),
        .init(name:"Ollama",category:"Développement",replaces:"Services IA cloud",
              summary:"Exécuter certains modèles IA localement",url:"https://ollama.com/",
              repository:"ollama/ollama",kind:"Éditeur",symbol:"cpu"),
        .init(name:"Unciv",category:"Jeux",replaces:"Civilization",
              summary:"Stratégie au tour par tour inspirée de Civ",url:"https://github.com/yairm210/Unciv",
              repository:"yairm210/Unciv",kind:"Éditeur",symbol:"globe"),
        .init(name:"0 A.D.",category:"Jeux",replaces:"Age of Empires",
              summary:"Stratégie historique temps réel",url:"https://play0ad.com/",
              repository:"0ad/0ad",kind:"Éditeur",symbol:"flag.2.crossed"),
        .init(name:"OpenRA",category:"Jeux",replaces:"Command & Conquer",
              summary:"Jeux de stratégie rétro en temps réel",url:"https://www.openra.net/",
              repository:"OpenRA/OpenRA",kind:"Éditeur",symbol:"flag"),
        .init(name:"Widelands",category:"Jeux",replaces:"The Settlers",
              summary:"Stratégie de gestion et économie",url:"https://www.widelands.org/",
              repository:"widelands/widelands",kind:"Éditeur",symbol:"house.fill"),
        .init(name:"Tabletop Club",category:"Jeux",replaces:"Tabletop Simulator",
              summary:"Table de jeu 3D open source",url:"https://github.com/drwhut/tabletop-club",
              repository:"drwhut/tabletop-club",kind:"Éditeur",symbol:"die.face.5"),
        .init(name:"Beyond All Reason",category:"Jeux",replaces:"Supreme Commander",
              summary:"Stratégie de bataille à grande échelle",url:"https://www.beyondallreason.info/",
              repository:"Beyond-All-Reason/Beyond-All-Reason",kind:"Éditeur",symbol:"shield.fill"),
        .init(name:"Immich",category:"Auto-hébergé",replaces:"Google Photos",
              summary:"Photos et sauvegardes sur son serveur",url:"https://immich.app/",
              repository:"immich-app/immich",kind:"Auto-hébergé",symbol:"photo.on.rectangle"),
        .init(name:"Nextcloud",category:"Auto-hébergé",replaces:"Google Drive",
              summary:"Fichiers et collaboration sur son cloud",url:"https://nextcloud.com/",
              repository:"nextcloud/server",kind:"Auto-hébergé",symbol:"cloud.fill"),
        .init(name:"Jellyfin",category:"Auto-hébergé",replaces:"Plex",
              summary:"Serveur libre de films et séries",url:"https://jellyfin.org/",
              repository:"jellyfin/jellyfin",kind:"Auto-hébergé",symbol:"play.rectangle"),
        .init(name:"Home Assistant",category:"Auto-hébergé",replaces:"SmartThings",
              summary:"Domotique locale et automatisations",url:"https://www.home-assistant.io/",
              repository:"home-assistant/core",kind:"Auto-hébergé",symbol:"house.fill"),
        .init(name:"Paperless-ngx",category:"Auto-hébergé",replaces:"Archive de documents cloud",
              summary:"Archivage et classement de factures",url:"https://docs.paperless-ngx.com/",
              repository:"paperless-ngx/paperless-ngx",kind:"Auto-hébergé",symbol:"doc.on.doc"),
        .init(name:"Vaultwarden",category:"Auto-hébergé",replaces:"Bitwarden hébergé",
              summary:"Serveur de mots de passe compatible Bitwarden",url:"https://github.com/dani-garcia/vaultwarden",
              repository:"dani-garcia/vaultwarden",kind:"Auto-hébergé",symbol:"lock.shield"),
        .init(name:"Navidrome",category:"Auto-hébergé",replaces:"Spotify (sa musique)",
              summary:"Serveur de bibliothèque musicale personnelle",url:"https://www.navidrome.org/",
              repository:"navidrome/navidrome",kind:"Auto-hébergé",symbol:"music.note.house"),
        .init(name:"Actual Budget",category:"Auto-hébergé",replaces:"YNAB",
              summary:"Budget personnel auto-hébergé",url:"https://actualbudget.org/",
              repository:"actualbudget/actual",kind:"Auto-hébergé",symbol:"chart.pie"),
        .init(name:"Forgejo",category:"Auto-hébergé",replaces:"GitHub (gestion Git)",
              summary:"Forge Git indépendante",url:"https://forgejo.org/",
              repository:"forgejo/forgejo",kind:"Auto-hébergé",symbol:"arrow.triangle.branch"),
        .init(name:"Uptime Kuma",category:"Auto-hébergé",replaces:"Pingdom",
              summary:"Suivi de disponibilité de services",url:"https://uptime.kuma.pet/",
              repository:"louislam/uptime-kuma",kind:"Auto-hébergé",symbol:"waveform.path.ecg")
    ]
    static var categories:[String] {
        Array(Set(all.map(\.category))).sorted()
    }
}

struct OrbitAlternativesPage:View {
    @EnvironmentObject private var store:StoreModel
    @EnvironmentObject private var operations:OrbitOperations
    @Binding var query:String
    @State private var category="Toutes"
    @State private var availability="Toutes"
    @State private var selected:CatalogApp?
    @State private var limit=30

    private func package(_ item:OrbitReplacement) -> CatalogApp? {
        guard item.kind=="Éditeur", let repo=item.repository else { return nil }
        let app=CatalogApp(repo:repo,name:item.name,category:item.category,
                           icon:item.symbol,aliases:[])
        guard store.catalogIsVerifiedMac(app) else { return nil }
        return store.catalog.first(where: {
            $0.repo.caseInsensitiveCompare(repo) == .orderedSame
        }) ?? app
    }

    private var entries:[OrbitReplacement] {
        let value=query.trimmingCharacters(in:.whitespacesAndNewlines)
        return OrbitReplacementLibrary.all.filter { item in
            (category=="Toutes" || item.category==category) &&
            (availability=="Toutes" ||
                (availability=="OrbitStore" && package(item) != nil) ||
                (availability=="Sources externes" && package(item)==nil)) &&
            (value.isEmpty || [item.name,item.replaces,item.summary,item.category]
                .contains(where:{$0.localizedCaseInsensitiveContains(value)}))
        }
    }

    private func open(_ item:OrbitReplacement) {
        if let app=package(item) {
            selected=app
        } else if let url=URL(string:item.url),url.scheme=="https" {
            NSWorkspace.shared.open(url)
        }
    }

    @ViewBuilder private func mark(_ item:OrbitReplacement)->some View {
        if let app=package(item),store.catalogIconURL(app) != nil {
            AuthenticAppIcon(repo:app.repo,name:app.name,
                iconURL:store.catalogIconURL(app),size:56)
        } else {
            Image(systemName:item.symbol)
                .font(.system(size:25,weight:.medium))
                .foregroundStyle(.indigo)
                .frame(width:56,height:56)
                .background(.indigo.opacity(0.09),
                            in:RoundedRectangle(cornerRadius:13))
        }
    }

    private func tile(_ item:OrbitReplacement)->some View {
        VStack(alignment:.leading,spacing:13) {
            HStack(alignment:.top,spacing:12) {
                mark(item)
                VStack(alignment:.leading,spacing:5) {
                    Text(item.name).font(.headline).foregroundStyle(.primary).lineLimit(1)
                    Text(item.category).font(.caption2).foregroundStyle(.secondary)
                }
                Spacer(minLength:4)
                Image(systemName:"arrow.up.right").font(.caption)
                    .foregroundStyle(.tertiary)
            }
            HStack(spacing:5) {
                Text("À la place de").font(.caption).foregroundStyle(.secondary)
                Text(item.replaces).font(.caption.weight(.semibold))
                    .foregroundStyle(.primary).lineLimit(2)
            }
            Text(item.summary).font(.subheadline).foregroundStyle(.secondary)
                .lineLimit(2).frame(height:38,alignment:.topLeading)
            Spacer(minLength:4)
            HStack(spacing:5) {
                if package(item) != nil {
                    Label("Fiche OrbitStore",systemImage:"checkmark.circle.fill")
                } else {
                    Label(item.kind,systemImage:"arrow.up.right.square")
                }
                Spacer()
                Image(systemName:"chevron.right")
            }
            .font(.caption.weight(.medium)).foregroundStyle(.indigo)
        }
        .padding(16).frame(maxWidth:.infinity,minHeight:207,alignment:.topLeading)
        .background(Color(nsColor:.controlBackgroundColor),
                    in:RoundedRectangle(cornerRadius:17))
        .overlay(RoundedRectangle(cornerRadius:17)
            .stroke(.primary.opacity(0.07)))
    }

    var body:some View {
        VStack(alignment:.leading,spacing:19) {
            VStack(alignment:.leading,spacing:6) {
                Label("Alternatives",systemImage:"arrow.triangle.branch")
                    .font(.system(size:31,weight:.bold,design:.rounded))
                Text("Trouve une autre solution aux logiciels populaires : pour les documents, la création, les jeux, la sécurité et le web.")
                    .font(.subheadline).foregroundStyle(.secondary)
                Text("Les alternatives ne sont pas forcément identiques : les différences de fonctions, de licence et de compatibilité doivent être vérifiées.")
                    .font(.caption).foregroundStyle(.secondary)
            }
            HStack(spacing:9) {
                Picker("Usage",selection:$category) {
                    Text("Tous les usages").tag("Toutes")
                    ForEach(OrbitReplacementLibrary.categories,id:\.self) { key in
                        Text(key).tag(key)
                    }
                }.pickerStyle(.menu).frame(width:200)
                Picker("Disponibilité",selection:$availability) {
                    Text("Toutes les sources").tag("Toutes")
                    Text("Fiche OrbitStore").tag("OrbitStore")
                    Text("Éditeurs et services").tag("Sources externes")
                }.pickerStyle(.menu).frame(width:200)
                Spacer()
                Text("\(entries.count) propositions").font(.caption).foregroundStyle(.secondary)
            }
            LazyVGrid(columns:[GridItem(.adaptive(minimum:275),spacing:14)],
                      alignment:.leading,spacing:14) {
                ForEach(Array(entries.prefix(limit))) { item in
                    Button { open(item) } label: { tile(item) }
                        .buttonStyle(.plain)
                }
            }
            if entries.isEmpty {
                ContentUnavailableView("Aucune alternative trouvée",
                    systemImage:"magnifyingglass",
                    description:Text("Essaie un nom de logiciel, un usage ou une autre source."))
                    .frame(maxWidth:.infinity,minHeight:140)
            }
            if entries.count>limit {
                HStack {
                    Spacer()
                    Button("Afficher davantage (\(entries.count-limit) restantes)") {
                        limit += 30
                    }.buttonStyle(.borderedProminent)
                    Spacer()
                }
            }
            Label("Installable signifie seulement qu'un paquet macOS a été repéré dans une release. Les boutiques officielles, services web et hébergements personnels s'ouvrent à l'extérieur.",
                systemImage:"info.circle")
                .font(.caption).foregroundStyle(.secondary)
        }
        .onChange(of:category) { _ in limit=30 }
        .onChange(of:availability) { _ in limit=30 }
        .onChange(of:query) { _ in limit=30 }
        .sheet(item:$selected) { app in
            CatalogDetails(entry:app)
                .environmentObject(store).environmentObject(operations)
        }
    }
}
