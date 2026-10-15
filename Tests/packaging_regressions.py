"""Check DogTag relocation and upstream release-version substitution."""

from pathlib import Path
import xml.etree.ElementTree as ET


ROOT = Path(__file__).resolve().parents[1]


def main():
    metadata = (ROOT / ".pkgmeta").read_text()
    source = Path("Modules/DogTagTexts")
    assert "PitBull4/Modules/DogTagTexts: PitBull4_DogTagTexts" in metadata
    document = ET.parse(ROOT / source / "load.xml")
    includes = [node.attrib["file"].replace("\\", "/")
                for node in document.getroot()
                if node.tag.rsplit("}", 1)[-1] == "Include"]
    assert len(includes) == 2
    for include in includes:
        path = Path(include)
        assert ".." not in path.parts, "DogTag must use its own packaged libraries"
        assert path.parts[0] == "Libs"
        destination = source / path.parent
        assert f"  {destination.as_posix()}: " in metadata
        relocated = Path("PitBull4_DogTagTexts") / path
        assert relocated.parts[:2] == ("PitBull4_DogTagTexts", "Libs")
    manifests = list(ROOT.glob("*.toc")) + list((ROOT / source).glob("*.toc"))
    for manifest in manifests:
        assert "## Version: @project-version@" in manifest.read_text(), manifest
    assert 'PitBull4.version = "@project-version@"' in (ROOT / "Main.lua").read_text()
    assert "  - Tests\n" in metadata
    assert "  - AGENTS.md\n" in metadata
    print(f"PASS: DogTag source/packaged paths, {len(manifests)} manifests, "
          "runtime version, and package exclusions.")


if __name__ == "__main__":
    main()
