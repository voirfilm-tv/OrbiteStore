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

    def test_generic_zip_not_verified(self):
        self.assertFalse(catalog.is_macos_asset("release.zip"))

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
