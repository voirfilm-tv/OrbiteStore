import importlib.util
import pathlib
import unittest

ROOT = pathlib.Path(__file__).resolve().parents[1]
spec = importlib.util.spec_from_file_location("catalog_index", ROOT / "scripts" / "index_catalog.py")
catalog = importlib.util.module_from_spec(spec)
spec.loader.exec_module(catalog)


class AssetClassificationTests(unittest.TestCase):
    def test_rejects_source_archive(self):
        self.assertFalse(catalog.is_macos_asset("project-source.zip"))
        self.assertFalse(catalog.is_macos_asset("project-src-mac.zip"))

    def test_rejects_windows_and_linux(self):
        self.assertFalse(catalog.is_macos_asset("app-windows.zip"))
        self.assertFalse(catalog.is_macos_asset("app-linux-x64.zip"))

    def test_recognizes_macos_packages(self):
        for name in ("OpenTTD-macos.dmg", "app-universal.pkg", "Game-darwin-arm64.zip",
                     "Game-macos-x86_64.zip"):
            self.assertTrue(catalog.is_macos_asset(name), name)

    def test_rejects_other_operating_system_pkgs_and_debug_symbols(self):
        self.assertFalse(catalog.is_macos_asset("Sunshine-FreeBSD-15.1-amd64.pkg"))
        self.assertFalse(catalog.is_macos_asset("tool.app.dSYM.zip"))
        self.assertFalse(catalog.is_macos_asset("cdda-osx-terminal-only.dmg"))

    def test_consumer_vs_developer_audience(self):
        self.assertEqual(catalog.classify_audience(
            {"full_name":"iina/iina","name":"iina","description":"Video player"}, "Multimédia","IINA.dmg"),"consumer")
        self.assertEqual(catalog.classify_audience(
            {"full_name":"unknown/commandtool","name":"Command tool","description":"CLI tool for developers"}, "Utilitaires","tool-macos.dmg"),"developer")
        self.assertEqual(catalog.classify_audience(
            {"full_name":"godotengine/godot","name":"Godot","description":"Game engine"}, "Développement","Godot-macos.zip"),"developer")

    def test_rejects_installer_marked_not_for_use(self):
        self.assertFalse(catalog.is_macos_asset("LosslessCut-mac-DONT-USE.pkg"))
        self.assertFalse(catalog.is_macos_asset("NotAnApp-macos-dSYM.zip"))

    def test_editorial_priority_is_not_package_verification(self):
        self.assertGreater(catalog.FEATURED_REPOS.get("openrct2/openrct2",0),0)
        self.assertFalse(catalog.is_macos_asset("OpenRCT2-source.zip"))
        self.assertIn(catalog.classify_audience(
            {"full_name":"storytold/photocraft","name":"PhotoCraft","description":"photo editor"},
            "Graphisme","photocraft-macos.dmg"),("consumer",))

    def test_negative_index_cache_expires(self):
        import datetime as dt
        fresh=(catalog.NOW-dt.timedelta(days=2)).isoformat()
        stale=(catalog.NOW-dt.timedelta(days=12)).isoformat()
        self.assertTrue(catalog.is_recent_rejection(fresh))
        self.assertFalse(catalog.is_recent_rejection(stale))
        self.assertFalse(catalog.is_recent_rejection("not-a-date"))

    def test_generic_zip_not_verified(self):
        self.assertFalse(catalog.is_macos_asset("release.zip"))

    def test_icon_finds_real_game_brand_in_data_directory(self):
        self.assertGreater(catalog.score_icon_path(
            "data/supertuxkart_512.png", "SuperTuxKart"), 100)
        self.assertEqual(catalog.ICON_PATH_HINTS["supertuxkart/stk-code"],
                         "data/supertuxkart_512.png")

    def test_icon_rejects_badges_and_ui_controls(self):
        self.assertEqual(catalog.score_icon_path(
            "docs/screenshots/supertuxkart_512.png", "SuperTuxKart"), -1)
        self.assertEqual(catalog.score_icon_path(
            "data/gui/icons/back.png", "SuperTuxKart"), -1)

    def test_genres_come_from_gameplay_not_stars(self):
        self.assertEqual(catalog.game_genre(
            "warzone2100/warzone2100", "Jeux"), "Stratégie")
        self.assertEqual(catalog.game_genre(
            "supertuxkart/stk-code", "Jeux"), "Course")
        self.assertEqual(catalog.game_genre(
            "drwhut/tabletop-club", "Jeux"), "Jeux de plateau")
        self.assertIsNone(catalog.game_genre(
            "appflowy-io/appflowy", "Bureautique"))

    def test_office_candidates_are_curated_without_bypassing_macos_gate(self):
        import json
        seeds=json.loads(catalog.SEEDS.read_text(encoding="utf-8"))
        names={item["repo"].lower():item["category"] for item in seeds}
        self.assertEqual(names["jgraph/drawio-desktop"],"Bureautique")
        self.assertEqual(names["obsidianmd/obsidian-releases"],"Bureautique")
        self.assertFalse(catalog.is_macos_asset("office-source.zip"))

    def test_no_frameworks_in_games(self):
        repo={"name":"Engine X","description":"A game engine","topics":["game-engine"]}
        self.assertEqual(catalog.classify("Jeux",repo,False),"Développement")

    def test_launchers_separate_from_playable_games(self):
        repo={"name":"Example Launcher","description":"A game launcher","topics":["game-launcher"]}
        self.assertEqual(catalog.classify("Jeux",repo,True),"Lanceurs & émulation")

    def test_game_porting_tool_is_not_playable_game(self):
        repo={"name":"NX2Apple","description":"Bring your own game to a one-click macOS app","topics":[]}
        self.assertEqual(catalog.classify("Jeux",repo,False),"Lanceurs & émulation")

    def test_game_engine_requiring_assets_is_not_a_game(self):
        repo={"name":"VCMI","description":"Open-source engine for Heroes of Might and Magic III","topics":[]}
        self.assertEqual(catalog.classify("Jeux",repo,False),"Lanceurs & émulation")

    def test_game_is_kept(self):
        repo={"name":"Great Game","description":"A beautiful turn-based strategy game","topics":["game"]}
        self.assertEqual(catalog.classify("Jeux",repo,False),"Jeux")


if __name__ == "__main__":
    unittest.main()
