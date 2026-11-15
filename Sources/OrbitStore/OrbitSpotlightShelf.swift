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
    static let games: [OrbitSpotlightApp] = [
        .init(name:"Tabletop Simulator",category:"Jeux",genre:"Jeux de plateau",
              subtitle:"Jeux de société, cartes et plateaux à plusieurs",source:"Steam",
              link:"https://store.steampowered.com/app/286160/",steamID:286160,symbol:"die.face.5.fill"),
        .init(name:"Civilization VI",category:"Jeux",genre:"Stratégie",
              subtitle:"Civilisations, diplomatie et conquête au tour par tour",source:"Steam",
              link:"https://store.steampowered.com/app/289070/",steamID:289070,symbol:"globe.europe.africa.fill"),
        .init(name:"Northgard",category:"Jeux",genre:"Stratégie",
              subtitle:"Stratégie et survie dans un univers viking",source:"Steam",
              link:"https://store.steampowered.com/app/466560/",steamID:466560,symbol:"shield.fill"),
        .init(name:"Balatro",category:"Jeux",genre:"Jeux de plateau",
              subtitle:"Cartes, combinaisons et roguelike",source:"Steam",
              link:"https://store.steampowered.com/app/2379780/",steamID:2379780,symbol:"suit.spade.fill"),
        .init(name:"Stardew Valley",category:"Jeux",genre:"Gestion",
              subtitle:"Ferme, village et coopération",source:"Steam",
              link:"https://store.steampowered.com/app/413150/",steamID:413150,symbol:"leaf.fill"),
        .init(name:"RimWorld",category:"Jeux",genre:"Gestion",
              subtitle:"Construire, gérer et défendre une colonie",source:"Steam",
              link:"https://store.steampowered.com/app/294100/",steamID:294100,symbol:"house.fill")
    ]

    static let office: [OrbitSpotlightApp] = [
        .init(name:"Microsoft 365",category:"Bureautique",genre:"",
              subtitle:"Word, Excel, PowerPoint et Outlook pour Mac",source:"Éditeur",
              link:"https://www.microsoft.com/fr-fr/microsoft-365",steamID:nil,symbol:"square.grid.2x2.fill"),
        .init(name:"LibreOffice",category:"Bureautique",genre:"",
              subtitle:"Traitement de texte, tableur et présentations gratuits",source:"Éditeur",
              link:"https://www.libreoffice.org/download/download-libreoffice/",steamID:nil,symbol:"doc.on.doc.fill"),
        .init(name:"Apple Pages",category:"Bureautique",genre:"",
              subtitle:"Documents et mise en page sur Mac",source:"Mac App Store",
              link:"https://apps.apple.com/fr/app/pages/id409201541",steamID:nil,symbol:"doc.richtext"),
        .init(name:"Apple Numbers",category:"Bureautique",genre:"",
              subtitle:"Tableurs et tableaux",source:"Mac App Store",
              link:"https://apps.apple.com/fr/app/numbers/id409203825",steamID:nil,symbol:"tablecells.fill"),
        .init(name:"Apple Keynote",category:"Bureautique",genre:"",
              subtitle:"Présentations et diaporamas",source:"Mac App Store",
              link:"https://apps.apple.com/fr/app/keynote/id409183694",steamID:nil,symbol:"rectangle.on.rectangle"),
        .init(name:"Notion",category:"Bureautique",genre:"",
              subtitle:"Notes, projets et espaces collaboratifs",source:"Éditeur",
              link:"https://www.notion.com/desktop",steamID:nil,symbol:"square.and.pencil")
    ]
}

private struct OrbitSpotlightGroup: Identifiable {
    let id: String
    let apps: [OrbitSpotlightApp]
}

struct OrbitSpotlightShelf: View {
    let section: String
    let gameGenre: String

    private var groups: [OrbitSpotlightGroup] {
        if section == "Jeux" {
            return [.init(id:"Des jeux qui donnent envie",apps:OrbitSpotlights.games.filter {
                gameGenre == "Tous" || $0.genre == gameGenre
            })]
        }
        if section == "Bureautique" {
            return [.init(id:"Les vrais incontournables",apps:OrbitSpotlights.office)]
        }
        return [.init(id:"Jeux incontournables",apps:OrbitSpotlights.games),
                .init(id:"Bureautique au quotidien",apps:OrbitSpotlights.office)]
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
